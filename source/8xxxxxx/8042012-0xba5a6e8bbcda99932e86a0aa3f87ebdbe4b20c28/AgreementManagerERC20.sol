pragma solidity 0.5.3;

import "./AgreementManager.sol";
import "./ERC20Interface.sol";


/**
    @notice
    See AgreementManager for comments on the overall nature of this contract.

    This is the contract defining how ERC20 agreements work (in contrast to ETH-only).

    @dev
    The relevant part of the inheritance tree is:
    AgreementManager
        AgreementManagerERC20
            AgreementManagerERC20_Simple
            AgreementManagerERC20_ERC792

    Search that file for "NOTES ON REENTRANCY" to learn more about our reentrancy protection
    strategy.
*/

contract AgreementManagerERC20 is AgreementManager {
    // -------------------------------------------------------------------------------------------
    // --------------------------------- special values ------------------------------------------
    // -------------------------------------------------------------------------------------------

    /**
    We store ETH/token amounts internally uint48s. The amount that we store internally is
    multipled by 10^TOKENPOWER, where TOKENPOWER is passed into the contract for each ERC20 token
    that the contract needs to represent. The constant MAX_TOKEN_POWER is used to check that these
    passed in values aren't too big. A token power of 50 can represent
    2^48 * 10^50 ~= 2.8 * 10^64 (since 2^48 ~= 2.8 * 10^14) of a token's equivalent of wei.
    There are 10^18 wei in an ETH, so if the token were ETH this could represent about
    10^46 ETH. Note that 2^256 is about 10^77, so we're unable to represent extremely high
    amounts of tokens with this scheme, but in practice we don't expect this to be an issue.
    Using MAX_TOKEN_POWER keeps our exponentiation from overflowing, since even
    if we add a bunch of 48 bit resolutions together before multiplying by 10^50 the result will
    be far less than 10^77.*/
    uint constant MAX_TOKEN_POWER = 50;

    // -------------------------------------------------------------------------------------------
    // ------------------------------------- events ----------------------------------------------
    // -------------------------------------------------------------------------------------------

    event PartyResolved(
        uint32 indexed agreementID,
        uint resolutionTokenA,
        uint resolutionTokenB
    );

    // -------------------------------------------------------------------------------------------
    // -------------------------------- struct definitions ---------------------------------------
    // -------------------------------------------------------------------------------------------

    /**
    Whenever an agreement is created, we store its state in an AgreementDataERC20 object.
    One of the main differences between this contract and AgreementManagerETH is the struct that
    they use to store agreement data. This struct is much larger than the one needed for ETH only.
    The variables are arranged so that the compiler can easily "pack" them into 7 uint256s
    under the hood. Look at the comments for createAgreementA to see what all these
    variables represent.
    Each resolution has two components: TokenA and TokenB. This is because party A might be using
    a different ERC20 token than party B. So we can't just treat units of party A's token the same
    as units of party B's token.
    TokenA is the token that A staked,
    TokenB is the token that party B staked.
    ArbitratorToken is the token that the arbitrator will be paid in.
    ...all three tokens can be different.
    Spacing shows the uint256s that we expect these to be packed in -- there are seven groups
    separated by spaces, representing the seven uint256s that will be used internally.*/
    struct AgreementDataERC20 {
        // Some effort is made to group together variables that might be changed in the same
        // transaction, for gas cost optimization.

        uint48 partyAResolutionTokenA; // Party A's resolution for tokenA
        uint48 partyAResolutionTokenB; // Party A's resolution for tokenB
        uint48 partyBResolutionTokenA; // Party B's resolution for tokenA
        uint48 partyBResolutionTokenB; // Party B's resolution for tokenB
        /** nextArbitrationStepAllowedAfterTimestamp is the most complex state variable, as we
        want to keep the contract small to save gas cost. Initially it represents the timestamp
        after which the parties are allowed to request arbitration. Once arbitration is requested
        the first time, it represents how long the party who hasn't yet requested arbitration (or
        fully paid for arbitration in the case of ERC 792 arbitration) has until they lose via a
        "default judgment" (aka lose the dispute simply because they didn't post the arbitration
        fee) */
        uint32 nextArbitrationStepAllowedAfterTimestamp;
        // A bitmap that holds all of our "virtual" bool values.
        // See the offsets for bool values defined above for a list of the boolean info we store.
        uint32 boolValues;

        address partyAToken; // Address of the token contract that party A stakes (or 0x0 if ETH)
        // resolutionTokenA and resolutionTokenB hold the "official, final" resolution of the
        // agreement. Once these values have been set, it means the agreement is over and funds
        // can be withdrawn / distributed.
        uint48 resolutionTokenA;
        uint48 resolutionTokenB;

        address partyBToken; // Address of the token contract that party A stakes (or 0x0 if ETH)
        // An agreement can be created with an optional "automatic" resolution, which either party
        // can trigger after autoResolveAfterTimestamp.
        uint48 automaticResolutionTokenA;
        uint48 automaticResolutionTokenB;

        // Address of the token contract that the arbitrator is paid in (or 0x0 if ETH)
        address arbitratorToken;
        // To understand the following three variables, see the comments above the definition of
        // MAX_TOKEN_POWER
        uint8 partyATokenPower;
        uint8 partyBTokenPower;
        uint8 arbitratorTokenPower;

        address partyAAddress; // ETH address of party A
        uint48 partyAStakeAmount; // Amount that party A is required to stake
        // An optional arbitration fee that is sent to the arbitrator's address once both parties
        // have deposited their stakes.
        uint48 partyAInitialArbitratorFee;

        address partyBAddress; // ETH address of party B
        uint48 partyBStakeAmount; // Amount that party B is required to stake
        // An optional arbitration fee that is sent to the arbitrator's address once both parties
        // have deposited their stakes.
        uint48 partyBInitialArbitratorFee;

        address arbitratorAddress; // ETH address of Arbitrator
        uint48 disputeFee; // Fee paid to arbitrator only if there's a dispute and they do work.
        // The timestamp after which either party can trigger the "automatic resolution".
        // This can only be triggered if no one has requested arbitration.
        uint32 autoResolveAfterTimestamp;
       // The # of days that the other party has to respond to an arbitration request from the
        // other party. If they fail to respond in time, the other party can trigger a default
        // judgment.
        uint16 daysToRespondToArbitrationRequest;
    }

    // -------------------------------------------------------------------------------------------
    // --------------------------------- internal state ------------------------------------------
    // -------------------------------------------------------------------------------------------

    // We store our agreements in a single array. When a new agreement is created we add it to the
    // end. The index into this array is the agreementID.
    // Agreements not having ERC792 disputes will only use an element in the agreements array for
    // their state.
    AgreementDataERC20[] agreements;

    // -------------------------------------------------------------------------------------------
    // ---------------------------- external getter functions ------------------------------------
    // -------------------------------------------------------------------------------------------

    function getResolutionNull() external pure returns (uint, uint) {
        return (resolutionToWei(RESOLUTION_NULL, 0), resolutionToWei(RESOLUTION_NULL, 0));
    }
    function getNumberOfAgreements() external view returns (uint) {
        return agreements.length;
    }

    /// @return the full internal state of an agreement.
    function getState(
        uint agreementID
    )
        external
        view
        returns (address[6] memory, uint[23] memory, bool[12] memory, bytes memory);

    // -------------------------------------------------------------------------------------------
    // -------------------- main external functions that affect state ----------------------------
    // -------------------------------------------------------------------------------------------

    /**
    @notice Adds a new agreement to the agreements array.
    This is only callable by partyA. So the caller needs to rearrange addresses so that they're
    partyA. Party A needs to pay their stake as part of calling this function (either sending ETH,
    or having approved a pull from the neccessary ERC20 tokens).
    @dev createAgreementA differs between versions, so is defined low in the inheritance tree.
    We don't need re-entrancy protection here because createAgreementA can't influence
    existing agreeemnts.
    @param agreementHash hash of agreement details. Not stored, just emitted in an event.
    @param agreementURI URI to 'metaEvidence' as defined in ERC 1497
    @param addresses :
    addresses[0]: address of partyA
    addresses[1]: address of partyB
    addresses[2]: address of arbitrator
    addresses[3]: token that partyA is depositing.. 0 if ETH
    addresses[4]: token that partyB is depositing.. 0 if ETH
    addresses[5]: token that arbitrator is paid in.. 0 if ETH
    @param quantities :
    quantities[0]: amount that party A is staking
    quantities[1]: amount that party B is staking
    quantities[2]: amount that party A pays arbitrator regardless of whether there's a dispute
    quantities[3]: amount that party B pays arbitrator regardless of whether there's a dispute
    quantities[4]: disputeFee: 48 bit value expressing in units of 10^^arbitratorTokenPower
    quantities[5]: Amount of wei from party A's stake to go to party A if an automatic resolution
                   is triggered.
    quantities[6]: Amount of wei from party B's stake to go to party A if an automatic resolution
                   is triggered.
    quantities[7]: 16 bit value, # of days to respond to arbitration request
    quantities[8]: 32 bit timestamp value before which arbitration can't be requested.
    quantities[9]: 32 bit timestamp value after which auto-resolution is allowed if no one
                   requested arbitration. 0 means never.
    quantities[10]: value such that all amounts of party A's staked token type are internally in
                    units of 10^^value
    quantities[11]: value such that all amounts of party B's staked token type are internally in
                    units of 10^^value
    quantities[12]: value such that all amounts of arbitrator's preferred token type are
                    internally in units of 10^^value
    @param arbExtraData Data to pass in to ERC792 arbitrator if a dispute is ever created. Use
    null when creating non-ERC792 agreements
    @return the agreement id of the newly added agreement*/
    function createAgreementA(
        bytes32 agreementHash,
        string calldata agreementURI,
        address[6] calldata addresses,
        uint[13] calldata quantities,
        bytes calldata arbExtraData
    )
        external
        payable
        returns (uint)
    {
        require(msg.sender == addresses[0], "Only party A can call createAgreementA.");
        require(
            (
                quantities[10] <= MAX_TOKEN_POWER &&
                quantities[11] <= MAX_TOKEN_POWER &&
                quantities[12] <= MAX_TOKEN_POWER
            ),
            "Token power too large."
        );
        require(
            (
                addresses[0] != addresses[1] &&
                addresses[0] != addresses[2] &&
                addresses[1] != addresses[2]
            ),
            "partyA, partyB, and arbitrator addresses must be unique."
        );
        require(
            quantities[7] >= 1 && quantities[7] <= MAX_DAYS_TO_RESPOND_TO_ARBITRATION_REQUEST,
            "Days to respond to arbitration was out of range."
        );

        // Populate a AgreementDataERC20 struct with the info provided.
        AgreementDataERC20 memory agreement;
        agreement.partyAAddress = addresses[0];
        agreement.partyBAddress = addresses[1];
        agreement.arbitratorAddress = addresses[2];
        agreement.partyAToken = addresses[3];
        agreement.partyBToken = addresses[4];
        agreement.arbitratorToken = addresses[5];
        agreement.partyAResolutionTokenA = RESOLUTION_NULL;
        agreement.partyAResolutionTokenB = RESOLUTION_NULL;
        agreement.partyBResolutionTokenA = RESOLUTION_NULL;
        agreement.partyBResolutionTokenB = RESOLUTION_NULL;
        agreement.resolutionTokenA = RESOLUTION_NULL;
        agreement.resolutionTokenB = RESOLUTION_NULL;
        agreement.partyAStakeAmount = toLargerUnit(quantities[0], quantities[10]);
        agreement.partyBStakeAmount = toLargerUnit(quantities[1], quantities[11]);
        require(
            (
                agreement.partyAStakeAmount < RESOLUTION_NULL &&
                agreement.partyBStakeAmount < RESOLUTION_NULL
            ),
            "Stake amounts were too large. Consider increasing the token powers."
        );
        agreement.partyAInitialArbitratorFee = toLargerUnit(quantities[2], quantities[12]);
        agreement.partyBInitialArbitratorFee = toLargerUnit(quantities[3], quantities[12]);
        agreement.disputeFee = toLargerUnit(quantities[4], quantities[12]);
        agreement.automaticResolutionTokenA = toLargerUnit(quantities[5], quantities[10]);
        agreement.automaticResolutionTokenB = toLargerUnit(quantities[6], quantities[11]);
        require(
            (
                agreement.automaticResolutionTokenA <= agreement.partyAStakeAmount &&
                agreement.automaticResolutionTokenB <= agreement.partyBStakeAmount
            ),
            "Automatic resolution was too large."
        );
        agreement.daysToRespondToArbitrationRequest = toUint16(quantities[7]);
        agreement.nextArbitrationStepAllowedAfterTimestamp = toUint32(quantities[8]);
        agreement.autoResolveAfterTimestamp = toUint32(quantities[9]);
        agreement.partyATokenPower = toUint8(quantities[10]);
        agreement.partyBTokenPower = toUint8(quantities[11]);
        agreement.arbitratorTokenPower = toUint8(quantities[12]);
        // set boolean values
        uint32 tempBools = setBool(0, PARTY_A_STAKE_PAID, true);
        if (add(quantities[1], quantities[3]) == 0) {
            tempBools = setBool(tempBools, PARTY_B_STAKE_PAID, true);
        }
        agreement.boolValues = tempBools;

        uint agreementID = sub(agreements.push(agreement), 1);

        checkContractSpecificConditionsForCreation(agreement.arbitratorToken);

        // This is a function because we want it to be a no-op for non-ERC792 agreements.
        storeArbitrationExtraData(agreementID, arbExtraData);

        emitAgreementCreationEvents(agreementID, agreementHash, agreementURI);

        // Verify that partyA paid deposit and fees.
        verifyDeposit_Untrusted_Guarded(agreements[agreementID], Party.A);

        // Pay the arbiter if needed, which happens if B was staking no funds and needed no
        // initial fee, but there was an initial fee from A.
        if ((add(quantities[1], quantities[3]) == 0) && (quantities[2] > 0)) {
            payOutInitialArbitratorFee_Untrusted_Unguarded(agreements[agreementID]);
        }

        return agreementID;
    }

    /// @notice Called by PartyB to deposit their stake, locking in the agreement so no one can
    /// unilaterally withdraw. PartyA already deposited funds in createAgreementA, so we only need
    /// a deposit function for partyB.
    function depositB(uint agreementID) external payable {
        AgreementDataERC20 storage agreement = agreements[agreementID];

        require(!pendingExternalCall(agreement), "Reentrancy protection is on.");
        require(agreementIsOpen(agreement), "Agreement not open.");
        require(msg.sender == agreement.partyBAddress, "Function can only be called by party B.");
        require(!partyStakePaid(agreement, Party.B), "Party B already deposited their stake.");
        // No need to check that party A deposited: they can't create an agreement otherwise.

        setPartyStakePaid(agreement, Party.B, true);

        emit PartyBDeposited(uint32(agreementID));

        verifyDeposit_Untrusted_Guarded(agreement, Party.B);

        if (add(agreement.partyAInitialArbitratorFee, agreement.partyBInitialArbitratorFee) > 0) {
            payOutInitialArbitratorFee_Untrusted_Unguarded(agreement);
        }
    }

    /// @notice Called to report a resolution of the agreement by a party. The resolution
    /// specifies how funds should be distributed between the parties.
    /// @param resTokenA Amount of party A's stake that the caller thinks should go to party A.
    /// The remaining amount would go to party B.
    /// @param resTokenB Amount of party B's stake that the caller thinks should go to party A.
    /// The remaining amount would go to party B.
    /// @param distributeFunds Whether to distribute funds to the two parties if this call
    /// results in an official resolution to the agreement.
    function resolveAsParty(
        uint agreementID,
        uint resTokenA,
        uint resTokenB,
        bool distributeFunds
    )
        external
    {
        AgreementDataERC20 storage agreement = agreements[agreementID];

        require(!pendingExternalCall(agreement), "Reentrancy protection is on.");
        require(agreementIsOpen(agreement), "Agreement not open.");
        require(agreementIsLockedIn(agreement), "Agreement not locked in.");

        uint48 resA = toLargerUnit(resTokenA, agreement.partyATokenPower);
        uint48 resB = toLargerUnit(resTokenB, agreement.partyBTokenPower);
        require(resA <= agreement.partyAStakeAmount, "Resolution out of range for token A.");
        require(resB <= agreement.partyBStakeAmount, "Resolution out of range for token B.");

        (Party callingParty, Party otherParty) = getCallingPartyAndOtherParty(agreement);

        // Keep track of who was the last to resolve.. useful for punishing 'late' resolutions.
        // We check the existing state of partyAResolvedLast only as a perf optimization, to avoid
        // unnecessary writes.
        if (callingParty == Party.A && !partyAResolvedLast(agreement)) {
            setPartyAResolvedLast(agreement, true);
        } else if (callingParty == Party.B && partyAResolvedLast(agreement)) {
            setPartyAResolvedLast(agreement, false);
        }

        // See if we need to update the deadline to respond to arbitration. We want to avoid a
        // situation where someone has (or will soon have) the right to request a default
        // judgment, then they change their resolution to be more favorable to them and
        // immediately request a default judgment for the new resolution.
        if (partyIsCloserToWinningDefaultJudgment(agreementID, agreement, callingParty)) {
            // If new resolution isn't compatible with the existing one, then the caller possibly
            // made the resolution more favorable to themself.
            // We know that an old resolution exists because for the caller to be closer to
            // winning a default judgment they must have requested arbitration, and they can only
            // request arbitration after resolving.
            (uint oldResA, uint oldResB) = partyResolution(agreement, callingParty);
            if (
                !resolutionsAreCompatibleBothExist(
                    agreement,
                    resA,
                    resB,
                    oldResA,
                    oldResB,
                    callingParty
                )
            ) {
                updateArbitrationResponseDeadline(agreement);
            }
        }

        setPartyResolution(agreement, callingParty, resA, resB);

        emit PartyResolved(uint32(agreementID), resA, resB);

        // If the resolution is 'compatible' with that of the other person, make it the
        // final resolution.
        (uint otherResA, uint otherResB) = partyResolution(agreement, otherParty);
        if (
            resolutionsAreCompatible(
                agreement,
                resA,
                resB,
                otherResA,
                otherResB,
                callingParty
            )
        ) {
            finalizeResolution_Untrusted_Unguarded(
                agreementID,
                agreement,
                resA,
                resB,
                distributeFunds,
                false
            );
        }
    }

    /// @notice If A calls createAgreementA but B is delaying in calling depositB, A can get their
    /// funds back by calling earlyWithdrawA. This closes the agreement to further deposits. A or
    /// B wouldhave to call createAgreementA again if they still wanted to do an agreement.
    function earlyWithdrawA(uint agreementID) external {
        AgreementDataERC20 storage agreement = agreements[agreementID];

        require(!pendingExternalCall(agreement), "Reentrancy protection is on");
        require(agreementIsOpen(agreement), "Agreement not open.");
        require(msg.sender == agreement.partyAAddress, "earlyWithdrawA not called by party A.");
        require(
            partyStakePaid(agreement, Party.A) && !partyStakePaid(agreement, Party.B),
            "Early withdraw not allowed."
        );
        require(!partyReceivedDistribution(agreement, Party.A), "partyA already received funds.");

        setPartyReceivedDistribution(agreement, Party.A, true);

        emit PartyAWithdrewEarly(uint32(agreementID));

        executeDistribution_Untrusted_Unguarded(
            agreement.partyAAddress,
            agreement.partyAToken,
            toWei(agreement.partyAStakeAmount, agreement.partyATokenPower),
            agreement.arbitratorToken,
            toWei(agreement.partyAInitialArbitratorFee, agreement.arbitratorTokenPower)
        );
    }

    /// @notice This can only be called after a resolution is established.
    /// Each party calls this to withdraw the funds they're entitled to, based on the resolution.
    /// Normally funds are distributed automatically when the agreement gets resolved. However
    /// it is possible for a malicious user to prevent their counterparty from getting an
    /// automatic distribution, by using an address for the agreement that can't receive payments.
    /// If this happens, the agreement should be resolved by setting the distributeFunds parameter
    /// to false in whichever function is called to resolve the disagreement. Then the parties can
    /// independently extract their funds via this function.
    function withdraw(uint agreementID) external {
        AgreementDataERC20 storage agreement = agreements[agreementID];
        require(!pendingExternalCall(agreement), "Reentrancy protection is on");
        require(agreement.resolutionTokenA != RESOLUTION_NULL, "Agreement not resolved.");

        emit PartyWithdrew(uint32(agreementID));

        distributeFundsToPartyHelper_Untrusted_Unguarded(
            agreementID,
            agreement,
            getCallingParty(agreement)
        );
    }

    /// @notice Request that the arbitrator get involved to settle the disagreement.
    /// Each party needs to pay the full arbitration fee when calling this. However they will be
    /// refunded the full fee if the arbitrator agrees with them.
    function requestArbitration(uint agreementID) external payable;

    /// @notice If the other person hasn't paid their arbitration fee in time, this function
    /// allows the caller to cause the agreement to be resolved in their favor without the
    /// arbitrator getting involved.
    /// @param distributeFunds Whether to distribute funds to both parties.
    function requestDefaultJudgment(uint agreementID, bool distributeFunds) external {
        AgreementDataERC20 storage agreement = agreements[agreementID];

        require(!pendingExternalCall(agreement), "Reentrancy protection is on.");
        require(agreementIsOpen(agreement), "Agreement not open.");
        require(agreementIsLockedIn(agreement), "Agreement not locked in.");

        (Party callingParty, Party otherParty) = getCallingPartyAndOtherParty(agreement);

        require(
            !partyResolutionIsNull(agreement, callingParty),
            "requestDefaultJudgment called before party resolved."
        );
        require(
            block.timestamp > agreement.nextArbitrationStepAllowedAfterTimestamp,
            "requestDefaultJudgment not allowed yet."
        );

        emit DefaultJudgment(uint32(agreementID));

        require(
            partyFullyPaidDisputeFee_Sometimes_Untrusted_Guarded(
                agreementID,
                agreement,
                callingParty
            ),
            "Party didn't fully pay the dispute fee."
        );
        require(
            !partyFullyPaidDisputeFee_Sometimes_Untrusted_Guarded(
                agreementID,
                agreement,
                otherParty
            ),
            "Other party fully paid the dispute fee."
        );

        (uint48 partyResA, uint48 partyResB) = partyResolution(
            agreement,
            callingParty
        );

        finalizeResolution_Untrusted_Unguarded(
            agreementID,
            agreement,
            partyResA,
            partyResB,
            distributeFunds,
            false
        );
    }

    /// @notice If enough time has elapsed, either party can trigger auto-resolution (if enabled)
    /// by calling this function, provided that neither party has requested arbitration yet.
    /// @param distributeFunds Whether to distribute funds to both parties
    function requestAutomaticResolution(uint agreementID, bool distributeFunds) external {
        AgreementDataERC20 storage agreement = agreements[agreementID];

        require(!pendingExternalCall(agreement), "Reentrancy protection is on.");
        require(agreementIsOpen(agreement), "Agreement not open.");
        require(agreementIsLockedIn(agreement), "Agreement not locked in.");
        require(
            (
                !partyRequestedArbitration(agreement, Party.A) &&
                !partyRequestedArbitration(agreement, Party.B)
            ),
            "Arbitration stops auto-resolution"
        );
        require(
            msg.sender == agreement.partyAAddress || msg.sender == agreement.partyBAddress,
            "Unauthorized sender."
        );
        require(
            agreement.autoResolveAfterTimestamp > 0,
            "Agreement does not support automatic resolutions."
        );
        require(
            block.timestamp > agreement.autoResolveAfterTimestamp,
            "AutoResolution not allowed yet."
        );

        emit AutomaticResolution(uint32(agreementID));

        finalizeResolution_Untrusted_Unguarded(
            agreementID,
            agreement,
            agreement.automaticResolutionTokenA,
            agreement.automaticResolutionTokenB,
            distributeFunds,
            false
        );
    }

    /// @notice Either party can record evidence on the blockchain in case off-chain communication
    /// breaks down. Uses ERC1497. Allows submitting evidence even after an agreement is closed in
    /// case someone wants to clear their name.
    /// @param evidence can be any string containing evidence. Usually will be a URI to a document
    /// or video containing evidence.
    function submitEvidence(uint agreementID, string calldata evidence) external {
        AgreementDataERC20 storage agreement = agreements[agreementID];

        require(
            (
                msg.sender == agreement.partyAAddress ||
                msg.sender == agreement.partyBAddress ||
                msg.sender == agreement.arbitratorAddress
            ),
            "Unauthorized sender."
        );

        emit Evidence(Arbitrator(agreement.arbitratorAddress), agreementID, msg.sender, evidence);
    }

    // -------------------------------------------------------------------------------------------
    // ----------------------- internal getter and setter functions ------------------------------
    // -------------------------------------------------------------------------------------------

    // Functions that simulate direct access to AgreementDataERC20 state variables.
    // These are used either for bools (where we need to use a bitmask), or for
    // functions when we need to vary between party A/B depending on the argument.
    // The later is necessary because the solidity compiler can't pack structs well when their
    // elements are arrays. So we can't just index into an array.

    // ------------- Some getter functions ---------------

    function partyResolution(
        AgreementDataERC20 storage agreement,
        Party party
    )
        internal
        view
        returns (uint48, uint48)
    {
        if (party == Party.A)
            return (agreement.partyAResolutionTokenA, agreement.partyAResolutionTokenB);
        else
            return (agreement.partyBResolutionTokenA, agreement.partyBResolutionTokenB);
    }

    function partyResolutionIsNull(
        AgreementDataERC20 storage agreement,
        Party party
    )
        internal
        view
        returns (bool)
    {
         // We can test only token A, because if token A will be null IFF token B is null
        if (party == Party.A) return agreement.partyAResolutionTokenA == RESOLUTION_NULL;
        else return agreement.partyBResolutionTokenA == RESOLUTION_NULL;
    }

    function partyAddress(
        AgreementDataERC20 storage agreement,
        Party party
    )
        internal
        view
        returns (address)
    {
        if (party == Party.A) return agreement.partyAAddress;
        else return agreement.partyBAddress;
    }

    function partyStakePaid(
        AgreementDataERC20 storage agreement,
        Party party
    )
        internal
        view
        returns (bool)
    {
        if (party == Party.A) return getBool(agreement.boolValues, PARTY_A_STAKE_PAID);
        else return getBool(agreement.boolValues, PARTY_B_STAKE_PAID);
    }

    function partyStakeAmount(
        AgreementDataERC20 storage agreement,
        Party party
    )
        internal
        view
        returns (uint48)
    {
        if (party == Party.A) return agreement.partyAStakeAmount;
        else return agreement.partyBStakeAmount;
    }

    function partyInitialArbitratorFee(
        AgreementDataERC20 storage agreement,
        Party party
    )
        internal
        view
        returns (uint48)
    {
        if (party == Party.A) return agreement.partyAInitialArbitratorFee;
        else return agreement.partyBInitialArbitratorFee;
    }

    function partyRequestedArbitration(
        AgreementDataERC20 storage agreement,
        Party party
    )
        internal
        view
        returns (bool)
    {
        if (party == Party.A) return getBool(agreement.boolValues, PARTY_A_REQUESTED_ARBITRATION);
        else return getBool(agreement.boolValues, PARTY_B_REQUESTED_ARBITRATION);
    }

    function partyReceivedDistribution(
        AgreementDataERC20 storage agreement,
        Party party
    )
        internal
        view
        returns (bool)
    {
        if (party == Party.A) return getBool(agreement.boolValues, PARTY_A_RECEIVED_DISTRIBUTION);
        else return getBool(agreement.boolValues, PARTY_B_RECEIVED_DISTRIBUTION);
    }

    function partyToken(
        AgreementDataERC20 storage agreement,
        Party party
    )
        internal
        view
        returns (address)
    {
        if (party == Party.A) return agreement.partyAToken;
        else return agreement.partyBToken;
    }

    function partyTokenPower(
        AgreementDataERC20 storage agreement,
        Party party
    )
        internal
        view
        returns (uint8)
    {
        if (party == Party.A) return agreement.partyATokenPower;
        else return agreement.partyBTokenPower;
    }

    function partyAResolvedLast(
        AgreementDataERC20 storage agreement
    )
        internal
        view
        returns (bool)
    {
        return getBool(agreement.boolValues, PARTY_A_RESOLVED_LAST);
    }

    function arbitratorResolved(
        AgreementDataERC20 storage agreement
    )
        internal
        view
        returns (bool)
    {
        return getBool(agreement.boolValues, ARBITRATOR_RESOLVED);
    }

    function arbitratorReceivedDisputeFee(
        AgreementDataERC20 storage agreement
    )
        internal
        view
        returns (bool)
    {
        return getBool(agreement.boolValues, ARBITRATOR_RECEIVED_DISPUTE_FEE);
    }

    function partyDisputeFeeLiability(
        AgreementDataERC20 storage agreement,
        Party party
    )
        internal
        view
        returns (bool)
    {
        if (party == Party.A) return getBool(agreement.boolValues, PARTY_A_DISPUTE_FEE_LIABILITY);
        else return getBool(agreement.boolValues, PARTY_B_DISPUTE_FEE_LIABILITY);
    }

    function pendingExternalCall(
        AgreementDataERC20 storage agreement
    )
        internal
        view
        returns (bool)
    {
        return getBool(agreement.boolValues, PENDING_EXTERNAL_CALL);
    }

    // ------------- Some setter functions ---------------

    function setPartyResolution(
        AgreementDataERC20 storage agreement,
        Party party,
        uint48 valueTokenA,
        uint48 valueTokenB
    )
        internal
    {
        if (party == Party.A) {
            agreement.partyAResolutionTokenA = valueTokenA;
            agreement.partyAResolutionTokenB = valueTokenB;
        } else {
            agreement.partyBResolutionTokenA = valueTokenA;
            agreement.partyBResolutionTokenB = valueTokenB;
        }
    }

    function setPartyStakePaid(
        AgreementDataERC20 storage agreement,
        Party party,
        bool value
    )
        internal
    {
        if (party == Party.A)
            agreement.boolValues = setBool(agreement.boolValues, PARTY_A_STAKE_PAID, value);
        else
            agreement.boolValues = setBool(agreement.boolValues, PARTY_B_STAKE_PAID, value);
    }

    function setPartyRequestedArbitration(
        AgreementDataERC20 storage agreement,
        Party party,
        bool value
    )
        internal
    {
        if (party == Party.A) {
            agreement.boolValues = setBool(
                agreement.boolValues,
                PARTY_A_REQUESTED_ARBITRATION,
                value
            );
        } else {
            agreement.boolValues = setBool(
                agreement.boolValues,
                PARTY_B_REQUESTED_ARBITRATION,
                value
            );
        }
    }

    function setPartyReceivedDistribution(
        AgreementDataERC20 storage agreement,
        Party party,
        bool value
    )
        internal
    {
        if (party == Party.A) {
            agreement.boolValues = setBool(
                agreement.boolValues,
                PARTY_A_RECEIVED_DISTRIBUTION,
                value
            );
        } else {
            agreement.boolValues = setBool(
                agreement.boolValues,
                PARTY_B_RECEIVED_DISTRIBUTION,
                value
            );
        }
    }

    function setPartyAResolvedLast(AgreementDataERC20 storage agreement, bool value) internal {
        agreement.boolValues = setBool(agreement.boolValues, PARTY_A_RESOLVED_LAST, value);
    }

    function setArbitratorResolved(AgreementDataERC20 storage agreement, bool value) internal {
        agreement.boolValues = setBool(agreement.boolValues, ARBITRATOR_RESOLVED, value);
    }

    function setArbitratorReceivedDisputeFee(
        AgreementDataERC20 storage agreement,
        bool value
    )
        internal
    {
        agreement.boolValues = setBool(
            agreement.boolValues,
            ARBITRATOR_RECEIVED_DISPUTE_FEE,
            value
        );
    }

    function setPartyDisputeFeeLiability(
        AgreementDataERC20 storage agreement,
        Party party,
        bool value
    )
        internal
    {
        if (party == Party.A) {
            agreement.boolValues = setBool(
                agreement.boolValues,
                PARTY_A_DISPUTE_FEE_LIABILITY,
                value
            );
        } else {
            agreement.boolValues = setBool(
                agreement.boolValues,
                PARTY_B_DISPUTE_FEE_LIABILITY,
                value
            );
        }
    }

    function setPendingExternalCall(AgreementDataERC20 storage agreement, bool value) internal {
        agreement.boolValues = setBool(agreement.boolValues, PENDING_EXTERNAL_CALL, value);
    }

    /// @notice set the value of PENDING_EXTERNAL_CALL and return the previous value.
    function getThenSetPendingExternalCall(
        AgreementDataERC20 storage agreement,
        bool value
    )
        internal
        returns (bool)
    {
        uint32 previousBools = agreement.boolValues;
        agreement.boolValues = setBool(previousBools, PENDING_EXTERNAL_CALL, value);
        return getBool(previousBools, PENDING_EXTERNAL_CALL);
    }

    // -------------------------------------------------------------------------------------------
    // -------------------------- internal helper functions --------------------------------------
    // -------------------------------------------------------------------------------------------

    /// @notice We store ETH/token amounts in uint48s demoninated in larger units of that token.
    /// Specifically, our internal representation is in units of 10^tokenPower wei.
    /// toWei converts from our internal representation to the wei amount.
    /// @dev This can't overflow. For an explanation of why see the comments for MAX_TOKEN_POWER.
    /// @param value internal value that we want to convert to wei
    /// @param tokenPower The exponent to use to convert our internal representation to wei.
    /// @return the wei value
    function toWei(uint value, uint tokenPower) internal pure returns (uint) {
        return mul(value, (10 ** tokenPower));
    }

    /// @notice Like toWei but resolutionToWei is for "resolution" values which might have a
    /// special value of RESOLUTION_NULL, which we need to handle separately.
    /// @dev This can't overflow. For an explanation of why see the comments for MAX_TOKEN_POWER.
    /// @param value internal value that we want to convert to wei
    /// @param tokenPower The exponent to use to convert our internal representation to wei.
    /// @return the wei value
    function resolutionToWei(uint value, uint tokenPower) internal pure returns (uint) {
        if (value == RESOLUTION_NULL) {
            return uint(~0); // set all bits of a uint to 1
        }
        return mul(value, (10 ** tokenPower));
    }

    /// @notice Convert a value expressed in wei to our internal representation (which is
    /// in units of 10^tokenPower wei)
    /// @dev This can't overflow. For an explanation of why see the comments for MAX_TOKEN_POWER.
    /// @param weiValue wei value that we want to convert from
    /// @param tokenPower The exponent to use to convert wei to our internal representation
    /// @return the amount of our internal units of the given value
    function toLargerUnit(uint weiValue, uint tokenPower) internal pure returns (uint48) {
        return toUint48(weiValue / (10 ** tokenPower));
    }

    /// @notice Requires that the caller be party A or party B.
    /// @return whichever party the caller is.
    function getCallingParty(AgreementDataERC20 storage agreement) internal view returns (Party) {
        if (msg.sender == agreement.partyAAddress) {
            return Party.A;
        } else if (msg.sender == agreement.partyBAddress) {
            return Party.B;
        } else {
            require(false, "getCallingParty must be called by a party to the agreement.");
        }
    }

    /// @param party a party for whom we want to get the other party.
    /// @return the other party who was not given in the parameter.
    function getOtherParty(Party party) internal pure returns (Party) {
        if (party == Party.A) {
            return Party.B;
        }
        return Party.A;
    }

    /// @notice Fails if called by anyone other than a party.
    /// @return the calling party first and the "other party" second.
    function getCallingPartyAndOtherParty(
        AgreementDataERC20 storage agreement
    )
        internal
        view
        returns (Party, Party)
    {
        if (msg.sender == agreement.partyAAddress) {
            return (Party.A, Party.B);
        } else if (msg.sender == agreement.partyBAddress) {
            return (Party.B, Party.A);
        } else {
            require(
                false,
                "getCallingPartyAndOtherParty must be called by a party to the agreement."
            );
        }
    }

    /// @notice This is a version of resolutionsAreCompatible where we know that both resolutions
    /// are not RESOLUTION_NULL. It's more gas efficient so we should use it when possible.
    /// See comments for resolutionsAreCompatible to understand the purpose and arguments.
    function resolutionsAreCompatibleBothExist(
        AgreementDataERC20 storage agreement,
        uint resolutionTokenA,
        uint resolutionTokenB,
        uint otherResolutionTokenA,
        uint otherResolutionTokenB,
        Party resolutionParty
    )
        internal
        view
        returns (bool)
    {
        // If the tokens are different, ensure that both token resolutions are compatible.
        if (agreement.partyAToken != agreement.partyBToken) {
            if (resolutionParty == Party.A) {
                return resolutionTokenA <= otherResolutionTokenA &&
                    resolutionTokenB <= otherResolutionTokenB;
            } else {
                return otherResolutionTokenA <= resolutionTokenA &&
                    otherResolutionTokenB <= resolutionTokenB;
            }
        }

        // Now we know tokens are the same. We need to convert to wei because the same resolution
        // can be represented in many different ways.
        uint resSum = add(
            resolutionToWei(resolutionTokenA, agreement.partyATokenPower),
            resolutionToWei(resolutionTokenB, agreement.partyBTokenPower)
        );
        uint otherSum = add(
            resolutionToWei(otherResolutionTokenA, agreement.partyATokenPower),
            resolutionToWei(otherResolutionTokenB, agreement.partyBTokenPower)
        );
        if (resolutionParty == Party.A) {
            return resSum <= otherSum;
        } else {
            return otherSum <= resSum;
        }
    }

    /// @notice Compatible means that the participants don't disagree in a selfish direction.
    /// Alternatively, it means that we know some resolution will satisfy both parties.
    /// If one person resolves to give the other person the maximum possible amount, this is
    /// always compatible with the other person's resolution, even if that resolution is
    /// RESOLUTION_NULL. Otherwise, one person having a resolution of RESOLUTION_NULL
    /// implies the resolutions are not compatible.
    /// @param resolutionTokenA The component of a resolution provided by either party A
    /// or party B representing party A's staked token. Can't be RESOLUTION_NULL.
    /// @param resolutionTokenB The component of a resolution provided by either party A
    /// or party B representing party B's staked token. Can't be RESOLUTION_NULL.
    /// @param otherResolutionTokenA The component of a resolution provided either by the
    /// other party or by the arbitrator representing party A's staked token. It may be
    /// RESOLUTION_NULL.
    /// @param otherResolutionTokenB The component of a resolution provided either by the
    /// other party or by the arbitrator representing party A's staked token. It may be
    /// RESOLUTION_NULL.
    /// @param resolutionParty The party corresponding to the resolution provided by the
    /// 'resolutionTokenA' and 'resolutionTokenB' parameters.
    /// @return whether the resolutions are compatible.
    function resolutionsAreCompatible(
        AgreementDataERC20 storage agreement,
        uint resolutionTokenA,
        uint resolutionTokenB,
        uint otherResolutionTokenA,
        uint otherResolutionTokenB,
        Party resolutionParty
    )
        internal
        view
        returns (bool)
    {
        // If we're not dealing with the NULL case, we can use resolutionsAreCompatibleBothExist
        if (otherResolutionTokenA != RESOLUTION_NULL) {
            return resolutionsAreCompatibleBothExist(
                agreement,
                resolutionTokenA,
                resolutionTokenB,
                otherResolutionTokenA,
                otherResolutionTokenB,
                resolutionParty
            );
        }

        // Now we know otherResolution is null.
        // See if resolutionParty wants to give all funds to the other party.
        if (resolutionParty == Party.A) {
            // only 0 from Party A is compatible with RESOLUTION_NULL
            return resolutionTokenA == 0 && resolutionTokenB == 0;
        } else {
            // only the max possible amount from Party B is compatible with RESOLUTION_NULL
            return resolutionTokenA == agreement.partyAStakeAmount &&
                resolutionTokenB == agreement.partyBStakeAmount;
        }
    }

    /// @return Whether the party provided is closer to winning a default judgment than the other
    /// party.
    function partyIsCloserToWinningDefaultJudgment(
        uint agreementID,
        AgreementDataERC20 storage agreement,
        Party party
    )
        internal
        returns (bool);

    /**
    @notice When a party withdraws, they may be owed a refund for any arbitration fee that they've
    paid in because this contract requires the loser of arbitration to pay the full fee.
    But since we don't know who the loser will be ahead of time, both parties must pay in the
    full arbitration amount when requesting arbitration.
    We assume we're only calling this function from an agreement with an official resolution.
    If this function has a it has a bug that overestimates the total amount that partyA and partyB
    can withdraw it could cause funds to be drained from the contract. Therefore
    it will be commented extensively in the implementations by inheriting contracts.
    @param agreementID id of the agreement
    @param agreement the agreement struct
    @param party the party for whom we are calculating the refund
    @return the value of the refund in wei.*/
    function getPartyArbitrationRefundInWei(
        uint agreementID,
        AgreementDataERC20 storage agreement,
        Party party
    )
        internal
        view
        returns (uint);

    /// @notice This lets us write one version of createAgreementA for both ERC792 and simple
    /// arbitration.
    /// @param arbExtraData some data that the creator of the agreement optionally passes in
    /// when creating an ERC792 agreement.
    function storeArbitrationExtraData(uint agreementID, bytes memory arbExtraData) internal;

    /// @notice Some inheriting contracts have restrictions on how the arbitrator can be paid.
    /// This enforces those restrictions.
    function checkContractSpecificConditionsForCreation(address arbitratorToken) internal;

    /// @dev '_Sometimes_Untrusted_Guarded' means that in some inheriting contracts it's
    /// _Untrusted_Guarded, in some it isn't. Look at the implementation in the specific
    /// contract you're interested in to know.
    function partyFullyPaidDisputeFee_Sometimes_Untrusted_Guarded(
        uint agreementID,
        AgreementDataERC20 storage agreement,
        Party party
    )
        internal
        returns (bool);

    /// @notice 'Open' means people should be allowed to take steps toward a future resolution.
    /// An agreement isn't open after it has ended (a final resolution exists), or if someone
    /// withdrew their funds before the second party could deposit theirs.
    /// @dev partyB can't do an early withdrawal, so we only need to check if partyA withdrew.
    function agreementIsOpen(AgreementDataERC20 storage agreement) internal view returns (bool) {
        // If the tokenA resolution is null then the tokenB one is too, so just check A
        return agreement.resolutionTokenA == RESOLUTION_NULL &&
            !partyReceivedDistribution(agreement, Party.A);
    }

    /// @notice 'Locked in' means both parties have deposited their stake. It conveys that the
    /// agreement is fully accepted and no one can get money out without someone else's approval.
    function agreementIsLockedIn(
        AgreementDataERC20 storage agreement
    )
        internal
        view
        returns (bool)
    {
        return partyStakePaid(agreement, Party.A) && partyStakePaid(agreement, Party.B);
    }

    /// @notice Set or extend the deadline for both parties to pay the arbitration fee.
    function updateArbitrationResponseDeadline(AgreementDataERC20 storage agreement) internal {
        agreement.nextArbitrationStepAllowedAfterTimestamp =
            toUint32(
                add(
                    block.timestamp,
                    mul(agreement.daysToRespondToArbitrationRequest, (1 days))
                )
            );
    }

    /// @notice When both parties have deposited their stakes, the arbitrator is paid any
    /// 'initial' arbitration fee that was required. We assume we've already checked that the
    /// arbitrator is owed a nonzero amount.
    function payOutInitialArbitratorFee_Untrusted_Unguarded(
        AgreementDataERC20 storage agreement
    )
        internal
    {
        uint totalInitialFeesWei = toWei(
            add(agreement.partyAInitialArbitratorFee, agreement.partyBInitialArbitratorFee),
            agreement.arbitratorTokenPower
        );

        sendFunds_Untrusted_Unguarded(
            agreement.arbitratorAddress,
            agreement.arbitratorToken,
            totalInitialFeesWei
        );
    }

    /// @notice Transfers funds from this contract to a given address
    /// @param to The address to send the funds.
    /// @param token The address of the token being sent.
    /// @param amount The amount of wei of the token to send.
    function sendFunds_Untrusted_Unguarded(
        address to,
        address token,
        uint amount
    )
        internal
    {
        if (amount == 0) {
            return;
        }
        if (token == address(0)) {
            // Need to cast to uint160 to make it payable.
            address(uint160(to)).transfer(amount);
        } else {
            require(ERC20Interface(token).transfer(to, amount), "ERC20 transfer failed.");
        }
    }

    /// @notice Pull ERC20 tokens into this contract from the caller
    /// @param token The address of the token being pulled.
    /// @param amount The amount of wei of the token to pulled.
    function receiveFunds_Untrusted_Unguarded(
        address token,
        uint amount
    )
        internal
    {
        if (token == address(0)) {
            require(msg.value == amount, "ETH value received was not what was expected.");
        } else if (amount > 0) {
            require(
                ERC20Interface(token).transferFrom(msg.sender, address(this), amount),
                "ERC20 transfer failed."
            );
        }
    }

    /// @notice The depositor needs to send their stake amount (in the token they're staking), and
    /// also potentially an initial arbitration fee, in arbitratorToken. This function verifies
    /// that the current transaction has caused those funds to be moved to our contract.
    function verifyDeposit_Untrusted_Guarded(
        AgreementDataERC20 storage agreement,
        Party party
    )
        internal
    {
        address partyTokenAddress = partyToken(agreement, party);

        // Make sure people don't accidentally send ETH when the only required tokens are ERC20
        if (partyTokenAddress != address(0) && agreement.arbitratorToken != address(0)) {
            require(msg.value == 0, "ETH was sent, but none was needed.");
        }

        // Wrap these receives in a reentrancy guard. (Technically this shouldn't be necessary,
        // but that's not obvious enough to make it worth risking a bug.)
        bool previousValue = getThenSetPendingExternalCall(agreement, true);
        if (partyTokenAddress == agreement.arbitratorToken) {
            // Both tokens we're receiving are of the same type, so we can do one combined receive
            receiveFunds_Untrusted_Unguarded(
                partyTokenAddress,
                add(
                    toWei(partyStakeAmount(agreement, party), partyTokenPower(agreement, party)),
                    toWei(
                        partyInitialArbitratorFee(agreement, party),
                        agreement.arbitratorTokenPower
                    )
                )
            );
        } else {
            // Tokens are of different types, so do one receive for each.
            receiveFunds_Untrusted_Unguarded(
                partyTokenAddress,
                toWei(partyStakeAmount(agreement, party), partyTokenPower(agreement, party))
            );
            receiveFunds_Untrusted_Unguarded(
                agreement.arbitratorToken,
                toWei(
                    partyInitialArbitratorFee(agreement, party),
                    agreement.arbitratorTokenPower
                )
            );
        }
        setPendingExternalCall(agreement, previousValue);
    }

    /// @notice Distribute funds from this contract to the given address, using up to two
    /// different tokens.
    /// @param to The address to distribute to.
    /// @param token1 The first token address
    /// @param amount1 The amount of token1 to distribute in wei
    /// @param token2 The second token address
    /// @param amount2 The amount of token2 to distribute in wei
    function executeDistribution_Untrusted_Unguarded(
        address to,
        address token1,
        uint amount1,
        address token2,
        uint amount2
    )
        internal
    {
        // All of the calls below are Reentrancy Safe, as they don't depend on any internal state
        // nor do they modify any state. You can quickly see this by noting that this function
        // doesn't have access to any references to an agreement, so it can't affect state.
        if (token1 == token2) {
            sendFunds_Untrusted_Unguarded(to, token1, add(amount1, amount2));
        } else {
            sendFunds_Untrusted_Unguarded(to, token1, amount1);
            sendFunds_Untrusted_Unguarded(to, token2, amount2);
        }
    }

    /// @notice Distribute funds from this contract to the given address, using up to three
    /// different tokens.
    /// @param to The address to distribute to.
    /// @param token1 The first token address
    /// @param amount1 The amount of token1 to distribute in wei
    /// @param token2 The second token address
    /// @param amount2 The amount of token2 to distribute in wei
    /// @param token3 The third token address
    /// @param amount3 The amount of token3 to distribute in wei
    function executeDistribution_Untrusted_Unguarded(
        address to,
        address token1,
        uint amount1,
        address token2,
        uint amount2,
        address token3,
        uint amount3
    )
        internal
    {
        // All of the calls below are Reentrancy Safe, as they don't depend on any internal state
        // nor do they modify any state. You can quickly see this by noting that this function
        // doesn't have access to any references to an agreement, so it can't affect state.

        // Check for all combinations of which tokens are the same, to minimize the amount of
        // transfers.
        if (token1 == token2 && token1 == token3) {
            sendFunds_Untrusted_Unguarded(to, token1, add(amount1, add(amount2, amount3)));
        } else if (token1 == token2) {
            sendFunds_Untrusted_Unguarded(to, token1, add(amount1, amount2));
            sendFunds_Untrusted_Unguarded(to, token3, amount3);
        } else if (token1 == token3) {
            sendFunds_Untrusted_Unguarded(to, token1, add(amount1, amount3));
            sendFunds_Untrusted_Unguarded(to, token2, amount2);
        } else if (token2 == token3) {
            sendFunds_Untrusted_Unguarded(to, token1, amount1);
            sendFunds_Untrusted_Unguarded(to, token2, add(amount2, amount3));
        } else {
            sendFunds_Untrusted_Unguarded(to, token1, amount1);
            sendFunds_Untrusted_Unguarded(to, token2, amount2);
            sendFunds_Untrusted_Unguarded(to, token3, amount3);
        }
    }

    /// @notice A helper function that sets the final resolution for the agreement, and
    /// also distributes funds to the participants based on distributeFundsToParties and
    /// distributeFundsToArbitrator.
    function finalizeResolution_Untrusted_Unguarded(
        uint agreementID,
        AgreementDataERC20 storage agreement,
        uint48 resA,
        uint48 resB,
        bool distributeFundsToParties,
        bool distributeFundsToArbitrator
    )
        internal
    {
        agreement.resolutionTokenA = resA;
        agreement.resolutionTokenB = resB;
        calculateDisputeFeeLiability(agreementID, agreement);
        if (distributeFundsToParties) {
            emit FundsDistributed(uint32(agreementID));
            // These calls are not "Reentrancy Safe" (see AgreementManager.sol comments).
            // Using reentrancy guard.
            bool previousValue = getThenSetPendingExternalCall(agreement, true);
            distributeFundsToPartyHelper_Untrusted_Unguarded(agreementID, agreement, Party.A);
            distributeFundsToPartyHelper_Untrusted_Unguarded(agreementID, agreement, Party.B);
            setPendingExternalCall(agreement, previousValue);
        }
        if (distributeFundsToArbitrator) {
            distributeFundsToArbitratorHelper_Untrusted_Unguarded(agreementID, agreement);
        }
    }

    /// @notice This can only be called after a resolution is established.
    /// A helper function to distribute funds owed to a party based on the resolution and any
    /// arbitration fee refund they're owed.
    /// Assumes that a resolution exists.
    function distributeFundsToPartyHelper_Untrusted_Unguarded(
        uint agreementID,
        AgreementDataERC20 storage agreement,
        Party party
    )
        internal
    {
        require(!partyReceivedDistribution(agreement, party), "party already received funds.");
        setPartyReceivedDistribution(agreement, party, true);

        uint distributionAmountA = 0;
        uint distributionAmountB = 0;
        if (party == Party.A) {
            distributionAmountA = agreement.resolutionTokenA;
            distributionAmountB = agreement.resolutionTokenB;
        } else {
            distributionAmountA = sub(agreement.partyAStakeAmount, agreement.resolutionTokenA);
            distributionAmountB = sub(agreement.partyBStakeAmount, agreement.resolutionTokenB);
        }

        uint arbRefundWei = getPartyArbitrationRefundInWei(agreementID, agreement, party);

        executeDistribution_Untrusted_Unguarded(
            partyAddress(agreement, party),
            agreement.partyAToken, toWei(distributionAmountA, agreement.partyATokenPower),
            agreement.partyBToken, toWei(distributionAmountB, agreement.partyBTokenPower),
            agreement.arbitratorToken, arbRefundWei);
    }

    /// @notice A helper function to distribute funds owed to the arbitrator. These funds can be
    /// distributed either when the arbitrator calls withdrawDisputeFee or resolveAsArbitrator.
    function distributeFundsToArbitratorHelper_Untrusted_Unguarded(
        uint agreementID,
        AgreementDataERC20 storage agreement
    )
        internal
    {
        require(!arbitratorReceivedDisputeFee(agreement), "Already received dispute fee.");
        setArbitratorReceivedDisputeFee(agreement, true);

        emit ArbitratorReceivedDisputeFee(uint32(agreementID));

        sendFunds_Untrusted_Unguarded(
            agreement.arbitratorAddress,
            agreement.arbitratorToken,
            toWei(agreement.disputeFee, agreement.arbitratorTokenPower)
        );
    }

    /// @notice Calculate and store in state variables who is responsible for paying any
    /// arbitration fee (if it was paid).
    /// @dev
    /// We set PARTY_A_DISPUTE_FEE_LIABILITY if partyA needs to pay some portion of the fee.
    /// We set PARTY_B_DISPUTE_FEE_LIABILITY if partyB needs to pay some portion of the fee.
    /// If both of the above values are true, then partyA and partyB are each liable for half of
    /// the arbitration fee.
    function calculateDisputeFeeLiability(
        uint argreementID,
        AgreementDataERC20 storage agreement
    )
        internal
    {
        // If arbitrator hasn't or won't get the dispute fee, there's no liability.
        if (!arbitratorGetsDisputeFee(argreementID, agreement)) {
            return;
        }

        // If A and B have compatible resolutions, then the arbitrator never issued a
        // ruling. Whichever of partyA and partyB resolved latest should have to pay the full
        // fee (because if they had resolved earlier, the arbitrator would never have had to be
        // called). See comments for PARTY_A_RESOLVED_LAST.
        if (
            resolutionsAreCompatibleBothExist(
                agreement,
                agreement.partyAResolutionTokenA,
                agreement.partyAResolutionTokenB,
                agreement.partyBResolutionTokenA,
                agreement.partyBResolutionTokenB,
                Party.A
            )
        ) {
            if (partyAResolvedLast(agreement)) {
                setPartyDisputeFeeLiability(agreement, Party.A, true);
            } else {
                setPartyDisputeFeeLiability(agreement, Party.B, true);
            }
            return;
        }

        // Now we know the parties rulings are not compatible with each other. If the ruling
        // from the arbitrator is compatible with either party, that party pays no fee and the
        // other party pays the full fee. Otherwise the parties are both liable for half the fee.
        if (
            resolutionsAreCompatibleBothExist(
                agreement,
                agreement.partyAResolutionTokenA,
                agreement.partyAResolutionTokenB,
                agreement.resolutionTokenA,
                agreement.resolutionTokenB,
                Party.A
            )
        ) {
            setPartyDisputeFeeLiability(agreement, Party.B, true);
        } else if (
            resolutionsAreCompatibleBothExist(
                agreement,
                agreement.partyBResolutionTokenA,
                agreement.partyBResolutionTokenB,
                agreement.resolutionTokenA,
                agreement.resolutionTokenB,
                Party.B
            )
        ) {
            setPartyDisputeFeeLiability(agreement, Party.A, true);
        } else {
            setPartyDisputeFeeLiability(agreement, Party.A, true);
            setPartyDisputeFeeLiability(agreement, Party.B, true);
        }
    }

    /// @return whether the arbitrator has either already gotten or is entitled to withdraw
    /// the dispute fee
    function arbitratorGetsDisputeFee(
        uint argreementID,
        AgreementDataERC20 storage agreement
    )
        internal
        returns (bool);
}

