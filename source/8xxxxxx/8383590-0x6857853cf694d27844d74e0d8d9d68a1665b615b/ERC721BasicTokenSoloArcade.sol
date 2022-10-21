pragma solidity ^0.4.24;

import "./ERC721Basic.sol";
import "./ERC721Receiver.sol";
import "./SafeMath.sol";
import "./AddressUtils.sol";
import "./SupportsInterfaceWithLookup.sol";


/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721BasicTokenSoloArcade is SupportsInterfaceWithLookup, ERC721Basic {

  using SafeMath for uint256;
  using AddressUtils for address;

  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
  bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

  // Mapping from token ID to owner
  mapping (uint256 => address) internal tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) internal tokenApprovals;

  // Mapping from owner to number of owned token
  mapping (address => uint256) internal ownedTokensCount;

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) internal operatorApprovals;
  
  //@dev stores all the game contracts that ERC721BasicToken will safely interact with
  mapping (address => bool) public gameContracts;
  
  //@dev sets the "gameMaster" who can add game contracts to marbles contract
  address public gameMaster;
  
  // @dev Throws if called by any account other than the gameMaster
  modifier onlyGameMaster() {
    require(msg.sender == gameMaster);
    _;
  }
  
  //@dev sets the game contracts that are allowed to interact with the marbles contract
  function setGameContracts(address _newGameContract) public onlyGameMaster{
      gameContracts[_newGameContract] = true;
  }
  
  //@dev stores all the transfered marbles in a form of a queue, helps the database to keep in sync
  mapping (uint256 => uint256) public transferedMarbleIndex;
  
  //@dev sets the status of the marble to transfered marble, helps the increment function to not increment over a marble thats has not being looked at by the database
  mapping (uint256 => bool) public transferedMarbles;
  
  //@dev used at the first number in the transfered queue
  uint256 public firstFirst = 1;
  
  //@dev used as last number in the transfered queue
  uint256 public lastLast = 0;
  
  
  constructor()
    public
  {
     //@dev sets the "gameMaster" to the address of the owner of the contract
     gameMaster = msg.sender;
    //@dev register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(InterfaceId_ERC721);
  }

  /**
   * @dev Gets the balance of the specified address
   * @param _owner address to query the balance of
   * @return uint256 representing the amount owned by the passed address
   */
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
  }

  /**
   * @dev Gets the owner of the specified token ID
   * @param _tokenId uint256 ID of the token to query the owner of
   * @return owner address currently marked as the owner of the given token ID
   */
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

  /**
   * @dev Approves another address to transfer the given token ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per token at a given time.
   * Can only be called by the token owner or an approved operator.
   * @param _to address to be approved for the given token ID
   * @param _tokenId uint256 ID of the token to be approved
   */
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    tokenApprovals[_tokenId] = _to;
    emit Approval(owner, _to, _tokenId);
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for the given token ID
   */
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

  /**
   * @dev Sets or unsets the approval of a given operator. Disabled for now.
   * An operator is allowed to transfer all tokens of the sender on their behalf
   * @param _to operator address to set the approval
   * @param _approved representing the status of the approval to be set
   */
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

  /**
   * @dev Tells whether an operator is approved by a given owner
   * @param _owner owner address which you want to query the approval of
   * @param _operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    public
    view
    returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }

  /**
   * @dev Transfers the ownership of a given token ID to another address
   * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
   * Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    require(_to != address(0));
    
    clearRemoveAdd(_from, _to, _tokenId);
    
    insertTokenTransferQue(_tokenId); 
    emit Transfer(_from, _to, _tokenId);
  }
  
   /**
   * @dev Transfers the ownership of a given token ID from the game contract
   * Requires the msg.sender to one of the game contracts approved by the game master
   * @param gameContract stores the address of the game contract the function was called from
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function transferFromGameSolo(address gameContract, address _from, address _to, uint256 _tokenId) public {
      require(gameContracts[gameContract]);
      require(gameContracts[msg.sender]);
      require(ownerOf(_tokenId) == msg.sender);
      require(_to != address(0));
      
      clearRemoveAdd(_from, _to, _tokenId);
      
      emit Transfer(_from, _to, _tokenId);
      
  }
  
   /**
   * @dev internal function used to insert token ID into the transfer queue
   * @param _tokenId uint256 ID of the token to be inserted in the toke queue
  */
  function insertTokenTransferQue(uint256 _tokenId) internal{
    lastLast += 1;
    transferedMarbleIndex[lastLast] = _tokenId;
    transferedMarbles[_tokenId] = true;
  }
  
  /**
   * @dev internal function changes ownership of a token ID, makes it easier to recycle code
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function clearRemoveAdd(address _from, address _to, uint256 _tokenId) internal {
       clearApproval(_from, _tokenId);
       removeTokenFrom(_from, _tokenId);
       addTokenTo(_to, _tokenId);
  }
  
  /**
   *@dev transfer function with the same logic as "transfeFrom" function, but this one does not place the marble
   *into the transfer queue. Please don't use this function without the the front end. The database will not be in sync with your transfer.
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function transferFromGameERC721(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
    require(gameContracts[msg.sender]);
    require(isApprovedOrOwner(tx.origin, _tokenId));
    require(_to != address(0));

    clearRemoveAdd(_from, _to, _tokenId);
    
    emit Transfer(_from, _to, _tokenId);
  }
  
  /**
   * @dev uses the same logic as the transferFrom function, but this function is only used to transfer prizes from games to a winning player.
   * requires that the msg.sender is the game contract added by the game master of the contract
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function transferPrizeFromGame(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
    require(gameContracts[msg.sender]);
    require(_to != address(0));
    clearRemoveAdd(_from, _to, _tokenId);
    emit Transfer(_from, _to, _tokenId);
  }
  
  
  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   *
   * Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
    // solium-disable-next-line arg-overflow
    safeTransferFrom(_from, _to, _tokenId, "");
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
   * @param _data bytes data to send along with a safe transfer check
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
  {
    transferFrom(_from, _to, _tokenId);
    // solium-disable-next-line arg-overflow
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

  /**
   * @dev Returns whether the specified token exists
   * @param _tokenId uint256 ID of the token to query the existence of
   * @return whether the token exists
   */
  function _exists(uint256 _tokenId) internal view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

  /**
   * @dev Returns whether the given spender can transfer a given token ID
   * @param _spender address of the spender to query
   * @param _tokenId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   *  is an operator of the owner, or is the owner of the token
   */
  function isApprovedOrOwner(
    address _spender,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(_tokenId);
    // Disable solium check because of
    // https://github.com/duaraghav8/Solium/issues/175
    // solium-disable-next-line operator-whitespace
    return (
      _spender == owner ||
      getApproved(_tokenId) == _spender ||
      isApprovedForAll(owner, _spender)
    );
  }

   /**
    * @dev Internal function to mint a new token
    * Reverts if the given token ID already exists
    * @param _to The address that will own the minted token
    * @param _tokenId uint256 ID of the token to be minted by the msg.sender
    */ 
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addTokenTo(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }

 

  /**
   * @dev Internal function to clear current approval of a given token ID
   * Reverts if the given address is not indeed the owner of the token
   * @param _owner owner of the token
   * @param _tokenId uint256 ID of the token to be transferred
   */
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
    }
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
    tokenOwner[_tokenId] = address(0);
  }

  /**
   * @dev Internal function to invoke `onERC721Received` on a target address
   * The call is not executed if the target address is not a contract
   * @param _from address representing the previous owner of the given token ID
   * @param _to target address that will receive the tokens
   * @param _tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return whether the call correctly returned the expected magic value
   */
  function checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(
      msg.sender, _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

// The MIT License (MIT)

// Copyright (c) 2016 Smart Contract Solutions, Inc.

// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:

// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// © 2018 GitHub, Inc.
