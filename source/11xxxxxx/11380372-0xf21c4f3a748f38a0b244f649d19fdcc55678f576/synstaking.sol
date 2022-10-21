pragma solidity >= 0.6.4;

import './ownable.sol';
import './SafeMath.sol';
import './IERC20.sol';

interface synStakingProxyInterface {
    function forwardfees() external;
}

contract synStaking is Owned {
  using SafeMath for uint256;

  constructor() public {
    SYNTKN = IERC20(0x1695936d6a953df699C38CA21c2140d497C08BD9);
    synStakingProxy = 0x0070F3e1147c03a1Bb0caF80035B7c362D312119;
    staking = synStakingProxyInterface(0x0070F3e1147c03a1Bb0caF80035B7c362D312119);
  }

  event feesIn(
      uint256 ethIn,
      uint256 fpsTotal,
      uint256 feesTotal
  );
  event userStakeEvent(
      address account,
      uint256 amount
  );
  event userUnStakeEvent(
      address account,
      uint256 amount
  );
  event userClaimEvent(
      address account,
      uint256 ethOut
  );

  IERC20 public SYNTKN;
  address public synStakingProxy;
  synStakingProxyInterface public staking;

  struct userStakeStruct {
    uint256 syn;
    uint256 fpsEntered;
  }

  uint256 public fpsTotal;
  uint256 public synTotal;
  uint256 public feesTotal;

  bool public stakingActive;

  mapping(address => userStakeStruct) public userStake;

    receive() external payable {
  }


  function stake(uint256 amount) public {
    require(SYNTKN.transferFrom(msg.sender, address(this), amount));
    claimReward();
    userStake[msg.sender].syn = userStake[msg.sender].syn.add(amount);
    userStake[msg.sender].fpsEntered = fpsTotal;
    synTotal = synTotal.add(amount);
    emit userStakeEvent(msg.sender, amount);
  }


  function unstake(uint256 amount) public {
    require(userStake[msg.sender].syn >= amount);
    claimReward();
    userStake[msg.sender].syn = userStake[msg.sender].syn.sub(amount);
    synTotal = synTotal.sub(amount);
    SYNTKN.transfer(msg.sender, amount);
    emit userUnStakeEvent(msg.sender, amount);
  }

  function claimReward() public {
    if(stakingActive && synStakingProxy.balance > 0) {
        staking.forwardfees();
    }
    updateTotals();
    if(userStake[msg.sender].syn > 0) {
        uint256 ethOut = userStake[msg.sender].syn >= synTotal ?
                feesTotal : getUserRewards(msg.sender);
        userStake[msg.sender].fpsEntered = fpsTotal;
        feesTotal = feesTotal.sub(ethOut);
        msg.sender.transfer(ethOut);
        emit userClaimEvent(msg.sender, ethOut);
    }
  }

  function updateTotals() public {
    uint256 ethIn = address(this).balance.sub(feesTotal);
    if(ethIn > 0 && synTotal != 0) {
        uint256 addFps = ethIn.mul(10**18).div(synTotal);
        fpsTotal = fpsTotal.add(addFps);
        feesTotal = feesTotal.add(addFps.mul(synTotal).div(10**18));
        emit feesIn(ethIn, fpsTotal, feesTotal);
    }
  }

  function emergencyRemove(uint256 amount) public {
    require(userStake[msg.sender].syn >= amount);
    userStake[msg.sender].syn = userStake[msg.sender].syn.sub(amount);
    synTotal = synTotal.sub(amount);
    SYNTKN.transfer(msg.sender, amount);
  }

  function getUserRewards(address account) public view returns(uint256) {
      return(fpsTotal.sub(userStake[account].fpsEntered)
                .mul(userStake[account].syn).div(10**18));
  }

  function setStakingStatus(bool status) public onlyOwner() {
    stakingActive = status;
  }
  function setStakingProxy(address stakingProxy) public onlyOwner() {
    synStakingProxy = stakingProxy;
    staking = synStakingProxyInterface(stakingProxy);
  }

}

