// File: @aragon/court/contracts/lib/os/ERC20.sol

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/lib/token/ERC20.sol
// Adapted to use pragma ^0.5.8 and satisfy our linter rules

pragma solidity ^0.5.8;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender) public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value) public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: @aragon/court/contracts/arbitration/IArbitrator.sol

pragma solidity ^0.5.8;



interface IArbitrator {
    /**
    * @dev Create a dispute over the Arbitrable sender with a number of possible rulings
    * @param _possibleRulings Number of possible rulings allowed for the dispute
    * @param _metadata Optional metadata that can be used to provide additional information on the dispute to be created
    * @return Dispute identification number
    */
    function createDispute(uint256 _possibleRulings, bytes calldata _metadata) external returns (uint256);

    /**
    * @dev Close the evidence period of a dispute
    * @param _disputeId Identification number of the dispute to close its evidence submitting period
    */
    function closeEvidencePeriod(uint256 _disputeId) external;

    /**
    * @dev Execute the Arbitrable associated to a dispute based on its final ruling
    * @param _disputeId Identification number of the dispute to be executed
    */
    function executeRuling(uint256 _disputeId) external;

    /**
    * @dev Tell the dispute fees information to create a dispute
    * @return recipient Address where the corresponding dispute fees must be transferred to
    * @return feeToken ERC20 token used for the fees
    * @return feeAmount Total amount of fees that must be allowed to the recipient
    */
    function getDisputeFees() external view returns (address recipient, ERC20 feeToken, uint256 feeAmount);

    /**
    * @dev Tell the subscription fees information for a subscriber to be up-to-date
    * @param _subscriber Address of the account paying the subscription fees for
    * @return recipient Address where the corresponding subscriptions fees must be transferred to
    * @return feeToken ERC20 token used for the subscription fees
    * @return feeAmount Total amount of fees that must be allowed to the recipient
    */
    function getSubscriptionFees(address _subscriber) external view returns (address recipient, ERC20 feeToken, uint256 feeAmount);
}

// File: @aragon/court/contracts/standards/ERC165.sol

pragma solidity ^0.5.8;


interface ERC165 {
    /**
    * @dev Query if a contract implements a certain interface
    * @param _interfaceId The interface identifier being queried, as specified in ERC-165
    * @return True if the contract implements the requested interface and if its not 0xffffffff, false otherwise
    */
    function supportsInterface(bytes4 _interfaceId) external pure returns (bool);
}

// File: @aragon/court/contracts/arbitration/IArbitrable.sol

pragma solidity ^0.5.8;




contract IArbitrable is ERC165 {
    bytes4 internal constant ERC165_INTERFACE_ID = bytes4(0x01ffc9a7);
    bytes4 internal constant ARBITRABLE_INTERFACE_ID = bytes4(0x88f3ee69);

    /**
    * @dev Emitted when an IArbitrable instance's dispute is ruled by an IArbitrator
    * @param arbitrator IArbitrator instance ruling the dispute
    * @param disputeId Identification number of the dispute being ruled by the arbitrator
    * @param ruling Ruling given by the arbitrator
    */
    event Ruled(IArbitrator indexed arbitrator, uint256 indexed disputeId, uint256 ruling);

    /**
    * @dev Emitted when new evidence is submitted for the IArbitrable instance's dispute
    * @param disputeId Identification number of the dispute receiving new evidence
    * @param submitter Address of the account submitting the evidence
    * @param evidence Data submitted for the evidence of the dispute
    * @param finished Whether or not the submitter has finished submitting evidence
    */
    event EvidenceSubmitted(uint256 indexed disputeId, address indexed submitter, bytes evidence, bool finished);

    /**
    * @dev Submit evidence for a dispute
    * @param _disputeId Id of the dispute in the Court
    * @param _evidence Data submitted for the evidence related to the dispute
    * @param _finished Whether or not the submitter has finished submitting evidence
    */
    function submitEvidence(uint256 _disputeId, bytes calldata _evidence, bool _finished) external;

    /**
    * @dev Give a ruling for a certain dispute, the account calling it must have rights to rule on the contract
    * @param _disputeId Identification number of the dispute to be ruled
    * @param _ruling Ruling given by the arbitrator, where 0 is reserved for "refused to make a decision"
    */
    function rule(uint256 _disputeId, uint256 _ruling) external;

    /**
    * @dev ERC165 - Query if a contract implements a certain interface
    * @param _interfaceId The interface identifier being queried, as specified in ERC-165
    * @return True if this contract supports the given interface, false otherwise
    */
    function supportsInterface(bytes4 _interfaceId) external pure returns (bool) {
        return _interfaceId == ARBITRABLE_INTERFACE_ID || _interfaceId == ERC165_INTERFACE_ID;
    }
}

// File: @aragon/court/contracts/treasury/ITreasury.sol

pragma solidity ^0.5.8;



interface ITreasury {
    /**
    * @dev Assign a certain amount of tokens to an account
    * @param _token ERC20 token to be assigned
    * @param _to Address of the recipient that will be assigned the tokens to
    * @param _amount Amount of tokens to be assigned to the recipient
    */
    function assign(ERC20 _token, address _to, uint256 _amount) external;

    /**
    * @dev Withdraw a certain amount of tokens
    * @param _token ERC20 token to be withdrawn
    * @param _to Address of the recipient that will receive the tokens
    * @param _amount Amount of tokens to be withdrawn from the sender
    */
    function withdraw(ERC20 _token, address _to, uint256 _amount) external;
}

// File: @aragon/court/contracts/lib/os/IsContract.sol

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/common/IsContract.sol
// Adapted to use pragma ^0.5.8 and satisfy our linter rules

pragma solidity ^0.5.8;


contract IsContract {
    /*
    * NOTE: this should NEVER be used for authentication
    * (see pitfalls: https://github.com/fergarrui/ethereum-security/tree/master/contracts/extcodesize).
    *
    * This is only intended to be used as a sanity check that an address is actually a contract,
    * RATHER THAN an address not being a contract.
    */
    function isContract(address _target) internal view returns (bool) {
        if (_target == address(0)) {
            return false;
        }

        uint256 size;
        assembly { size := extcodesize(_target) }
        return size > 0;
    }
}

// File: @aragon/court/contracts/lib/os/SafeMath64.sol

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/lib/math/SafeMath64.sol
// Adapted to use pragma ^0.5.8 and satisfy our linter rules

pragma solidity ^0.5.8;


/**
 * @title SafeMath64
 * @dev Math operations for uint64 with safety checks that revert on error
 */
library SafeMath64 {
    string private constant ERROR_ADD_OVERFLOW = "MATH64_ADD_OVERFLOW";
    string private constant ERROR_SUB_UNDERFLOW = "MATH64_SUB_UNDERFLOW";
    string private constant ERROR_MUL_OVERFLOW = "MATH64_MUL_OVERFLOW";
    string private constant ERROR_DIV_ZERO = "MATH64_DIV_ZERO";

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint64 _a, uint64 _b) internal pure returns (uint64) {
        uint256 c = uint256(_a) * uint256(_b);
        require(c < 0x010000000000000000, ERROR_MUL_OVERFLOW); // 2**64 (less gas this way)

        return uint64(c);
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint64 _a, uint64 _b) internal pure returns (uint64) {
        require(_b > 0, ERROR_DIV_ZERO); // Solidity only automatically asserts when dividing by 0
        uint64 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint64 _a, uint64 _b) internal pure returns (uint64) {
        require(_b <= _a, ERROR_SUB_UNDERFLOW);
        uint64 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint64 _a, uint64 _b) internal pure returns (uint64) {
        uint64 c = _a + _b;
        require(c >= _a, ERROR_ADD_OVERFLOW);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint64 a, uint64 b) internal pure returns (uint64) {
        require(b != 0, ERROR_DIV_ZERO);
        return a % b;
    }
}

// File: @aragon/court/contracts/lib/os/Uint256Helpers.sol

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/common/Uint256Helpers.sol
// Adapted to use pragma ^0.5.8 and satisfy our linter rules

pragma solidity ^0.5.8;


library Uint256Helpers {
    uint256 private constant MAX_UINT8 = uint8(-1);
    uint256 private constant MAX_UINT64 = uint64(-1);

    string private constant ERROR_UINT8_NUMBER_TOO_BIG = "UINT8_NUMBER_TOO_BIG";
    string private constant ERROR_UINT64_NUMBER_TOO_BIG = "UINT64_NUMBER_TOO_BIG";

    function toUint8(uint256 a) internal pure returns (uint8) {
        require(a <= MAX_UINT8, ERROR_UINT8_NUMBER_TOO_BIG);
        return uint8(a);
    }

    function toUint64(uint256 a) internal pure returns (uint64) {
        require(a <= MAX_UINT64, ERROR_UINT64_NUMBER_TOO_BIG);
        return uint64(a);
    }
}

// File: @aragon/court/contracts/lib/os/TimeHelpers.sol

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/common/TimeHelpers.sol
// Adapted to use pragma ^0.5.8 and satisfy our linter rules

pragma solidity ^0.5.8;



contract TimeHelpers {
    using Uint256Helpers for uint256;

    /**
    * @dev Returns the current block number.
    *      Using a function rather than `block.number` allows us to easily mock the block number in
    *      tests.
    */
    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    /**
    * @dev Returns the current block number, converted to uint64.
    *      Using a function rather than `block.number` allows us to easily mock the block number in
    *      tests.
    */
    function getBlockNumber64() internal view returns (uint64) {
        return getBlockNumber().toUint64();
    }

    /**
    * @dev Returns the current timestamp.
    *      Using a function rather than `block.timestamp` allows us to easily mock it in
    *      tests.
    */
    function getTimestamp() internal view returns (uint256) {
        return block.timestamp; // solium-disable-line security/no-block-members
    }

    /**
    * @dev Returns the current timestamp, converted to uint64.
    *      Using a function rather than `block.timestamp` allows us to easily mock it in
    *      tests.
    */
    function getTimestamp64() internal view returns (uint64) {
        return getTimestamp().toUint64();
    }
}

