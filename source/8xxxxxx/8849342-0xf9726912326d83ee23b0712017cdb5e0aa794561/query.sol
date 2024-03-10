pragma solidity ^0.5.1;
//Copyright Octobase.co 2019
import "./signer.sol";
import "./vault.sol";
import "./roundtable.sol";

contract Query
{
    using SafeMath for uint256;

    constructor() public { }

    function getState(Vault _vault)
        external
        view
        returns (
            address _owner,
            address _signer,
            ISigner.AccessState _state,
            IRoundTable _roundTable,
            uint256 _callNonce)
    {
        Signer signer = Signer(_vault.signer());

        return (
            signer.getOwner(),
            address(signer),
            signer.getAccessState(),
            IRoundTable(signer.getRoundTable()),
            signer.getCallNonce());
    }

    enum ActiveProposalType
    {
        None,           //0x00
        ChangeOwner,    //0x01
        ChangeRoundTable//0x02
    }

    enum Vote
    {
        NotVoted,       //0x00
        Supported,      //0x01
        Opposed         //0x02
    }

    function getRoundTableState(Vault _vault)
        external
        view
        returns (
            RoundTable RoundTableAddress,
		    address GuardianAAddress,
            address GuardianBAddress,
            address GuardianCAddress,
            address GuardianDAddress,
            address ProposalAddress,
            uint256 ProposalCounts,
            uint256 ProposalDate,
            ActiveProposalType ActiveProposal,
            Vote GuardianAVote,
            Vote GuardianBVote,
            Vote GuardianCVote,
            Vote GuardianDVote,
            Vote WardVote)
    {
        RoundTableAddress = RoundTable(Signer(_vault.signer()).getRoundTable());
        {
            address[4] memory guardians = getGuardians(RoundTableAddress);
            GuardianAAddress = guardians[0];
            GuardianBAddress = guardians[1];
            GuardianCAddress = guardians[2];
            GuardianDAddress = guardians[3];
        }
        {
            (uint256[9] memory votes) = getVotes(RoundTableAddress);
            ProposalCounts = votes[6] + (votes[7] * 4294967296); //ChangeOwnerProposalsCount and ChangeRoundTableProposalsCount offset 32 bits
            ProposalDate = votes[8];
            //ChangeOwnerProposalsCount = votes[6];
            //ChangeRoundTableProposalsCount = votes[7];
            ActiveProposal = ActiveProposalType(votes[5]);
            GuardianAVote = Vote(votes[1]);
            GuardianBVote = Vote(votes[2]);
            GuardianCVote = Vote(votes[3]);
            GuardianDVote = Vote(votes[4]);
            WardVote = Vote(votes[0]);
            ProposalAddress = getProposalAddress(RoundTableAddress, ActiveProposal);
        }
    }

    function getProposalAddress(RoundTable _roundTable, ActiveProposalType _activeProposal)
        private
        view
        returns(address)
    {
        if (_activeProposal == ActiveProposalType.None)
        {
            return address(0);
        }
        else if (_activeProposal == ActiveProposalType.ChangeOwner)
        {
            uint256 changeOwnerProposalCount = _roundTable.changeOwnerProposalCount();
            address proposedOwner;
            (,, proposedOwner,,,,,) = _roundTable.changeOwnerProposals(changeOwnerProposalCount.sub(1));
            return proposedOwner;
        }
        else
        {
            uint256 changeRoundTableProposalCount = _roundTable.changeRoundTableProposalCount();
            IRoundTable proposedRoundTable;
            (,, proposedRoundTable,,,,,) = _roundTable.changeRoundTableProposals(changeRoundTableProposalCount.sub(1));
            return address(proposedRoundTable);
        }
    }

    function getVotes(RoundTable _roundTable)
        private
        view
        returns(uint256[9] memory _votes)
    {
        uint256 changeRoundTableProposalCount = _roundTable.changeRoundTableProposalCount();
        uint256 changeOwnerProposalCount = _roundTable.changeOwnerProposalCount();
        uint256 guardianCount = _roundTable.guardianCount();

        RoundTable.ProposalExecutionState roundTableProposalState;
        RoundTable.ProposalExecutionState ownerProposalState;

        _votes[6] = changeOwnerProposalCount;
        _votes[7] = changeRoundTableProposalCount;

        if (changeRoundTableProposalCount > 0)
        {
            (,roundTableProposalState,,,,,_votes[8],) = _roundTable
                .changeRoundTableProposals(changeRoundTableProposalCount.sub(1));
        }

        if (changeOwnerProposalCount > 0)
        {
            (,ownerProposalState,,,,,_votes[8],) = _roundTable
                .changeOwnerProposals(changeOwnerProposalCount.sub(1));
        }

        if (roundTableProposalState == RoundTable.ProposalExecutionState.inProgress)
        {
            _votes[5] = 0x02;

            _votes[0] = uint256(_roundTable.getWardRoundTableVote(changeRoundTableProposalCount.sub(1)));
            if (guardianCount >= 1)
            {
                _votes[1] = uint256(_roundTable.getRoundTableVote(changeRoundTableProposalCount.sub(1), 0));
            }
            if (guardianCount >= 2)
            {
                _votes[2] = uint256(_roundTable.getRoundTableVote(changeRoundTableProposalCount.sub(1), 1));
            }
            if (guardianCount >= 3)
            {
                _votes[3] = uint256(_roundTable.getRoundTableVote(changeRoundTableProposalCount.sub(1), 2));
            }
            if (guardianCount >= 4)
            {
                _votes[4] = uint256(_roundTable.getRoundTableVote(changeRoundTableProposalCount.sub(1), 3));
            }
        }
        else if (ownerProposalState == RoundTable.ProposalExecutionState.inProgress)
        {
            _votes[5] = 0x01;

            _votes[0] = uint256(_roundTable.getWardOwnerVote(changeOwnerProposalCount.sub(1)));
            if (guardianCount >= 1)
            {
                _votes[1] = uint256(_roundTable.getOwnerVote(changeOwnerProposalCount.sub(1), 0));
            }
            if (guardianCount >= 2)
            {
                _votes[2] = uint256(_roundTable.getOwnerVote(changeOwnerProposalCount.sub(1), 1));
            }
            if (guardianCount >= 3)
            {
                _votes[3] = uint256(_roundTable.getOwnerVote(changeOwnerProposalCount.sub(1), 2));
            }
            if (guardianCount >= 4)
            {
                _votes[4] = uint256(_roundTable.getOwnerVote(changeOwnerProposalCount.sub(1), 3));
            }
        }
        else
        {
            _votes[5] = 0x00;
            _votes[0] = 0x00;
            _votes[1] = 0x00;
            _votes[2] = 0x00;
            _votes[3] = 0x00;
        }
    }

    function getGuardians(RoundTable _roundTable)
        private
        view
        returns(address[4] memory _guardians)
    {
        uint256 guardianCount = _roundTable.guardianCount();

        if (guardianCount >= 1)
        {
            _guardians[0] = address(Signer(uint256(_roundTable.guardians(0))).getVault());
        }
        if (guardianCount >= 2)
        {
            _guardians[1] = address(Signer(uint256(_roundTable.guardians(1))).getVault());
        }
        if (guardianCount >= 3)
        {
            _guardians[2] = address(Signer(uint256(_roundTable.guardians(2))).getVault());
        }
        if (guardianCount >= 4)
        {
            _guardians[3] = address(Signer(uint256(_roundTable.guardians(3))).getVault());
        }
    }

    function getVault(Signer _signer)
        external
        view
        returns (IVault vault)
    {
        return _signer.getVault();
    }

    function getLimit(Vault _vault, address _tokenAddress)
        external
        view
        returns (
            uint256 _max,
            uint256 _spent,
            uint256 _startDateUtc,
            uint256 _windowSeconds,
            uint256 _lastLimitWindow,
            //uint256 _nextWindowStartDateUtc,
            Vault.LimitState _state,
            uint256 _proposalExecuteDate,
            uint256 _proposalMax,
            uint256 _proposalStartDateUtc,
            uint256 _proposalWindowSeconds)
    {
        (_max, _spent, _startDateUtc, _windowSeconds, _lastLimitWindow, _state) = _vault.getLimit(_tokenAddress);
        if (_state != IVault.LimitState.Uninitialized)
        {
            _startDateUtc = _windowSeconds.mul(_lastLimitWindow).add(_startDateUtc);
            if (_state == IVault.LimitState.ProposalPending)
            {
                (_proposalExecuteDate, _proposalMax, _proposalStartDateUtc, _proposalWindowSeconds) = _vault.getProposal(_tokenAddress);
                if (_proposalExecuteDate <= block.timestamp)
                {
                    _max = _proposalMax;
                    _startDateUtc = _proposalWindowSeconds.mul(_lastLimitWindow).add(_proposalStartDateUtc);
                    _windowSeconds = _proposalWindowSeconds;
                    _state = IVault.LimitState.NoProposal;
                    (_proposalExecuteDate, _proposalMax, _proposalStartDateUtc, _proposalWindowSeconds) = (0, 0, 0, 0);
                }
            }
        }
    }

    function getRoundTableStateForGuardian(Vault _vault, Signer _guardian)
        external
        view
        returns(RoundTable.GuardianRoundTableState _guardianWardState)
    {
        return RoundTable(Signer(_vault.signer()).getRoundTable()).getRoundTableStateForGuardian(address(_guardian));
    }

    function getWardStateForGuardian(Vault _vault, Signer _guardian)
        external
        view
        returns(RoundTable.GuardianWardState _guardianWardState)
    {
        return RoundTable(Signer(_vault.signer()).getRoundTable()).getWardStateForGuardian(address(_guardian));
    }
}
