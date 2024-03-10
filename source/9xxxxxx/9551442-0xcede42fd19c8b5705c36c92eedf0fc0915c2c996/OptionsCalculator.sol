pragma solidity ^0.4.26;

import "./ESOPTypes.sol";

contract OptionsCalculator is Destructable, ESOPTypes
{
	using SafeMath for uint;

    uint constant public FP_SCALE = 10000;

	// cliff duration in seconds
	uint public cliffPeriod;
	// vesting duration in seconds
	uint public vestingPeriod;
	// maximum promille that can fade out
	uint public maxFadeoutPromille;
	// minimal options after fadeout
	function residualAmountPromille() public constant returns(uint) { return FP_SCALE - maxFadeoutPromille; }
	// exit bonus promille
	uint public bonusOptionsPromille;
	// per mille of unassigned poolOptions that new employee gets
	uint public newEmployeePoolPromille;
	// options per share
	uint public optionsPerShare;
	// company address
	address public companyAddress;
	// options strike price
	uint constant public STRIKE_PRICE = 1;

	modifier onlyCompany()
	{
		require (msg.sender == companyAddress);
		_;
	}

	function calcNewEmployeePoolOptions(uint remainingPoolOptions) public constant returns (uint)
	{
		return (remainingPoolOptions * newEmployeePoolPromille).divRound(FP_SCALE);
	}

	function calculateVestedOptions(uint t, uint vestingStarts, uint options) public constant returns (uint)
	{
		if (t <= vestingStarts)
			return 0;

		uint effectiveTime = t - vestingStarts;
		if (effectiveTime < cliffPeriod)
			return 0;
		if (effectiveTime < vestingPeriod)
			return (options * effectiveTime).divRound(vestingPeriod);
		return options;
	}

	function applyFadeoutToOptions(uint32 t, uint32 issueDate, uint32 terminatedAt, uint options, uint vestedOptions) public constant returns (uint)
	{
		// fadeout duration equals to employment duration

		if (t < terminatedAt)
			return vestedOptions;
		uint timefromTermination = t - terminatedAt;
		uint employmentPeriod = terminatedAt - issueDate;

		// minimum value of options at the end of fadeout, it is a % of all employee's options
		uint minFadeValue = (options * (FP_SCALE - maxFadeoutPromille)).divRound(FP_SCALE);

		// however employee cannot have more than options after fadeout than he was vested at termination
		if (minFadeValue >= vestedOptions)
			return vestedOptions;

		// fadeout period complete
		if (timefromTermination > employmentPeriod)
			return minFadeValue;

		return (minFadeValue + ((vestedOptions - minFadeValue) * (employmentPeriod - timefromTermination)).divRound(employmentPeriod) );
	}

	// returns tuple of (vested pool options, vested extra options, bonus)
	function calculateOptionsComponents(uint[9] employee, uint32 calcAtTime,uint32 conversionOfferedAt,
										bool disableAcceleratedVesting) public constant returns (uint, uint, uint)
	{
		Employee memory emp = deserializeEmployee(employee);

		// no options if:
		// 	1. converted options
		// 	2. esop is not singed
		// 	3. employee with no options

		if (emp.state == EmployeeState.OptionsExercised)
			return (0,0,0);

		if (emp.state == EmployeeState.WaitingForSignature)
			return (0,0,0);

		uint issuedOptions = emp.poolOptions + emp.extraOptions;
		if (issuedOptions == 0)
			return (0,0,0);

		// no options when esop is being converted and conversion deadline expired
		bool isESOPConverted = conversionOfferedAt > 0 && calcAtTime >= conversionOfferedAt;

		// if emp is terminated but we calc options before term, simulate employed again
		if (calcAtTime < emp.terminatedAt && emp.terminatedAt > 0)
			emp.state = EmployeeState.Employed;

		uint vestedOptions = issuedOptions;
		bool accelerateVesting = isESOPConverted && emp.state == EmployeeState.Employed && !disableAcceleratedVesting;

		if (!accelerateVesting)
		{
			// choose vesting time
			uint32 calcVestingAt = calcAtTime;
			if(emp.state == EmployeeState.Terminated)
				calcVestingAt = emp.terminatedAt;
			else if(emp.suspendedAt > 0 && emp.suspendedAt < calcAtTime)
				calcVestingAt = emp.suspendedAt;
			else if(conversionOfferedAt > 0)
				calcVestingAt = conversionOfferedAt;

			vestedOptions = calculateVestedOptions(calcVestingAt, emp.issueDate, issuedOptions);
		}
		// calc fadeout for terminated employees
		if (emp.state == EmployeeState.Terminated)
		{
			// use conversion event time to compute fadeout to stop fadeout on conversion IF not after conversion date
			if(isESOPConverted)
				vestedOptions = applyFadeoutToOptions(conversionOfferedAt, emp.issueDate, emp.terminatedAt, issuedOptions, vestedOptions);
			else
				vestedOptions = applyFadeoutToOptions(calcAtTime, emp.issueDate, emp.terminatedAt, issuedOptions, vestedOptions);
		}

		uint vestedPoolOptions;
		uint vestedExtraOptions;
		(vestedPoolOptions, vestedExtraOptions) = extractVestedOptionsComponents(emp.poolOptions, emp.extraOptions, vestedOptions);

		if(accelerateVesting)
			return	(vestedPoolOptions, vestedExtraOptions, (vestedPoolOptions*bonusOptionsPromille).divRound(FP_SCALE));

		return	(vestedPoolOptions, vestedExtraOptions, 0);
	}

	function calculateOptions(uint[9] employee, uint32 calcAtTime, uint32 conversionOfferedAt, bool disableAcceleratedVesting) public constant returns (uint)
	{
		uint vestedPoolOptions;
		uint vestedExtraOptions;
		uint bonus;
		(vestedPoolOptions, vestedExtraOptions, bonus) = calculateOptionsComponents(employee, calcAtTime, conversionOfferedAt, disableAcceleratedVesting);
		return vestedPoolOptions + vestedExtraOptions + bonus;
	}

	function extractVestedOptionsComponents(uint issuedPoolOptions, uint issuedExtraOptions, uint vestedOptions) public pure returns (uint, uint)
	{
		if (issuedExtraOptions == 0)
			return (vestedOptions, 0);
		uint poolOptions = (issuedPoolOptions*vestedOptions).divRound(issuedPoolOptions + issuedExtraOptions);
		return (poolOptions, vestedOptions - poolOptions);
	}

	function calculateFadeoutToPool(uint32 t, uint[9] employee) public constant returns (uint, uint)
	{
		Employee memory emp = deserializeEmployee(employee);

		uint vestedOptions = calculateVestedOptions(emp.terminatedAt, emp.issueDate, emp.poolOptions);
		uint returnedPoolOptions = applyFadeoutToOptions(emp.fadeoutStarts, emp.issueDate, emp.terminatedAt, emp.poolOptions, vestedOptions) -

		applyFadeoutToOptions(t, emp.issueDate, emp.terminatedAt, emp.poolOptions, vestedOptions);

		uint vestedExtraOptions = calculateVestedOptions(emp.terminatedAt, emp.issueDate, emp.extraOptions);
		uint returnedExtraOptions = applyFadeoutToOptions(emp.fadeoutStarts, emp.issueDate, emp.terminatedAt, emp.extraOptions, vestedExtraOptions) -

		applyFadeoutToOptions(t, emp.issueDate, emp.terminatedAt, emp.extraOptions, vestedExtraOptions);

		return (returnedPoolOptions, returnedExtraOptions);
	}

	function simulateOptions(uint32 issueDate, uint32 terminatedAt, uint32 poolOptions,
		uint32 extraOptions, uint32 suspendedAt, uint8 employeeState, uint32 calcAtTime) public constant returns (uint)
	{
		Employee memory emp = Employee({issueDate: issueDate,
										terminatedAt: terminatedAt,
										poolOptions: poolOptions,
										extraOptions: extraOptions,
										state: EmployeeState(employeeState),
										timeToSign: issueDate + 2 weeks,
										fadeoutStarts: terminatedAt,
										suspendedAt: suspendedAt,
										idx:1});

		return calculateOptions(serializeEmployee(emp), calcAtTime, 0, false);
	}

	function setParameters(uint32 pCliffPeriod, uint32 pVestingPeriod,
						uint32 pResidualAmountPromille, uint32 pBonusOptionsPromille,
						uint32 pNewEmployeePoolPromille, uint32 pOptionsPerShare) external onlyCompany
	{
		require (pResidualAmountPromille <= FP_SCALE);
		require (pBonusOptionsPromille <= FP_SCALE);
		require (pNewEmployeePoolPromille <= FP_SCALE);
		require (pOptionsPerShare != 0);

		require (pCliffPeriod <= pVestingPeriod);
		require (optionsPerShare == 0);

		cliffPeriod = pCliffPeriod;
		vestingPeriod = pVestingPeriod;
		maxFadeoutPromille = FP_SCALE - pResidualAmountPromille;
		bonusOptionsPromille = pBonusOptionsPromille;
		newEmployeePoolPromille = pNewEmployeePoolPromille;
		optionsPerShare = pOptionsPerShare;
	}

	constructor (address pCompanyAddress) public
	{
		companyAddress = pCompanyAddress;
	}
}

