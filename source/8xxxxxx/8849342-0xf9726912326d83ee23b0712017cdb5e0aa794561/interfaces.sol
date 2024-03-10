//Copyright Octobase.co 2019
pragma solidity ^0.5.1;
import "./statuscodes.sol";

contract ISigner
{
    enum AccessState
    {
        Uninitiated, //0x00
        Active, //0x01
        Frozen //0x02
    }

    function getNonces()
        public
        view
        returns (bool isActive, uint256 callNonce, address owner);

    function changeOwner(address _newOwner)
        external
        returns (StatusCodes.Status status);

    function freeze(address _owner)
        external
        returns (StatusCodes.Status status);

    function changeRoundTable(IRoundTable _newRoundTable)
        external
        returns (StatusCodes.Status status);

    function getAccessState()
        public
        view
        returns (ISigner.AccessState);

    function getUsedOwnerKey(address _owner)
        public
        view
        returns(bool);

    function checkFreezeInvalidation(
            uint256 _upgradeProposalDate,
            uint256 _upgradeExecutionDate)
        external
        //view
        returns(bool _isValid);
}

interface IVault
{
    enum LimitState
    {
        Uninitialized,
        NoProposal,
        ProposalPending
    }
    
    function initVault(uint256 _weiMax, uint256 _weiStartDateUtc, uint256 _weiWindowSeconds)
        external
        returns(StatusCodes.Status status);

    function sendWei(address payable _to, uint256 _amount)
        external
        returns (StatusCodes.Status status);

    function sendErc20(address _tokenContract, address _to, uint256 _amount)
        external
        returns (StatusCodes.Status status);
}

contract IRoundTable
{
    function proposeAndSupportRoundTableChange(address _newRoundTable)
        external
        returns (StatusCodes.Status status, uint proposalId);
}

interface IRoundTableFactory
{
    function produceRoundTable(
            ISigner _signer,
            address[] calldata _guardians)
        external
        returns (StatusCodes.Status status, IRoundTable roundTable);
}