// File: @aragon/court/contracts/court/clock/IClock.sol

pragma solidity ^0.5.8;


interface IClock {
    /**
    * @dev Ensure that the current term of the clock is up-to-date
    * @return Identification number of the current term
    */
    function ensureCurrentTerm() external returns (uint64);

    /**
    * @dev Transition up to a certain number of terms to leave the clock up-to-date
    * @param _maxRequestedTransitions Max number of term transitions allowed by the sender
    * @return Identification number of the term ID after executing the heartbeat transitions
    */
    function heartbeat(uint64 _maxRequestedTransitions) external returns (uint64);

    /**
    * @dev Ensure that a certain term has its randomness set
    * @return Randomness of the current term
    */
    function ensureCurrentTermRandomness() external returns (bytes32);

    /**
    * @dev Tell the last ensured term identification number
    * @return Identification number of the last ensured term
    */
    function getLastEnsuredTermId() external view returns (uint64);

    /**
    * @dev Tell the current term identification number. Note that there may be pending term transitions.
    * @return Identification number of the current term
    */
    function getCurrentTermId() external view returns (uint64);

    /**
    * @dev Tell the number of terms the clock should transition to be up-to-date
    * @return Number of terms the clock should transition to be up-to-date
    */
    function getNeededTermTransitions() external view returns (uint64);

    /**
    * @dev Tell the information related to a term based on its ID
    * @param _termId ID of the term being queried
    * @return startTime Term start time
    * @return randomnessBN Block number used for randomness in the requested term
    * @return randomness Randomness computed for the requested term
    */
    function getTerm(uint64 _termId) external view returns (uint64 startTime, uint64 randomnessBN, bytes32 randomness);

    /**
    * @dev Tell the randomness of a term even if it wasn't computed yet
    * @param _termId Identification number of the term being queried
    * @return Randomness of the requested term
    */
    function getTermRandomness(uint64 _termId) external view returns (bytes32);
}

// File: @aragon/court/contracts/court/clock/CourtClock.sol

pragma solidity ^0.5.8;





contract CourtClock is IClock, TimeHelpers {
    using SafeMath64 for uint64;

    string private constant ERROR_TERM_DOES_NOT_EXIST = "CLK_TERM_DOES_NOT_EXIST";
    string private constant ERROR_TERM_DURATION_TOO_LONG = "CLK_TERM_DURATION_TOO_LONG";
    string private constant ERROR_TERM_RANDOMNESS_NOT_YET = "CLK_TERM_RANDOMNESS_NOT_YET";
    string private constant ERROR_TERM_RANDOMNESS_UNAVAILABLE = "CLK_TERM_RANDOMNESS_UNAVAILABLE";
    string private constant ERROR_BAD_FIRST_TERM_START_TIME = "CLK_BAD_FIRST_TERM_START_TIME";
    string private constant ERROR_TOO_MANY_TRANSITIONS = "CLK_TOO_MANY_TRANSITIONS";
    string private constant ERROR_INVALID_TRANSITION_TERMS = "CLK_INVALID_TRANSITION_TERMS";
    string private constant ERROR_CANNOT_DELAY_STARTED_COURT = "CLK_CANNOT_DELAY_STARTED_COURT";
    string private constant ERROR_CANNOT_DELAY_PAST_START_TIME = "CLK_CANNOT_DELAY_PAST_START_TIME";

    // Maximum number of term transitions a callee may have to assume in order to call certain functions that require the Court being up-to-date
    uint64 internal constant MAX_AUTO_TERM_TRANSITIONS_ALLOWED = 1;

    // Max duration in seconds that a term can last
    uint64 internal constant MAX_TERM_DURATION = 365 days;

    // Max time until first term starts since contract is deployed
    uint64 internal constant MAX_FIRST_TERM_DELAY_PERIOD = 2 * MAX_TERM_DURATION;

    struct Term {
        uint64 startTime;              // Timestamp when the term started
        uint64 randomnessBN;           // Block number for entropy
        bytes32 randomness;            // Entropy from randomnessBN block hash
    }

    // Duration in seconds for each term of the Court
    uint64 private termDuration;

    // Last ensured term id
    uint64 private termId;

    // List of Court terms indexed by id
    mapping (uint64 => Term) private terms;

    event Heartbeat(uint64 previousTermId, uint64 currentTermId);
    event StartTimeDelayed(uint64 previousStartTime, uint64 currentStartTime);

    /**
    * @dev Ensure a certain term has already been processed
    * @param _termId Identification number of the term to be checked
    */
    modifier termExists(uint64 _termId) {
        require(_termId <= termId, ERROR_TERM_DOES_NOT_EXIST);
        _;
    }

    /**
    * @dev Constructor function
    * @param _termParams Array containing:
    *        0. _termDuration Duration in seconds per term
    *        1. _firstTermStartTime Timestamp in seconds when the court will open (to give time for juror on-boarding)
    */
    constructor(uint64[2] memory _termParams) public {
        uint64 _termDuration = _termParams[0];
        uint64 _firstTermStartTime = _termParams[1];

        require(_termDuration < MAX_TERM_DURATION, ERROR_TERM_DURATION_TOO_LONG);
        require(_firstTermStartTime >= getTimestamp64() + _termDuration, ERROR_BAD_FIRST_TERM_START_TIME);
        require(_firstTermStartTime <= getTimestamp64() + MAX_FIRST_TERM_DELAY_PERIOD, ERROR_BAD_FIRST_TERM_START_TIME);

        termDuration = _termDuration;

        // No need for SafeMath: we already checked values above
        terms[0].startTime = _firstTermStartTime - _termDuration;
    }

    /**
    * @notice Ensure that the current term of the Court is up-to-date. If the Court is outdated by more than `MAX_AUTO_TERM_TRANSITIONS_ALLOWED`
    *         terms, the heartbeat function must be called manually instead.
    * @return Identification number of the current term
    */
    function ensureCurrentTerm() external returns (uint64) {
        return _ensureCurrentTerm();
    }

    /**
    * @notice Transition up to `_maxRequestedTransitions` terms
    * @param _maxRequestedTransitions Max number of term transitions allowed by the sender
    * @return Identification number of the term ID after executing the heartbeat transitions
    */
    function heartbeat(uint64 _maxRequestedTransitions) external returns (uint64) {
        return _heartbeat(_maxRequestedTransitions);
    }

    /**
    * @notice Ensure that a certain term has its randomness set. As we allow to draft disputes requested for previous terms, if there
    *      were mined more than 256 blocks for the current term, the blockhash of its randomness BN is no longer available, given
    *      round will be able to be drafted in the following term.
    * @return Randomness of the current term
    */
    function ensureCurrentTermRandomness() external returns (bytes32) {
        // If the randomness for the given term was already computed, return
        uint64 currentTermId = termId;
        Term storage term = terms[currentTermId];
        bytes32 termRandomness = term.randomness;
        if (termRandomness != bytes32(0)) {
            return termRandomness;
        }

        // Compute term randomness
        bytes32 newRandomness = _computeTermRandomness(currentTermId);
        require(newRandomness != bytes32(0), ERROR_TERM_RANDOMNESS_UNAVAILABLE);
        term.randomness = newRandomness;
        return newRandomness;
    }

    /**
    * @dev Tell the term duration of the Court
    * @return Duration in seconds of the Court term
    */
    function getTermDuration() external view returns (uint64) {
        return termDuration;
    }

    /**
    * @dev Tell the last ensured term identification number
    * @return Identification number of the last ensured term
    */
    function getLastEnsuredTermId() external view returns (uint64) {
        return _lastEnsuredTermId();
    }

    /**
    * @dev Tell the current term identification number. Note that there may be pending term transitions.
    * @return Identification number of the current term
    */
    function getCurrentTermId() external view returns (uint64) {
        return _currentTermId();
    }

    /**
    * @dev Tell the number of terms the Court should transition to be up-to-date
    * @return Number of terms the Court should transition to be up-to-date
    */
    function getNeededTermTransitions() external view returns (uint64) {
        return _neededTermTransitions();
    }

    /**
    * @dev Tell the information related to a term based on its ID. Note that if the term has not been reached, the
    *      information returned won't be computed yet. This function allows querying future terms that were not computed yet.
    * @param _termId ID of the term being queried
    * @return startTime Term start time
    * @return randomnessBN Block number used for randomness in the requested term
    * @return randomness Randomness computed for the requested term
    */
    function getTerm(uint64 _termId) external view returns (uint64 startTime, uint64 randomnessBN, bytes32 randomness) {
        Term storage term = terms[_termId];
        return (term.startTime, term.randomnessBN, term.randomness);
    }

    /**
    * @dev Tell the randomness of a term even if it wasn't computed yet
    * @param _termId Identification number of the term being queried
    * @return Randomness of the requested term
    */
    function getTermRandomness(uint64 _termId) external view termExists(_termId) returns (bytes32) {
        return _computeTermRandomness(_termId);
    }

    /**
    * @dev Internal function to ensure that the current term of the Court is up-to-date. If the Court is outdated by more than
    *      `MAX_AUTO_TERM_TRANSITIONS_ALLOWED` terms, the heartbeat function must be called manually.
    * @return Identification number of the resultant term ID after executing the corresponding transitions
    */
    function _ensureCurrentTerm() internal returns (uint64) {
        // Check the required number of transitions does not exceeds the max allowed number to be processed automatically
        uint64 requiredTransitions = _neededTermTransitions();
        require(requiredTransitions <= MAX_AUTO_TERM_TRANSITIONS_ALLOWED, ERROR_TOO_MANY_TRANSITIONS);

        // If there are no transitions pending, return the last ensured term id
        if (uint256(requiredTransitions) == 0) {
            return termId;
        }

        // Process transition if there is at least one pending
        return _heartbeat(requiredTransitions);
    }

    /**
    * @dev Internal function to transition the Court terms up to a requested number of terms
    * @param _maxRequestedTransitions Max number of term transitions allowed by the sender
    * @return Identification number of the resultant term ID after executing the requested transitions
    */
    function _heartbeat(uint64 _maxRequestedTransitions) internal returns (uint64) {
        // Transition the minimum number of terms between the amount requested and the amount actually needed
        uint64 neededTransitions = _neededTermTransitions();
        uint256 transitions = uint256(_maxRequestedTransitions < neededTransitions ? _maxRequestedTransitions : neededTransitions);
        require(transitions > 0, ERROR_INVALID_TRANSITION_TERMS);

        uint64 blockNumber = getBlockNumber64();
        uint64 previousTermId = termId;
        uint64 currentTermId = previousTermId;
        for (uint256 transition = 1; transition <= transitions; transition++) {
            // Term IDs are incremented by one based on the number of time periods since the Court started. Since time is represented in uint64,
            // even if we chose the minimum duration possible for a term (1 second), we can ensure terms will never reach 2^64 since time is
            // already assumed to fit in uint64.
            Term storage previousTerm = terms[currentTermId++];
            Term storage currentTerm = terms[currentTermId];
            _onTermTransitioned(currentTermId);

            // Set the start time of the new term. Note that we are using a constant term duration value to guarantee
            // equally long terms, regardless of heartbeats.
            currentTerm.startTime = previousTerm.startTime.add(termDuration);

            // In order to draft a random number of jurors in a term, we use a randomness factor for each term based on a
            // block number that is set once the term has started. Note that this information could not be known beforehand.
            currentTerm.randomnessBN = blockNumber + 1;
        }

        termId = currentTermId;
        emit Heartbeat(previousTermId, currentTermId);
        return currentTermId;
    }

    /**
    * @dev Internal function to delay the first term start time only if it wasn't reached yet
    * @param _newFirstTermStartTime New timestamp in seconds when the court will open
    */
    function _delayStartTime(uint64 _newFirstTermStartTime) internal {
        require(_currentTermId() == 0, ERROR_CANNOT_DELAY_STARTED_COURT);

        Term storage term = terms[0];
        uint64 currentFirstTermStartTime = term.startTime.add(termDuration);
        require(_newFirstTermStartTime > currentFirstTermStartTime, ERROR_CANNOT_DELAY_PAST_START_TIME);

        // No need for SafeMath: we already checked above that `_newFirstTermStartTime` > `currentFirstTermStartTime` >= `termDuration`
        term.startTime = _newFirstTermStartTime - termDuration;
        emit StartTimeDelayed(currentFirstTermStartTime, _newFirstTermStartTime);
    }

    /**
    * @dev Internal function to notify when a term has been transitioned. This function must be overridden to provide custom behavior.
    * @param _termId Identification number of the new current term that has been transitioned
    */
    function _onTermTransitioned(uint64 _termId) internal;

    /**
    * @dev Internal function to tell the last ensured term identification number
    * @return Identification number of the last ensured term
    */
    function _lastEnsuredTermId() internal view returns (uint64) {
        return termId;
    }

    /**
    * @dev Internal function to tell the current term identification number. Note that there may be pending term transitions.
    * @return Identification number of the current term
    */
    function _currentTermId() internal view returns (uint64) {
        return termId.add(_neededTermTransitions());
    }

    /**
    * @dev Internal function to tell the number of terms the Court should transition to be up-to-date
    * @return Number of terms the Court should transition to be up-to-date
    */
    function _neededTermTransitions() internal view returns (uint64) {
        // Note that the Court is always initialized providing a start time for the first-term in the future. If that's the case,
        // no term transitions are required.
        uint64 currentTermStartTime = terms[termId].startTime;
        if (getTimestamp64() < currentTermStartTime) {
            return uint64(0);
        }

        // No need for SafeMath: we already know that the start time of the current term is in the past
        return (getTimestamp64() - currentTermStartTime) / termDuration;
    }

    /**
    * @dev Internal function to compute the randomness that will be used to draft jurors for the given term. This
    *      function assumes the given term exists. To determine the randomness factor for a term we use the hash of a
    *      block number that is set once the term has started to ensure it cannot be known beforehand. Note that the
    *      hash function being used only works for the 256 most recent block numbers.
    * @param _termId Identification number of the term being queried
    * @return Randomness computed for the given term
    */
    function _computeTermRandomness(uint64 _termId) internal view returns (bytes32) {
        Term storage term = terms[_termId];
        require(getBlockNumber64() > term.randomnessBN, ERROR_TERM_RANDOMNESS_NOT_YET);
        return blockhash(term.randomnessBN);
    }
}

