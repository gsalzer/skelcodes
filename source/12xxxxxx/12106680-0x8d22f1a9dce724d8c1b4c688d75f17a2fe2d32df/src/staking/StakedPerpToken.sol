// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

import { IERC20 } from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import { IERC20WithCheckpointing } from "./aragonone/IERC20WithCheckpointing.sol";
import { Checkpointing } from "./aragonone/Checkpointing.sol";
import { CheckpointingHelpers } from "./aragonone/CheckpointingHelpers.sol";
import { ERC20ViewOnly } from "../utils/ERC20ViewOnly.sol";
import { Decimal } from "../utils/Decimal.sol";
import { DecimalERC20 } from "../utils/DecimalERC20.sol";
import { BlockContext } from "../utils/BlockContext.sol";
import { PerpFiOwnableUpgrade } from "../utils/PerpFiOwnableUpgrade.sol";
import { AddressArray } from "../utils/AddressArray.sol";
import { IStakeModule } from "../interface/IStakeModule.sol";

contract StakedPerpToken is IERC20WithCheckpointing, ERC20ViewOnly, DecimalERC20, PerpFiOwnableUpgrade, BlockContext {
    using Checkpointing for Checkpointing.History;
    using CheckpointingHelpers for uint256;
    using SafeMath for uint256;
    using AddressArray for address[];

    uint256 public constant TOKEN_AMOUNT_LIMIT = 20;

    //
    // EVENTS
    //
    event Staked(address staker, uint256 amount);
    event Unstaked(address staker, uint256 amount);
    event Withdrawn(address staker, uint256 amount);
    event StakeModuleAdded(address stakedModule);
    event StakeModuleRemoved(address stakedModule);

    //**********************************************************//
    //    The below state variables can not change the order    //
    //**********************************************************//

    // ERC20 variables
    string public name;
    string public symbol;
    uint8 public decimals;
    // ERC20 variables

    // Checkpointing total supply of the deposited token
    Checkpointing.History internal totalSupplyHistory;

    // Checkpointing balances of the deposited token by staker
    mapping(address => Checkpointing.History) internal balancesHistory;

    // staker => the time staker can withdraw PERP
    mapping(address => uint256) public stakerCooldown;

    // staker => PERP staker can withdraw
    mapping(address => Decimal.decimal) public stakerWithdrawPendingBalance;

    address[] public stakeModules;
    IERC20 public perpToken;
    uint256 public cooldownPeriod;

    //**********************************************************//
    //    The above state variables can not change the order    //
    //**********************************************************//

    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//
    uint256[50] private __gap;

    //
    // FUNCTIONS
    //
    function initialize(IERC20 _perpToken, uint256 _cooldownPeriod) external initializer {
        require(address(_perpToken) != address(0), "Invalid input.");
        __Ownable_init();
        name = "Staked Perpetual";
        symbol = "sPERP";
        decimals = 18;
        perpToken = _perpToken;
        cooldownPeriod = _cooldownPeriod;
    }

    function stake(Decimal.decimal calldata _amount) external {
        requireNonZeroAmount(_amount);
        requireStakeModuleExisted();
        address msgSender = _msgSender();

        // copy calldata amount to memory
        Decimal.decimal memory amount = _amount;

        // stake after unstake is allowed, and the states mutated by unstake() will being undo
        if (stakerWithdrawPendingBalance[msgSender].toUint() != 0) {
            amount = amount.addD(stakerWithdrawPendingBalance[msgSender]);
            delete stakerWithdrawPendingBalance[msgSender];
            delete stakerCooldown[msgSender];
        }

        // if staking after unstaking, the amount to be transferred does not need to be updated
        _transferFrom(perpToken, msgSender, address(this), _amount);
        _mint(msgSender, amount);

        // Have to update balance first
        for (uint256 i; i < stakeModules.length; i++) {
            IStakeModule(stakeModules[i]).notifyStakeChanged(msgSender);
        }

        emit Staked(msgSender, amount.toUint());
    }

    // this function mutates stakerWithdrawPendingBalance, stakerCooldown, addTotalSupplyCheckPoint,
    // addPersonalBalanceCheckPoint, burn
    function unstake() external {
        address msgSender = _msgSender();
        requireStakeModuleExisted();
        require(stakerWithdrawPendingBalance[msgSender].toUint() == 0, "Need to withdraw first");

        Decimal.decimal memory balance = Decimal.decimal(balancesHistory[msgSender].latestValue());
        requireNonZeroAmount(balance);

        _burn(msgSender, balance);

        stakerCooldown[msgSender] = _blockTimestamp().add(cooldownPeriod);
        stakerWithdrawPendingBalance[msgSender] = balance;

        // Have to update balance first
        for (uint256 i; i < stakeModules.length; i++) {
            IStakeModule(stakeModules[i]).notifyStakeChanged(msgSender);
        }

        emit Unstaked(msgSender, balance.toUint());
    }

    function withdraw() external {
        address msgSender = _msgSender();
        Decimal.decimal memory balance = stakerWithdrawPendingBalance[msgSender];
        requireNonZeroAmount(balance);
        // there won't be a case that cooldown == 0 && balance == 0
        require(_blockTimestamp() >= stakerCooldown[msgSender], "Still in cooldown");

        delete stakerWithdrawPendingBalance[msgSender];
        delete stakerCooldown[msgSender];
        _transfer(perpToken, msgSender, balance);

        emit Withdrawn(msgSender, balance.toUint());
    }

    function addStakeModule(IStakeModule _stakeModule) external onlyOwner {
        require(stakeModules.length < TOKEN_AMOUNT_LIMIT, "exceed stakeModule amount limit");
        require(stakeModules.add(address(_stakeModule)), "invalid input");

        emit StakeModuleAdded(address(_stakeModule));
    }

    function removeStakeModule(IStakeModule _stakeModule) external onlyOwner {
        address removedAddr = stakeModules.remove(address(_stakeModule));
        require(removedAddr != address(0), "stakeModule does not exist");
        require(removedAddr == address(_stakeModule), "remove wrong stakeModule");

        emit StakeModuleRemoved(address(_stakeModule));
    }

    //
    // VIEW FUNCTIONS
    //

    //
    // override: ERC20
    //
    function balanceOf(address _owner) public view override returns (uint256) {
        return _balanceOfAt(_owner, _blockNumber()).toUint();
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupplyAt(_blockNumber()).toUint();
    }

    //
    // override: IERC20WithCheckpointing
    //
    function balanceOfAt(address _owner, uint256 __blockNumber) external view override returns (uint256) {
        return _balanceOfAt(_owner, __blockNumber).toUint();
    }

    function totalSupplyAt(uint256 __blockNumber) external view override returns (uint256) {
        return _totalSupplyAt(__blockNumber).toUint();
    }

    //
    // EXTERNAL FUNCTIONS
    //
    function getStakeModuleLength() external view returns (uint256) {
        return stakeModules.length;
    }

    //
    // INTERNAL FUNCTIONS
    //
    function isStakeModuleExisted(IStakeModule _stakeModule) public view returns (bool) {
        return stakeModules.isExisted(address(_stakeModule));
    }

    function _mint(address account, Decimal.decimal memory amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        Decimal.decimal memory balance = Decimal.decimal(balanceOf(account));
        Decimal.decimal memory newBalance = balance.addD(amount);
        Decimal.decimal memory currentTotalSupply = Decimal.decimal(totalSupply());
        Decimal.decimal memory newTotalSupply = currentTotalSupply.addD(amount);

        uint256 blockNumber = _blockNumber();
        addPersonalBalanceCheckPoint(account, blockNumber, newBalance);
        addTotalSupplyCheckPoint(blockNumber, newTotalSupply);

        emit Transfer(address(0), account, amount.toUint());
    }

    function _burn(address account, Decimal.decimal memory amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        Decimal.decimal memory balance = Decimal.decimal(balanceOf(account));
        Decimal.decimal memory newBalance = balance.subD(amount);
        Decimal.decimal memory currentTotalSupply = Decimal.decimal(totalSupply());
        Decimal.decimal memory newTotalSupply = currentTotalSupply.subD(amount);

        uint256 blockNumber = _blockNumber();
        addPersonalBalanceCheckPoint(account, blockNumber, newBalance);
        addTotalSupplyCheckPoint(blockNumber, newTotalSupply);

        emit Transfer(account, address(0), amount.toUint());
    }

    function addTotalSupplyCheckPoint(uint256 __blockNumber, Decimal.decimal memory _amount) internal {
        totalSupplyHistory.addCheckpoint(__blockNumber.toUint64Time(), _amount.toUint().toUint192Value());
    }

    function addPersonalBalanceCheckPoint(
        address _staker,
        uint256 __blockNumber,
        Decimal.decimal memory _amount
    ) internal {
        balancesHistory[_staker].addCheckpoint(__blockNumber.toUint64Time(), _amount.toUint().toUint192Value());
    }

    function _balanceOfAt(address _owner, uint256 __blockNumber) internal view returns (Decimal.decimal memory) {
        return Decimal.decimal(balancesHistory[_owner].getValueAt(__blockNumber.toUint64Time()));
    }

    function _totalSupplyAt(uint256 __blockNumber) internal view returns (Decimal.decimal memory) {
        return Decimal.decimal(totalSupplyHistory.getValueAt(__blockNumber.toUint64Time()));
    }

    //
    // REQUIRE FUNCTIONS
    //
    function requireNonZeroAmount(Decimal.decimal memory _amount) private pure {
        require(_amount.toUint() > 0, "Amount is 0");
    }

    function requireStakeModuleExisted() internal view {
        require(stakeModules.length > 0, "no stakeModule");
    }
}

