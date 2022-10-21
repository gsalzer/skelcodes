//Copyright Octobase.co 2019
pragma solidity ^0.5.1;

import "./safemath.sol";
import "./statuscodes.sol";
import "./interfaces.sol";

contract RoundTable
{
    using SafeMath for uint256;

    //Structs
    enum GuardianRoundTableState
    {
        Unknown, //0x00 Never a valid response, due to 0x00 being the default RPC response
        NoActiveProposal, //0x01
        NeedToVote, //0x02
        SupportedProposal, //0x03
        OpposedProposal, //0x04
        NotAGuardian //0x05
    }

    enum GuardianWardState
    {
        Unknown, //0x00 Never a valid response, due to 0x00 being the default RPC response
        Active, //0x01
        AwaitingProposal, //0x02 Ward frozen and no proposal for a new owner exists
        NeedToVote, //0x03
        SupportedProposal, //0x04
        OpposedProposal, //0x05
        NotAGuardian //0x06
    }

    struct ChangeOwnerProposal
    {
        uint id;
        ProposalExecutionState state;
        address newOwner;
        uint totalVotesCast;
        uint totalSupportingVotes;
        uint totalOpposingVotes;
        mapping (address => Vote) votes;
        uint dateProposed;
        uint256 dateResolved;
    }

    enum ProposalExecutionState
    {
        poposalDoesNotExist, //0x00
        inProgress, //0x01
        passed, //0x02
        defeated //0x03
    }

    struct ChangeRoundTableProposal
    {
        uint id;
        ProposalExecutionState state;
        IRoundTable newRoundTable;
        uint totalVotesCast;
        uint totalSupportingVotes;
        uint totalOpposingVotes;
        mapping (address => Vote) votes;
        uint dateProposed;
        uint256 dateResolved;
    }

    function getRoundTableVote(uint256 _id, uint256 _guardianIndex)
        public
        view
        returns(Vote _result)
    {
        return changeRoundTableProposals[_id].votes[guardians[_guardianIndex]];
    }

    function getOwnerVote(uint256 _id, uint256 _guardianIndex)
        public
        view
        returns(Vote _result)
    {
        return changeOwnerProposals[_id].votes[guardians[_guardianIndex]];
    }

    function getWardRoundTableVote(uint256 _id)
        public
        view
        returns(Vote _result)
    {
        return changeRoundTableProposals[_id].votes[address(ward)];
    }

    function getWardOwnerVote(uint256 _id)
        public
        view
        returns(Vote _result)
    {
        return changeOwnerProposals[_id].votes[address(ward)];
    }

    enum Vote
    {
        notVoted, //0x00
        support, //0x01
        oppose //0x02
    }

    //Events
    event FreezeWard(address indexed freezer, ISigner indexed ward);
    event ProposeOwnerChange(
        address indexed proposer,
        ISigner indexed ward,
        address indexed owner,
        uint256 proposalId);
    event ProposeRoundTableChange(
        address indexed _proposer,
        ISigner indexed _ward,
        IRoundTable indexed _newRoundTable,
        uint256 proposalId);
    event VoteOnChangeOwner(address indexed voter, ISigner indexed ward, uint256 proposalId, bool isInSupport);
    event VoteOnChangeRoundTable(address indexed voter, ISigner indexed ward, uint256 proposalId, bool isInSupport);
    event ResolveChangeOwner(address indexed resolver, ISigner indexed ward, uint256 proposalId, bool isPassed);
    event ResolveChangeRoundTable(address indexed resolver, ISigner indexed ward, uint256 proposalId, bool isPassed);

    //State
    uint256 constant cooldownPeriod = 7 days;

    address[] public guardians;
    mapping(address => bool) public guardianMappings;
    uint256 public guardianCount;
    ISigner public ward;

    uint public supportingVotesThreshold;
    ChangeOwnerProposal[] public changeOwnerProposals;
    ChangeRoundTableProposal[] public changeRoundTableProposals;

    IRoundTableFactory public parentFactory;

    constructor(
            ISigner _ward,
            address[] memory _guardians,
            IRoundTableFactory _parentFactory)
        public
    {
        require(_guardians.length > 0, "Needs at least 1 guardian");

        for (uint index = 0; index < _guardians.length; index++)
        {
            address guardian = _guardians[index];
            guardianMappings[guardian] = true;
            guardians.push(guardian);
        }
        guardianCount = _guardians.length;
        supportingVotesThreshold = guardianCount.add(1).div(2).add(1); // half the the guardians+ward is the new threshold
        ward = _ward;
        parentFactory = _parentFactory;
    }

    modifier onlyGuardians() {
        require(guardianMappings[msg.sender], "Only Guardians");
        _;
    }

    modifier onlyWard() {
        require(address(ward) == msg.sender, "Only ward");
        _;
    }

    modifier onlyGuardiansOrWard() {
        require(address(ward) == msg.sender || guardianMappings[msg.sender], "Only guardians or wards");
        _;
    }

    function freezeWard(address _owner)
        external
        onlyGuardians
        returns (StatusCodes.Status status)
    {
        StatusCodes.Status result = ward.freeze(_owner);
        require(result == StatusCodes.Status.Success || result == StatusCodes.Status.AlreadyDone, "Error attempting to freeze signer");

        emit FreezeWard(msg.sender, ward);
        return result;
    }

    function hasActiveProposal()
        public
        view
        returns(bool)
    {
        if (changeOwnerProposals.length > 0)
        {
            ChangeOwnerProposal storage lastProposal = changeOwnerProposals[changeOwnerProposals.length.sub(1)];
            if(lastProposal.state == ProposalExecutionState.inProgress)
                return true;
        }

        if (changeRoundTableProposals.length > 0)
        {
            ChangeRoundTableProposal storage lastProposal = changeRoundTableProposals[changeRoundTableProposals.length.sub(1)];
            if (lastProposal.state == ProposalExecutionState.inProgress)
                return true;
        }

        return false;
    }

    function supportedRecentDefeatedProposal(address _sender)
        public
        view
        returns(bool)
    {
        if (changeOwnerProposals.length > 0)
        {
            ChangeOwnerProposal storage lastChangeOwnerProposal = changeOwnerProposals[changeOwnerProposals.length.sub(1)];
            if (lastChangeOwnerProposal.state == ProposalExecutionState.defeated &&
                lastChangeOwnerProposal.votes[_sender] == Vote.support &&
                lastChangeOwnerProposal.dateResolved >= block.timestamp.sub(1 days))
            {
                return true;
            }
        }

        if (changeRoundTableProposals.length > 0)
        {
            ChangeRoundTableProposal storage lastChangeRoundTableProposal = changeRoundTableProposals[changeRoundTableProposals.length.sub(1)];
            if (lastChangeRoundTableProposal.state == ProposalExecutionState.defeated &&
                lastChangeRoundTableProposal.votes[_sender] == Vote.support &&
                lastChangeRoundTableProposal.dateResolved >= block.timestamp.sub(1 days))
            {
                return true;
            }
        }

        return false;
    }

    function proposeAndSupportOwnerChange(address _newOwner, uint _proposalId)
        external
        onlyGuardians
        returns (StatusCodes.Status status)
    {
        require(ward.getAccessState() == ISigner.AccessState.Frozen, "Ward must be frozen");
        require(ward.getUsedOwnerKey(_newOwner) == false, "Owner keys cannot be reused");
        require(changeOwnerProposals.length == _proposalId, "Invalid proposalID");
        require(!hasActiveProposal(), "There can only be one active proposal");
        require(!supportedRecentDefeatedProposal(msg.sender), "Must wait 24 hours after defeat to re-propose");

        if (changeOwnerProposals.length > 0)
        {
            ChangeOwnerProposal storage lastProposal = changeOwnerProposals[changeOwnerProposals.length.sub(1)];
            require(
                lastProposal.state != ProposalExecutionState.inProgress,
                "There can only be one active proposal");
        }

        ChangeOwnerProposal memory proposal = ChangeOwnerProposal({
            id: changeOwnerProposals.length,
            state: ProposalExecutionState.inProgress,
            newOwner: _newOwner,
            totalVotesCast: 0,
            totalSupportingVotes: 0,
            totalOpposingVotes: 0,
            dateProposed: block.timestamp,
            dateResolved: 0
            });
        changeOwnerProposals.push(proposal);

        emit ProposeOwnerChange(msg.sender, ward, _newOwner, _proposalId);
        internalVoteOnChangeOwnerProposal(proposal.id, true);
        return (StatusCodes.Status.Success);
    }

    function proposeAndSupportRoundTableChange(IRoundTable _newRoundTable)
        external
        onlyWard
        returns (StatusCodes.Status status, uint proposalId)
    {
        require(!hasActiveProposal(), "There can only be one active proposal");
        require(!supportedRecentDefeatedProposal(msg.sender), "Must wait 24 hours after defeat to re-propose");

        if (changeRoundTableProposals.length > 0)
        {
            ChangeRoundTableProposal storage lastProposal = changeRoundTableProposals[changeRoundTableProposals.length.sub(1)];
            require(
                lastProposal.state != ProposalExecutionState.inProgress,
                "There can only be one active proposal");
        }

        ChangeRoundTableProposal memory proposal = ChangeRoundTableProposal({
            id: changeRoundTableProposals.length,
            state: ProposalExecutionState.inProgress,
            newRoundTable: _newRoundTable,
            totalVotesCast: 0,
            totalSupportingVotes: 0,
            totalOpposingVotes: 0,
            dateProposed: block.timestamp,
            dateResolved: 0
            });
        changeRoundTableProposals.push(proposal);
        emit ProposeRoundTableChange(
            msg.sender,
            ward,
            _newRoundTable,
            proposal.id);
        internalVoteOnChangeRoundTableProposal(proposal.id, true);
        return (StatusCodes.Status.Success, proposal.id);
    }

    function voteOnChangeOwner(uint _proposalId, bool _supportProposal)
        external
        onlyGuardiansOrWard
        returns (StatusCodes.Status status)
    {
        return internalVoteOnChangeOwnerProposal(_proposalId, _supportProposal);
    }

    function voteOnChangeRoundTableProposal(uint _proposalId, bool _supportProposal)
        external
        onlyGuardiansOrWard
        returns (StatusCodes.Status status)
    {
        return internalVoteOnChangeRoundTableProposal(_proposalId, _supportProposal);
    }

    function internalVoteOnChangeOwnerProposal(
            uint _proposalId,
            bool _supportProposal)
        internal
        returns (StatusCodes.Status status)
    {
        require(_proposalId == changeOwnerProposals.length.sub(1), "ProposalId mismatch");
        ChangeOwnerProposal storage proposal = changeOwnerProposals[_proposalId];
        if (proposal.state == ProposalExecutionState.passed)
        {
            revert ("Proposal already passed");
        }
        if (proposal.state == ProposalExecutionState.defeated)
        {
            revert ("Proposal already defeated");
        }

        Vote existingVote = proposal.votes[address(msg.sender)];
        if (existingVote == Vote.support)
        {
            proposal.totalVotesCast = proposal.totalVotesCast.sub(1);
            proposal.totalSupportingVotes = proposal.totalSupportingVotes.sub(1);
        }
        else if (existingVote == Vote.oppose)
        {
            proposal.totalVotesCast = proposal.totalVotesCast.sub(1);
            proposal.totalOpposingVotes = proposal.totalOpposingVotes.sub(1);
        }

        proposal.totalVotesCast = proposal.totalVotesCast.add(1);
        proposal.totalSupportingVotes = proposal.totalSupportingVotes.add(_supportProposal ? 1 : 0);
        proposal.totalOpposingVotes = proposal.totalOpposingVotes.add(_supportProposal ? 0 : 1);
        proposal.votes[address(msg.sender)] = _supportProposal ? Vote.support : Vote.oppose;

        emit VoteOnChangeOwner(msg.sender, ward, proposal.id, _supportProposal);

        if (proposal.totalSupportingVotes >= supportingVotesThreshold)
        {
            privateResolveChangeOwnerProposal(proposal, msg.sender, true);
        }
        else if (proposal.totalOpposingVotes > guardianCount.add(1).sub(supportingVotesThreshold))
        {
            privateResolveChangeOwnerProposal(proposal, msg.sender, false);
        }

        return StatusCodes.Status.Success;
    }

    function internalVoteOnChangeRoundTableProposal(
            uint _proposalId,
            bool _supportProposal)
        internal
        returns (StatusCodes.Status _statusCode)
    {
        require(_proposalId == changeRoundTableProposals.length.sub(1), "Not the id of the last active proposal");
        ChangeRoundTableProposal storage proposal = changeRoundTableProposals[_proposalId];
        if (proposal.state == ProposalExecutionState.passed)
        {
            revert ("Proposal already passed");
        }
        if (proposal.state == ProposalExecutionState.defeated)
        {
            revert ("Proposal already defeated");
        }

        Vote existingVote = proposal.votes[address(msg.sender)];
        if (existingVote == Vote.support)
        {
            proposal.totalVotesCast = proposal.totalVotesCast.sub(1);
            proposal.totalSupportingVotes = proposal.totalSupportingVotes.sub(1);
        }
        else if (existingVote == Vote.oppose)
        {
            proposal.totalVotesCast = proposal.totalVotesCast.sub(1);
            proposal.totalOpposingVotes = proposal.totalOpposingVotes.sub(1);
        }

        proposal.totalVotesCast = proposal.totalVotesCast.add(1);
        proposal.totalSupportingVotes = proposal.totalSupportingVotes.add(_supportProposal ? 1 : 0);
        proposal.totalOpposingVotes = proposal.totalOpposingVotes.add(_supportProposal ? 0 : 1);
        proposal.votes[address(msg.sender)] = _supportProposal ? Vote.support : Vote.oppose;

        emit VoteOnChangeRoundTable(msg.sender, ward, proposal.id, _supportProposal);

        if (proposal.totalSupportingVotes >= supportingVotesThreshold)
        {
            privateResolveChangeRoundTableProposal(proposal, msg.sender, true);
        }
        else if (proposal.totalOpposingVotes > guardianCount.add(1).sub(supportingVotesThreshold))
        {
            privateResolveChangeRoundTableProposal(proposal, msg.sender, false);
        }

        return StatusCodes.Status.Success;
    }

    function executeChangeOwnerProposal(uint _proposalId)
        external
    {
        ChangeOwnerProposal storage proposal = changeOwnerProposals[_proposalId];
        require(proposal.state == ProposalExecutionState.inProgress, "The proposal has been executed");
        if (proposal.dateProposed <= block.timestamp.sub(cooldownPeriod))
        {
            privateResolveChangeOwnerProposal(
                proposal,
                msg.sender,
                proposal.totalSupportingVotes > proposal.totalOpposingVotes);
        }
        else
        {
            revert("Proposal execution failed");
        }
    }

    function privateResolveChangeOwnerProposal(
            ChangeOwnerProposal storage _proposal,
            address _resolver,
            bool _passed)
        private
        returns (StatusCodes.Status Status)
    {
        if(_passed)
        {
            ward.changeOwner(_proposal.newOwner);
            _proposal.state = ProposalExecutionState.passed;
        }
        else
        {
            _proposal.state = ProposalExecutionState.defeated;
        }
        _proposal.dateResolved = block.timestamp;
        emit ResolveChangeOwner(_resolver, ward, _proposal.id, _passed);
        return StatusCodes.Status.Success;
    }

    function executeChangeRoundTableProposal(uint _proposalId)
        external
    {
        ChangeRoundTableProposal storage proposal = changeRoundTableProposals[_proposalId];
        require(proposal.state == ProposalExecutionState.inProgress, "The proposal has been executed");
        if (proposal.dateProposed <= block.timestamp.sub(cooldownPeriod))
        {
            privateResolveChangeRoundTableProposal(
                proposal,
                msg.sender,
                proposal.totalSupportingVotes > proposal.totalOpposingVotes);
        }
        else
        {
            revert("Proposal execution failed");
        }
    }

    function privateResolveChangeRoundTableProposal(
            ChangeRoundTableProposal storage _proposal,
            address _resolver,
            bool _passed)
        private
        returns (StatusCodes.Status Status)
    {
        if (_passed)
        {
            ward.changeRoundTable(IRoundTable(_proposal.newRoundTable));
            _proposal.state = ProposalExecutionState.passed;
        }
        else
        {
            _proposal.state = ProposalExecutionState.defeated;
        }
        _proposal.dateResolved = block.timestamp;
        emit ResolveChangeRoundTable(_resolver, ward, _proposal.id, _passed);
        return StatusCodes.Status.Success;
    }

    function guardianChangeOwnerVote(uint256 _proposalId, address _guardian)
        external
        view
        returns(Vote vote)
    {
        if (_proposalId >= changeOwnerProposals.length) {
            return Vote.notVoted;
        }
        return changeOwnerProposals[_proposalId].votes[_guardian];
    }

    function guardianChangeRoundTableVote(uint256 _proposalId, address _guardian)
        external
        view
        returns(Vote vote)
    {
        if (_proposalId >= changeRoundTableProposals.length) {
            return Vote.notVoted;
        }

        return changeRoundTableProposals[_proposalId].votes[_guardian];
    }

    function getRoundTableStateForGuardian(address _guardian)
        external
        view
        returns(GuardianRoundTableState _guardianWardState)
    {
        if (!guardianMappings[_guardian])
            return GuardianRoundTableState.NotAGuardian;

        if (changeRoundTableProposals.length == 0) {
            return GuardianRoundTableState.NoActiveProposal;
        } else {
            ChangeRoundTableProposal storage proposal = changeRoundTableProposals[changeRoundTableProposals.length.sub(1)];
            if (proposal.state != ProposalExecutionState.inProgress) {
                return GuardianRoundTableState.NoActiveProposal;
            } else {
                Vote myVote = proposal.votes[_guardian];
                if (myVote == Vote.support) {
                    return GuardianRoundTableState.SupportedProposal;
                } else if (myVote == Vote.oppose) {
                    return GuardianRoundTableState.OpposedProposal;
                } else if (myVote == Vote.notVoted) {
                    return GuardianRoundTableState.NeedToVote;
                } else {
                    return GuardianRoundTableState.Unknown;
                }
            }
        }
    }

    function getWardStateForGuardian(address _guardian)
        external
        view
        returns(GuardianWardState _guardianWardState)
    {
        if (!guardianMappings[_guardian])
            return GuardianWardState.NotAGuardian;
        ISigner _ward = ISigner(ward);

        if (changeOwnerProposals.length == 0) {
            if (_ward.getAccessState() == ISigner.AccessState.Active) {
                return GuardianWardState.Active;
            } else if (_ward.getAccessState() == ISigner.AccessState.Frozen){
                return GuardianWardState.AwaitingProposal;
            } else {
                return GuardianWardState.Unknown;
            }
        } else {
            ChangeOwnerProposal storage proposal = changeOwnerProposals[changeOwnerProposals.length.sub(1)];
            if (proposal.state != ProposalExecutionState.inProgress) {
                if (_ward.getAccessState() == ISigner.AccessState.Active) {
                    return GuardianWardState.Active;
                } else if (_ward.getAccessState() == ISigner.AccessState.Frozen){
                    return GuardianWardState.AwaitingProposal;
                } else {
                    return GuardianWardState.Unknown;
                }
            } else {
                Vote myVote = proposal.votes[_guardian];
                if (myVote == Vote.support) {
                    return GuardianWardState.SupportedProposal;
                } else if (myVote == Vote.oppose) {
                    return GuardianWardState.OpposedProposal;
                } else if (myVote == Vote.notVoted) {
                    return GuardianWardState.NeedToVote;
                } else {
                    return GuardianWardState.Unknown;
                }
            }
        }
    }

    function changeOwnerProposalCount()
        external
        view
        returns(uint _proposalCount)
    {
        return changeOwnerProposals.length;
    }

    function changeRoundTableProposalCount()
        external
        view
        returns(uint _proposalCount)
    {
        return changeRoundTableProposals.length;
    }

    function octobaseType()
        external
        pure
        returns (uint16 typeCode)
    {
        return 7;
    }

    function octobaseTypeVersion()
        external
        pure
        returns (uint32 typeVersion)
    {
        return 1;
    }
}