// File: @aragon/court/contracts/court/config/IConfig.sol

pragma solidity ^0.5.8;



interface IConfig {

    /**
    * @dev Tell the full Court configuration parameters at a certain term
    * @param _termId Identification number of the term querying the Court config of
    * @return token Address of the token used to pay for fees
    * @return fees Array containing:
    *         0. jurorFee Amount of fee tokens that is paid per juror per dispute
    *         1. draftFee Amount of fee tokens per juror to cover the drafting cost
    *         2. settleFee Amount of fee tokens per juror to cover round settlement cost
    * @return roundStateDurations Array containing the durations in terms of the different phases of a dispute:
    *         0. evidenceTerms Max submitting evidence period duration in terms
    *         1. commitTerms Commit period duration in terms
    *         2. revealTerms Reveal period duration in terms
    *         3. appealTerms Appeal period duration in terms
    *         4. appealConfirmationTerms Appeal confirmation period duration in terms
    * @return pcts Array containing:
    *         0. penaltyPct Permyriad of min active tokens balance to be locked for each drafted juror (‱ - 1/10,000)
    *         1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @return roundParams Array containing params for rounds:
    *         0. firstRoundJurorsNumber Number of jurors to be drafted for the first round of disputes
    *         1. appealStepFactor Increasing factor for the number of jurors of each round of a dispute
    *         2. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    * @return appealCollateralParams Array containing params for appeal collateral:
    *         0. appealCollateralFactor Multiple of dispute fees required to appeal a preliminary ruling
    *         1. appealConfirmCollateralFactor Multiple of dispute fees required to confirm appeal
    * @return minActiveBalance Minimum amount of tokens jurors have to activate to participate in the Court
    */
    function getConfig(uint64 _termId) external view
        returns (
            ERC20 feeToken,
            uint256[3] memory fees,
            uint64[5] memory roundStateDurations,
            uint16[2] memory pcts,
            uint64[4] memory roundParams,
            uint256[2] memory appealCollateralParams,
            uint256 minActiveBalance
        );

    /**
    * @dev Tell the draft config at a certain term
    * @param _termId Identification number of the term querying the draft config of
    * @return feeToken Address of the token used to pay for fees
    * @return draftFee Amount of fee tokens per juror to cover the drafting cost
    * @return penaltyPct Permyriad of min active tokens balance to be locked for each drafted juror (‱ - 1/10,000)
    */
    function getDraftConfig(uint64 _termId) external view returns (ERC20 feeToken, uint256 draftFee, uint16 penaltyPct);

    /**
    * @dev Tell the min active balance config at a certain term
    * @param _termId Term querying the min active balance config of
    * @return Minimum amount of tokens jurors have to activate to participate in the Court
    */
    function getMinActiveBalance(uint64 _termId) external view returns (uint256);

    /**
    * @dev Tell whether a certain holder accepts automatic withdrawals of tokens or not
    * @return True if the given holder accepts automatic withdrawals of their tokens, false otherwise
    */
    function areWithdrawalsAllowedFor(address _holder) external view returns (bool);
}

// File: @aragon/court/contracts/court/config/CourtConfigData.sol

pragma solidity ^0.5.8;



contract CourtConfigData {
    struct Config {
        FeesConfig fees;                        // Full fees-related config
        DisputesConfig disputes;                // Full disputes-related config
        uint256 minActiveBalance;               // Minimum amount of tokens jurors have to activate to participate in the Court
    }

    struct FeesConfig {
        ERC20 token;                            // ERC20 token to be used for the fees of the Court
        uint16 finalRoundReduction;             // Permyriad of fees reduction applied for final appeal round (‱ - 1/10,000)
        uint256 jurorFee;                       // Amount of tokens paid to draft a juror to adjudicate a dispute
        uint256 draftFee;                       // Amount of tokens paid per round to cover the costs of drafting jurors
        uint256 settleFee;                      // Amount of tokens paid per round to cover the costs of slashing jurors
    }

    struct DisputesConfig {
        uint64 evidenceTerms;                   // Max submitting evidence period duration in terms
        uint64 commitTerms;                     // Committing period duration in terms
        uint64 revealTerms;                     // Revealing period duration in terms
        uint64 appealTerms;                     // Appealing period duration in terms
        uint64 appealConfirmTerms;              // Confirmation appeal period duration in terms
        uint16 penaltyPct;                      // Permyriad of min active tokens balance to be locked for each drafted juror (‱ - 1/10,000)
        uint64 firstRoundJurorsNumber;          // Number of jurors drafted on first round
        uint64 appealStepFactor;                // Factor in which the jurors number is increased on each appeal
        uint64 finalRoundLockTerms;             // Period a coherent juror in the final round will remain locked
        uint256 maxRegularAppealRounds;         // Before the final appeal
        uint256 appealCollateralFactor;         // Permyriad multiple of dispute fees required to appeal a preliminary ruling (‱ - 1/10,000)
        uint256 appealConfirmCollateralFactor;  // Permyriad multiple of dispute fees required to confirm appeal (‱ - 1/10,000)
    }

    struct DraftConfig {
        ERC20 feeToken;                         // ERC20 token to be used for the fees of the Court
        uint16 penaltyPct;                      // Permyriad of min active tokens balance to be locked for each drafted juror (‱ - 1/10,000)
        uint256 draftFee;                       // Amount of tokens paid per round to cover the costs of drafting jurors
    }
}

