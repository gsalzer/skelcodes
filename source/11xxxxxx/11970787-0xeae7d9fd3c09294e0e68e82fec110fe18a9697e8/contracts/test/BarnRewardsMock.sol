pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "../external/barnbridge/BarnInterface.sol";
import "./ERC20Mintable.sol";
import "@pooltogether/fixed-point/contracts/FixedPoint.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract BarnBridgeToken is
    ERC20Mintable("BarnBridge Governance Token", "BOND")
{}

contract BarnRewardsMock is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    uint256 constant decimals = 10 ** 18;

    struct Pull {
        address source;
        uint256 startTs;
        uint256 endTs;
        uint256 totalDuration;
        uint256 totalAmount;
    }

    Pull public pullFeature;
    uint256 public lastPullTs;

    uint256 public balanceBefore;
    uint256 public currentMultiplier;

    mapping(address => uint256) public userMultiplier;
    mapping(address => uint256) public owed;

    BarnInterface public barn;
    BarnBridgeToken public rewardToken;

    event Claim(address indexed user, uint256 amount);

    constructor(address _token, address _barn) public {

        rewardToken = BarnBridgeToken(_token);
        barn = BarnInterface(_barn);
    }

    // registerUserAction is called by the Barn every time the user does a deposit or withdrawal in order to
    // account for the changes in reward that the user should get
    // it updates the amount owed to the user without transferring the funds
    function registerUserAction(address user) public {
        require(msg.sender == address(barn), "only callable by barn");

        _calculateOwed(user);
    }

    // claim calculates the currently owed reward and transfers the funds to the user
    function claim() public {
        _calculateOwed(msg.sender);

        uint256 amount = owed[msg.sender];
        require(amount > 0, "nothing to claim");

        owed[msg.sender] = 0;

        rewardToken.transfer(msg.sender, amount);

        // acknowledge the amount that was transferred to the user
        ackFunds();

        emit Claim(msg.sender, amount);
    }

    // ackFunds checks the difference between the last known balance of `token` and the current one
    // if it goes up, the multiplier is re-calculated
    // if it goes down, it only updates the known balance
    function ackFunds() public {
        uint256 balanceNow = rewardToken.balanceOf(address(this));

        if (balanceNow == 0 || balanceNow <= balanceBefore) {
            balanceBefore = balanceNow;
            return;
        }

        uint256 totalStakedBond = barn.bondStaked();
        // if there's no bond staked, it doesn't make sense to ackFunds because there's nobody to distribute them to
        // and the calculation would fail anyways due to division by 0
        if (totalStakedBond == 0) {
            return;
        }

        uint256 diff = balanceNow.sub(balanceBefore);
        uint256 multiplier = currentMultiplier.add(diff.mul(decimals).div(totalStakedBond));

        balanceBefore = balanceNow;
        currentMultiplier = multiplier;
    }

    // setupPullToken is used to setup the rewards system; only callable by contract owner
    // set source to address(0) to disable the functionality
    function setupPullToken(address source, uint256 startTs, uint256 endTs, uint256 amount) public {
        require(msg.sender == owner(), "!owner");

        pullFeature.source = source;
        pullFeature.startTs = startTs;
        pullFeature.endTs = endTs;
        pullFeature.totalDuration = endTs.sub(startTs);
        pullFeature.totalAmount = amount;
        lastPullTs = startTs;
    }

    // setBarn sets the address of the BarnBridge Barn into the state variable
    function setBarn(address _barn) public {
        require(msg.sender == owner(), "!owner");

        barn = BarnInterface(_barn);
    }

    // _pullToken calculates the amount based on the time passed since the last pull relative
    // to the total amount of time that the pull functionality is active and executes a transferFrom from the
    // address supplied as `pullTokenFrom`, if enabled
    function _pullToken() internal {
        if (
            pullFeature.source == address(0) ||
            block.timestamp < pullFeature.startTs
        ) {
            return;
        }

        uint256 timestampCap = pullFeature.endTs;
        if (block.timestamp < pullFeature.endTs) {
            timestampCap = block.timestamp;
        }

        if (lastPullTs >= timestampCap) {
            return;
        }

        uint256 timeSinceLastPull = timestampCap.sub(lastPullTs);
        uint256 shareToPull = timeSinceLastPull.mul(decimals).div(pullFeature.totalDuration);
        uint256 amountToPull = pullFeature.totalAmount.mul(shareToPull).div(decimals);

        lastPullTs = block.timestamp;
        rewardToken.transferFrom(pullFeature.source, address(this), amountToPull);
    }

    // _calculateOwed calculates and updates the total amount that is owed to an user and updates the user's multiplier
    // to the current value
    // it automatically attempts to pull the token from the source and acknowledge the funds
    function _calculateOwed(address user) internal {
        _pullToken();
        ackFunds();

        uint256 reward = _userPendingReward(user);

        owed[user] = owed[user].add(reward);
        userMultiplier[user] = currentMultiplier;
    }

    // _userPendingReward calculates the reward that should be based on the current multiplier / anything that's not included in the `owed[user]` value
    // it does not represent the entire reward that's due to the user unless added on top of `owed[user]`
    function _userPendingReward(address user) internal view returns (uint256) {
        uint256 multiplier = currentMultiplier.sub(userMultiplier[user]);
        
        return barn.balanceOf(user).mul(multiplier).div(decimals);
    }


}

