pragma solidity 0.5.16;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "./uniswapV2Periphery/interfaces/IUniswapV2Router01.sol";
import "./library/BasisPoints.sol";
import "./LidSimplifiedPresaleTimer.sol";


contract LidSimplifiedPresaleRedeemer is Initializable, Ownable {
    using BasisPoints for uint;
    using SafeMath for uint;

    uint public redeemBP;
    uint public redeemInterval;

    uint public totalShares;
    uint public totalDepositors;
    mapping(address => uint) public accountDeposits;
    mapping(address => uint) public accountShares;
    mapping(address => uint) public accountClaimedTokens;

    address private presale;

    modifier onlyPresaleContract {
        require(msg.sender == presale, "Only callable by presale contract.");
        _;
    }

    function initialize(
        uint _redeemBP,
        uint _redeemInterval,
        address _presale,
        address owner
    ) external initializer {
        Ownable.initialize(owner);

        redeemBP = _redeemBP;
        redeemInterval = _redeemInterval;
        presale = _presale;
    }

    function setClaimed(address account, uint amount) external onlyPresaleContract {
        accountClaimedTokens[account] = accountClaimedTokens[account].add(amount);
    }

    function setDeposit(address account, uint deposit) external onlyPresaleContract {
        if (accountDeposits[account] == 0) totalDepositors = totalDepositors.add(1);
        accountDeposits[account] = accountDeposits[account].add(deposit);
        uint sharesToAdd = deposit;
        accountShares[account] = accountShares[account].add(sharesToAdd);
        totalShares = totalShares.add(sharesToAdd);
    }

    function calculateRatePerEth(uint totalPresaleTokens, uint hardCap) external pure returns (uint) {
        return totalPresaleTokens
        .mul(1 ether)
        .div(
            getMaxShares(hardCap)
        );
    }

    function calculateReedemable(
        address account,
        uint finalEndTime,
        uint totalPresaleTokens
    ) external view returns (uint) {
        if (finalEndTime == 0) return 0;
        if (finalEndTime >= now) return 0;
        uint earnedTokens = accountShares[account].mul(totalPresaleTokens).div(totalShares);
        uint claimedTokens = accountClaimedTokens[account];
        uint cycles = now.sub(finalEndTime).div(redeemInterval).add(1);
        uint totalRedeemable = earnedTokens.mulBP(redeemBP).mul(cycles);
        uint claimable;
        if (totalRedeemable >= earnedTokens) {
            claimable = earnedTokens.sub(claimedTokens);
        } else {
            claimable = totalRedeemable.sub(claimedTokens);
        }
        return claimable;
    }

    function getMaxShares(uint hardCap) public pure returns (uint) {
        return hardCap;
    }
}

