// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
interface IGovERC721 is IERC721, IERC721Metadata, IERC721Enumerable{

    event VotingPowerAdded(address indexed voter, uint256 indexed tokenId, uint256 indexed votes);
    event VotingPowerRemoved(address indexed voter, uint256 indexed tokenId,uint256 indexed votes);
  
    function totalVotingPower() external view returns (uint256);

    function delegateVotingPower(address _address) external view returns (uint256);
  
    function tokenVotingPower(uint256 _tokenId) external view returns (uint256);
    
    function isLocked(address _account) external view returns (bool);
    function _lockNFT(address _voter, uint256 _proposal)  external returns (bool);
    function calculateCurve() external view returns (uint256);
    function splitNFT(address _to, uint256 _tokenId, uint256 _split_amount)external returns (bool);
    function buyVotes() external payable returns (bool);
    function earnVotes(uint256 _value, address _seller, address _buyer, address _contract)  external returns (uint256);
    function setDAOContract(address _DAO)  external returns (bool);
    function setExchangeContract(address _exchange)  external returns (bool);
    function toggleOnline()  external returns (bool);
}