// File: @aragon/court/contracts/lib/os/SafeMath.sol

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/lib/math/SafeMath.sol
// Adapted to use pragma ^0.5.8 and satisfy our linter rules

pragma solidity >=0.4.24 <0.6.0;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    string private constant ERROR_ADD_OVERFLOW = "MATH_ADD_OVERFLOW";
    string private constant ERROR_SUB_UNDERFLOW = "MATH_SUB_UNDERFLOW";
    string private constant ERROR_MUL_OVERFLOW = "MATH_MUL_OVERFLOW";
    string private constant ERROR_DIV_ZERO = "MATH_DIV_ZERO";

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b, ERROR_MUL_OVERFLOW);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0, ERROR_DIV_ZERO); // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a, ERROR_SUB_UNDERFLOW);
        uint256 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a, ERROR_ADD_OVERFLOW);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, ERROR_DIV_ZERO);
        return a % b;
    }
}

// File: @aragon/court/contracts/lib/PctHelpers.sol

pragma solidity ^0.5.8;



library PctHelpers {
    using SafeMath for uint256;

    uint256 internal constant PCT_BASE = 10000; // ‱ (1 / 10,000)

    function isValid(uint16 _pct) internal pure returns (bool) {
        return _pct <= PCT_BASE;
    }

    function pct(uint256 self, uint16 _pct) internal pure returns (uint256) {
        return self.mul(uint256(_pct)) / PCT_BASE;
    }

    function pct256(uint256 self, uint256 _pct) internal pure returns (uint256) {
        return self.mul(_pct) / PCT_BASE;
    }

    function pctIncrease(uint256 self, uint16 _pct) internal pure returns (uint256) {
        // No need for SafeMath: for addition note that `PCT_BASE` is lower than (2^256 - 2^16)
        return self.mul(PCT_BASE + uint256(_pct)) / PCT_BASE;
    }
}

// File: @aragon/court/contracts/court/config/CourtConfig.sol

pragma solidity ^0.5.8;







