pragma solidity ^0.4.24;

import "ERC721.sol";
import "ERC721Metadata.sol";
import "math/SafeMath.sol";
import "ownership/Ownable.sol";

/// @title OathForge: NFT Registry
/// @author GuildCrypt
contract OathForge is ERC721, ERC721Metadata, Ownable {

  using SafeMath for uint256;

  uint256 private _totalSupply;
  uint256 private _nextTokenId;
  mapping(uint256 => uint256) private _sunsetInitiatedAt;
  mapping(uint256 => uint256) private _sunsetLength;
  mapping(uint256 => uint256) private _redemptionCodeHashSubmittedAt;
  mapping(uint256 => bytes32) private _redemptionCodeHash;
  mapping(address => bool) private _isBlacklisted;

  /// @param name The ERC721 Metadata name
  /// @param symbol The ERC721 Metadata symbol
  constructor(string name, string symbol) ERC721Metadata(name, symbol) public {}

  /// @dev Emits when a sunset has been initiated
  /// @param tokenId The token id
  event SunsetInitiated(uint256 indexed tokenId);

  /// @dev Emits when a redemption code hash has been submitted
  /// @param tokenId The token id
  /// @param redemptionCodeHash The redemption code hash
  event RedemptionCodeHashSubmitted(uint256 indexed tokenId, bytes32 redemptionCodeHash);

  /// @dev Returns the total number of tokens (minted - burned) registered
  function totalSupply() external view returns(uint256){
    return _totalSupply;
  }

  /// @dev Returns the token id of the next minted token
  function nextTokenId() external view returns(uint256){
    return _nextTokenId;
  }

  /// @dev Returns if an address is blacklisted
  /// @param to The address to check
  function isBlacklisted(address to) external view returns(bool){
    return _isBlacklisted[to];
  }

  /// @dev Returns the timestamp at which a token's sunset was initated. Returns 0 if no sunset has been initated.
  /// @param tokenId The token id
  function sunsetInitiatedAt(uint256 tokenId) external view returns(uint256){
    return _sunsetInitiatedAt[tokenId];
  }

  /// @dev Returns the sunset length of a token
  /// @param tokenId The token id
  function sunsetLength(uint256 tokenId) external view returns(uint256){
    return _sunsetLength[tokenId];
  }

  /// @dev Returns the redemption code hash submitted for a token
  /// @param tokenId The token id
  function redemptionCodeHash(uint256 tokenId) external view returns(bytes32){
    return _redemptionCodeHash[tokenId];
  }

  /// @dev Returns the timestamp at which a redemption code hash was submitted
  /// @param tokenId The token id
  function redemptionCodeHashSubmittedAt(uint256 tokenId) external view returns(uint256){
    return _redemptionCodeHashSubmittedAt[tokenId];
  }

  /// @dev Mint a token. Only `owner` may call this function.
  /// @param to The receiver of the token
  /// @param tokenURI The tokenURI of the the tokenURI
  /// @param __sunsetLength The length (in seconds) that a sunset period can last
  function mint(address to, string tokenURI, uint256 __sunsetLength) public onlyOwner {
    _mint(to, _nextTokenId);
    _sunsetLength[_nextTokenId] = __sunsetLength;
    _setTokenURI(_nextTokenId, tokenURI);
    _nextTokenId = _nextTokenId.add(1);
    _totalSupply = _totalSupply.add(1);
  }

  /// @dev Initiate a sunset. Sets `sunsetInitiatedAt` to current timestamp. Only `owner` may call this function.
  /// @param tokenId The id of the token
  function initiateSunset(uint256 tokenId) external onlyOwner {
    require(tokenId < _nextTokenId);
    require(_sunsetInitiatedAt[tokenId] == 0);
    _sunsetInitiatedAt[tokenId] = now;
    emit SunsetInitiated(tokenId);
  }

  /// @dev Submit a redemption code hash for a specific token. Burns the token. Sets `redemptionCodeHashSubmittedAt` to current timestamp. Decreases `totalSupply` by 1.
  /// @param tokenId The id of the token
  /// @param __redemptionCodeHash The redemption code hash
  function submitRedemptionCodeHash(uint256 tokenId, bytes32 __redemptionCodeHash) external {
    _burn(msg.sender, tokenId);
    _redemptionCodeHashSubmittedAt[tokenId] = now;
    _redemptionCodeHash[tokenId] = __redemptionCodeHash;
    _totalSupply = _totalSupply.sub(1);
    emit RedemptionCodeHashSubmitted(tokenId, __redemptionCodeHash);
  }

  /// @dev Transfers the ownership of a given token ID to another address. Usage of this method is discouraged, use `safeTransferFrom` whenever possible. Requires the msg sender to be the owner, approved, or operator
  /// @param from current owner of the token
  /// @param to address to receive the ownership of the given token ID
  /// @param tokenId uint256 ID of the token to be transferred
  function transferFrom(address from, address to, uint256 tokenId) public {
    require(!_isBlacklisted[to]);
    if (_sunsetInitiatedAt[tokenId] > 0) {
      require(now <= _sunsetInitiatedAt[tokenId].add(_sunsetLength[tokenId]));
    }
    super.transferFrom(from, to, tokenId);
  }

  /**
   * @dev Approves another address to transfer the given token ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per token at a given time.
   * Can only be called by the token owner or an approved operator.
   * @param to address to be approved for the given token ID
   * @param tokenId uint256 ID of the token to be approved
   */
  function approve(address to, uint256 tokenId) public {
    require(!_isBlacklisted[to]);
    super.approve(to, tokenId);
  }

  /**
    * @dev Sets or unsets the approval of a given operator
    * An operator is allowed to transfer all tokens of the sender on their behalf
    * @param to operator address to set the approval
    * @param approved representing the status of the approval to be set
    */
  function setApprovalForAll(address to, bool approved) public {
    require(!_isBlacklisted[to]);
    super.setApprovalForAll(to, approved);
  }

  /// @dev Set `tokenUri`. Only `owner` may do this.
  /// @param tokenId The id of the token
  /// @param tokenURI The token URI
  function setTokenURI(uint256 tokenId, string tokenURI) external onlyOwner {
    _setTokenURI(tokenId, tokenURI);
  }

  /// @dev Set if an address is blacklisted
  /// @param to The address to change
  /// @param __isBlacklisted True if the address should be blacklisted, false otherwise
  function setIsBlacklisted(address to, bool __isBlacklisted) external onlyOwner {
    _isBlacklisted[to] = __isBlacklisted;
  }

}

