/**
 * This is custom ERC-721 token with some add on functionalities
*/

pragma solidity 0.5.17;

import "./BaseERC721.sol";

/**
 * @title CustomERC721
 * @author Prashant Prabhakar Singh [prashantprabhakar123@gmail.com]
 */
contract CustomERC721 is BaseERC721 {

  // mapping for replay protection
  mapping(address => uint) private userNonce;

  bool public isNormalUserAllowed; // can normal user access advanced features
  
  constructor(string memory name, string memory symbol, string memory baseURI) public BaseERC721(name, symbol, baseURI) {
    isNormalUserAllowed = false;
  }

  modifier canAccessProvableFunctions() {
    require(isNormalUserAllowed || msg.sender == owner || isDeputyOwner[msg.sender], "Not allowed to access provable fns");
    _;
  }

  /**
   * @dev Allows normal users to call provable fns
   * Reverts if the sender is not owner of contract
   * @param _perm permission to users
   */
  function allowNormalUser(bool _perm)
    public 
    onlyOwner
  {
    isNormalUserAllowed = _perm;
  }
  
  /**
   * @dev Allows submitting already signed transaction
   * Reverts if the signed data is incorrect
   * @param message signed message by user
   * @param r signature
   * @param s signature
   * @param v recovery id of signature
   * @param spender address which is approved
   * @param approved bool value for status of approval
   * message should be hash(functionWord, contractAddress, nonce, fnParams)
   */
  function provable_setApprovalForAll(bytes32 message, bytes32 r, bytes32 s, uint8 v, address spender, bool approved)
    public
    noEmergencyFreeze
    canAccessProvableFunctions
  {
    address signer = getSigner(message, r, s, v);
    require (signer != address(0), "Invalid signer");

    bytes32 proof = getMessageSetApprovalForAll(signer, spender, approved);
    require(proof == message, "Invalid proof");

    // perform the original set Approval
    operatorApprovals[signer][spender] = approved;
    emit ApprovalForAll(signer, spender, approved);
    userNonce[signer] = userNonce[signer].add(1);
  }

  /**
   * @dev Allows submitting already signed transaction for NFT transfer
   * Reverts if the signed data is incorrect
   * @param message signed message by user
   * @param r signature
   * @param s signature
   * @param v recovery id of signature
   * @param to recipient address
   * @param tokenId ID of NFT
   * message should be hash(functionWord, contractAddress, nonce, fnParams)
   */
  function provable_transfer(bytes32 message, bytes32 r, bytes32 s, uint8 v, address to, uint tokenId)
    public 
    noEmergencyFreeze
    canAccessProvableFunctions
  {
    address signer = getSigner(message, r, s, v);
    require (signer != address(0),"Invalid signer");

    bytes32 proof = getMessageTransfer(signer, to, tokenId);
    require (proof == message, "Invalid proof");
    
    // Execute original function
    require(to != address(0), "Zero address not allowed");
    clearApproval(signer, tokenId);
    removeTokenFrom(signer, tokenId);
    addTokenTo(to, tokenId);
    emit Transfer(signer, to, tokenId);

    // update state variables
    userNonce[signer] = userNonce[signer].add(1);
  }

  /**
   * @dev Check signer of a message
   * @param message signed message by user
   * @param r signature
   * @param s signature
   * @param v recovery id of signature
   * @return signer of message
   */
  function getSigner(bytes32 message, bytes32 r, bytes32 s,  uint8 v) public pure returns (address){
    bytes memory prefix = "\x19Ethereum Signed Message:\n32";
    bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, message));
    address signer = ecrecover(prefixedHash,v,r,s);
    return signer;
  }

  /**
   * @dev Get message to be signed for transfer
   * @param signer of message
   * @param to recipient address
   * @param id NFT id
   * @return hash of (functionWord, contractAddress, nonce, ...fnParams)
   */
  function getMessageTransfer(address signer, address to, uint id)
    public
    view
    returns (bytes32) 
  {
    return keccak256(abi.encodePacked(
      bytes4(0xb483afd3),
      address(this),
      userNonce[signer],
      to,
      id
    ));
  }

  /**
   * @dev Get message to be signed for set Approval
   * @param signer of message
   * @param spender address which is approved
   * @param approved bool value for status of approval
   * @return hash of (functionWord, contractAddress, nonce, ...fnParams)
   */
  function getMessageSetApprovalForAll(address signer, address spender, bool approved)
    public 
    view 
    returns (bytes32)
  {
    bytes32 proof = keccak256(abi.encodePacked(
      bytes4(0xbad4c8ea),
      address(this),
      userNonce[signer],
      spender,
      approved
    ));
    return proof;
  }

  /**
  * returns nonce of user to be used for next signing
  */
  function getUserNonce(address user) public view returns (uint) {
    return userNonce[user];
  }

  /**
   * @dev Owner can transfer out any accidentally sent ERC20 tokens
   * @param contractAddress ERC20 contract address
   * @param to withdrawal address
   * @param value no of tokens to be withdrawan
   */
  function transferAnyERC20Token(address contractAddress, address to,  uint value) public onlyOwner {
    ERC20Interface(contractAddress).transfer(to, value);
  }

  /**
   * @dev Owner can transfer out any accidentally sent ERC721 tokens
   * @param contractAddress ERC721 contract address
   * @param to withdrawal address
   * @param tokenId Id of 721 token
   */
  function withdrawAnyERC721Token(address contractAddress, address to, uint tokenId) public onlyOwner {
    ERC721Basic(contractAddress).safeTransferFrom(address(this), to, tokenId);
  }

  /**
   * @dev Owner kill the smart contract
   * @param message Confirmation message to prevent accidebtal calling
   * @notice BE VERY CAREFULL BEFORE CALLING THIS FUNCTION
   * Better pause the contract
   * DO CALL "transferAnyERC20Token" before TO WITHDRAW ANY ERC-2O's FROM CONTRACT
   */
  function kill(uint message) public onlyOwner {
    require (message == 123456789987654321, "Invalid code");
    // Transfer Eth to owner and terminate contract
    selfdestruct(msg.sender);
  }

}