contract CourtConfig is IConfig, CourtConfigData {
    using SafeMath64 for uint64;
    using PctHelpers for uint256;

    string private constant ERROR_TOO_OLD_TERM = "CONF_TOO_OLD_TERM";
    string private constant ERROR_INVALID_PENALTY_PCT = "CONF_INVALID_PENALTY_PCT";
    string private constant ERROR_INVALID_FINAL_ROUND_REDUCTION_PCT = "CONF_INVALID_FINAL_ROUND_RED_PCT";
    string private constant ERROR_INVALID_MAX_APPEAL_ROUNDS = "CONF_INVALID_MAX_APPEAL_ROUNDS";
    string private constant ERROR_LARGE_ROUND_PHASE_DURATION = "CONF_LARGE_ROUND_PHASE_DURATION";
    string private constant ERROR_BAD_INITIAL_JURORS_NUMBER = "CONF_BAD_INITIAL_JURORS_NUMBER";
    string private constant ERROR_BAD_APPEAL_STEP_FACTOR = "CONF_BAD_APPEAL_STEP_FACTOR";
    string private constant ERROR_ZERO_COLLATERAL_FACTOR = "CONF_ZERO_COLLATERAL_FACTOR";
    string private constant ERROR_ZERO_MIN_ACTIVE_BALANCE = "CONF_ZERO_MIN_ACTIVE_BALANCE";

    // Max number of terms that each of the different adjudication states can last (if lasted 1h, this would be a year)
    uint64 internal constant MAX_ADJ_STATE_DURATION = 8670;

    // Cap the max number of regular appeal rounds
    uint256 internal constant MAX_REGULAR_APPEAL_ROUNDS_LIMIT = 10;

    // Future term ID in which a config change has been scheduled
    uint64 private configChangeTermId;

    // List of all the configs used in the Court
    Config[] private configs;

    // List of configs indexed by id
    mapping (uint64 => uint256) private configIdByTerm;

    // Holders opt-in config for automatic withdrawals
    mapping (address => bool) private withdrawalsAllowed;

    event NewConfig(uint64 fromTermId, uint64 courtConfigId);
    event AutomaticWithdrawalsAllowedChanged(address indexed holder, bool allowed);

    /**
    * @dev Constructor function
    * @param _feeToken Address of the token contract that is used to pay for fees
    * @param _fees Array containing:
    *        0. jurorFee Amount of fee tokens that is paid per juror per dispute
    *        1. draftFee Amount of fee tokens per juror to cover the drafting cost
    *        2. settleFee Amount of fee tokens per juror to cover round settlement cost
    * @param _roundStateDurations Array containing the durations in terms of the different phases of a dispute:
    *        0. evidenceTerms Max submitting evidence period duration in terms
    *        1. commitTerms Commit period duration in terms
    *        2. revealTerms Reveal period duration in terms
    *        3. appealTerms Appeal period duration in terms
    *        4. appealConfirmationTerms Appeal confirmation period duration in terms
    * @param _pcts Array containing:
    *        0. penaltyPct Permyriad of min active tokens balance to be locked for each drafted juror (‱ - 1/10,000)
    *        1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @param _roundParams Array containing params for rounds:
    *        0. firstRoundJurorsNumber Number of jurors to be drafted for the first round of disputes
    *        1. appealStepFactor Increasing factor for the number of jurors of each round of a dispute
    *        2. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    *        3. finalRoundLockTerms Number of terms that a coherent juror in a final round is disallowed to withdraw (to prevent 51% attacks)
    * @param _appealCollateralParams Array containing params for appeal collateral:
    *        0. appealCollateralFactor Multiple of dispute fees required to appeal a preliminary ruling
    *        1. appealConfirmCollateralFactor Multiple of dispute fees required to confirm appeal
    * @param _minActiveBalance Minimum amount of juror tokens that can be activated
    */
    constructor(
        ERC20 _feeToken,
        uint256[3] memory _fees,
        uint64[5] memory _roundStateDurations,
        uint16[2] memory _pcts,
        uint64[4] memory _roundParams,
        uint256[2] memory _appealCollateralParams,
        uint256 _minActiveBalance
    )
        public
    {
        // Leave config at index 0 empty for non-scheduled config changes
        configs.length = 1;
        _setConfig(
            0,
            0,
            _feeToken,
            _fees,
            _roundStateDurations,
            _pcts,
            _roundParams,
            _appealCollateralParams,
            _minActiveBalance
        );
    }

    /**
    * @notice Set the automatic withdrawals config for the sender to `_allowed`
    * @param _allowed Whether or not the automatic withdrawals are allowed by the sender
    */
    function setAutomaticWithdrawals(bool _allowed) external {
        withdrawalsAllowed[msg.sender] = _allowed;
        emit AutomaticWithdrawalsAllowedChanged(msg.sender, _allowed);
    }

    /**
    * @dev Tell the full Court configuration parameters at a certain term
    * @param _termId Identification number of the term querying the Court config of
    * @return token Address of the token used to pay for fees
    * @return fees Array containing:
    *         0. jurorFee Amount of fee tokens that is paid per juror per dispute
    *         1. draftFee Amount of fee tokens per juror to cover the drafting cost
    *         2. settleFee Amount of fee tokens per juror to cover round settlement cost
    * @return roundStateDurations Array containing the durations in terms of the different phases of a dispute:
    *         0. evidenceTerms Max submitting evidence period duration in terms
    *         1. commitTerms Commit period duration in terms
    *         2. revealTerms Reveal period duration in terms
    *         3. appealTerms Appeal period duration in terms
    *         4. appealConfirmationTerms Appeal confirmation period duration in terms
    * @return pcts Array containing:
    *         0. penaltyPct Permyriad of min active tokens balance to be locked for each drafted juror (‱ - 1/10,000)
    *         1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @return roundParams Array containing params for rounds:
    *         0. firstRoundJurorsNumber Number of jurors to be drafted for the first round of disputes
    *         1. appealStepFactor Increasing factor for the number of jurors of each round of a dispute
    *         2. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    * @return appealCollateralParams Array containing params for appeal collateral:
    *         0. appealCollateralFactor Multiple of dispute fees required to appeal a preliminary ruling
    *         1. appealConfirmCollateralFactor Multiple of dispute fees required to confirm appeal
    * @return minActiveBalance Minimum amount of tokens jurors have to activate to participate in the Court
    */
    function getConfig(uint64 _termId) external view
        returns (
            ERC20 feeToken,
            uint256[3] memory fees,
            uint64[5] memory roundStateDurations,
            uint16[2] memory pcts,
            uint64[4] memory roundParams,
            uint256[2] memory appealCollateralParams,
            uint256 minActiveBalance
        );

    /**
    * @dev Tell the draft config at a certain term
    * @param _termId Identification number of the term querying the draft config of
    * @return feeToken Address of the token used to pay for fees
    * @return draftFee Amount of fee tokens per juror to cover the drafting cost
    * @return penaltyPct Permyriad of min active tokens balance to be locked for each drafted juror (‱ - 1/10,000)
    */
    function getDraftConfig(uint64 _termId) external view returns (ERC20 feeToken, uint256 draftFee, uint16 penaltyPct);

    /**
    * @dev Tell the min active balance config at a certain term
    * @param _termId Term querying the min active balance config of
    * @return Minimum amount of tokens jurors have to activate to participate in the Court
    */
    function getMinActiveBalance(uint64 _termId) external view returns (uint256);

    /**
    * @dev Tell whether a certain holder accepts automatic withdrawals of tokens or not
    * @param _holder Address of the token holder querying if withdrawals are allowed for
    * @return True if the given holder accepts automatic withdrawals of their tokens, false otherwise
    */
    function areWithdrawalsAllowedFor(address _holder) external view returns (bool) {
        return withdrawalsAllowed[_holder];
    }

    /**
    * @dev Tell the term identification number of the next scheduled config change
    * @return Term identification number of the next scheduled config change
    */
    function getConfigChangeTermId() external view returns (uint64) {
        return configChangeTermId;
    }

    /**
    * @dev Internal to make sure to set a config for the new term, it will copy the previous term config if none
    * @param _termId Identification number of the new current term that has been transitioned
    */
    function _ensureTermConfig(uint64 _termId) internal {
        // If the term being transitioned had no config change scheduled, keep the previous one
        uint256 currentConfigId = configIdByTerm[_termId];
        if (currentConfigId == 0) {
            uint256 previousConfigId = configIdByTerm[_termId.sub(1)];
            configIdByTerm[_termId] = previousConfigId;
        }
    }

    /**
    * @dev Assumes that sender it's allowed (either it's from governor or it's on init)
    * @param _termId Identification number of the current Court term
    * @param _fromTermId Identification number of the term in which the config will be effective at
    * @param _feeToken Address of the token contract that is used to pay for fees.
    * @param _fees Array containing:
    *        0. jurorFee Amount of fee tokens that is paid per juror per dispute
    *        1. draftFee Amount of fee tokens per juror to cover the drafting cost
    *        2. settleFee Amount of fee tokens per juror to cover round settlement cost
    * @param _roundStateDurations Array containing the durations in terms of the different phases of a dispute:
    *        0. evidenceTerms Max submitting evidence period duration in terms
    *        1. commitTerms Commit period duration in terms
    *        2. revealTerms Reveal period duration in terms
    *        3. appealTerms Appeal period duration in terms
    *        4. appealConfirmationTerms Appeal confirmation period duration in terms
    * @param _pcts Array containing:
    *        0. penaltyPct Permyriad of min active tokens balance to be locked for each drafted juror (‱ - 1/10,000)
    *        1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @param _roundParams Array containing params for rounds:
    *        0. firstRoundJurorsNumber Number of jurors to be drafted for the first round of disputes
    *        1. appealStepFactor Increasing factor for the number of jurors of each round of a dispute
    *        2. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    *        3. finalRoundLockTerms Number of terms that a coherent juror in a final round is disallowed to withdraw (to prevent 51% attacks)
    * @param _appealCollateralParams Array containing params for appeal collateral:
    *        0. appealCollateralFactor Multiple of dispute fees required to appeal a preliminary ruling
    *        1. appealConfirmCollateralFactor Multiple of dispute fees required to confirm appeal
    * @param _minActiveBalance Minimum amount of juror tokens that can be activated
    */
    function _setConfig(
        uint64 _termId,
        uint64 _fromTermId,
        ERC20 _feeToken,
        uint256[3] memory _fees,
        uint64[5] memory _roundStateDurations,
        uint16[2] memory _pcts,
        uint64[4] memory _roundParams,
        uint256[2] memory _appealCollateralParams,
        uint256 _minActiveBalance
    )
        internal
    {
        // If the current term is not zero, changes must be scheduled at least after the current period.
        // No need to ensure delays for on-going disputes since these already use their creation term for that.
        require(_termId == 0 || _fromTermId > _termId, ERROR_TOO_OLD_TERM);

        // Make sure appeal collateral factors are greater than zero
        require(_appealCollateralParams[0] > 0 && _appealCollateralParams[1] > 0, ERROR_ZERO_COLLATERAL_FACTOR);

        // Make sure the given penalty and final round reduction pcts are not greater than 100%
        require(PctHelpers.isValid(_pcts[0]), ERROR_INVALID_PENALTY_PCT);
        require(PctHelpers.isValid(_pcts[1]), ERROR_INVALID_FINAL_ROUND_REDUCTION_PCT);

        // Disputes must request at least one juror to be drafted initially
        require(_roundParams[0] > 0, ERROR_BAD_INITIAL_JURORS_NUMBER);

        // Prevent that further rounds have zero jurors
        require(_roundParams[1] > 0, ERROR_BAD_APPEAL_STEP_FACTOR);

        // Make sure the max number of appeals allowed does not reach the limit
        uint256 _maxRegularAppealRounds = _roundParams[2];
        bool isMaxAppealRoundsValid = _maxRegularAppealRounds > 0 && _maxRegularAppealRounds <= MAX_REGULAR_APPEAL_ROUNDS_LIMIT;
        require(isMaxAppealRoundsValid, ERROR_INVALID_MAX_APPEAL_ROUNDS);

        // Make sure each adjudication round phase duration is valid
        for (uint i = 0; i < _roundStateDurations.length; i++) {
            require(_roundStateDurations[i] > 0 && _roundStateDurations[i] < MAX_ADJ_STATE_DURATION, ERROR_LARGE_ROUND_PHASE_DURATION);
        }

        // Make sure min active balance is not zero
        require(_minActiveBalance > 0, ERROR_ZERO_MIN_ACTIVE_BALANCE);

        // If there was a config change already scheduled, reset it (in that case we will overwrite last array item).
        // Otherwise, schedule a new config.
        if (configChangeTermId > _termId) {
            configIdByTerm[configChangeTermId] = 0;
        } else {
            configs.length++;
        }

        uint64 courtConfigId = uint64(configs.length - 1);
        Config storage config = configs[courtConfigId];

        config.fees = FeesConfig({
            token: _feeToken,
            jurorFee: _fees[0],
            draftFee: _fees[1],
            settleFee: _fees[2],
            finalRoundReduction: _pcts[1]
        });

        config.disputes = DisputesConfig({
            evidenceTerms: _roundStateDurations[0],
            commitTerms: _roundStateDurations[1],
            revealTerms: _roundStateDurations[2],
            appealTerms: _roundStateDurations[3],
            appealConfirmTerms: _roundStateDurations[4],
            penaltyPct: _pcts[0],
            firstRoundJurorsNumber: _roundParams[0],
            appealStepFactor: _roundParams[1],
            maxRegularAppealRounds: _maxRegularAppealRounds,
            finalRoundLockTerms: _roundParams[3],
            appealCollateralFactor: _appealCollateralParams[0],
            appealConfirmCollateralFactor: _appealCollateralParams[1]
        });

        config.minActiveBalance = _minActiveBalance;

        configIdByTerm[_fromTermId] = courtConfigId;
        configChangeTermId = _fromTermId;

        emit NewConfig(_fromTermId, courtConfigId);
    }

    /**
    * @dev Internal function to get the Court config for a given term
    * @param _termId Identification number of the term querying the Court config of
    * @param _lastEnsuredTermId Identification number of the last ensured term of the Court
    * @return token Address of the token used to pay for fees
    * @return fees Array containing:
    *         0. jurorFee Amount of fee tokens that is paid per juror per dispute
    *         1. draftFee Amount of fee tokens per juror to cover the drafting cost
    *         2. settleFee Amount of fee tokens per juror to cover round settlement cost
    * @return roundStateDurations Array containing the durations in terms of the different phases of a dispute:
    *         0. evidenceTerms Max submitting evidence period duration in terms
    *         1. commitTerms Commit period duration in terms
    *         2. revealTerms Reveal period duration in terms
    *         3. appealTerms Appeal period duration in terms
    *         4. appealConfirmationTerms Appeal confirmation period duration in terms
    * @return pcts Array containing:
    *         0. penaltyPct Permyriad of min active tokens balance to be locked for each drafted juror (‱ - 1/10,000)
    *         1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @return roundParams Array containing params for rounds:
    *         0. firstRoundJurorsNumber Number of jurors to be drafted for the first round of disputes
    *         1. appealStepFactor Increasing factor for the number of jurors of each round of a dispute
    *         2. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    *         3. finalRoundLockTerms Number of terms that a coherent juror in a final round is disallowed to withdraw (to prevent 51% attacks)
    * @return appealCollateralParams Array containing params for appeal collateral:
    *         0. appealCollateralFactor Multiple of dispute fees required to appeal a preliminary ruling
    *         1. appealConfirmCollateralFactor Multiple of dispute fees required to confirm appeal
    * @return minActiveBalance Minimum amount of juror tokens that can be activated
    */
    function _getConfigAt(uint64 _termId, uint64 _lastEnsuredTermId) internal view
        returns (
            ERC20 feeToken,
            uint256[3] memory fees,
            uint64[5] memory roundStateDurations,
            uint16[2] memory pcts,
            uint64[4] memory roundParams,
            uint256[2] memory appealCollateralParams,
            uint256 minActiveBalance
        )
    {
        Config storage config = _getConfigFor(_termId, _lastEnsuredTermId);

        FeesConfig storage feesConfig = config.fees;
        feeToken = feesConfig.token;
        fees = [feesConfig.jurorFee, feesConfig.draftFee, feesConfig.settleFee];

        DisputesConfig storage disputesConfig = config.disputes;
        roundStateDurations = [
            disputesConfig.evidenceTerms,
            disputesConfig.commitTerms,
            disputesConfig.revealTerms,
            disputesConfig.appealTerms,
            disputesConfig.appealConfirmTerms
        ];
        pcts = [disputesConfig.penaltyPct, feesConfig.finalRoundReduction];
        roundParams = [
            disputesConfig.firstRoundJurorsNumber,
            disputesConfig.appealStepFactor,
            uint64(disputesConfig.maxRegularAppealRounds),
            disputesConfig.finalRoundLockTerms
        ];
        appealCollateralParams = [disputesConfig.appealCollateralFactor, disputesConfig.appealConfirmCollateralFactor];

        minActiveBalance = config.minActiveBalance;
    }

    /**
    * @dev Tell the draft config at a certain term
    * @param _termId Identification number of the term querying the draft config of
    * @param _lastEnsuredTermId Identification number of the last ensured term of the Court
    * @return feeToken Address of the token used to pay for fees
    * @return draftFee Amount of fee tokens per juror to cover the drafting cost
    * @return penaltyPct Permyriad of min active tokens balance to be locked for each drafted juror (‱ - 1/10,000)
    */
    function _getDraftConfig(uint64 _termId,  uint64 _lastEnsuredTermId) internal view
        returns (ERC20 feeToken, uint256 draftFee, uint16 penaltyPct)
    {
        Config storage config = _getConfigFor(_termId, _lastEnsuredTermId);
        return (config.fees.token, config.fees.draftFee, config.disputes.penaltyPct);
    }

    /**
    * @dev Internal function to get the min active balance config for a given term
    * @param _termId Identification number of the term querying the min active balance config of
    * @param _lastEnsuredTermId Identification number of the last ensured term of the Court
    * @return Minimum amount of juror tokens that can be activated at the given term
    */
    function _getMinActiveBalance(uint64 _termId, uint64 _lastEnsuredTermId) internal view returns (uint256) {
        Config storage config = _getConfigFor(_termId, _lastEnsuredTermId);
        return config.minActiveBalance;
    }

    /**
    * @dev Internal function to get the Court config for a given term
    * @param _termId Identification number of the term querying the min active balance config of
    * @param _lastEnsuredTermId Identification number of the last ensured term of the Court
    * @return Court config for the given term
    */
    function _getConfigFor(uint64 _termId, uint64 _lastEnsuredTermId) internal view returns (Config storage) {
        uint256 id = _getConfigIdFor(_termId, _lastEnsuredTermId);
        return configs[id];
    }

    /**
    * @dev Internal function to get the Court config ID for a given term
    * @param _termId Identification number of the term querying the Court config of
    * @param _lastEnsuredTermId Identification number of the last ensured term of the Court
    * @return Identification number of the config for the given terms
    */
    function _getConfigIdFor(uint64 _termId, uint64 _lastEnsuredTermId) internal view returns (uint256) {
        // If the given term is lower or equal to the last ensured Court term, it is safe to use a past Court config
        if (_termId <= _lastEnsuredTermId) {
            return configIdByTerm[_termId];
        }

        // If the given term is in the future but there is a config change scheduled before it, use the incoming config
        uint64 scheduledChangeTermId = configChangeTermId;
        if (scheduledChangeTermId <= _termId) {
            return configIdByTerm[scheduledChangeTermId];
        }

        // If no changes are scheduled, use the Court config of the last ensured term
        return configIdByTerm[_lastEnsuredTermId];
    }
}

