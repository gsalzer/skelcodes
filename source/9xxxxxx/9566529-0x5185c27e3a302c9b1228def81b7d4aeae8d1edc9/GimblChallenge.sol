pragma solidity ^0.5.16;

import "./Administrable.sol";
import "./GIMTokenInterface.sol";

contract SafeMath {
  function safeMul(uint a, uint b) pure internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) pure internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) pure internal returns (uint) {
    assert(b <= a);
    return a - b;
  }
}

contract GimblChallenge is SafeMath, Administrable {
  enum ChallengeStatus { CREATED, ACHIEVED, FAILED }
  enum Currency { ETH, GIM }

  struct Challenge {
    address payable challenger;
    address payable challenged;
    uint256 amount;
    Currency currency;
    ChallengeStatus status;
    uint256 gimblFeesPpm;
    uint256 gimblFees;
  }
  mapping (uint256 => Challenge) challenges;
  uint256 public challengeCount;
  uint256 public minimumETHChallengeAmount;
  uint256 public minimumGIMChallengeAmount;
  GIMTokenInterface gimToken;

  event ChallengeCreated(uint256 challengeIndex);
  event ChallengeResolved(uint256 challengeIndex);

  constructor(uint256 _minimumETHChallengeAmount, uint256 _minimumGIMChallengeAmount, address _gimTokenAddress) public {
    minimumETHChallengeAmount = _minimumETHChallengeAmount;
    minimumGIMChallengeAmount = _minimumGIMChallengeAmount;
    gimToken = GIMTokenInterface(_gimTokenAddress);
  }

  function updateMinimumChallengeAmounts(uint256 _minimumETHChallengeAmount, uint256 _minimumGIMChallengeAmount) public onlyOwner {
    minimumETHChallengeAmount = _minimumETHChallengeAmount;
    minimumGIMChallengeAmount = _minimumGIMChallengeAmount;
  }

  function createETHChallenge(address payable _challenged, uint256 _gimblFeesPpm) public payable {
    require(_challenged != msg.sender);
    require(msg.value >= minimumETHChallengeAmount);

    challenges[challengeCount].challenger = msg.sender;
    challenges[challengeCount].challenged = _challenged;
    challenges[challengeCount].amount = msg.value;
    challenges[challengeCount].currency = Currency.ETH;
    challenges[challengeCount].gimblFeesPpm = _gimblFeesPpm;

    emit ChallengeCreated(challengeCount);
    challengeCount += 1;
  }

  function createGIMChallenge(address payable _challenged, uint256 _gimblFeesPpm, uint256 _amount) public {
    require(_challenged != msg.sender);
    require(_amount >= minimumGIMChallengeAmount);

    require(gimToken.transferGIM(msg.sender, address(this), _amount));

    challenges[challengeCount].challenger = msg.sender;
    challenges[challengeCount].challenged = _challenged;
    challenges[challengeCount].amount = _amount;
    challenges[challengeCount].currency = Currency.GIM;
    challenges[challengeCount].gimblFeesPpm = _gimblFeesPpm;

    emit ChallengeCreated(challengeCount);
    challengeCount += 1;
  }

  function resolveChallenge(uint256 _challengeIndex, bool _achieved) public onlyAdministrator {
    Challenge storage challenge = challenges[_challengeIndex];
    require(_challengeIndex < challengeCount && challenge.status == ChallengeStatus.CREATED);

    if (_achieved) {
      challenge.status = ChallengeStatus.ACHIEVED;
      challenge.gimblFees = safeDiv(safeMul(challenge.gimblFeesPpm, challenge.amount), 10 ** 3);
      if (challenge.currency == Currency.ETH) {
        challenge.challenged.transfer(safeSub(challenge.amount, challenge.gimblFees));
        owner.transfer(challenge.gimblFees);
      } else {
        gimToken.transfer(challenge.challenged, safeSub(challenge.amount, challenge.gimblFees));
        gimToken.transfer(owner, challenge.gimblFees);
      }
    } else {
      challenge.status = ChallengeStatus.FAILED;
      if (challenge.currency == Currency.ETH) {
        challenge.challenger.transfer(challenge.amount);
      } else {
        gimToken.transfer(challenge.challenger, challenge.amount);
      }
    }

    emit ChallengeResolved(_challengeIndex);
  }

  function getChallenge(uint256 _challengeIndex) public view returns (address challenger, address challenged, uint256 amount, Currency currency, uint256 status, uint256 gimblFeesPpm, uint256 gimblFees){
    Challenge storage c = challenges[_challengeIndex];
    return (c.challenger, c.challenged, c.amount, c.currency, uint256(c.status), c.gimblFeesPpm, c.gimblFees);
  }
}

