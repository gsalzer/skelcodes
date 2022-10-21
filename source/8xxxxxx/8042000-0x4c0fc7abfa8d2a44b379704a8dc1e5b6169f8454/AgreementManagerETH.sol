pragma solidity 0.5.3;

import "./AgreementManager.sol";

/**
    @notice
    See AgreementManager for comments on the overall nature of this contract.

    This is the contract defining how ETH-only agreements work.

    @dev
    The relevant part of the inheritance tree is:
    AgreementManager
        AgreementManagerETH
            AgreementManagerETH_Simple
            AgreementManagerETH_ERC792
*/

contract AgreementManagerETH is AgreementManager {
    // -------------------------------------------------------------------------------------------
    // --------------------------------- special values ------------------------------------------
    // -------------------------------------------------------------------------------------------

    // We store ETH amounts in millionths of ETH, not Wei. So we need to do conversions using this
    // factor. 10^6 * 10^12 = 10^18, the number of wei in one Ether
    uint constant ETH_AMOUNT_ADJUST_FACTOR = 1000*1000*1000*1000;

    // -------------------------------------------------------------------------------------------
    // ------------------------------------- events ----------------------------------------------
    // -------------------------------------------------------------------------------------------

    event PartyResolved(uint32 indexed agreementID, uint resolution);

    // -------------------------------------------------------------------------------------------
    // -------------------------------- struct definitions ---------------------------------------
    // -------------------------------------------------------------------------------------------

    /** Whenever an agreement is created, we store its state in an AgreementDataETH object. One of
    the main differences between this contract and the ERC20 version is the struct that they use
    to store agreement data. This struct is smaller than the one needed for ERC20. The variables
    are arranged so that the compiler can easily "pack" them into 4 uint256s under the hood. Look
    at the comments for createAgreementA to see what all these variables represent.
    Spacing shows the uint256s that we expect these to be packed in -- there are four groups
    separated by spaces, representing the four uint256s that will be used internally.*/
    struct AgreementDataETH {
        // Put the data that can change all in the first "uint" slot, for gas cost optimization.
        uint48 partyAResolution; // Resolution for partyA
        uint48 partyBResolution; // Resolution for partyB
        // An agreement can be created with an optional "automatic" resolution which either party
        // can trigger after autoResolveAfterTimestamp.
        uint48 automaticResolution;
        // Resolution holds the "official, final" resolution of the agreement. Once this value has
        // been set, it means the agreement is over and funds can be withdrawn.
        uint48 resolution;
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

        address partyAAddress; // ETH address of party A
        uint48 partyAStakeAmount; // Amount that party A is required to stake
        // An optional arbitration fee that is sent to the arbitrator's ETH address once both
        // parties have deposited their stakes.
        uint48 partyAInitialArbitratorFee;

        address partyBAddress; // ETH address of party B
        uint48 partyBStakeAmount; // Amount that party B is required to stake
        // An optional arbitration fee that is sent to the arbitrator's ETH address once both
        // parties have deposited their stakes.
        uint48 partyBInitialArbitratorFee;

        address arbitratorAddress; // ETH address of Arbitrator
        uint48 disputeFee; // Fee paid to arbitrator only if there's a dispute and they do work.
        // The timestamp after which either party can trigger the "automatic resolution". This can
        // only be triggered if no one has requested arbitration.
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
    AgreementDataETH[] agreements;

    // -------------------------------------------------------------------------------------------
    // ---------------------------- external getter functions ------------------------------------
    // -------------------------------------------------------------------------------------------

    function getResolutionNull() external pure returns (uint) {
        return resolutionToWei(RESOLUTION_NULL);
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
        returns (address[3] memory, uint[16] memory, bool[12] memory, bytes memory);

    // -------------------------------------------------------------------------------------------
    // -------------------- main external functions that affect state ----------------------------
    // -------------------------------------------------------------------------------------------

    /**
    @notice Adds a new agreement to the agreements array.
    This is only callable by partyA. So the caller needs to rearrange addresses so that they're
    partyA. Party A needs to pay their stake as part of calling this function by sending ETH.
    @dev createAgreementA differs between versions, so is defined low in the inheritance tree.
    We don't need re-entrancy protection here because createAgreementA can't influence
    existing agreeemnts.
    @param agreementHash hash of agreement details. Not stored, just emitted in an event.
    @param agreementURI URI to 'metaEvidence' as defined in ERC 1497. Not stored, just emitted.
    @param participants :
    participants[0]: Address of partyA
    participants[1]: Address of partyB
    participants[2]: Address of arbitrator
    @param quantities :
    quantities[0]: Amount that party A is staking
    quantities[1]: Amount that party B is staking
    quantities[2]: Amount that party A pays arbitrator regardless of if there's a dispute
    quantities[3]: Amount that party B pays arbitrator regardless of if there's a dispute
    quantities[4]: Fee for arbitrator if there is a dispute
    quantities[5]: Amount of wei to go to party A if an automatic resolution is triggered.
    quantities[6]: 16 bit value, # of days to respond to arbitration request
    quantities[7]: 32 bit timestamp value before which arbitration can't be requested.
    quantities[8]: 32 bit timestamp value after which auto-resolution is allowed if no one
                   requested arbitration. 0 means never.
    @param arbExtraData Data to pass in to ERC792 arbitrator if a dispute is ever created. Use
    null when creating non-ERC792 agreements
    @return the agreement id of the newly added agreement*/
    function createAgreementA(
        bytes32 agreementHash,
        string calldata agreementURI,
        address[3] calldata participants,
        uint[9] calldata quantities,
        bytes calldata arbExtraData
    )
        external
        payable
        returns (uint)
    {
        require(msg.sender == participants[0], "Only party A can call createAgreementA.");
        require(msg.value == add(quantities[0], quantities[2]), "Payment not correct.");
        require(
            (
                participants[0] != participants[1] &&
                participants[0] != participants[2] &&
                participants[1] != participants[2]
            ),
            "partyA, partyB, and arbitrator addresses must be unique."
        );
        require(
            quantities[6] >= 1 && quantities[6] <= MAX_DAYS_TO_RESPOND_TO_ARBITRATION_REQUEST,
            "Days to respond to arbitration was out of range."
        );

        // Populate a AgreementDataETH struct with the info provided.
        AgreementDataETH memory agreement;
        agreement.partyAAddress = participants[0];
        agreement.partyBAddress = participants[1];
        agreement.arbitratorAddress = participants[2];
        agreement.partyAResolution = RESOLUTION_NULL;
        agreement.partyBResolution = RESOLUTION_NULL;
        agreement.resolution = RESOLUTION_NULL;
        agreement.partyAStakeAmount = toMillionth(quantities[0]);
        agreement.partyBStakeAmount = toMillionth(quantities[1]);
        uint sumOfStakes = add(agreement.partyAStakeAmount, agreement.partyBStakeAmount);
        require(sumOfStakes < RESOLUTION_NULL, "Stake amounts were too large.");
        agreement.partyAInitialArbitratorFee = toMillionth(quantities[2]);
        agreement.partyBInitialArbitratorFee = toMillionth(quantities[3]);
        agreement.disputeFee = toMillionth(quantities[4]);
        agreement.automaticResolution = toMillionth(quantities[5]);
        require(agreement.automaticResolution <= sumOfStakes, "Automatic resolution too large.");
        agreement.daysToRespondToArbitrationRequest = toUint16(quantities[6]);
        agreement.nextArbitrationStepAllowedAfterTimestamp = toUint32(quantities[7]);
        agreement.autoResolveAfterTimestamp = toUint32(quantities[8]);
        // set boolean values
        uint32 tempBools = setBool(0, PARTY_A_STAKE_PAID, true);
        if (add(quantities[1], quantities[3]) == 0) {
            tempBools = setBool(tempBools, PARTY_B_STAKE_PAID, true);
        }
        agreement.boolValues = tempBools;

        // Add the new agreement to our array and create the agreementID
        uint agreementID = sub(agreements.push(agreement), 1);

        // This is a function because we want it to be a no-op for non-ERC792 agreements.
        storeArbitrationExtraData(agreementID, arbExtraData);

        emitAgreementCreationEvents(agreementID, agreementHash, agreementURI);

        // Pay the arbitrator if needed, which happens if B was staking no funds and needed no
        // initial fee, but there was an initial fee from A.
        if ((add(quantities[1], quantities[3]) == 0) && (quantities[2] > 0)) {
            payOutInitialArbitratorFee_Untrusted_Unguarded(agreementID);
        }
        return agreementID;
    }

    /// @notice Called by PartyB to deposit their stake, locking in the agreement so no one can
    /// unilaterally withdraw. PartyA already deposited funds in createAgreementA, so we only need
    /// a deposit function for partyB.
    function depositB(uint agreementID) external payable {
        AgreementDataETH storage agreement = agreements[agreementID];

        require(!pendingExternalCall(agreement), "Reentrancy protection is on.");
        require(agreementIsOpen(agreement), "Agreement not open.");
        require(msg.sender == agreement.partyBAddress, "Function can only be called by party B.");
        require(!partyStakePaid(agreement, Party.B), "Party B already deposited their stake.");
        // No need to check that party A deposited: they can't create an agreement otherwise.

        require(
            msg.value == toWei(
                add(agreement.partyBStakeAmount, agreement.partyBInitialArbitratorFee)
            ),
            "Party B deposit amount was unexpected."
        );

        setPartyStakePaid(agreement, Party.B, true);

        emit PartyBDeposited(uint32(agreementID));

        if (add(agreement.partyAInitialArbitratorFee, agreement.partyBInitialArbitratorFee) > 0) {
            payOutInitialArbitratorFee_Untrusted_Unguarded(agreementID);
        }
    }

    /// @notice Called to report a resolution of the agreement by a party. The resolution
    /// specifies how funds should be distributed between the parties.
    /// @param resolutionWei The amount of wei that the caller thinks should go to party A.
    /// The remaining amount of wei staked for this agreement would go to party B.
    /// @param distributeFunds Whether to distribute funds to the two parties if this call
    /// results in an official resolution to the agreement.
    function resolveAsParty(uint agreementID, uint resolutionWei, bool distributeFunds) external {
        AgreementDataETH storage agreement = agreements[agreementID];

        require(!pendingExternalCall(agreement), "Reentrancy protection is on.");
        require(agreementIsOpen(agreement), "Agreement not open.");
        require(agreementIsLockedIn(agreement), "Agreement not locked in.");

        uint48 res = toMillionth(resolutionWei);
        require(
            res <= add(agreement.partyAStakeAmount, agreement.partyBStakeAmount),
            "Resolution out of range."
        );

        (Party callingParty, Party otherParty) = getCallingPartyAndOtherParty(agreement);

        // Keep track of who was the last to resolve.. useful for punishing 'late' resolutions.
        // We check the existing state of partyAResolvedLast only as a perf optimization,
        // to avoid unnecessary writes.
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
            // If new resolution isn't compatible with the existing one, then the caller
            // made the resolution more favorable to themself.
            // We know that an old resolution exists because for the caller to be closer to
            // winning a default judgment they must have requested arbitration, and they can only
            // request arbitration after resolving.
            if (
                !resolutionsAreCompatibleBothExist(
                    res,
                    partyResolution(agreement, callingParty),
                    callingParty
                )
            ) {
                updateArbitrationResponseDeadline(agreement);
            }
        }

        setPartyResolution(agreement, callingParty, res);

        emit PartyResolved(uint32(agreementID), resolutionWei);

        // If the resolution is 'compatible' with that of the other person, make it the
        // final resolution.
        uint otherRes = partyResolution(agreement, otherParty);
        if (resolutionsAreCompatible(agreement, res, otherRes, callingParty)) {
            finalizeResolution_Untrusted_Unguarded(
                agreementID,
                agreement,
                res,
                distributeFunds,
                false
            );
        }
    }

    /// @notice If A calls createAgreementA but B is delaying in calling depositB, A can get their
    /// funds back by calling earlyWithdrawA. This closes the agreement to further deposits. A or
    /// B would have to call createAgreementA again if they still wanted to do an agreement.
    function earlyWithdrawA(uint agreementID) external {
        AgreementDataETH storage agreement = agreements[agreementID];

        require(!pendingExternalCall(agreement), "Reentrancy protection is on");
        require(agreementIsOpen(agreement), "Agreement not open.");
        require(msg.sender == agreement.partyAAddress, "withdrawA must be called by party A.");
        require(
            partyStakePaid(agreement, Party.A) && !partyStakePaid(agreement, Party.B),
            "Early withdraw not allowed."
        );
        require(!partyReceivedDistribution(agreement, Party.A), "partyA already received funds.");

        setPartyReceivedDistribution(agreement, Party.A, true);

        emit PartyAWithdrewEarly(uint32(agreementID));

        msg.sender.transfer(
            toWei(add(agreement.partyAStakeAmount, agreement.partyAInitialArbitratorFee))
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
        AgreementDataETH storage agreement = agreements[agreementID];
        require(!pendingExternalCall(agreement), "Reentrancy protection is on");
        require(agreement.resolution != RESOLUTION_NULL, "Agreement is not resolved.");

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
        AgreementDataETH storage agreement = agreements[agreementID];

        require(!pendingExternalCall(agreement), "Reentrancy protection is on");
        require(agreementIsOpen(agreement), "Agreement not open.");
        require(agreementIsLockedIn(agreement), "Agreement not locked in.");

        (Party callingParty, Party otherParty) = getCallingPartyAndOtherParty(agreement);

        require(
            RESOLUTION_NULL != partyResolution(agreement, callingParty),
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

        finalizeResolution_Untrusted_Unguarded(
            agreementID,
            agreement,
            partyResolution(agreement, callingParty),
            distributeFunds,
            false
        );
    }

    /// @notice If enough time has elapsed, either party can trigger auto-resolution (if enabled)
    /// by calling this function, provided that neither party has requested arbitration yet.
    /// @param distributeFunds Whether to distribute funds to both parties
    function requestAutomaticResolution(uint agreementID, bool distributeFunds) external {
        AgreementDataETH storage agreement = agreements[agreementID];

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
            agreement.automaticResolution,
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
        AgreementDataETH storage agreement = agreements[agreementID];

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

    // Functions that simulate direct access to AgreementDataETH state variables. These are used
    // either for bools (where we need to use a bitmask), or for functions when we need to vary
    // between party A/B depending on the argument. The later is necessary because the solidity
    // compiler can't pack structs well when their elements are arrays. So we can't just index
    // into an array.

    // ------------- Some getter functions ---------------

    function partyResolution(
        AgreementDataETH storage agreement,
        Party party
    )
        internal
        view
        returns (uint48)
    {
        if (party == Party.A) return agreement.partyAResolution;
        else return agreement.partyBResolution;
    }

    function partyAddress(
        AgreementDataETH storage agreement,
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
        AgreementDataETH storage agreement,
        Party party
    )
        internal
        view
        returns (bool)
    {
        if (party == Party.A) return getBool(agreement.boolValues, PARTY_A_STAKE_PAID);
        else return getBool(agreement.boolValues, PARTY_B_STAKE_PAID);
    }

    function partyRequestedArbitration(
        AgreementDataETH storage agreement,
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
        AgreementDataETH storage agreement,
        Party party
    )
        internal
        view
        returns (bool)
    {
        if (party == Party.A) return getBool(agreement.boolValues, PARTY_A_RECEIVED_DISTRIBUTION);
        else return getBool(agreement.boolValues, PARTY_B_RECEIVED_DISTRIBUTION);
    }

    function partyAResolvedLast(AgreementDataETH storage agreement) internal view returns (bool) {
        return getBool(agreement.boolValues, PARTY_A_RESOLVED_LAST);
    }

    function arbitratorResolved(AgreementDataETH storage agreement) internal view returns (bool) {
        return getBool(agreement.boolValues, ARBITRATOR_RESOLVED);
    }

    function arbitratorReceivedDisputeFee(
        AgreementDataETH storage agreement
    )
        internal
        view
        returns (bool)
    {
        return getBool(agreement.boolValues, ARBITRATOR_RECEIVED_DISPUTE_FEE);
    }

    function partyDisputeFeeLiability(
        AgreementDataETH storage agreement,
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
        AgreementDataETH storage agreement
    )
        internal
        view
        returns (bool)
    {
        return getBool(agreement.boolValues, PENDING_EXTERNAL_CALL);
    }

    // ------------- Some setter functions ---------------

    function setPartyResolution(
        AgreementDataETH storage agreement,
        Party party,
        uint48 value
    )
        internal
    {
        if (party == Party.A) agreement.partyAResolution = value;
        else agreement.partyBResolution = value;
    }

    function setPartyStakePaid(
        AgreementDataETH storage agreement,
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
        AgreementDataETH storage agreement,
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
        AgreementDataETH storage agreement,
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

    function setPartyAResolvedLast(AgreementDataETH storage agreement, bool value) internal {
        agreement.boolValues = setBool(agreement.boolValues, PARTY_A_RESOLVED_LAST, value);
    }

    function setArbitratorResolved(AgreementDataETH storage agreement, bool value) internal {
        agreement.boolValues = setBool(agreement.boolValues, ARBITRATOR_RESOLVED, value);
    }

    function setArbitratorReceivedDisputeFee(
        AgreementDataETH storage agreement,
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
        AgreementDataETH storage agreement,
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

    function setPendingExternalCall(AgreementDataETH storage agreement, bool value) internal {
        agreement.boolValues = setBool(agreement.boolValues, PENDING_EXTERNAL_CALL, value);
    }

    /// @notice set the value of PENDING_EXTERNAL_CALL and return the previous value.
    function getThenSetPendingExternalCall(
        AgreementDataETH storage agreement,
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
    // ----------------------------- internal helper functions -----------------------------------
    // -------------------------------------------------------------------------------------------

    /// @notice We store ETH/token amounts in uint48s demoninated in "millionths of ETH." toWei
    /// converts from our internal representation to the wei amount.
    /// @param millionthValue millionths of ETH that we want to convert
    /// @return the wei value of millionthValue
    function toWei(uint millionthValue) internal pure returns (uint) {
        return mul(millionthValue, ETH_AMOUNT_ADJUST_FACTOR);
    }

    /// @notice Like toWei, but resolutionToWei is for "resolution" values which might have a
    /// special value of RESOLUTION_NULL, which we need to handle separately.
    /// @param millionthValue millionths of ETH that we want to convert
    /// @return the wei value of millionthValue
    function resolutionToWei(uint millionthValue) internal pure returns (uint) {
        if (millionthValue == RESOLUTION_NULL) {
            return uint(~0); // set all bits of a uint to 1
        }
        return mul(millionthValue, ETH_AMOUNT_ADJUST_FACTOR);
    }

    /// @notice Convert a value expressed in wei to our internal representation in "millionths of
    /// ETH"
    function toMillionth(uint weiValue) internal pure returns (uint48) {
        return toUint48(weiValue / ETH_AMOUNT_ADJUST_FACTOR);
    }

    /// @notice Requires that the caller be party A or party B.
    /// @return whichever party the caller is.
    function getCallingParty(AgreementDataETH storage agreement) internal view returns (Party) {
        if (msg.sender == agreement.partyAAddress) {
            return Party.A;
        } else if (msg.sender == agreement.partyBAddress) {
            return Party.B;
        } else {
            require(false, "getCallingParty must be called by a party to the agreement.");
        }
    }

    /// @notice Returns the "other" party.
    function getOtherParty(Party party) internal pure returns (Party) {
        if (party == Party.A) {
            return Party.B;
        }
        return Party.A;
    }

    /// @notice Fails if called by anyone other than a party.
    /// @return the calling party first and the "other party" second.
    function getCallingPartyAndOtherParty(
        AgreementDataETH storage agreement
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
        uint resolution,
        uint otherResolution,
        Party resolutionParty
    )
        internal
        pure
        returns (bool)
    {
        if (resolutionParty == Party.A) {
            return resolution <= otherResolution;
        } else {
            return resolution >= otherResolution;
        }
    }

    /// @notice Compatible means that the participants don't disagree in a selfish direction.
    /// Alternatively, it means that we know some resolution will satisfy both parties.
    /// If one person resolves to give the other person the maximum possible amount, this is
    /// always compatible with the other person's resolution, even if that resolution is
    /// RESOLUTION_NULL. Otherwise, one person having a resolution of RESOLUTION_NULL
    /// implies the resolutions are not compatible.
    /// @param resolution Must be a resolution provided by either party A or party B, and this
    /// resolution must not be RESOLUTION_NULL
    /// @param otherResolution The resolution from either the other party or by the arbitrator.
    /// This resolution can be RESOLUTION_NULL.
    /// @param resolutionParty The party corresponding to the resolution provided by the
    /// 'resolution' parameter.
    /// @return whether the resolutions are compatible.
    function resolutionsAreCompatible(
        AgreementDataETH storage agreement,
        uint resolution,
        uint otherResolution,
        Party resolutionParty
    )
        internal
        view
        returns (bool)
    {
        // If we're not dealing with the NULL case, we can use resolutionsAreCompatibleBothExist
        if (otherResolution != RESOLUTION_NULL) {
            return resolutionsAreCompatibleBothExist(
                resolution,
                otherResolution,
                resolutionParty
            );
        }

        // Now we know otherResolution is RESOLUTION_NULL.
        // See if resolutionParty wants to give all funds to the other party.
        if (resolutionParty == Party.A) {
            // only 0 from Party A is compatible with RESOLUTION_NULL
            return resolution == 0;
        } else {
            // only the max possible amount from Party B is compatible with RESOLUTION_NULL
            return resolution == add(agreement.partyAStakeAmount, agreement.partyBStakeAmount);
        }
    }

    /// @return Whether the party provided is closer to winning a default judgment than the other
    /// party.
    function partyIsCloserToWinningDefaultJudgment(
        uint agreementID,
        AgreementDataETH storage agreement,
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
        AgreementDataETH storage agreement,
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

    /// @dev '_Sometimes_Untrusted_Guarded' means that in some inheriting contracts it's
    /// _Untrusted_Guarded, in some it isn't. Look at the implementation in the specific
    /// contract you're interested in to know.
    function partyFullyPaidDisputeFee_Sometimes_Untrusted_Guarded(
        uint agreementID,
        AgreementDataETH storage agreement,
        Party party
    )
        internal
        returns (bool);

    /// @notice 'Open' means people should be allowed to take steps toward a future resolution.
    /// An agreement isn't open after it has ended (a final resolution exists), or if someone
    /// withdrew their funds before the second party could deposit theirs.
    /// @dev partyB can't do an early withdrawal, so we only need to check if partyA withdrew
    function agreementIsOpen(AgreementDataETH storage agreement) internal view returns (bool) {
        return agreement.resolution == RESOLUTION_NULL &&
            !partyReceivedDistribution(agreement, Party.A);

    }

    /// @notice 'Locked in' means both parties have deposited their stake. It conveys that the
    /// agreement is fully accepted and no one can withdraw without someone else's approval.
    function agreementIsLockedIn(
        AgreementDataETH storage agreement
    )
        internal
        view
        returns (bool)
    {
        return partyStakePaid(agreement, Party.A) && partyStakePaid(agreement, Party.B);
    }

    /// @notice When both parties have deposited their stakes, the arbitrator is paid any
    /// 'initial' arbitration fee that was required. We assume we've already checked that the
    /// arbitrator is owed a nonzero amount.
    function payOutInitialArbitratorFee_Untrusted_Unguarded(uint agreementID) internal {
        AgreementDataETH storage agreement = agreements[agreementID];

        uint totalInitialFeesWei = toWei(
            add(agreement.partyAInitialArbitratorFee, agreement.partyBInitialArbitratorFee)
        );

        // Convert address to make it payable
        address(uint160(agreement.arbitratorAddress)).transfer(totalInitialFeesWei);
    }

    /// @notice Set or extend the deadline for both parties to pay the arbitration fee.
    function updateArbitrationResponseDeadline(AgreementDataETH storage agreement) internal {
        agreement.nextArbitrationStepAllowedAfterTimestamp =
            toUint32(
                add(
                    block.timestamp,
                    mul(agreement.daysToRespondToArbitrationRequest, (1 days))
                )
            );
    }

    /// @notice A helper function that sets the final resolution for the agreement, and
    /// also distributes funds to the participants based on distributeFundsToParties and
    /// distributeFundsToArbitrator.
    function finalizeResolution_Untrusted_Unguarded(
        uint agreementID,
        AgreementDataETH storage agreement,
        uint48 res,
        bool distributeFundsToParties,
        bool distributeFundsToArbitrator
    )
        internal
    {
        agreement.resolution = res;
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
        AgreementDataETH storage agreement,
        Party party
    )
        internal
    {
        require(!partyReceivedDistribution(agreement, party), "party already received funds.");
        setPartyReceivedDistribution(agreement, party, true);

        uint distributionAmount = 0;
        if (party == Party.A) {
            distributionAmount = agreement.resolution;
        } else {
            distributionAmount = sub(
                add(agreement.partyAStakeAmount, agreement.partyBStakeAmount),
                agreement.resolution
            );
        }

        uint distributionWei = add(
            toWei(distributionAmount),
            getPartyArbitrationRefundInWei(agreementID, agreement, party)
        );

        if (distributionWei > 0) {
            // Need to do this conversion to make the address payable
            address(uint160(partyAddress(agreement, party))).transfer(distributionWei);
        }
    }

    /// @notice A helper function to distribute funds owed to the arbitrator. These funds can be
    /// distributed either when the arbitrator calls withdrawDisputeFee or resolveAsArbitrator.
    function distributeFundsToArbitratorHelper_Untrusted_Unguarded(
        uint agreementID,
        AgreementDataETH storage agreement
    )
        internal
    {
        require(!arbitratorReceivedDisputeFee(agreement), "Already received dispute fee.");
        setArbitratorReceivedDisputeFee(agreement, true);

        emit ArbitratorReceivedDisputeFee(uint32(agreementID));

        uint feeAmount = agreement.disputeFee;
        if (feeAmount > 0) {
            address(uint160(agreement.arbitratorAddress)).transfer(toWei(feeAmount));
        }
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
        AgreementDataETH storage agreement
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
                agreement.partyAResolution,
                agreement.partyBResolution,
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
                agreement.partyAResolution,
                agreement.resolution,
                Party.A
            )
        ) {
            setPartyDisputeFeeLiability(agreement, Party.B, true);
        } else if (
            resolutionsAreCompatibleBothExist(
                agreement.partyBResolution,
                agreement.resolution,
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
        AgreementDataETH storage agreement
    )
        internal
        returns (bool);
}