// File: @aragon/court/contracts/court/controller/Controller.sol

pragma solidity ^0.5.8;





contract Controller is IsContract, CourtClock, CourtConfig {
    string private constant ERROR_SENDER_NOT_GOVERNOR = "CTR_SENDER_NOT_GOVERNOR";
    string private constant ERROR_INVALID_GOVERNOR_ADDRESS = "CTR_INVALID_GOVERNOR_ADDRESS";
    string private constant ERROR_IMPLEMENTATION_NOT_CONTRACT = "CTR_IMPLEMENTATION_NOT_CONTRACT";
    string private constant ERROR_INVALID_IMPLS_INPUT_LENGTH = "CTR_INVALID_IMPLS_INPUT_LENGTH";

    address private constant ZERO_ADDRESS = address(0);

    // DisputeManager module ID - keccak256(abi.encodePacked("DISPUTE_MANAGER"))
    bytes32 internal constant DISPUTE_MANAGER = 0x14a6c70f0f6d449c014c7bbc9e68e31e79e8474fb03b7194df83109a2d888ae6;

    // Treasury module ID - keccak256(abi.encodePacked("TREASURY"))
    bytes32 internal constant TREASURY = 0x06aa03964db1f7257357ef09714a5f0ca3633723df419e97015e0c7a3e83edb7;

    // Voting module ID - keccak256(abi.encodePacked("VOTING"))
    bytes32 internal constant VOTING = 0x7cbb12e82a6d63ff16fe43977f43e3e2b247ecd4e62c0e340da8800a48c67346;

    // JurorsRegistry module ID - keccak256(abi.encodePacked("JURORS_REGISTRY"))
    bytes32 internal constant JURORS_REGISTRY = 0x3b21d36b36308c830e6c4053fb40a3b6d79dde78947fbf6b0accd30720ab5370;

    // Subscriptions module ID - keccak256(abi.encodePacked("SUBSCRIPTIONS"))
    bytes32 internal constant SUBSCRIPTIONS = 0x2bfa3327fe52344390da94c32a346eeb1b65a8b583e4335a419b9471e88c1365;

    /**
    * @dev Governor of the whole system. Set of three addresses to recover funds, change configuration settings and setup modules
    */
    struct Governor {
        address funds;      // This address can be unset at any time. It is allowed to recover funds from the ControlledRecoverable modules
        address config;     // This address is meant not to be unset. It is allowed to change the different configurations of the whole system
        address modules;    // This address can be unset at any time. It is allowed to plug/unplug modules from the system
    }

    // Governor addresses of the system
    Governor private governor;

    // List of modules registered for the system indexed by ID
    mapping (bytes32 => address) internal modules;

    event ModuleSet(bytes32 id, address addr);
    event FundsGovernorChanged(address previousGovernor, address currentGovernor);
    event ConfigGovernorChanged(address previousGovernor, address currentGovernor);
    event ModulesGovernorChanged(address previousGovernor, address currentGovernor);

    /**
    * @dev Ensure the msg.sender is the funds governor
    */
    modifier onlyFundsGovernor {
        require(msg.sender == governor.funds, ERROR_SENDER_NOT_GOVERNOR);
        _;
    }

    /**
    * @dev Ensure the msg.sender is the modules governor
    */
    modifier onlyConfigGovernor {
        require(msg.sender == governor.config, ERROR_SENDER_NOT_GOVERNOR);
        _;
    }

    /**
    * @dev Ensure the msg.sender is the modules governor
    */
    modifier onlyModulesGovernor {
        require(msg.sender == governor.modules, ERROR_SENDER_NOT_GOVERNOR);
        _;
    }

    /**
    * @dev Constructor function
    * @param _termParams Array containing:
    *        0. _termDuration Duration in seconds per term
    *        1. _firstTermStartTime Timestamp in seconds when the court will open (to give time for juror on-boarding)
    * @param _governors Array containing:
    *        0. _fundsGovernor Address of the funds governor
    *        1. _configGovernor Address of the config governor
    *        2. _modulesGovernor Address of the modules governor
    * @param _feeToken Address of the token contract that is used to pay for fees
    * @param _fees Array containing:
    *        0. jurorFee Amount of fee tokens that is paid per juror per dispute
    *        1. draftFee Amount of fee tokens per juror to cover the drafting cost
    *        2. settleFee Amount of fee tokens per juror to cover round settlement cost
    * @param _roundStateDurations Array containing the durations in terms of the different phases of a dispute:
    *        0. evidenceTerms Max submitting evidence period duration in terms
    *        1. commitTerms Commit period duration in terms
    *        2. revealTerms Reveal period duration in terms
    *        3. appealTerms Appeal period duration in terms
    *        4. appealConfirmationTerms Appeal confirmation period duration in terms
    * @param _pcts Array containing:
    *        0. penaltyPct Permyriad of min active tokens balance to be locked to each drafted jurors (‱ - 1/10,000)
    *        1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @param _roundParams Array containing params for rounds:
    *        0. firstRoundJurorsNumber Number of jurors to be drafted for the first round of disputes
    *        1. appealStepFactor Increasing factor for the number of jurors of each round of a dispute
    *        2. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    *        3. finalRoundLockTerms Number of terms that a coherent juror in a final round is disallowed to withdraw (to prevent 51% attacks)
    * @param _appealCollateralParams Array containing params for appeal collateral:
    *        1. appealCollateralFactor Permyriad multiple of dispute fees required to appeal a preliminary ruling
    *        2. appealConfirmCollateralFactor Permyriad multiple of dispute fees required to confirm appeal
    * @param _minActiveBalance Minimum amount of juror tokens that can be activated
    */
    constructor(
        uint64[2] memory _termParams,
        address[3] memory _governors,
        ERC20 _feeToken,
        uint256[3] memory _fees,
        uint64[5] memory _roundStateDurations,
        uint16[2] memory _pcts,
        uint64[4] memory _roundParams,
        uint256[2] memory _appealCollateralParams,
        uint256 _minActiveBalance
    )
        public
        CourtClock(_termParams)
        CourtConfig(_feeToken, _fees, _roundStateDurations, _pcts, _roundParams, _appealCollateralParams, _minActiveBalance)
    {
        _setFundsGovernor(_governors[0]);
        _setConfigGovernor(_governors[1]);
        _setModulesGovernor(_governors[2]);
    }

    /**
    * @notice Change Court configuration params
    * @param _fromTermId Identification number of the term in which the config will be effective at
    * @param _feeToken Address of the token contract that is used to pay for fees
    * @param _fees Array containing:
    *        0. jurorFee Amount of fee tokens that is paid per juror per dispute
    *        1. draftFee Amount of fee tokens per juror to cover the drafting cost
    *        2. settleFee Amount of fee tokens per juror to cover round settlement cost
    * @param _roundStateDurations Array containing the durations in terms of the different phases of a dispute:
    *        0. evidenceTerms Max submitting evidence period duration in terms
    *        1. commitTerms Commit period duration in terms
    *        2. revealTerms Reveal period duration in terms
    *        3. appealTerms Appeal period duration in terms
    *        4. appealConfirmationTerms Appeal confirmation period duration in terms
    * @param _pcts Array containing:
    *        0. penaltyPct Permyriad of min active tokens balance to be locked to each drafted jurors (‱ - 1/10,000)
    *        1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @param _roundParams Array containing params for rounds:
    *        0. firstRoundJurorsNumber Number of jurors to be drafted for the first round of disputes
    *        1. appealStepFactor Increasing factor for the number of jurors of each round of a dispute
    *        2. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    *        3. finalRoundLockTerms Number of terms that a coherent juror in a final round is disallowed to withdraw (to prevent 51% attacks)
    * @param _appealCollateralParams Array containing params for appeal collateral:
    *        1. appealCollateralFactor Permyriad multiple of dispute fees required to appeal a preliminary ruling
    *        2. appealConfirmCollateralFactor Permyriad multiple of dispute fees required to confirm appeal
    * @param _minActiveBalance Minimum amount of juror tokens that can be activated
    */
    function setConfig(
        uint64 _fromTermId,
        ERC20 _feeToken,
        uint256[3] calldata _fees,
        uint64[5] calldata _roundStateDurations,
        uint16[2] calldata _pcts,
        uint64[4] calldata _roundParams,
        uint256[2] calldata _appealCollateralParams,
        uint256 _minActiveBalance
    )
        external
        onlyConfigGovernor
    {
        uint64 currentTermId = _ensureCurrentTerm();
        _setConfig(
            currentTermId,
            _fromTermId,
            _feeToken,
            _fees,
            _roundStateDurations,
            _pcts,
            _roundParams,
            _appealCollateralParams,
            _minActiveBalance
        );
    }

    /**
    * @notice Delay the Court start time to `_newFirstTermStartTime`
    * @param _newFirstTermStartTime New timestamp in seconds when the court will open
    */
    function delayStartTime(uint64 _newFirstTermStartTime) external onlyConfigGovernor {
        _delayStartTime(_newFirstTermStartTime);
    }

    /**
    * @notice Change funds governor address to `_newFundsGovernor`
    * @param _newFundsGovernor Address of the new funds governor to be set
    */
    function changeFundsGovernor(address _newFundsGovernor) external onlyFundsGovernor {
        require(_newFundsGovernor != ZERO_ADDRESS, ERROR_INVALID_GOVERNOR_ADDRESS);
        _setFundsGovernor(_newFundsGovernor);
    }

    /**
    * @notice Change config governor address to `_newConfigGovernor`
    * @param _newConfigGovernor Address of the new config governor to be set
    */
    function changeConfigGovernor(address _newConfigGovernor) external onlyConfigGovernor {
        require(_newConfigGovernor != ZERO_ADDRESS, ERROR_INVALID_GOVERNOR_ADDRESS);
        _setConfigGovernor(_newConfigGovernor);
    }

    /**
    * @notice Change modules governor address to `_newModulesGovernor`
    * @param _newModulesGovernor Address of the new governor to be set
    */
    function changeModulesGovernor(address _newModulesGovernor) external onlyModulesGovernor {
        require(_newModulesGovernor != ZERO_ADDRESS, ERROR_INVALID_GOVERNOR_ADDRESS);
        _setModulesGovernor(_newModulesGovernor);
    }

    /**
    * @notice Remove the funds governor. Set the funds governor to the zero address.
    * @dev This action cannot be rolled back, once the funds governor has been unset, funds cannot be recovered from recoverable modules anymore
    */
    function ejectFundsGovernor() external onlyFundsGovernor {
        _setFundsGovernor(ZERO_ADDRESS);
    }

    /**
    * @notice Remove the modules governor. Set the modules governor to the zero address.
    * @dev This action cannot be rolled back, once the modules governor has been unset, system modules cannot be changed anymore
    */
    function ejectModulesGovernor() external onlyModulesGovernor {
        _setModulesGovernor(ZERO_ADDRESS);
    }

    /**
    * @notice Set module `_id` to `_addr`
    * @param _id ID of the module to be set
    * @param _addr Address of the module to be set
    */
    function setModule(bytes32 _id, address _addr) external onlyModulesGovernor {
        _setModule(_id, _addr);
    }

    /**
    * @notice Set many modules at once
    * @param _ids List of ids of each module to be set
    * @param _addresses List of addressed of each the module to be set
    */
    function setModules(bytes32[] calldata _ids, address[] calldata _addresses) external onlyModulesGovernor {
        require(_ids.length == _addresses.length, ERROR_INVALID_IMPLS_INPUT_LENGTH);

        for (uint256 i = 0; i < _ids.length; i++) {
            _setModule(_ids[i], _addresses[i]);
        }
    }

    /**
    * @dev Tell the full Court configuration parameters at a certain term
    * @param _termId Identification number of the term querying the Court config of
    * @return token Address of the token used to pay for fees
    * @return fees Array containing:
    *         0. jurorFee Amount of fee tokens that is paid per juror per dispute
    *         1. draftFee Amount of fee tokens per juror to cover the drafting cost
    *         2. settleFee Amount of fee tokens per juror to cover round settlement cost
    * @return roundStateDurations Array containing the durations in terms of the different phases of a dispute:
    *         0. evidenceTerms Max submitting evidence period duration in terms
    *         1. commitTerms Commit period duration in terms
    *         2. revealTerms Reveal period duration in terms
    *         3. appealTerms Appeal period duration in terms
    *         4. appealConfirmationTerms Appeal confirmation period duration in terms
    * @return pcts Array containing:
    *         0. penaltyPct Permyriad of min active tokens balance to be locked for each drafted juror (‱ - 1/10,000)
    *         1. finalRoundReduction Permyriad of fee reduction for the last appeal round (‱ - 1/10,000)
    * @return roundParams Array containing params for rounds:
    *         0. firstRoundJurorsNumber Number of jurors to be drafted for the first round of disputes
    *         1. appealStepFactor Increasing factor for the number of jurors of each round of a dispute
    *         2. maxRegularAppealRounds Number of regular appeal rounds before the final round is triggered
    *         3. finalRoundLockTerms Number of terms that a coherent juror in a final round is disallowed to withdraw (to prevent 51% attacks)
    * @return appealCollateralParams Array containing params for appeal collateral:
    *         0. appealCollateralFactor Multiple of dispute fees required to appeal a preliminary ruling
    *         1. appealConfirmCollateralFactor Multiple of dispute fees required to confirm appeal
    */
    function getConfig(uint64 _termId) external view
        returns (
            ERC20 feeToken,
            uint256[3] memory fees,
            uint64[5] memory roundStateDurations,
            uint16[2] memory pcts,
            uint64[4] memory roundParams,
            uint256[2] memory appealCollateralParams,
            uint256 minActiveBalance
        )
    {
        uint64 lastEnsuredTermId = _lastEnsuredTermId();
        return _getConfigAt(_termId, lastEnsuredTermId);
    }

    /**
    * @dev Tell the draft config at a certain term
    * @param _termId Identification number of the term querying the draft config of
    * @return feeToken Address of the token used to pay for fees
    * @return draftFee Amount of fee tokens per juror to cover the drafting cost
    * @return penaltyPct Permyriad of min active tokens balance to be locked for each drafted juror (‱ - 1/10,000)
    */
    function getDraftConfig(uint64 _termId) external view returns (ERC20 feeToken, uint256 draftFee, uint16 penaltyPct) {
        uint64 lastEnsuredTermId = _lastEnsuredTermId();
        return _getDraftConfig(_termId, lastEnsuredTermId);
    }

    /**
    * @dev Tell the min active balance config at a certain term
    * @param _termId Identification number of the term querying the min active balance config of
    * @return Minimum amount of tokens jurors have to activate to participate in the Court
    */
    function getMinActiveBalance(uint64 _termId) external view returns (uint256) {
        uint64 lastEnsuredTermId = _lastEnsuredTermId();
        return _getMinActiveBalance(_termId, lastEnsuredTermId);
    }

    /**
    * @dev Tell the address of the funds governor
    * @return Address of the funds governor
    */
    function getFundsGovernor() external view returns (address) {
        return governor.funds;
    }

    /**
    * @dev Tell the address of the config governor
    * @return Address of the config governor
    */
    function getConfigGovernor() external view returns (address) {
        return governor.config;
    }

    /**
    * @dev Tell the address of the modules governor
    * @return Address of the modules governor
    */
    function getModulesGovernor() external view returns (address) {
        return governor.modules;
    }

    /**
    * @dev Tell address of a module based on a given ID
    * @param _id ID of the module being queried
    * @return Address of the requested module
    */
    function getModule(bytes32 _id) external view returns (address) {
        return _getModule(_id);
    }

    /**
    * @dev Tell the address of the DisputeManager module
    * @return Address of the DisputeManager module
    */
    function getDisputeManager() external view returns (address) {
        return _getDisputeManager();
    }

    /**
    * @dev Tell the address of the Treasury module
    * @return Address of the Treasury module
    */
    function getTreasury() external view returns (address) {
        return _getModule(TREASURY);
    }

    /**
    * @dev Tell the address of the Voting module
    * @return Address of the Voting module
    */
    function getVoting() external view returns (address) {
        return _getModule(VOTING);
    }

    /**
    * @dev Tell the address of the JurorsRegistry module
    * @return Address of the JurorsRegistry module
    */
    function getJurorsRegistry() external view returns (address) {
        return _getModule(JURORS_REGISTRY);
    }

    /**
    * @dev Tell the address of the Subscriptions module
    * @return Address of the Subscriptions module
    */
    function getSubscriptions() external view returns (address) {
        return _getSubscriptions();
    }

    /**
    * @dev Internal function to set the address of the funds governor
    * @param _newFundsGovernor Address of the new config governor to be set
    */
    function _setFundsGovernor(address _newFundsGovernor) internal {
        emit FundsGovernorChanged(governor.funds, _newFundsGovernor);
        governor.funds = _newFundsGovernor;
    }

    /**
    * @dev Internal function to set the address of the config governor
    * @param _newConfigGovernor Address of the new config governor to be set
    */
    function _setConfigGovernor(address _newConfigGovernor) internal {
        emit ConfigGovernorChanged(governor.config, _newConfigGovernor);
        governor.config = _newConfigGovernor;
    }

    /**
    * @dev Internal function to set the address of the modules governor
    * @param _newModulesGovernor Address of the new modules governor to be set
    */
    function _setModulesGovernor(address _newModulesGovernor) internal {
        emit ModulesGovernorChanged(governor.modules, _newModulesGovernor);
        governor.modules = _newModulesGovernor;
    }

    /**
    * @dev Internal function to set a module
    * @param _id Id of the module to be set
    * @param _addr Address of the module to be set
    */
    function _setModule(bytes32 _id, address _addr) internal {
        require(isContract(_addr), ERROR_IMPLEMENTATION_NOT_CONTRACT);
        modules[_id] = _addr;
        emit ModuleSet(_id, _addr);
    }

    /**
    * @dev Internal function to notify when a term has been transitioned
    * @param _termId Identification number of the new current term that has been transitioned
    */
    function _onTermTransitioned(uint64 _termId) internal {
        _ensureTermConfig(_termId);
    }

    /**
    * @dev Internal function to tell the address of the DisputeManager module
    * @return Address of the DisputeManager module
    */
    function _getDisputeManager() internal view returns (address) {
        return _getModule(DISPUTE_MANAGER);
    }

    /**
    * @dev Internal function to tell the address of the Subscriptions module
    * @return Address of the Subscriptions module
    */
    function _getSubscriptions() internal view returns (address) {
        return _getModule(SUBSCRIPTIONS);
    }

    /**
    * @dev Internal function to tell address of a module based on a given ID
    * @param _id ID of the module being queried
    * @return Address of the requested module
    */
    function _getModule(bytes32 _id) internal view returns (address) {
        return modules[_id];
    }
}

