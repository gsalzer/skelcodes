// File: contracts/ownership/PayableOwnable.sol

pragma solidity 0.5.10;

/**
 * @title PayableOwnable
 * @dev The PayableOwnable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 * PayableOwnable is extended from open-zeppelin Ownable smart contract, with the difference of making the owner
 * a payable address.
 */
contract PayableOwnable {
    address payable internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address payable) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity 0.5.10;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity 0.5.10;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/PumaPayPullPayment.sol

pragma solidity 0.5.10;




/// @title PumaPay Pull Payment - Contract that facilitates our pull payment protocol
/// @author PumaPay Dev Team - <developers@pumapay.io>
contract PumaPayPullPayment is PayableOwnable {

    using SafeMath for uint256;

    /// ===============================================================================================================
    ///                                      Events
    /// ===============================================================================================================

    event LogExecutorAdded(address executor);
    event LogExecutorRemoved(address executor);
    event LogSetConversionRate(string currency, uint256 conversionRate);

    event LogSmartContractActorFunded(string actorRole, address payable actor, uint256 timestamp);

    event LogPaymentRegistered(
        address customerAddress,
        bytes32 paymentID,
        bytes32 businessID,
        string uniqueReferenceID
    );
    event LogPaymentCancelled(
        address customerAddress,
        bytes32 paymentID,
        bytes32 businessID,
        string uniqueReferenceID
    );
    event LogPullPaymentExecuted(
        address customerAddress,
        bytes32 paymentID,
        bytes32 businessID,
        string uniqueReferenceID,
        uint256 amountInPMA,
        uint256 conversionRate
    );

    /// ===============================================================================================================
    ///                                      Constants
    /// ===============================================================================================================

    uint256 constant private RATE_CALCULATION_NUMBER = 10 ** 26;    /// Check `calculatePMAFromFiat()` for more details
    uint256 constant private OVERFLOW_LIMITER_NUMBER = 10 ** 20;    /// 1e^20 - Prevent numeric overflows

    /// @dev The following variables are not needed any more, but are kept hre for clarity on the calculation that
    /// is being done for the PMA to Fiat from rate.
    /// uint256 constant private DECIMAL_FIXER = 10 ** 10; /// 1e^10 - This transforms the Rate from decimals to uint256
    /// uint256 constant private FIAT_TO_CENT_FIXER = 100; /// Fiat currencies have 100 cents in 1 basic monetary unit.

    uint256 constant private ONE_ETHER = 1 ether;                               /// PumaPay token has 18 decimals - same as one ETHER
    uint256 constant private FUNDING_AMOUNT = 0.5 ether;                        /// Amount to transfer to owner/executor
    uint256 constant private MINIMUM_AMOUNT_OF_ETH_FOR_OPERATORS = 0.15 ether;  /// min amount of ETH for owner/executor

    bytes32 constant private EMPTY_BYTES32 = "";

    /// ===============================================================================================================
    ///                                      Members
    /// ===============================================================================================================

    IERC20 public token;

    mapping(string => uint256) private conversionRates;
    mapping(address => bool) public executors;
    mapping(address => mapping(address => PullPayment)) public pullPayments;

    struct PullPayment {
        bytes32 paymentID;                      /// ID of the payment
        bytes32 businessID;                     /// ID of the business
        string uniqueReferenceID;               /// unique reference ID the business is adding on the pull payment
        string currency;                        /// 3-letter abbr i.e. 'EUR' / 'USD' etc.
        uint256 initialPaymentAmountInCents;    /// initial payment amount in fiat in cents
        uint256 fiatAmountInCents;              /// payment amount in fiat in cents
        uint256 frequency;                      /// how often merchant can pull - in seconds
        uint256 numberOfPayments;               /// amount of pull payments merchant can make
        uint256 startTimestamp;                 /// when subscription starts - in seconds
        uint256 nextPaymentTimestamp;           /// timestamp of next payment
        uint256 lastPaymentTimestamp;           /// timestamp of last payment
        uint256 cancelTimestamp;                /// timestamp the payment was cancelled
        address treasuryAddress;                /// address which pma tokens will be transfer to on execution
    }

    /// ===============================================================================================================
    ///                                      Modifiers
    /// ===============================================================================================================
    modifier isExecutor() {
        require(executors[msg.sender], "msg.sender not an executor");
        _;
    }

    modifier executorExists(address _executor) {
        require(executors[_executor], "Executor does not exists.");
        _;
    }

    modifier executorDoesNotExists(address _executor) {
        require(!executors[_executor], "Executor already exists.");
        _;
    }

    modifier paymentExists(address _customerAddress, address _pullPaymentExecutor) {
        require(doesPaymentExist(_customerAddress, _pullPaymentExecutor), "Pull Payment does not exists");
        _;
    }

    modifier paymentNotCancelled(address _customerAddress, address _pullPaymentExecutor) {
        require(pullPayments[_customerAddress][_pullPaymentExecutor].cancelTimestamp == 0, "Pull Payment is cancelled.");
        _;
    }

    modifier isValidPullPaymentExecutionRequest(address _customerAddress, address _pullPaymentExecutor, bytes32 _paymentID, uint256 _paymentNumber)
    {
        require(pullPayments[_customerAddress][_pullPaymentExecutor].numberOfPayments == _paymentNumber,
            "Invalid pull payment execution request - Pull payment number of payment is invalid");

        require(
            (pullPayments[_customerAddress][_pullPaymentExecutor].initialPaymentAmountInCents > 0 ||
        (now >= pullPayments[_customerAddress][_pullPaymentExecutor].startTimestamp &&
        now >= pullPayments[_customerAddress][_pullPaymentExecutor].nextPaymentTimestamp)
            ), "Invalid pull payment execution request - Time of execution is invalid."
        );
        require(pullPayments[_customerAddress][_pullPaymentExecutor].numberOfPayments > 0,
            "Invalid pull payment execution request - Number of payments is zero.");

        require((pullPayments[_customerAddress][_pullPaymentExecutor].cancelTimestamp == 0 ||
        pullPayments[_customerAddress][_pullPaymentExecutor].cancelTimestamp > pullPayments[_customerAddress][_pullPaymentExecutor].nextPaymentTimestamp),
            "Invalid pull payment execution request - Pull payment is cancelled");
        require(keccak256(
            abi.encodePacked(pullPayments[_customerAddress][_pullPaymentExecutor].paymentID)
        ) == keccak256(abi.encodePacked(_paymentID)),
            "Invalid pull payment execution request - Payment ID not matching.");
        _;
    }

    modifier isValidDeletionRequest(bytes32 _paymentID, address _customerAddress, address _pullPaymentExecutor) {
        require(_customerAddress != address(0), "Invalid deletion request - Client address is ZERO_ADDRESS.");
        require(_pullPaymentExecutor != address(0), "Invalid deletion request - Beneficiary address is ZERO_ADDRESS.");
        require(_paymentID != EMPTY_BYTES32, "Invalid deletion request - Payment ID is empty.");
        _;
    }

    modifier isValidAddress(address _address) {
        require(_address != address(0), "Invalid address - ZERO_ADDRESS provided");
        _;
    }

    modifier validConversionRate(string memory _currency) {
        require(bytes(_currency).length != 0, "Invalid conversion rate - Currency is empty.");
        _;
    }

    modifier validAmount(uint256 _amount) {
        require(_amount > 0, "Invalid amount - Must be higher than zero");
        require(_amount <= OVERFLOW_LIMITER_NUMBER, "Invalid amount - Must be lower than the overflow limit.");
        _;
    }

    /// ===============================================================================================================
    ///                                      Constructor
    /// ===============================================================================================================

    /// @dev Contract constructor - sets the token address that the contract facilitates.
    /// @param _token Token Address.
    constructor (address _token)
    public {
        require(_token != address(0), "Invalid address for token - ZERO_ADDRESS provided");
        token = IERC20(_token);
    }

    // @notice Will receive any eth sent to the contract
    function() external payable {
    }

    /// ===============================================================================================================
    ///                                      Public Functions - Owner Only
    /// ===============================================================================================================

    /// @dev Adds a new executor. - can be executed only by the owner.
    /// When adding a new executor 0.5 ETH is transferred to allow the executor to pay for gas.
    /// The balance of the owner is also checked and if funding is needed 0.5 ETH is transferred.
    /// @param _executor - address of the executor which cannot be zero address.

    function addExecutor(address payable _executor)
    public
    onlyOwner
    isValidAddress(_executor)
    executorDoesNotExists(_executor)
    {
        executors[_executor] = true;
        if (isFundingNeeded(_executor)) {
            _executor.transfer(FUNDING_AMOUNT);
            emit LogSmartContractActorFunded("executor", _executor, now);
        }

        if (isFundingNeeded(owner())) {
            owner().transfer(FUNDING_AMOUNT);

            emit LogSmartContractActorFunded("owner", owner(), now);
        }

        emit LogExecutorAdded(_executor);
    }

    /// @dev Removes a new executor. - can be executed only by the owner.
    /// The balance of the owner is checked and if funding is needed 0.5 ETH is transferred.
    /// @param _executor - address of the executor which cannot be zero address.
    function removeExecutor(address payable _executor)
    public
    onlyOwner
    isValidAddress(_executor)
    executorExists(_executor)
    {
        executors[_executor] = false;
        if (isFundingNeeded(owner())) {
            owner().transfer(FUNDING_AMOUNT);

            emit LogSmartContractActorFunded("owner", owner(), now);
        }
        emit LogExecutorRemoved(_executor);
    }

    /// @dev Sets the exchange rate for a currency. - can be executed only by the onwer.
    /// Emits 'LogSetConversionRate' with the currency and the updated rate.
    /// The balance of the owner is checked and if funding is needed 0.5 ETH is transferred.
    /// @param _currency - address of the executor which cannot be zero address
    /// @param _rate - address of the executor which cannot be zero address
    function setRate(string memory _currency, uint256 _rate)
    public
    onlyOwner
    validAmount(_rate)
    returns (bool) {
        require(bytes(_currency).length != 0, "Invalid conversion rate - Currency is empty.");
        conversionRates[_currency] = _rate;
        emit LogSetConversionRate(_currency, _rate);

        if (isFundingNeeded(owner())) {
            owner().transfer(FUNDING_AMOUNT);

            emit LogSmartContractActorFunded("owner", owner(), now);
        }

        return true;
    }

    /// ===============================================================================================================
    ///                                      Public Functions - Executors Only
    /// ===============================================================================================================

    /// @dev Registers a new pull payment to the PumaPay Pull Payment Contract - The registration can be executed only
    /// by one of the executors of the PumaPay Pull Payment Contract
    /// and the PumaPay Pull Payment Contract checks that the pull payment has been singed by the customerAddress of the account.
    /// The balance of the executor (msg.sender) is checked and if funding is needed 0.5 ETH is transferred.
    /// Emits 'LogPaymentRegistered' with customerAddress address, beneficiary address and paymentID.
    /// @param v - recovery ID of the ETH signature. - https://github.com/ethereum/EIPs/issues/155
    /// @param r - R output of ECDSA signature.
    /// @param s - S output of ECDSA signature.
    /// @param _ids - array with the IDs for the payment ([0] paymentID, [1] businessID).
    /// @param _addresses - all the relevant addresses for the payment.
    /// @param _currency - currency of the payment / 3-letter abbr i.e. 'EUR'.
    /// @param _uniqueReferenceID - unique reference ID is the id that the business uses within their system.
    /// @param _fiatAmountInCents - payment amount in fiat in cents.
    /// @param _frequency - how often merchant can pull - in seconds.
    /// @param _numberOfPayments - amount of pull payments merchant can make
    /// @param _startTimestamp - when subscription starts - in seconds.
    function registerPullPayment(
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32[2] memory _ids, // [0] paymentID, [1] businessID
        address[3] memory _addresses, // [0] customerAddress, [1] pull payment executor, [2] treasury wallet
        string memory _currency,
        string memory _uniqueReferenceID,
        uint256 _initialPaymentAmountInCents,
        uint256 _fiatAmountInCents,
        uint256 _frequency,
        uint256 _numberOfPayments,
        uint256 _startTimestamp
    )
    public
    isExecutor()
    {
        require(!doesPaymentExist(_addresses[0], _addresses[1]), "Pull Payment already exists.");

        require(_ids[0] != EMPTY_BYTES32, "Payment ID is empty.");
        require(_ids[1] != EMPTY_BYTES32, "Business ID is empty.");
        require(bytes(_currency).length > 0, "Currency is empty.");
        require(bytes(_uniqueReferenceID).length > 0, "Unique Reference ID is empty.");

        require(_addresses[0] != address(0), "Customer Address is ZERO_ADDRESS.");
        require(_addresses[1] != address(0), "Beneficiary Address is ZERO_ADDRESS.");
        require(_addresses[2] != address(0), "Treasury Address is ZERO_ADDRESS.");

        require(_fiatAmountInCents > 0, "Payment amount in fiat is zero.");
        require(_frequency > 0, "Payment frequency is zero.");
        require(_numberOfPayments > 0, "Payment number of payments is zero.");
        require(_startTimestamp > 0, "Payment start time is zero.");

        require(_fiatAmountInCents <= OVERFLOW_LIMITER_NUMBER, "Payment amount is higher than the overflow limit.");
        require(_frequency <= OVERFLOW_LIMITER_NUMBER, "Payment frequency is higher than the overflow limit.");
        require(_numberOfPayments <= OVERFLOW_LIMITER_NUMBER, "Payment number of payments is higher than the overflow limit.");
        require(_startTimestamp <= OVERFLOW_LIMITER_NUMBER, "Payment start time is higher than the overflow limit.");

        pullPayments[_addresses[0]][_addresses[1]].currency = _currency;
        pullPayments[_addresses[0]][_addresses[1]].initialPaymentAmountInCents = _initialPaymentAmountInCents;
        pullPayments[_addresses[0]][_addresses[1]].fiatAmountInCents = _fiatAmountInCents;
        pullPayments[_addresses[0]][_addresses[1]].frequency = _frequency;
        pullPayments[_addresses[0]][_addresses[1]].startTimestamp = _startTimestamp;
        pullPayments[_addresses[0]][_addresses[1]].numberOfPayments = _numberOfPayments;
        pullPayments[_addresses[0]][_addresses[1]].paymentID = _ids[0];
        pullPayments[_addresses[0]][_addresses[1]].businessID = _ids[1];
        pullPayments[_addresses[0]][_addresses[1]].uniqueReferenceID = _uniqueReferenceID;
        pullPayments[_addresses[0]][_addresses[1]].treasuryAddress = _addresses[2];

        require(isValidRegistration(
                v,
                r,
                s,
                _addresses[0],
                _addresses[1],
                pullPayments[_addresses[0]][_addresses[1]]),
            "Invalid pull payment registration - ECRECOVER_FAILED"
        );

        pullPayments[_addresses[0]][_addresses[1]].nextPaymentTimestamp = _startTimestamp;
        pullPayments[_addresses[0]][_addresses[1]].lastPaymentTimestamp = 0;
        pullPayments[_addresses[0]][_addresses[1]].cancelTimestamp = 0;

        if (isFundingNeeded(msg.sender)) {
            msg.sender.transfer(FUNDING_AMOUNT);

            emit LogSmartContractActorFunded("executor", msg.sender, now);
        }

        emit LogPaymentRegistered(_addresses[0], _ids[0], _ids[1], _uniqueReferenceID);
    }

    /// @dev Deletes a pull payment for a beneficiary - The deletion needs can be executed only by one of the
    /// executors of the PumaPay Pull Payment Contract
    /// and the PumaPay Pull Payment Contract checks that the beneficiary and the paymentID have
    /// been singed by the customerAddress of the account.
    /// This method sets the cancellation of the pull payment in the pull payments array for this beneficiary specified.
    /// The balance of the executor (msg.sender) is checked and if funding is needed 0.5 ETH is transferred.
    /// Emits 'LogPaymentCancelled' with beneficiary address and paymentID.
    /// @param v - recovery ID of the ETH signature. - https://github.com/ethereum/EIPs/issues/155
    /// @param r - R output of ECDSA signature.
    /// @param s - S output of ECDSA signature.
    /// @param _paymentID - ID of the payment.
    /// @param _customerAddress - customerAddress address that is linked to this pull payment.
    /// @param _pullPaymentExecutor - address that is allowed to execute this pull payment.
    function deletePullPayment(
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 _paymentID,
        address _customerAddress,
        address _pullPaymentExecutor
    )
    public
    isExecutor()
    paymentExists(_customerAddress, _pullPaymentExecutor)
    paymentNotCancelled(_customerAddress, _pullPaymentExecutor)
    isValidDeletionRequest(_paymentID, _customerAddress, _pullPaymentExecutor)
    {
        require(isValidDeletion(v, r, s, _paymentID, _customerAddress, _pullPaymentExecutor), "Invalid deletion - ECRECOVER_FAILED.");

        pullPayments[_customerAddress][_pullPaymentExecutor].cancelTimestamp = now;

        if (isFundingNeeded(msg.sender)) {
            msg.sender.transfer(FUNDING_AMOUNT);

            emit LogSmartContractActorFunded("executor", msg.sender, now);
        }

        emit LogPaymentCancelled(
            _customerAddress,
            _paymentID,
            pullPayments[_customerAddress][_pullPaymentExecutor].businessID,
            pullPayments[_customerAddress][_pullPaymentExecutor].uniqueReferenceID
        );
    }

    /// ===============================================================================================================
    ///                                      Public Functions
    /// ===============================================================================================================

    /// @dev Executes a pull payment for the msg.sender - The pull payment should exist and the payment request
    /// should be valid in terms of when it can be executed.
    /// Emits 'LogPullPaymentExecuted' with customerAddress address, msg.sender as the beneficiary address and the paymentID.
    /// Use Case 1: Single/Recurring Fixed Pull Payment (initialPaymentAmountInCents == 0 )
    /// ------------------------------------------------
    /// We calculate the amount in PMA using the rate for the currency specified in the pull payment
    /// and the 'fiatAmountInCents' and we transfer from the customerAddress account the amount in PMA.
    /// After execution we set the last payment timestamp to NOW, the next payment timestamp is incremented by
    /// the frequency and the number of payments is decreased by 1.
    /// Use Case 2: Recurring Fixed Pull Payment with initial fee (initialPaymentAmountInCents > 0)
    /// ------------------------------------------------------------------------------------------------
    /// We calculate the amount in PMA using the rate for the currency specified in the pull payment
    /// and the 'initialPaymentAmountInCents' and we transfer from the customerAddress account the amount in PMA.
    /// After execution we set the last payment timestamp to NOW and the 'initialPaymentAmountInCents to ZERO.
    /// @param _customerAddress - address of the customerAddress from which the msg.sender requires to pull funds.
    /// @param _paymentID - ID of the payment.
    function executePullPayment(address _customerAddress, bytes32 _paymentID, uint256 _paymentNumber)
    public
    paymentExists(_customerAddress, msg.sender)
    isValidPullPaymentExecutionRequest(_customerAddress, msg.sender, _paymentID, _paymentNumber)
    {
        uint256 amountInPMA;
        address customerAddress = _customerAddress;
        uint256 initialAmountInCents = pullPayments[customerAddress][msg.sender].initialPaymentAmountInCents;
        string memory currency = pullPayments[customerAddress][msg.sender].currency;

        if (initialAmountInCents > 0) {
            amountInPMA = calculatePMAFromFiat(initialAmountInCents, currency);

            pullPayments[customerAddress][msg.sender].initialPaymentAmountInCents = 0;
        } else {
            amountInPMA = calculatePMAFromFiat(pullPayments[customerAddress][msg.sender].fiatAmountInCents, currency);

            pullPayments[customerAddress][msg.sender].nextPaymentTimestamp =
            pullPayments[customerAddress][msg.sender].nextPaymentTimestamp + pullPayments[customerAddress][msg.sender].frequency;
            pullPayments[customerAddress][msg.sender].numberOfPayments = pullPayments[customerAddress][msg.sender].numberOfPayments - 1;
        }

        pullPayments[customerAddress][msg.sender].lastPaymentTimestamp = now;
        token.transferFrom(
            customerAddress,
            pullPayments[customerAddress][msg.sender].treasuryAddress,
            amountInPMA
        );

        emit LogPullPaymentExecuted(
            customerAddress,
            pullPayments[customerAddress][msg.sender].paymentID,
            pullPayments[customerAddress][msg.sender].businessID,
            pullPayments[customerAddress][msg.sender].uniqueReferenceID,
            amountInPMA,
            conversionRates[currency]
        );
    }

    function getRate(string memory _currency) public view returns (uint256) {
        return conversionRates[_currency];
    }

    /// ===============================================================================================================
    ///                                      Internal Functions
    /// ===============================================================================================================

    /// @dev Calculates the PMA Rate for the fiat currency specified - The rate is set every 10 minutes by our PMA server
    /// for the currencies specified in the smart contract.
    /// @param _fiatAmountInCents - payment amount in fiat CENTS so that is always integer
    /// @param _currency - currency in which the payment needs to take place
    /// RATE CALCULATION EXAMPLE
    /// ------------------------
    /// RATE ==> 1 PMA = 0.01 USD$
    /// 1 USD$ = 1/0.01 PMA = 100 PMA
    /// Start the calculation from one ether - PMA Token has 18 decimals
    /// Multiply by the DECIMAL_FIXER (1e+10) to fix the multiplication of the rate
    /// Multiply with the fiat amount in cents
    /// Divide by the Rate of PMA to Fiat in cents
    /// Divide by the FIAT_TO_CENT_FIXER to fix the _fiatAmountInCents
    /// ---------------------------------------------------------------------------------------------------------------
    /// To save on gas, we have 'pre-calculated' the equation below and have set a constant in its place.
    /// ONE_ETHER.mul(DECIMAL_FIXER).div(FIAT_TO_CENT_FIXER) = RATE_CALCULATION_NUMBER
    /// ONE_ETHER = 10^18           |
    /// DECIMAL_FIXER = 10^10       |   => 10^18 * 10^10 / 100 ==> 10^26  => RATE_CALCULATION_NUMBER = 10^26
    /// FIAT_TO_CENT_FIXER = 100    |
    /// NOTE: The aforementioned value is linked to the OVERFLOW_LIMITER_NUMBER which is set to 10^20.
    /// ---------------------------------------------------------------------------------------------------------------
    function calculatePMAFromFiat(uint256 _fiatAmountInCents, string memory _currency)
    internal
    view
    validConversionRate(_currency)
    validAmount(_fiatAmountInCents)
    returns (uint256) {
        return RATE_CALCULATION_NUMBER.mul(_fiatAmountInCents).div(conversionRates[_currency]);
    }

    /// @dev Checks if a registration request is valid by comparing the v, r, s params
    /// and the hashed params with the customerAddress address.
    /// @param v - recovery ID of the ETH signature. - https://github.com/ethereum/EIPs/issues/155
    /// @param r - R output of ECDSA signature.
    /// @param s - S output of ECDSA signature.
    /// @param _customerAddress - customerAddress address that is linked to this pull payment.
    /// @param _pullPaymentExecutor - address that is allowed to execute this pull payment.
    /// @param _pullPayment - pull payment to be validated.
    /// @return bool - if the v, r, s params with the hashed params match the customerAddress address
    function isValidRegistration(
        uint8 v,
        bytes32 r,
        bytes32 s,
        address _customerAddress,
        address _pullPaymentExecutor,
        PullPayment memory _pullPayment
    )
    internal
    pure
    returns (bool)
    {
        return ecrecover(
            keccak256(
                abi.encodePacked(
                    _pullPaymentExecutor,
                    _pullPayment.paymentID,
                    _pullPayment.businessID,
                    _pullPayment.uniqueReferenceID,
                    _pullPayment.treasuryAddress,
                    _pullPayment.currency,
                    _pullPayment.initialPaymentAmountInCents,
                    _pullPayment.fiatAmountInCents,
                    _pullPayment.frequency,
                    _pullPayment.numberOfPayments,
                    _pullPayment.startTimestamp
                )
            ),
            v, r, s) == _customerAddress;
    }

    /// @dev Checks if a deletion request is valid by comparing the v, r, s params
    /// and the hashed params with the customerAddress address.
    /// @param v - recovery ID of the ETH signature. - https://github.com/ethereum/EIPs/issues/155
    /// @param r - R output of ECDSA signature.
    /// @param s - S output of ECDSA signature.
    /// @param _paymentID - ID of the payment.
    /// @param _customerAddress - customerAddress address that is linked to this pull payment.
    /// @param _pullPaymentExecutor - address that is allowed to execute this pull payment.
    /// @return bool - if the v, r, s params with the hashed params match the customerAddress address
    function isValidDeletion(
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 _paymentID,
        address _customerAddress,
        address _pullPaymentExecutor
    )
    internal
    view
    returns (bool)
    {
        return ecrecover(
            keccak256(
                abi.encodePacked(
                    _paymentID,
                    _pullPaymentExecutor
                )
            ), v, r, s) == _customerAddress
        && keccak256(
            abi.encodePacked(pullPayments[_customerAddress][_pullPaymentExecutor].paymentID)
        ) == keccak256(abi.encodePacked(_paymentID)
        );
    }

    /// @dev Checks if a payment for a beneficiary of a customerAddress exists.
    /// @param _customerAddress - customerAddress address that is linked to this pull payment.
    /// @param _pullPaymentExecutor - address to execute a pull payment.
    /// @return bool - whether the beneficiary for this customerAddress has a pull payment to execute.
    function doesPaymentExist(address _customerAddress, address _pullPaymentExecutor)
    internal
    view
    returns (bool) {
        return (
        bytes(pullPayments[_customerAddress][_pullPaymentExecutor].currency).length > 0 &&
        pullPayments[_customerAddress][_pullPaymentExecutor].fiatAmountInCents > 0 &&
        pullPayments[_customerAddress][_pullPaymentExecutor].frequency > 0 &&
        pullPayments[_customerAddress][_pullPaymentExecutor].startTimestamp > 0 &&
        pullPayments[_customerAddress][_pullPaymentExecutor].numberOfPayments > 0 &&
        pullPayments[_customerAddress][_pullPaymentExecutor].nextPaymentTimestamp > 0
        );
    }

    /// @dev Checks if the address of an owner/executor needs to be funded.
    /// The minimum amount the owner/executors should always have is 0.15 ETH
    /// @param _address - address of owner/executors that the balance is checked against.
    /// @return bool - whether the address needs more ETH.
    function isFundingNeeded(address _address)
    private
    view
    returns (bool) {
        return address(_address).balance <= MINIMUM_AMOUNT_OF_ETH_FOR_OPERATORS;
    }
}
