//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "hardhat/console.sol";
import "./utils/Constants.sol";
import "./interfaces/IStrategy.sol";

contract Zunami is Context, Ownable, ERC20 {
    using SafeERC20 for IERC20Metadata;

    struct PendingDeposit {
        uint256[3] amounts;
        address depositor;
    }

    struct PendingWithdrawal {
        uint256 lpAmount;
        uint256[3] minAmounts;
        address withdrawer;
    }

    struct PoolInfo {
        IStrategy strategy;
        uint256 startTime;
    }

    uint8 private constant POOL_ASSETS = 3;

    address[POOL_ASSETS] public tokens;
    mapping(address => uint256) public deposited;
    // Info of each pool
    PoolInfo[] public poolInfo;
    uint256 public totalDeposited;

    uint256 public FEE_DENOMINATOR = 1000;
    uint256 public managementFee = 10; // 1%
    bool public isLock = false;
    uint256 public constant MIN_LOCK_TIME = 86400; // 1 day

    address public admin;
    uint256 public completedDeposits;
    uint256 public completedWithdrawals;
    PendingWithdrawal[] public pendingWithdrawals;
    mapping(address => uint256[]) public accDepositPending;

    event Deposited(address depositor, uint256[3] amounts, uint256 lpShares);
    event Withdrawn(address withdrawer, uint256[3] amounts, uint256 lpShares);
    event AddStrategy(address strategyAddr);
    event BadDeposit(address depositor, uint256[3] amounts, uint256 lpShares);
    event BadWithdraw(address withdrawer, uint256[3] amounts, uint256 lpShares);

    modifier isLocked() {
        require(!isLock, "Zunami: Deposit functions locked");
        _;
    }

    constructor() ERC20("ZunamiLP", "ZLP") {
        tokens[0] = Constants.DAI_ADDRESS;
        tokens[1] = Constants.USDC_ADDRESS;
        tokens[2] = Constants.USDT_ADDRESS;
    }

    function setManagementFee(uint256 newManagementFee) external onlyOwner {
        require(newManagementFee < FEE_DENOMINATOR, "Zunami: wrong fee");
        managementFee = newManagementFee;
    }

    function calcManagementFee(uint256 amount) public view virtual
    returns (uint256)
    {
        return (amount * managementFee) / FEE_DENOMINATOR;
    }

    // total holdings for all pools
    function totalHoldings() public view virtual returns (uint256) {
        uint256 length = poolInfo.length;
        uint256 totalHold = 0;
        for (uint256 pid = 0; pid < length; ++pid) {
            totalHold + poolInfo[pid].strategy.totalHoldings();
        }
        return totalHold;
    }

    function lpPrice() public view virtual returns (uint256) {
        return totalHoldings() / totalSupply();
    }

    function delegateDeposit(uint256[3] memory amounts) external virtual isLocked {
        // user transfer funds to contract
        for (uint256 i = 0; i < amounts.length; ++i) {
            if (amounts[i] > 0) {
                IERC20Metadata(tokens[i]).safeTransferFrom(
                    _msgSender(),
                    address(this),
                    amounts[i]
                );
            }
        }
        accDepositPending[_msgSender()] = amounts;
    }


    function delegateWithdrawal(uint256 lpAmount, uint256[3] memory minAmounts)
    external virtual
    {
        PendingWithdrawal memory pendingWithdrawal;
        pendingWithdrawal.lpAmount = lpAmount;
        pendingWithdrawal.minAmounts = minAmounts;
        pendingWithdrawal.withdrawer = _msgSender();
        pendingWithdrawals.push(pendingWithdrawal);
    }

    function completeDeposits(address[] memory userList, uint256 pid)
    external virtual onlyOwner
    {
        IStrategy strategy = poolInfo[pid].strategy;
        uint256[3] memory totalAmounts;
        // total sum deposit, contract > strategy
        uint256 addHoldings = 0;
        // sum for calculate LPs
        for (uint256 i = 0; i < userList.length; i++) {
            // calculate user deposit amounts
            uint256 sum = 0;
            for (uint256 x = 0; x < totalAmounts.length; ++x) {
                uint256 decimalsMultiplier = 1;
                if (IERC20Metadata(tokens[x]).decimals() < 18) {
                    decimalsMultiplier =
                    10 ** (18 - IERC20Metadata(tokens[x]).decimals());
                }
                totalAmounts[x] += accDepositPending[userList[i]][x];
                addHoldings += accDepositPending[userList[i]][x] * decimalsMultiplier;
                sum += accDepositPending[userList[i]][x] * decimalsMultiplier;
            }
            // calculate lpShares
            uint256 lpShares = 0;
            uint256 holdings = totalHoldings();
            deposited[userList[i]] += sum;
            totalDeposited += sum;
            if (holdings == 0) {
                lpShares = sum;
            } else {
                lpShares = (sum * totalSupply()) / (holdings + addHoldings - sum);
            }
            _mint(userList[i], lpShares);
            // remove deposit from list
            accDepositPending[userList[i]] = [0, 0, 0];
        }
        for (uint256 _i = 0; _i < POOL_ASSETS; ++_i) {
            if (totalAmounts[_i] > 0) {
                IERC20Metadata(tokens[_i]).safeTransfer(address(strategy), totalAmounts[_i]);
            }
        }
        require(strategy.deposit(totalAmounts), "too low amount!");
    }

    function completeWithdrawals(uint256 withdrawalsToComplete, uint256 pid)
    external virtual onlyOwner
    {
        uint256 maxWithdrawals = withdrawalsToComplete < pendingWithdrawals.length
        ? withdrawalsToComplete : pendingWithdrawals.length;
        for (uint256 i = 0; i < maxWithdrawals && pendingWithdrawals.length > 0; i++) {
            delegatedWithdrawal(
                pendingWithdrawals[0].withdrawer,
                pendingWithdrawals[0].lpAmount,
                pendingWithdrawals[0].minAmounts,
                pid
            );
            pendingWithdrawals[0] = pendingWithdrawals[pendingWithdrawals.length - 1];
            pendingWithdrawals.pop();
        }
    }

    function deposit(uint256[3] memory amounts, uint256 pid)
    external virtual isLocked returns (uint256)
    {
        IStrategy strategy = poolInfo[pid].strategy;
        require(block.timestamp >= poolInfo[pid].startTime, "Zunami: strategy not started yet!");
        uint256 sum = 0;
        for (uint256 i = 0; i < POOL_ASSETS; ++i) {
            uint256 decimalsMultiplier = 1;
            if (IERC20Metadata(tokens[i]).decimals() < 18) {
                decimalsMultiplier =
                10 ** (18 - IERC20Metadata(tokens[i]).decimals());
            }
            sum += amounts[i] * decimalsMultiplier;
        }
        uint256 holdings = totalHoldings();
        deposited[_msgSender()] += sum;
        totalDeposited += sum;

        uint256 lpShares = 0;
        if (holdings == 0) {
            lpShares = sum;
        } else {
            lpShares = (sum * totalSupply()) / holdings;
        }
        _mint(_msgSender(), lpShares);

        for (uint256 i = 0; i < amounts.length; ++i) {
            if (amounts[i] > 0)
            {
                IERC20Metadata(tokens[i]).safeTransferFrom(
                    _msgSender(),
                    address(strategy),
                    amounts[i]
                );
            }
        }
        require(strategy.deposit(amounts), "too low amount!");
        emit Deposited(_msgSender(), amounts, lpShares);
        return lpShares;
    }

    function withdraw(uint256 lpShares, uint256[3] memory minAmounts, uint256 pid)
    external virtual
    {
        IStrategy strategy = poolInfo[pid].strategy;
        require(balanceOf(_msgSender()) >= lpShares,
            "Zunami: not enough LP balance"
        );
        require(strategy.withdraw(_msgSender(), lpShares, minAmounts),
            "user lps share should be at least required");
        uint256 userDeposit = (totalDeposited * lpShares) / totalSupply();
        _burn(_msgSender(), lpShares);
        deposited[_msgSender()] -= userDeposit;
        totalDeposited -= userDeposit;
        emit Withdrawn(_msgSender(), minAmounts, lpShares);
    }

    function delegatedWithdrawal(
        address withdrawer,
        uint256 lpShares,
        uint256[3] memory minAmounts,
        uint256 pid
    ) internal virtual {
        if (balanceOf(withdrawer) >= lpShares && lpShares > 0) {
            IStrategy strategy = poolInfo[pid].strategy;
            if (!(strategy.withdraw(withdrawer, lpShares, minAmounts))) {
                emit BadWithdraw(withdrawer, minAmounts, lpShares);
                return;
            }
            uint256 userDeposit = (totalDeposited * lpShares) / totalSupply();
            _burn(withdrawer, lpShares);
            deposited[withdrawer] -= userDeposit;
            totalDeposited -= userDeposit;
            emit Withdrawn(withdrawer, minAmounts, lpShares);
        }
    }

    function setLock(bool _lock) external virtual onlyOwner
    {
        isLock = _lock;
    }

    function claimManagementFees(address strategyAddr) external virtual onlyOwner
    {
        IStrategy(strategyAddr).claimManagementFees();
    }

    // new functions
    function add(address _strategy) external virtual onlyOwner {
        poolInfo.push(PoolInfo({
        strategy : IStrategy(_strategy),
        startTime : block.timestamp + MIN_LOCK_TIME
        }));
    }

    function moveFunds(uint256 _from, uint256 _to)
    external virtual onlyOwner {
        IStrategy fromStrat = poolInfo[_from].strategy;
        IStrategy toStrat = poolInfo[_to].strategy;
        fromStrat.withdrawAll();
        uint256[3] memory amounts;
        for (uint256 i = 0; i < POOL_ASSETS; ++i) {
            amounts[i] = IERC20Metadata(tokens[i]).balanceOf(address(this));
            if (amounts[i] > 0) {
                IERC20Metadata(tokens[i]).safeTransfer(
                    address(toStrat),
                    amounts[i]
                );
            }
        }
        toStrat.deposit(amounts);
    }

    function moveFundsBatch(uint256[] memory _from, uint256 _to)
    external virtual onlyOwner {
        uint256 length = _from.length;
        uint256[3] memory amounts;
        for (uint256 i = 0; i < length; ++i) {
            poolInfo[_from[i]].strategy.withdrawAll();
        }
        for (uint256 _i = 0; _i < POOL_ASSETS; ++_i) {
            amounts[_i] = IERC20Metadata(tokens[_i]).balanceOf(address(this));
        }
        require(poolInfo[_to].strategy.deposit(amounts), "too low amount!");
    }

    function emergencyWithdraw() external virtual onlyOwner {
        uint256 length = poolInfo.length;
        require(length > 1, "Zunami: Nothing withdraw");
        uint256[3] memory amounts;
        for (uint256 i = 1; i < length; ++i) {
            poolInfo[i].strategy.withdrawAll();
        }
        for (uint256 _i = 0; _i < POOL_ASSETS; ++_i) {
            amounts[_i] = IERC20Metadata(tokens[_i]).balanceOf(address(this));
        }
        require(poolInfo[0].strategy.deposit(amounts), "too low amount!");
    }

    // user withdraw funds from list
    function pendingDepositRemove() external virtual {
        for (uint256 i = 0; i < POOL_ASSETS; ++i) {
            if (accDepositPending[_msgSender()][i] > 0) {
                IERC20Metadata(tokens[i]).safeTransfer(_msgSender(), accDepositPending[_msgSender()][i]);
            }
        }
        accDepositPending[_msgSender()] = [0, 0, 0];
    }

}