// File: @aragon/court/contracts/lib/os/SafeERC20.sol

// Brought from https://github.com/aragon/aragonOS/blob/v4.3.0/contracts/common/SafeERC20.sol
// Adapted to use pragma ^0.5.8 and satisfy our linter rules

pragma solidity ^0.5.8;



library SafeERC20 {
    // Before 0.5, solidity has a mismatch between `address.transfer()` and `token.transfer()`:
    // https://github.com/ethereum/solidity/issues/3544
    bytes4 private constant TRANSFER_SELECTOR = 0xa9059cbb;

    /**
    * @dev Same as a standards-compliant ERC20.transfer() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeTransfer(ERC20 _token, address _to, uint256 _amount) internal returns (bool) {
        bytes memory transferCallData = abi.encodeWithSelector(
            TRANSFER_SELECTOR,
            _to,
            _amount
        );
        return invokeAndCheckSuccess(address(_token), transferCallData);
    }

    /**
    * @dev Same as a standards-compliant ERC20.transferFrom() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeTransferFrom(ERC20 _token, address _from, address _to, uint256 _amount) internal returns (bool) {
        bytes memory transferFromCallData = abi.encodeWithSelector(
            _token.transferFrom.selector,
            _from,
            _to,
            _amount
        );
        return invokeAndCheckSuccess(address(_token), transferFromCallData);
    }

    /**
    * @dev Same as a standards-compliant ERC20.approve() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeApprove(ERC20 _token, address _spender, uint256 _amount) internal returns (bool) {
        bytes memory approveCallData = abi.encodeWithSelector(
            _token.approve.selector,
            _spender,
            _amount
        );
        return invokeAndCheckSuccess(address(_token), approveCallData);
    }

    function invokeAndCheckSuccess(address _addr, bytes memory _calldata) private returns (bool) {
        bool ret;
        assembly {
            let ptr := mload(0x40)    // free memory pointer

            let success := call(
                gas,                  // forward all gas
                _addr,                // address
                0,                    // no value
                add(_calldata, 0x20), // calldata start
                mload(_calldata),     // calldata length
                ptr,                  // write output over free memory
                0x20                  // uint256 return
            )

            if gt(success, 0) {
            // Check number of bytes returned from last function call
                switch returndatasize

                // No bytes returned: assume success
                case 0 {
                    ret := 1
                }

                // 32 bytes returned: check if non-zero
                case 0x20 {
                // Only return success if returned data was true
                // Already have output in ptr
                    ret := eq(mload(ptr), 1)
                }

                // Not sure what was returned: don't mark as success
                default { }
            }
        }
        return ret;
    }
}

// File: contracts/PrecedenceCampaignArbitrable.sol

pragma solidity ^0.5.8;








contract PrecedenceCampaignArbitrable is IArbitrable {
    using SafeERC20 for ERC20;

    string public constant ERROR_SENDER_NOT_ALLOWED = "PCA_SENDER_NOT_ALLOWED";
    string public constant ERROR_RECOVER_FUNDS_FAILED = "PCA_RECOVER_FUNDS_FAILED";

    address public owner;
    IArbitrator public arbitrator;

    modifier only(address _who) {
        require(msg.sender == _who, ERROR_SENDER_NOT_ALLOWED);
        _;
    }

    constructor (address _owner, IArbitrator _arbitrator) public {
        owner = _owner;
        arbitrator = _arbitrator;
    }

    function createDispute(uint256 _possibleRulings, bytes calldata _metadata) external only(owner) returns (uint256) {
        return _createDispute(_possibleRulings, _metadata);
    }

    function submitEvidence(uint256 _disputeId, bytes calldata _evidence, bool _finished) external only(owner) {
        _submitEvidence(_disputeId, msg.sender, _evidence, _finished);
    }

    function submitEvidenceFor(uint256 _disputeId, address _submitter, bytes calldata _evidence, bool _finished) external only(owner) {
        _submitEvidence(_disputeId, _submitter, _evidence, _finished);
    }

    function createAndSubmit(
        uint256 _possibleRulings,
        bytes calldata _metadata,
        address _submitter1,
        address _submitter2,
        bytes calldata _evidence1,
        bytes calldata _evidence2
    )
        external
        only(owner)
        returns (uint256)
    {
        uint256 disputeId = _createDispute(_possibleRulings, _metadata);
        _submitEvidence(disputeId, _submitter1, _evidence1, false);
        _submitEvidence(disputeId, _submitter2, _evidence2, false);

        return disputeId;
    }

    function closeEvidencePeriod(uint256 _disputeId) external only(owner) {
        arbitrator.closeEvidencePeriod(_disputeId);
    }

    function rule(uint256 _disputeId, uint256 _ruling) external only(address(arbitrator)) {
        emit Ruled(IArbitrator(msg.sender), _disputeId, _ruling);
    }

    function setOwner(address _owner) external only(owner) {
        owner = _owner;
    }

    function withdraw(ERC20 _token, address _to, uint256 _amount) external only(owner) {
        ITreasury treasury = ITreasury(Controller(address(arbitrator)).getTreasury());
        treasury.withdraw(_token, _to, _amount);
    }

    function recoverFunds(address _token, address payable _to, uint256 _amount) external only(owner) {
        require(ERC20(_token).safeTransfer(_to, _amount), ERROR_RECOVER_FUNDS_FAILED);
    }

    function _createDispute(uint256 _possibleRulings, bytes memory _metadata) internal returns (uint256) {
        (address recipient, ERC20 feeToken, uint256 disputeFees) = arbitrator.getDisputeFees();
        feeToken.approve(recipient, disputeFees);
        return arbitrator.createDispute(_possibleRulings, _metadata);
    }

    function _submitEvidence(uint256 _disputeId, address _submitter, bytes memory _evidence, bool _finished) internal {
        emit EvidenceSubmitted(_disputeId, _submitter, _evidence, _finished);
        if (_finished) {
            arbitrator.closeEvidencePeriod(_disputeId);
        }
    }
}
