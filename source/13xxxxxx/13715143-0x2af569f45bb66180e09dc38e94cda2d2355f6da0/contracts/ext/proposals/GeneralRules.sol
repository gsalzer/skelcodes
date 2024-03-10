// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../../base/model/IProposalsManager.sol";
import "../../core/model/IOrganization.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@ethereansos/items-v2/contracts/model/Item.sol";
import {TransferUtilities} from "@ethereansos/swissknife/contracts/lib/GeneralUtilities.sol";

contract BySpecificAddress is IProposalChecker {

    string public constant LABEL = 'host';

    string public uri;
    address public value;
    bool public discriminant;

    function lazyInit(bytes memory lazyInitData) external returns(bytes memory lazyInitResponseData) {
        require(keccak256(bytes(uri)) == keccak256(""));
        (uri, lazyInitResponseData) = abi.decode(lazyInitData, (string, bytes));
        require(keccak256(bytes(uri)) != keccak256(""));

        (value, discriminant) = abi.decode(lazyInitResponseData, (address, bool));

        lazyInitResponseData = "";
    }

    function setValue(address newValue) external {
        require(msg.sender == value, "unauthorized");
        require(discriminant, "cannot change");
        require(newValue != address(0), "void");
        value = newValue;
    }

    function makeReadOnly() external {
        require(msg.sender == value, "unauthorized");
        require(discriminant, "cannot change");
        discriminant = false;
    }

    function check(address, bytes32, bytes calldata, address from, address) external override view returns(bool) {
        return from == value;
    }
}

contract ChangeOrganizationUriProposal {

    string public constant LABEL = 'changeOrganizationUri';

    string public uri;

    string public value;

    string public additionalUri;

    function lazyInit(bytes memory lazyInitData) external returns(bytes memory lazyInitResponseData) {
        require(keccak256(bytes(uri)) == keccak256(""));
        (uri, lazyInitResponseData) = abi.decode(lazyInitData, (string, bytes));
        require(keccak256(bytes(uri)) != keccak256(""));

        (additionalUri, value) = abi.decode(lazyInitResponseData, (string, string));

        lazyInitResponseData = "";
    }

    function execute(bytes32) external {
        IOrganization(ILazyInitCapableElement(msg.sender).host()).setUri(value);
    }
}

