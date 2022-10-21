pragma solidity 0.5.3;

import "./SafeUtils.sol";
import "./EvidenceProducer.sol";

/**
    @notice
    AgreementManager allows two parties (A and B) to represent some sort of agreement that
    involves staking ETH. The general flow is: they both deposit a stake (they can withdraw until
    both stakes have been deposited), then their agreement is either fulfilled or not based on
    actions outside of this contract, then either party can "resolve" by specifying how they think
    funds should be split based on each party's actions in relation to the agreement terms.
    Funds are automatically dispersed once there's a resolution. If the parties disagree, they can
    summon a predefined arbitrator to settle their dispute.

    @dev
    There are several types of AgreementManager which inherit from this contract. The inheritance
    tree looks like:
    AgreementManager
        AgreementManagerETH
            AgreementManagerETH_Simple
            AgreementManagerETH_ERC792
        AgreementManagerERC20
            AgreementManagerERC20_Simple
            AgreementManagerERC792_Simple

    Essentially there are two options:
    (1) Does the agreement use exclusively ETH, or also at least one ERC20 Token?
    (2) Does the agreement use simple arbitration (an agreed upon external address), or ERC792
        (Kleros) arbitration?
    There are four contracts, one for each combination of options, although much of their code is
    shared. AgreementManagerERC20 can handle purely ETH agreements, but it's cheaper to use
    AgreementManagerETH.

    To avoid comment duplication, comments have been pushed as high in the inheritance tree as
    possible. Several functions are declared for the first time in AgreementManagerETH and
    AgreementManagerERC20 rather than in AgreementManager, because they take slightly different
    arguments.

    **** NOTES ON REENTRANCY ****

    For ease of review, functions that call untrusted external functions (even via multiple calls)
    and which have these external calls wrapped in a reentrancy guard will have
    "_Untrusted_Guarded" appended to the function name. Untrusted functions which don't have their
    external calls wrapped in a reentrancy guard will have _Untrusted_Unguarded appended to their
    name. One function has "_Sometimes_Untrusted_Guarded" appended to its name, as it's
    _Untrusted_Guarded untrusted in some inheriting functions. This naming convention does not
    apply to public and external functions.

    An external function call is safe if (a) nothing after the function call depends on any
    contract state that can change after the call is made, and (b) no contract state will be
    changed after the external call. When those two conditions don't obviously hold we use a
    reentrancy guard. When those two conditions do hold we safely ignore reentrancy protection.
    We'll refer to calls that clearly meet both conditions as being "Reentrancy Safe" in other
    comments.

    You can prove to yourself that our code is reentrancy safe by verifying these things:
    (1) Every function whose name ends with "_Untrusted_Guarded" has a reentrancy guard wrapped
    around any external calls that it contains.
    (2) Every function call whose name ends with "_Untrusted_Unguarded" is either Reentrancy Safe
    as described above, or it's wrapped in a reentrancy guard.
    (3) The body of every function whose name ends with "_Untrusted_Unguarded" contains only
    Reentrancy Safe calls.
    (4) Every external function in our contracts that modifies the state of a pre-existing
    agreement is protected by a reentrancy check.

    Note that a reentrancy guard looks like "getThenSetPendingExternalCall(agreement, true)"
    before the code that it's guarding, and "setPendingExternalCall(agreement, previousValue)"
    after the code that it's guarding. A reentrancy check looks like:
    'require(!pendingExternalCall(agreement), "Reentrancy protection is on");'
*/

