pragma solidity ^0.5.0;

import "./GridBase.sol";
import "./ERC721.sol";
import "./safemath.sol";

contract GridOwnership is ERC721, GridBase {

  using SafeMath for uint256;

  mapping (uint => address) gridApprovals;

  modifier onlyOwnerOf(uint _gridId) {
    require(msg.sender == arr_struct_grid[_gridId].owner, "you are not owner of this grid");
    _;
  }

  function balanceOf(address _owner) public view returns (uint256 _balance) {
    return mappingOwnerGridCount[_owner];
  }

  function ownerOf(uint256 _tokenId) public view returns (address _owner) {
    _owner = arr_struct_grid[_tokenId].owner;
    require(_owner != address(0), "address invalid");
  }

  function _transfer(address _from, address payable _to, uint256 _tokenId) private {
    mappingOwnerGridCount[_to] = mappingOwnerGridCount[_to].add(1);
    mappingOwnerGridCount[msg.sender] = mappingOwnerGridCount[msg.sender].sub(1);
    arr_struct_grid[_tokenId].owner = _to;
    emit Transfer(_from, _to, _tokenId);
  }

  function transfer(address payable _to, uint256 _tokenId) external onlyOwnerOf(_tokenId) whenNotPaused {
    // Safety check to prevent against an unexpected 0x0 default.
    require(_to != address(0), "address invalid");
    // Disallow transfers to this contract to prevent accidental misuse.
    // The contract should never own any kitties (except very briefly
    // after a gen0 cat is created and before it goes on auction).
    require(_to != address(this), "address invalid");
    // Disallow transfers to the auction contracts to prevent accidental
    // misuse. Auction contracts should only take ownership of kitties
    // through the allow + transferFrom flow.
    //require(_to != address(saleAuction));
    //require(_to != address(siringAuction));
    _transfer(msg.sender, _to, _tokenId);
  }

  function approve(address payable _to, uint256 _tokenId) external onlyOwnerOf(_tokenId) whenNotPaused {
    gridApprovals[_tokenId] = _to;
    emit Approval(msg.sender, _to, _tokenId);
  }

  function takeOwnership(uint256 _tokenId) public {
    require(gridApprovals[_tokenId] == msg.sender, "you are not that guy");
    address owner = ownerOf(_tokenId);
    _transfer(owner, msg.sender, _tokenId);
  }
}
