pragma solidity 0.5.12;

import './SafeMath.sol';

/// @title TimeAlly Super Goal Achiever Plan (TSGAP)
/// @author The EraSwap Team
/// @notice The benefits are transparently stored in advance in this contract
contract TimeAllySIP {
  using SafeMath for uint256;

  struct SIPPlan {
    bool isPlanActive;
    uint256 minimumMonthlyCommitmentAmount; /// @dev minimum amount 500 ES
    uint256 accumulationPeriodMonths; /// @dev 12 months
    uint256 benefitPeriodYears; /// @dev 9 years
    uint256 gracePeriodSeconds; /// @dev 60*60*24*10
    uint256 monthlyBenefitFactor; /// @dev this is per 1000; i.e 200 for 20%
    uint256 gracePenaltyFactor; /// @dev penalty on first powerBoosterAmount, this is per 1000; i.e 10 for 1%
    uint256 defaultPenaltyFactor; /// @dev penalty on first powerBoosterAmount, this is per 1000; i.e 20 for 2%
  }

  struct SIP {
    uint256 planId;
    uint256 stakingTimestamp;
    uint256 monthlyCommitmentAmount;
    uint256 totalDeposited;
    uint256 lastWithdrawlMonthId;
    uint256 powerBoosterWithdrawls;
    uint256 numberOfAppointees;
    uint256 appointeeVotes;
    mapping(uint256 => uint256) depositStatus; /// @dev 2 => ontime, 1 => grace, 0 => defaulted / not yet
    mapping(uint256 => uint256) monthlyBenefitAmount;
    mapping(address => bool) nominees;
    mapping(address => bool) appointees;
  }

  address public owner;
  ERC20 public token;

  /// @dev 1 Year = 365.242 days for taking care of leap years
  uint256 public EARTH_SECONDS_IN_MONTH = 2629744;

  /// @notice whenever a deposit is done by user, benefit amount (to be paid
  /// in due plan time) will be already added to this. and in case of withdrawl,
  /// it is subtracted from this.
  uint256 public pendingBenefitAmountOfAllStakers;

  /// @notice deposited by Era Swap Donors. It is given as benefits to  ES stakers.
  /// on every withdrawl this deposit is reduced, and on some point of time
  /// if enough fundsDeposit is not available to assure staker benefit,
  /// contract will allow staker to deposit
  uint256 public fundsDeposit;

  /// @notice allocating storage for multiple sip plans
  SIPPlan[] public sipPlans;

  /// @notice allocating storage for multiple sips of multiple users
  mapping(address => SIP[]) public sips;

  /// @notice charge is ES amount given as rewards that can be used for SIP in this contract.
  mapping(address => uint256) public prepaidES;

  /// @notice event schema for monitoring funds added by donors
  event FundsDeposited (
    uint256 _depositAmount
  );

  /// @notice event schema for monitoring unallocated fund withdrawn by owner
  event FundsWithdrawn (
    uint256 _withdrawlAmount
  );

  /// @notice event schema for monitoring new sips by stakers
  event NewSIP (
    address indexed _staker,
    uint256 _sipId,
    uint256 _monthlyCommitmentAmount
  );

  /// @notice event schema for monitoring deposits made by stakers to sips
  event NewDeposit (
    address indexed _staker,
    uint256 indexed _sipId,
    uint256 _monthId,
    uint256 _depositAmount,
    uint256 _benefitQueued,
    address _depositedBy
  );

  /// @notice event schema for monitoring sip benefit withdrawn by stakers
  event BenefitWithdrawl (
    address indexed _staker,
    uint256 indexed _sipId,
    uint256 _fromMonthId,
    uint256 _toMonthId,
    uint256 _withdrawlAmount,
    address _withdrawnBy
  );

  /// @notice event schema for monitoring power booster withdrawn by stakers
  event PowerBoosterWithdrawl (
    address indexed _staker,
    uint256 indexed _sipId,
    uint256 _boosterSerial,
    uint256 _withdrawlAmount,
    address _withdrawnBy
  );

  /// @notice event schema for monitoring power booster withdrawn by stakers
  event NomineeUpdated (
    address indexed _staker,
    uint256 indexed _sipId,
    address indexed _nomineeAddress,
    bool _nomineeStatus
  );

  /// @notice event schema for monitoring power booster withdrawls by stakers
  event AppointeeUpdated (
    address indexed _staker,
    uint256 indexed _sipId,
    address indexed _appointeeAddress,
    bool _appointeeStatus
  );

  /// @notice event schema for monitoring power booster withdrawls by stakers
  event AppointeeVoted (
    address indexed _staker,
    uint256 indexed _sipId,
    address indexed _appointeeAddress
  );

  /// @notice restricting access to some functionalities to owner
  modifier onlyOwner() {
    require(msg.sender == owner, 'only deployer can call');
    _;
  }

  /// @notice restricting access of staker's SIP to them and their sip nominees
  modifier meOrNominee(address _stakerAddress, uint256 _sipId) {
    SIP storage _sip = sips[_stakerAddress][_sipId];

    /// @notice if transacter is not staker, then transacter should be nominee
    if(msg.sender != _stakerAddress) {
      require(_sip.nominees[msg.sender], 'nomination should be there');
    }
    _;
  }

  /// @notice sets up TimeAllySIP contract when deployed
  /// @param _token: is EraSwap ERC20 Smart Contract Address
  constructor(ERC20 _token) public {
    owner = msg.sender;
    token = _token;
  }

  /// @notice this function is used by owner to create plans for new SIPs
  /// @param _minimumMonthlyCommitmentAmount: minimum SIP monthly amount in exaES
  /// @param _accumulationPeriodMonths: number of months to deposit commitment amount
  /// @param _benefitPeriodYears: number of years of benefit
  /// @param _gracePeriodSeconds: grace allowance to stakers to deposit monthly
  /// @param _monthlyBenefitFactor: this is per 1000; i.e 200 for 20%
  /// @param _gracePenaltyFactor: due to late deposits, this is per 1000
  /// @param _defaultPenaltyFactor: due to missing deposits, this is per 1000
  function createSIPPlan(
    uint256 _minimumMonthlyCommitmentAmount,
    uint256 _accumulationPeriodMonths,
    uint256 _benefitPeriodYears,
    uint256 _gracePeriodSeconds,
    uint256 _monthlyBenefitFactor,
    uint256 _gracePenaltyFactor,
    uint256 _defaultPenaltyFactor
  ) public onlyOwner {

    /// @notice saving new sip plan details to blockchain storage
    sipPlans.push(SIPPlan({
      isPlanActive: true,
      minimumMonthlyCommitmentAmount: _minimumMonthlyCommitmentAmount,
      accumulationPeriodMonths: _accumulationPeriodMonths,
      benefitPeriodYears: _benefitPeriodYears,
      gracePeriodSeconds: _gracePeriodSeconds,
      monthlyBenefitFactor: _monthlyBenefitFactor,
      gracePenaltyFactor: _gracePenaltyFactor,
      defaultPenaltyFactor: _defaultPenaltyFactor
    }));
  }

  /// @notice this function is used by owner to disable or re-enable a sip plan
  /// @dev sips already initiated by a plan will continue only new will be restricted
  /// @param _planId: select a plan to make it inactive
  /// @param _newStatus: true or false.
  function updatePlanStatus(uint256 _planId, bool _newStatus) public onlyOwner {
    sipPlans[_planId].isPlanActive = _newStatus;
  }

  /// @notice this function is used by donors to add funds to fundsDeposit
  /// @dev ERC20 approve is required to be done for this contract earlier
  /// @param _depositAmount: amount in exaES to deposit
  function addFunds(uint256 _depositAmount) public {

    /// @notice transfer tokens from the donor to contract
    require(
      token.transferFrom(msg.sender, address(this), _depositAmount)
      , 'tokens should be transfered'
    );

    /// @notice increment amount in fundsDeposit
    fundsDeposit = fundsDeposit.add(_depositAmount);

    /// @notice emiting event that funds been deposited
    emit FundsDeposited(_depositAmount);
  }

  /// @notice this is used by owner to withdraw ES that are not allocated to any SIP
  /// @param _withdrawlAmount: amount in exaES to withdraw
  function withdrawFunds(uint256 _withdrawlAmount) public onlyOwner {

    /// @notice check if withdrawing only unutilized tokens
    require(
      fundsDeposit.sub(pendingBenefitAmountOfAllStakers) >= _withdrawlAmount
      , 'cannot withdraw excess funds'
    );

    /// @notice decrement amount in fundsDeposit
    fundsDeposit = fundsDeposit.sub(_withdrawlAmount);

    /// @notice transfer tokens to withdrawer
    token.transfer(msg.sender, _withdrawlAmount);

    /// @notice emit that funds are withdrawn
    emit FundsWithdrawn(_withdrawlAmount);
  }

  /// @notice this function is used to add ES as prepaid for SIP
  /// @dev ERC20 approve needs to be done
  /// @param _amount: ES to deposit
  function addToPrepaid(uint256 _amount) public {
    require(token.transferFrom(msg.sender, address(this), _amount));
    prepaidES[msg.sender] = prepaidES[msg.sender].add(_amount);
  }

  /// @notice this function is used to send ES as prepaid for SIP
  /// @param _addresses: address array to send prepaid ES for SIP
  /// @param _amounts: prepaid ES for SIP amounts to send to corresponding addresses
  function sendPrepaidESDifferent(
    address[] memory _addresses,
    uint256[] memory _amounts
  ) public {
    for(uint256 i = 0; i < _addresses.length; i++) {
      prepaidES[msg.sender] = prepaidES[msg.sender].sub(_amounts[i]);
      prepaidES[_addresses[i]] = prepaidES[_addresses[i]].add(_amounts[i]);
    }
  }

  /// @notice this function is used to initiate a new SIP along with first deposit
  /// @dev ERC20 approve is required to be done for this contract earlier, also
  ///  fundsDeposit should be enough otherwise contract will not accept
  /// @param _planId: choose a SIP plan
  /// @param _monthlyCommitmentAmount: needs to be more than minimum specified in plan.
  /// @param _usePrepaidES: should prepaidES be used.
  function newSIP(
    uint256 _planId,
    uint256 _monthlyCommitmentAmount,
    bool _usePrepaidES
  ) public {
    /// @notice check if sip plan selected is active
    require(
      sipPlans[_planId].isPlanActive
      , 'sip plan is not active'
    );

    /// @notice check if commitment amount is at least minimum
    require(
      _monthlyCommitmentAmount >= sipPlans[_planId].minimumMonthlyCommitmentAmount
      , 'amount should be atleast minimum'
    );

    /// @notice calculate benefits to be given during benefit period due to this deposit
    uint256 _singleMonthBenefit = _monthlyCommitmentAmount
      .mul(sipPlans[ _planId ].monthlyBenefitFactor)
      .div(1000);

    uint256 _benefitsToBeGiven = _singleMonthBenefit
      .mul(sipPlans[ _planId ].benefitPeriodYears);

    /// @notice ensure if enough funds are already present in fundsDeposit
    require(
      fundsDeposit >= _benefitsToBeGiven.add(pendingBenefitAmountOfAllStakers)
      , 'enough funds for benefits should be there in contract'
    );

    /// @notice if staker wants to use charge then use that else take from wallet
    if(_usePrepaidES) {
      /// @notice subtracting prepaidES from staker
      prepaidES[msg.sender] = prepaidES[msg.sender].sub(_monthlyCommitmentAmount);
    } else {
      /// @notice begin sip process by transfering first month tokens from staker to contract
      require(token.transferFrom(msg.sender, address(this), _monthlyCommitmentAmount));
    }


    /// @notice saving sip details to blockchain storage
    sips[msg.sender].push(SIP({
      planId: _planId,
      stakingTimestamp: now,
      monthlyCommitmentAmount: _monthlyCommitmentAmount,
      totalDeposited: _monthlyCommitmentAmount,
      lastWithdrawlMonthId: 0, /// @dev withdrawl monthId starts from 1
      powerBoosterWithdrawls: 0,
      numberOfAppointees: 0,
      appointeeVotes: 0
    }));

    /// @notice sipId starts from 0. first sip of user will have id 0, then 1 and so on.
    uint256 _sipId = sips[msg.sender].length - 1;

    /// @dev marking month 1 as paid on time
    sips[msg.sender][_sipId].depositStatus[1] = 2;
    sips[msg.sender][_sipId].monthlyBenefitAmount[1] = _singleMonthBenefit;

    /// @notice incrementing pending benefits
    pendingBenefitAmountOfAllStakers = pendingBenefitAmountOfAllStakers.add(
      _benefitsToBeGiven
    );

    /// @notice emit that new sip is initiated
    emit NewSIP(
      msg.sender,
      sips[msg.sender].length - 1,
      _monthlyCommitmentAmount
    );

    /// @notice emit that first deposit is done
    emit NewDeposit(
      msg.sender,
      _sipId,
      1,
      _monthlyCommitmentAmount,
      _benefitsToBeGiven,
      msg.sender
    );
  }

  /// @notice this function is used to do monthly commitment deposit of SIP
  /// @dev ERC20 approve is required to be done for this contract earlier, also
  ///  fundsDeposit should be enough otherwise contract will not accept
  ///  Also, deposit can also be done by any nominee of this SIP.
  /// @param _stakerAddress: address of staker who has an SIP
  /// @param _sipId: id of SIP in staker address portfolio
  /// @param _depositAmount: amount to deposit,
  /// @param _monthId: specify the month to deposit
  /// @param _usePrepaidES: should prepaidES be used.
  function monthlyDeposit(
    address _stakerAddress,
    uint256 _sipId,
    uint256 _depositAmount,
    uint256 _monthId,
    bool _usePrepaidES
  ) public meOrNominee(_stakerAddress, _sipId) {
    SIP storage _sip = sips[_stakerAddress][_sipId];
    require(
      _depositAmount >= _sip.monthlyCommitmentAmount
      , 'deposit cannot be less than commitment'
    );

    /// @notice cannot deposit again for a month in which a deposit is already done
    require(
      _sip.depositStatus[_monthId] == 0
      , 'cannot deposit again'
    );

    /// @notice calculating benefits to be given in future because of this deposit
    uint256 _singleMonthBenefit = _depositAmount
      .mul(sipPlans[ _sip.planId ].monthlyBenefitFactor)
      .div(1000);

    uint256 _benefitsToBeGiven = _singleMonthBenefit
      .mul(sipPlans[ _sip.planId ].benefitPeriodYears);

    /// @notice checking if enough unallocated funds are available
    require(
      fundsDeposit >= _benefitsToBeGiven.add(pendingBenefitAmountOfAllStakers)
      , 'enough funds should be there in SIP'
    );

    /// @notice check if deposit is allowed according to current time
    uint256 _depositStatus = getDepositStatus(_stakerAddress, _sipId, _monthId);
    require(_depositStatus > 0, 'grace period elapsed or too early');

    /// @notice if staker wants to use charge then use that else take from wallet
    if(_usePrepaidES) {
      /// @notice subtracting prepaidES from staker
      prepaidES[msg.sender] = prepaidES[msg.sender].sub(_depositAmount);
    } else {
      /// @notice transfering staker tokens to SIP contract
      require(token.transferFrom(msg.sender, address(this), _depositAmount));
    }

    /// @notice updating deposit status
    _sip.depositStatus[_monthId] = _depositStatus;
    _sip.monthlyBenefitAmount[_monthId] = _singleMonthBenefit;

    /// @notice adding to total deposit in SIP
    _sip.totalDeposited = _sip.totalDeposited.add(_depositAmount);

    /// @notice adding to pending benefits
    pendingBenefitAmountOfAllStakers = pendingBenefitAmountOfAllStakers.add(
      _benefitsToBeGiven
    );

    /// @notice emit that first deposit is done
    emit NewDeposit(_stakerAddress, _sipId, _monthId, _depositAmount, _benefitsToBeGiven, msg.sender);
  }

  /// @notice this function is used to withdraw benefits.
  /// @dev withdraw can be done by any nominee of this SIP.
  /// @param _stakerAddress: address of initiater of this SIP.
  /// @param _sipId: id of SIP in staker address portfolio.
  /// @param _withdrawlMonthId: withdraw month id starts from 1 upto as per plan.
  function withdrawBenefit(
    address _stakerAddress,
    uint256 _sipId,
    uint256 _withdrawlMonthId
  ) public meOrNominee(_stakerAddress, _sipId) {

    /// @notice require statements are in this function getPendingWithdrawlAmount
    uint256 _withdrawlAmount = getPendingWithdrawlAmount(
      _stakerAddress,
      _sipId,
      _withdrawlMonthId,
      msg.sender != _stakerAddress /// @dev _isNomineeWithdrawing
    );

    SIP storage _sip = sips[_stakerAddress][_sipId];

    /// @notice marking that user has withdrawn upto _withdrawlmonthId month
    uint256 _lastWithdrawlMonthId = _sip.lastWithdrawlMonthId;
    _sip.lastWithdrawlMonthId = _withdrawlMonthId;

    /// @notice updating pending benefits
    pendingBenefitAmountOfAllStakers = pendingBenefitAmountOfAllStakers.sub(_withdrawlAmount);

    /// @notice updating fundsDeposit
    fundsDeposit = fundsDeposit.sub(_withdrawlAmount);

    /// @notice transfering tokens to the user wallet address
    if(_withdrawlAmount > 0) {
      token.transfer(msg.sender, _withdrawlAmount);
    }

    /// @notice emit that benefit withdrawl is done
    emit BenefitWithdrawl(
      _stakerAddress,
      _sipId,
      _lastWithdrawlMonthId + 1,
      _withdrawlMonthId,
      _withdrawlAmount,
      msg.sender
    );
  }

  /// @notice this functin is used to withdraw powerbooster
  /// @dev withdraw can be done by any nominee of this SIP.
  /// @param _stakerAddress: address of initiater of this SIP.
  /// @param _sipId: id of SIP in staker address portfolio.
  function withdrawPowerBooster(
    address _stakerAddress,
    uint256 _sipId
  ) public meOrNominee(_stakerAddress, _sipId) {
    SIP storage _sip = sips[_stakerAddress][_sipId];

    /// @notice taking the next power booster withdrawl
    /// @dev not using safemath because this is under safe range
    uint256 _powerBoosterSerial = _sip.powerBoosterWithdrawls + 1;

    /// @notice limiting only 3 powerbooster withdrawls
    require(_powerBoosterSerial <= 3, 'only 3 power boosters');

    /// @notice calculating allowed time
    /// @dev not using SafeMath because uint256 range is safe
    uint256 _allowedTimestamp = _sip.stakingTimestamp
      + sipPlans[ _sip.planId ].accumulationPeriodMonths * EARTH_SECONDS_IN_MONTH
      + sipPlans[ _sip.planId ].benefitPeriodYears * 12 * EARTH_SECONDS_IN_MONTH * _powerBoosterSerial / 3 - EARTH_SECONDS_IN_MONTH;

    /// @notice opening window for nominee after sometime
    if(msg.sender != _stakerAddress) {
      if(_sip.appointeeVotes > _sip.numberOfAppointees.div(2)) {
        /// @notice with concensus of appointees, withdraw is allowed in 6 months
        _allowedTimestamp += EARTH_SECONDS_IN_MONTH * 6;
      } else {
        /// @notice otherwise a default of 1 year delay in withdrawing benefits
        _allowedTimestamp += EARTH_SECONDS_IN_MONTH * 12;
      }
    }

    /// @notice restricting early withdrawl
    require(now > _allowedTimestamp, 'cannot withdraw early');

    /// @notice marking that power booster is withdrawn
    _sip.powerBoosterWithdrawls = _powerBoosterSerial;

    /// @notice calculating power booster amount
    uint256 _powerBoosterAmount = _sip.totalDeposited.div(3);

    /// @notice penalising power booster amount as per plan if commitment not met as per plan
    if(_powerBoosterSerial == 1) {
      uint256 _totalPenaltyFactor;
      for(uint256 i = 1; i <= sipPlans[ _sip.planId ].accumulationPeriodMonths; i++) {
        if(_sip.depositStatus[i] == 0) {
          /// @notice for defaulted months
          _totalPenaltyFactor += sipPlans[ _sip.planId ].defaultPenaltyFactor;
        } else if(_sip.depositStatus[i] == 1) {
          /// @notice for grace period months
          _totalPenaltyFactor += sipPlans[ _sip.planId ].gracePenaltyFactor;
        }
      }
      uint256 _penaltyAmount = _powerBoosterAmount.mul(_totalPenaltyFactor).div(1000);

      /// @notice if there is any penalty then apply the penalty
      if(_penaltyAmount > 0) {

        /// @notice allocate penalty amount into fund.
        fundsDeposit = fundsDeposit.add(_penaltyAmount);

        /// @notice emiting event that funds been deposited
        emit FundsDeposited(_penaltyAmount);

        /// @notice subtracting penalty form power booster amount
        _powerBoosterAmount = _powerBoosterAmount.sub(_penaltyAmount);
      }
    }

    /// @notice transfering tokens to wallet of withdrawer
    token.transfer(msg.sender, _powerBoosterAmount);

    /// @notice emit that power booster withdrawl is done
    emit PowerBoosterWithdrawl(
      _stakerAddress,
      _sipId,
      _powerBoosterSerial,
      _powerBoosterAmount,
      msg.sender
    );
  }

  /// @notice this function is used to update nominee status of a wallet address in SIP
  /// @param _sipId: id of SIP in staker portfolio.
  /// @param _nomineeAddress: eth wallet address of nominee.
  /// @param _newNomineeStatus: true or false, whether this should be a nominee or not.
  function toogleNominee(
    uint256 _sipId,
    address _nomineeAddress,
    bool _newNomineeStatus
  ) public {

    /// @notice updating nominee status
    sips[msg.sender][_sipId].nominees[_nomineeAddress] = _newNomineeStatus;

    /// @notice emiting event for UI and other applications
    emit NomineeUpdated(msg.sender, _sipId, _nomineeAddress, _newNomineeStatus);
  }

  /// @notice this function is used to update appointee status of a wallet address in SIP
  /// @param _sipId: id of SIP in staker portfolio.
  /// @param _appointeeAddress: eth wallet address of appointee.
  /// @param _newAppointeeStatus: true or false, should this have appointee rights or not.
  function toogleAppointee(
    uint256 _sipId,
    address _appointeeAddress,
    bool _newAppointeeStatus
  ) public {
    SIP storage _sip = sips[msg.sender][_sipId];

    /// @notice if not an appointee already and _newAppointeeStatus is true, adding appointee
    if(!_sip.appointees[_appointeeAddress] && _newAppointeeStatus) {
      _sip.numberOfAppointees = _sip.numberOfAppointees.add(1);
      _sip.appointees[_appointeeAddress] = true;
    }

    /// @notice if already an appointee and _newAppointeeStatus is false, removing appointee
    else if(_sip.appointees[_appointeeAddress] && !_newAppointeeStatus) {
      _sip.appointees[_appointeeAddress] = false;
      _sip.numberOfAppointees = _sip.numberOfAppointees.sub(1);
    }

    emit AppointeeUpdated(msg.sender, _sipId, _appointeeAddress, _newAppointeeStatus);
  }

  /// @notice this function is used by appointee to vote that nominees can withdraw early
  /// @dev need to be appointee, set by staker themselves
  /// @param _stakerAddress: address of initiater of this SIP.
  /// @param _sipId: id of SIP in staker portfolio.
  function appointeeVote(
    address _stakerAddress,
    uint256 _sipId
  ) public {
    SIP storage _sip = sips[_stakerAddress][_sipId];

    /// @notice checking if appointee has rights to cast a vote
    require(_sip.appointees[msg.sender]
      , 'should be appointee to cast vote'
    );

    /// @notice removing appointee's rights to vote again
    _sip.appointees[msg.sender] = false;

    /// @notice adding a vote to SIP
    _sip.appointeeVotes = _sip.appointeeVotes.add(1);

    /// @notice emit that appointee has voted
    emit AppointeeVoted(_stakerAddress, _sipId, msg.sender);
  }

  /// @notice this function is used to read all time deposit status of any staker SIP
  /// @param _stakerAddress: address of initiater of this SIP.
  /// @param _sipId: id of SIP in staker portfolio.
  /// @param _monthId: deposit month id starts from 1 upto as per plan
  /// @return 0 => no deposit, 1 => grace deposit, 2 => on time deposit
  function getDepositDoneStatus(
    address _stakerAddress,
    uint256 _sipId,
    uint256 _monthId
  ) public view returns (uint256) {
    return sips[_stakerAddress][_sipId].depositStatus[_monthId];
  }

  /// @notice this function is used to calculate deposit status according to current time
  /// @dev it is used in deposit function require statement.
  /// @param _stakerAddress: address of initiater of this SIP.
  /// @param _sipId: id of SIP in staker portfolio.
  /// @param _monthId: deposit month id to calculate status for
  /// @return 0 => too late, 1 => its grace time, 2 => on time
  function getDepositStatus(
    address _stakerAddress,
    uint256 _sipId,
    uint256 _monthId
  ) public view returns (uint256) {
    SIP storage _sip = sips[_stakerAddress][_sipId];

    /// @notice restricting month between 1 and max accumulation month
    require(
      _monthId >= 1 && _monthId
        <= sipPlans[ _sip.planId ].accumulationPeriodMonths
      , 'invalid deposit month'
    );

    /// @dev not using safemath because _monthId is bounded.
    uint256 onTimeTimestamp = _sip.stakingTimestamp + EARTH_SECONDS_IN_MONTH * (_monthId - 1);

    /// @notice deposit allowed only one month before deadline
    if(now < onTimeTimestamp - EARTH_SECONDS_IN_MONTH) {
      return 0; /// @notice means deposit is in advance than allowed
    } else if(onTimeTimestamp >= now) {
      return 2; /// @notice means deposit is ontime
    } else if(onTimeTimestamp + sipPlans[ _sip.planId ].gracePeriodSeconds >= now) {
      return 1; /// @notice means deposit is in grace period
    } else {
      return 0; /// @notice means even grace period is elapsed
    }
  }

  /// @notice this function is used to get avalilable withdrawls upto a withdrawl month id
  /// @param _stakerAddress: address of initiater of this SIP.
  /// @param _sipId: id of SIP in staker portfolio.
  /// @param _withdrawlMonthId: withdrawl month id upto which to calculate returns for
  /// @param _isNomineeWithdrawing: different status in case of nominee withdrawl
  /// @return gives available withdrawl amount upto the withdrawl month id
  function getPendingWithdrawlAmount(
    address _stakerAddress,
    uint256 _sipId,
    uint256 _withdrawlMonthId,
    bool _isNomineeWithdrawing
  ) public view returns (uint256) {
    SIP storage _sip = sips[_stakerAddress][_sipId];

    /// @notice check if withdrawl month is in allowed range
    require(
      _withdrawlMonthId > 0 && _withdrawlMonthId <= sipPlans[ _sip.planId ].benefitPeriodYears * 12
      , 'invalid withdraw month'
    );

    /// @notice check if already withdrawled upto the withdrawl month id
    require(
      _withdrawlMonthId > _sip.lastWithdrawlMonthId
      , 'cannot withdraw again'
    );

    /// @notice calculate allowed time for staker
    uint256 withdrawlAllowedTimestamp
      = _sip.stakingTimestamp
        + EARTH_SECONDS_IN_MONTH * (
          sipPlans[ _sip.planId ].accumulationPeriodMonths
            + _withdrawlMonthId - 1
        );

    /// @notice if nominee is withdrawing, update the allowed time
    if(_isNomineeWithdrawing) {
      if(_sip.appointeeVotes > _sip.numberOfAppointees.div(2)) {
        /// @notice with concensus of appointees, withdraw is allowed in 6 months
        withdrawlAllowedTimestamp += EARTH_SECONDS_IN_MONTH * 6;
      } else {
        /// @notice otherwise a default of 1 year delay in withdrawing benefits
        withdrawlAllowedTimestamp += EARTH_SECONDS_IN_MONTH * 12;
      }
    }

    /// @notice restricting early withdrawl
    require(now >= withdrawlAllowedTimestamp
      , 'cannot withdraw early'
    );

    /// @notice calculate average deposit
    uint256 _benefitToGive;
    for(uint256 _i = _sip.lastWithdrawlMonthId + 1; _i <= _withdrawlMonthId; _i++) {
      uint256 _modulus = _i%sipPlans[ _sip.planId ].accumulationPeriodMonths;
      if(_modulus == 0) _modulus = sipPlans[ _sip.planId ].accumulationPeriodMonths;
      _benefitToGive = _benefitToGive.add(
        _sip.monthlyBenefitAmount[_modulus]
      );
    }

    return _benefitToGive;
  }

  function viewMonthlyBenefitAmount(
    address _stakerAddress,
    uint256 _sipId,
    uint256 _depositMonthId
  ) public view returns (uint256) {
    return sips[_stakerAddress][_sipId].monthlyBenefitAmount[_depositMonthId];
  }

  /// @notice this function is used to view nomination
  /// @param _stakerAddress: address of initiater of this SIP.
  /// @param _sipId: id of SIP in staker portfolio.
  /// @param _nomineeAddress: eth wallet address of nominee.
  /// @return tells whether this address is a nominee or not
  function viewNomination(
    address _stakerAddress,
    uint256 _sipId,
    address _nomineeAddress
  ) public view returns (bool) {
    return sips[_stakerAddress][_sipId].nominees[_nomineeAddress];
  }

  /// @notice this function is used to view appointation
  /// @param _stakerAddress: address of initiater of this SIP.
  /// @param _sipId: id of SIP in staker portfolio.
  /// @param _appointeeAddress: eth wallet address of apointee.
  /// @return tells whether this address is a appointee or not
  function viewAppointation(
    address _stakerAddress,
    uint256 _sipId,
    address _appointeeAddress
  ) public view returns (bool) {
    return sips[_stakerAddress][_sipId].appointees[_appointeeAddress];
  }
}

/// @dev For interface requirement
contract ERC20 {
  function transfer(address _to, uint256 _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