/*contract SlashingConditionAtCreation {
    using TransferUtilities for address;

    uint256 public constant ONE_HUNDRED = 1e18;

    string public uri;

    uint256 public tokenIndex;
    bool public amountIsPercentage;
    uint256 public value;

    mapping(bytes32 => bool) public alreadyCalled;
    mapping(bytes32 => uint256) public toValue;

    function lazyInit(bytes memory lazyInitData) external returns(bytes memory lazyInitResponseData) {
        require(keccak256(bytes(uri)) == keccak256(""));
        (uri, lazyInitResponseData) = abi.decode(lazyInitData, (string, bytes));
        require(keccak256(bytes(uri)) != keccak256(""));

        (tokenIndex, amountIsPercentage, value) = abi.decode(lazyInitResponseData, (uint256, bool, uint256));

        lazyInitResponseData = "";
    }

    function check(address, bytes32 proposalId, bytes calldata proposalData, address, address) external returns(bool) {
        IProposalsManager.Proposal memory proposal = abi.decode(proposalData, (IProposalsManager.Proposal));
        if(!alreadyCalled[proposalId]) {
            _take(proposalId, proposal);
        } else {
            _give(proposalId, proposal);
        }
        return true;
    }

    function _take(bytes32 proposalId, IProposalsManager.Proposal memory proposal) private {
        require(IProposalsManager(address(this)).lastProposalId() == proposalId, "not last proposal");
        alreadyCalled[proposalId] = true;
        address from = proposal.proposer;
        (address[] memory collections, uint256[] memory objecIds,) = abi.decode(proposal.votingTokens, (address[], uint256[], uint256[]));

        address collection = collections[tokenIndex];
        uint256 objectId = objecIds[tokenIndex];

        if(collection == address(0)) {
            toValue[proposalId] = _takeERC20(address(uint160(objectId)), from);
        } else {
            toValue[proposalId] = _takeItem(collection, objectId, from);
        }
    }

    function _give(bytes32 proposalId, IProposalsManager.Proposal memory proposal) private {
        require(toValue[proposalId] > 0, "empty value");
        address to = proposal.proposer;
        (address[] memory collections, uint256[] memory objecIds,) = abi.decode(proposal.votingTokens, (address[], uint256[], uint256[]));
        address collection = collections[tokenIndex];
        uint256 objectId = objecIds[tokenIndex];
        if(collection == address(0)) {
            address tokenAddress = address(uint160(objectId));
            tokenAddress.safeTransfer(to, toValue[proposalId]);
        } else {
            Item(collection).safeTransferFrom(address(this), to, objectId, toValue[proposalId], "");
        }
        toValue[proposalId] = 0;
    }

    function _takeERC20(address tokenAddress, address from) private returns (uint256 realValue) {
        realValue = amountIsPercentage ? _calculatePercentage(IERC20(tokenAddress).totalSupply(), value) : value;
        tokenAddress.safeTransferFrom(from, address(this), realValue);
    }

    function _takeItem(address tokenAddress, uint256 objectId, address from) private returns (uint256 realValue) {
        Item item = Item(tokenAddress);
        realValue = amountIsPercentage ? _calculatePercentage(item.totalSupply(objectId), value) : value;
        item.safeTransferFrom(from, address(this), objectId, realValue, "");
    }

    function _calculatePercentage(uint256 totalSupply, uint256 percentage) private pure returns (uint256) {
        return (totalSupply * ((percentage * 1e18) / ONE_HUNDRED)) / 1e18;
    }
}

contract VoteAtCreation {
    using TransferUtilities for address;

    uint256 public constant ONE_HUNDRED = 1e18;

    string public uri;

    uint256 public tokenIndex;
    bool public amountIsPercentage;
    uint256 public value;

    event Init(uint256 tokenIndex, bool amountIsPercentage, uint256 value);

    function lazyInit(bytes memory lazyInitData) external returns(bytes memory lazyInitResponseData) {
        require(keccak256(bytes(uri)) == keccak256(""));
        (uri, lazyInitResponseData) = abi.decode(lazyInitData, (string, bytes));
        require(keccak256(bytes(uri)) != keccak256(""));

        (tokenIndex, amountIsPercentage, value) = abi.decode(lazyInitResponseData, (uint256, bool, uint256));
        emit Init(tokenIndex, amountIsPercentage, value);
        lazyInitResponseData = "";
    }

    event Malmenato(address[] add, uint256[] obj, uint256 addLength, uint256 objLength, uint256 tokenIndex);

    function check(address, bytes32 proposalId, bytes calldata proposalData, address, address) external returns(bool) {
        require(IProposalsManager(address(this)).lastProposalId() == proposalId, "not last proposal");
        IProposalsManager.Proposal memory proposal = abi.decode(proposalData, (IProposalsManager.Proposal));
        address from = proposal.proposer;
        (address[] memory collections, uint256[] memory objectIds,) = abi.decode(proposal.votingTokens, (address[], uint256[], uint256[]));

        emit Malmenato(collections, objectIds, collections.length, objectIds.length, tokenIndex);

        address collection = collections[tokenIndex];
        uint256 objectId = objectIds[tokenIndex];

        if(collection == address(0)) {
            _voteWithERC20(address(uint160(objectId)), from, proposalId);
        } else {
            _voteWithItem(collection, objectId, from, proposalId);
        }
        return true;
    }

    function _voteWithERC20(address tokenAddress, address from, bytes32 proposalId) private returns (uint256 realValue) {
        realValue = amountIsPercentage ? _calculatePercentage(IERC20(tokenAddress).totalSupply(), value) : value;
        tokenAddress.safeTransferFrom(from, address(this), realValue);
        tokenAddress.safeApprove(address(this), realValue);
        IProposalsManager(address(this)).vote(tokenAddress, "", proposalId, realValue, 0, from, false);
    }

    function _voteWithItem(address tokenAddress, uint256 objectId, address from, bytes32 proposalId) private returns (uint256 realValue) {
        Item item = Item(tokenAddress);
        realValue = amountIsPercentage ? _calculatePercentage(item.totalSupply(objectId), value) : value;
        item.safeTransferFrom(from, address(this), objectId, realValue, abi.encode(proposalId, realValue, 0, from, false));
    }

    function _calculatePercentage(uint256 totalSupply, uint256 percentage) private pure returns (uint256) {
        return (totalSupply * ((percentage * 1e18) / ONE_HUNDRED)) / 1e18;
    }
}*/