contract AgreementManager is SafeUtils, EvidenceProducer {
    // -------------------------------------------------------------------------------------------
    // --------------------------------- special values ------------------------------------------
    // -------------------------------------------------------------------------------------------

    // When the parties to an agreement report the outcome, they enter a "resolution", which is
    // the amount of wei that party A should get. Party B is understood to get the remaining wei.
    // RESOLUTION_NULL is a special value indicating "no resolution has been entered yet".
    uint48 constant RESOLUTION_NULL = ~(uint48(0)); // set all bits to one.

    uint constant MAX_DAYS_TO_RESPOND_TO_ARBITRATION_REQUEST = 365*30; // Approximately 30 years

    // "party A" and "party B" are the two parties to the agreement
    enum Party { A, B }

    // ---------------------------------
    // Offsets for AgreementData.boolValues
    // --------------------------------
    // We pack all of our bool values into a uint32 for gas cost optimization. Each constant below
    // represents a "virtual" boolean variable.
    // These are the offets into that uint32 (AgreementData.boolValues)

    uint constant PARTY_A_STAKE_PAID = 0; // Has party A fully paid their stake?
    uint constant PARTY_B_STAKE_PAID = 1; // Has party B fully paid their stake?
    uint constant PARTY_A_REQUESTED_ARBITRATION = 2; // Has party A requested arbitration?
    uint constant PARTY_B_REQUESTED_ARBITRATION = 3; // Has party B requested arbitration?
    // The "RECEIVED_DISTRIBUTION" values represent whether we've either sent an
    // automatic funds distribution to the party, or they've explicitly withdrawn.
    // There's a non-intuitive edge case: these variables can be true even if the distribution
    // amount is zero, as long as we went through the process that would have resulted in a
    // positive distribution if there was one.
    uint constant PARTY_A_RECEIVED_DISTRIBUTION = 4;
    uint constant PARTY_B_RECEIVED_DISTRIBUTION = 5;
    /** PARTY_A_RESOLVED_LAST is used to detect certain bad behavior where a party will first
    resolve to a "bad" value, wait for their counterparty to summon an arbitrator, and then
    resolve to the correct value to avoid having the arbitator rule against them. At any point
    where the arbitrator has been paid before the dishonest party switches to a reasonable ruling,
    we want the person who switched to the eventually official ruling last to be the one to pay
    the arbitration fee.*/
    uint constant PARTY_A_RESOLVED_LAST = 6;
    uint constant ARBITRATOR_RESOLVED = 7; // Did the arbitrator enter a resolution?
    uint constant ARBITRATOR_RECEIVED_DISPUTE_FEE = 8; // Did arbitrator receive the dispute fee?
    // The DISPUTE_FEE_LIABILITY are used to keep track if which party is responsible for paying
    // the arbitrator's dispute fee. If both are true then each party is responsible for half.
    uint constant PARTY_A_DISPUTE_FEE_LIABILITY = 9;
    uint constant PARTY_B_DISPUTE_FEE_LIABILITY = 10;
    // We use this flag internally to guard against reentrancy attacks.
    uint constant PENDING_EXTERNAL_CALL = 11;

    // -------------------------------------------------------------------------------------------
    // ------------------------------------- events ----------------------------------------------
    // -------------------------------------------------------------------------------------------

    // Some events specific to inheriting contracts are only defined in those contracts, so this
    // is not a full list of events that the instantiated contracts will output.

    /// @notice links the agreementID to the hash of the agreement, so the written agreement terms
    /// can be associated with this Ethereum contract.
    event AgreementCreated(uint32 indexed agreementID, bytes32 agreementHash);

    event PartyBDeposited(uint32 indexed agreementID);
    event PartyAWithdrewEarly(uint32 indexed agreementID);
    event PartyWithdrew(uint32 indexed agreementID);
    event FundsDistributed(uint32 indexed agreementID);
    event ArbitratorReceivedDisputeFee(uint32 indexed agreementID);
    event ArbitrationRequested(uint32 indexed agreementID);
    event DefaultJudgment(uint32 indexed agreementID);
    event AutomaticResolution(uint32 indexed agreementID);

    // -------------------------------------------------------------------------------------------
    // --------------------------- public / external functions -----------------------------------
    // -------------------------------------------------------------------------------------------

    /// @notice A fallback function that prevents anyone from sending ETH directly to this
    /// and inheriting contracts, since it isn't payable.
    function () external {}

    // -------------------------------------------------------------------------------------------
    // ----------------------- internal getter and setter functions ------------------------------
    // -------------------------------------------------------------------------------------------

    /// @param flagField bitfield containing a bunch of virtual bool values
    /// @param offset index into flagField of the bool we want to know the value of
    /// @return value of the bool specified by offset
    function getBool(uint flagField, uint offset) internal pure returns (bool) {
        return ((flagField >> offset) & 1) == 1;
    }

    /// @param flagField bitfield containing a bunch of virtual bool values
    /// @param offset index into flagField of the bool we want to set the value of
    /// @param value value to set the bit specified by offset to
    /// @return the new value of flagField containing the modified bool value
    function setBool(uint32 flagField, uint offset, bool value) internal pure returns (uint32) {
        if (value) {
            return flagField | uint32(1 << offset);
        } else {
            return flagField & ~(uint32(1 << offset));
        }
    }

    // -------------------------------------------------------------------------------------------
    // -------------------------- internal helper functions --------------------------------------
    // -------------------------------------------------------------------------------------------

    /// @notice Emit some events upon every contract creation
    /// @param agreementHash hash of the text of the agreement
    /// @param agreementURI URL of JSON representing the agreement
    function emitAgreementCreationEvents(
        uint agreementID,
        bytes32 agreementHash,
        string memory agreementURI
    )
        internal
    {
        // We want to emit both of these because we want to emit the agreement hash, and we also
        // want to adhere to ERC1497
        emit MetaEvidence(agreementID, agreementURI);
        emit AgreementCreated(uint32(agreementID), agreementHash);
    }
}

