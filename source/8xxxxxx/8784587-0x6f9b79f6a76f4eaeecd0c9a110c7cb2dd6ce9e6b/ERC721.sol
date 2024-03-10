pragma solidity ^0.5.11;

contract ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function transfer(address payable _to, uint256 _tokenId) external;
    function approve(address payable _to, uint256 _tokenId) external;
    function takeOwnership(uint256 _tokenId) public;
}

