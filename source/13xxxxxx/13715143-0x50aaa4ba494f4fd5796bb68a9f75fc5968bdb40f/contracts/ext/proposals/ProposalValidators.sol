// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@ethereansos/swissknife/contracts/factory/model/IFactory.sol";
import "../../base/model/IProposalsManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@ethereansos/items-v2/contracts/model/Item.sol";

contract ValidateQuorum is IProposalChecker {

    string public constant LABEL = 'quorum';

    uint256 public constant ONE_HUNDRED = 1e18;

    string public uri;
    uint256 public value;
    bool public discriminant;

    function lazyInit(bytes memory lazyInitData) external returns(bytes memory lazyInitResponseData) {
        require(keccak256(bytes(uri)) == keccak256(""));
        (uri, lazyInitResponseData) = abi.decode(lazyInitData, (string, bytes));
        require(keccak256(bytes(uri)) != keccak256(""));

        (value, discriminant) = abi.decode(lazyInitResponseData, (uint256, bool));

        lazyInitResponseData = "";
    }

    function check(address, bytes32, bytes calldata proposalData, address, address) external override view returns(bool) {
        IProposalsManager.Proposal memory proposal  = abi.decode(proposalData, (IProposalsManager.Proposal));
        uint256 quorum = discriminant ? _calculatePercentage(_calculateCensusTotalSupply(proposal), value) : value;
        return ((proposal.accept + proposal.refuse) >= quorum) && (proposal.accept > proposal.refuse);
    }

    function _calculateCensusTotalSupply(IProposalsManager.Proposal memory proposal) private view returns (uint256 censusTotalSupply) {
        (address[] memory collectionAddresses, uint256[] memory objectIds, uint256[] memory weights) = abi.decode(proposal.votingTokens, (address[], uint256[], uint256[]));
        for(uint256 i = 0; i < collectionAddresses.length; i++) {
            censusTotalSupply += (_calculateTotalSupply(collectionAddresses[i], objectIds[i]) * weights[i]);
        }
    }

    function _calculatePercentage(uint256 totalSupply, uint256 percentage) private pure returns (uint256) {
        return (totalSupply * ((percentage * 1e18) / ONE_HUNDRED)) / 1e18;
    }

    function _calculateTotalSupply(address collectionAddress, uint256 collectionId) private view returns(uint256) {
        if(collectionAddress == address(0)) {
            return IERC20(address(uint160(collectionId))).totalSupply();
        }
        return Item(collectionAddress).totalSupply(collectionId);
    }
}

contract CanBeValidBeforeBlockLength is IProposalChecker {

    string public constant LABEL = 'validationBomb';

    string public uri;
    uint256 public value;

    function lazyInit(bytes memory lazyInitData) external returns(bytes memory lazyInitResponseData) {
        require(keccak256(bytes(uri)) == keccak256(""));
        (uri, lazyInitResponseData) = abi.decode(lazyInitData, (string, bytes));
        require(keccak256(bytes(uri)) != keccak256(""));

        value = abi.decode(lazyInitResponseData, (uint256));

        lazyInitResponseData = "";
    }

    function check(address, bytes32, bytes calldata proposalData, address, address) external override view returns(bool) {
        return block.number < (value + abi.decode(proposalData, (IProposalsManager.Proposal)).creationBlock);
    }
}
