pragma solidity >= 0.6.4;

import './ownable.sol';
import './SafeMath.sol';
import './IERC20.sol';

interface synStakingInterface {
  // Stakes SYN
  function stake(uint256 amount) external;
  // Unstakes SYN
  function unstake(uint256 amount) external;
  // Claims any ETH owed to msg.sender for staking SYN
  function claimReward() external;
  // Emergency removes staked SYN
  function emergencyRemove(uint256 amount) external;
}

contract uniV2Staking is Owned {
  using SafeMath for uint256;

  struct userStakeStruct {
    uint256 uniV2Tokens;
    uint256 fpuEntered;
  }

  IERC20 public synToken;
  IERC20 public uniV2Token;
  synStakingInterface public synStaking;

  mapping(address => userStakeStruct) public userStake;
  // Map of original SYN owner -> amount of SYN they've staked via this contract
  mapping(address => uint) public stakedSyn;


  // Total amount of UniV2Tokens staked
  uint256 public uniV2TotalStaked;
  // Amount of fees per UniV2Token currently staked
  uint256 public fpuTotal;
  // Total fees this contract has earned that can be given to UniV2Token stakers
  uint256 public feesTotal;

  event feesIn(
    uint256 ethIn,
    uint256 fpuTotal,
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
  event newSynStaking(
    address oldSynStaking,
    address newSynStaking
  );

  constructor() public {
    synToken = IERC20(0x1695936d6a953df699C38CA21c2140d497C08BD9);
    // SYN-ETH pair https://info.uniswap.org/pair/0xdf27a38946a1ace50601ef4e10f07a9cc90d7231
    uniV2Token = IERC20(0xdF27A38946a1AcE50601Ef4e10f07A9CC90d7231);
    // Syn Staking impl
    setSynStaking(0xf21c4F3a748F38A0B244f649d19FdcC55678F576);
  }

  // Allow this contract to receive ETH
  receive() external payable {}

  // Stake uniV2Tokens
  function stake(uint256 amount) external {
    require(uniV2Token.transferFrom(msg.sender, address(this), amount));
    claimReward();
    userStake[msg.sender].uniV2Tokens = userStake[msg.sender].uniV2Tokens.add(amount);
    userStake[msg.sender].fpuEntered = fpuTotal;
    uniV2TotalStaked = uniV2TotalStaked.add(amount);
    emit userStakeEvent(msg.sender, amount);
  }

  // Unstake uniV2Tokens
  function unstake(uint256 amount) external {
    require(userStake[msg.sender].uniV2Tokens >= amount);
    claimReward();
    userStake[msg.sender].uniV2Tokens = userStake[msg.sender].uniV2Tokens.sub(amount);
    uniV2TotalStaked = uniV2TotalStaked.sub(amount);
    uniV2Token.transfer(msg.sender, amount);
    emit userUnStakeEvent(msg.sender, amount);
  }

  // Claims msg.sender's reward for staking uniV2Tokens
  function claimReward() public {
    // Claim earned ETH from SYN staking. This also forwards fees into synStaking
    synStaking.claimReward();
    // Update state to deal w/ earned ETH we just claimed
    updateTotals();
    // Give sender their owed ETH
    if(userStake[msg.sender].uniV2Tokens > 0) {
        uint256 ethOut = userStake[msg.sender].uniV2Tokens >= uniV2TotalStaked ?
                feesTotal : getUserRewards(msg.sender);
        userStake[msg.sender].fpuEntered = fpuTotal;
        feesTotal = feesTotal.sub(ethOut);
        msg.sender.transfer(ethOut);
        emit userClaimEvent(msg.sender, ethOut);
    }
  }

  function updateTotals() public {
    uint256 ethIn = address(this).balance.sub(feesTotal);
    if(ethIn > 0 && uniV2TotalStaked != 0) {
        uint256 addFpu = ethIn.mul(10**18).div(uniV2TotalStaked);
        fpuTotal = fpuTotal.add(addFpu);
        feesTotal = feesTotal.add(addFpu.mul(uniV2TotalStaked).div(10**18));
        emit feesIn(ethIn, fpuTotal, feesTotal);
    }
  }

  // Emergency removal of staked uniV2Tokens
  function emergencyRemove(uint256 amount) public {
    require(userStake[msg.sender].uniV2Tokens >= amount);
    userStake[msg.sender].uniV2Tokens = userStake[msg.sender].uniV2Tokens.sub(amount);
    uniV2TotalStaked = uniV2TotalStaked.sub(amount);
    uniV2Token.transfer(msg.sender, amount);
  }

  function getUserRewards(address account) public view returns(uint256) {
      return(fpuTotal.sub(userStake[account].fpuEntered)
                .mul(userStake[account].uniV2Tokens).div(10**18));
  }

  // ---- Fns to add/remove SYN to stake via this contract ----

  // Note `stakeSyn` and `unstakeSyn` can result in ETH rewards being given to this
  // contract as a result of the `synStaking.(un)stake` call. This is okay because calls
  // to `stake`, `unstake`, and `claimReward` in this contract call `updateTotals`,
  // which will calculate ethIn based off any new eth balance this contract has
  // before it performs anything important

  // Stake SYN via this contract, giving all earned fees to this contract
  function stakeSyn(uint amount) external {
    uint synBalanceBefore = synToken.balanceOf(address(this));
    // Transfer the SYN into this contract first
    require(synToken.transferFrom(msg.sender, address(this), amount));
    // To cover the case of someone accidentally sending SYN directly to this contract.
    // It'll get staked and owned by whoever calls stakeSyn first
    uint synAmountToStake = synToken.balanceOf(address(this)).sub(synBalanceBefore);
    // Now allow synStaking to transfer our synAmountToStake SYN into synStaking
    synToken.approve(address(synStaking), synAmountToStake);
    // Stake it
    synStaking.stake(synAmountToStake);
    // Record that sender has staked syn via this contract
    stakedSyn[msg.sender] = stakedSyn[msg.sender].add(synAmountToStake);
  }

  // Unstake SYN that has been staked via this contract, giving all earned fees to this contract
  function unstakeSyn(uint amount) external {
    // Prevent someone from unstaking more SYN than they have staked via this contract
    require(amount <= stakedSyn[msg.sender]);
    // Unstake it
    synStaking.unstake(amount);
    // Record that sender has unstaked syn via this contract
    stakedSyn[msg.sender] = stakedSyn[msg.sender].sub(amount);
    // Transfer the syn that was unstaked from this contract to the sender
    require(synToken.transfer(msg.sender, amount));
  }

  function emergencyRemoveSyn(uint amount) external {
    // Prevent someone from emergency removing more syn than they have staked via this contract
    require(amount <= stakedSyn[msg.sender]);
    // Record that sender has unstaked syn via this contract
    stakedSyn[msg.sender] = stakedSyn[msg.sender].sub(amount);
    // Emergency remove that syn
    synStaking.emergencyRemove(amount);
    // Transfer the syn that was removed from this contract to the sender
    require(synToken.transferFrom(address(this), msg.sender, amount));
  }

  // ---- Owner only ----

  function setSynStaking(address _synStaking) public onlyOwner() {
    address oldSynStaking = address(synStaking);
    synStaking = synStakingInterface(_synStaking);
    emit newSynStaking(
      oldSynStaking,
      _synStaking
    );
  }
}

