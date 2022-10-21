// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

/// @title ERC-2665 NFT Transfer Fee Extension
/// @dev See https://github.com/ethereum/EIPs/issues/2665
///  Note: the ERC-165 identifier for this interface is 0x509ffea4.
///  Note: you must also implement the ERC-165 identifier of ERC-721, which is 0x80ac58cd.
interface ERC2665 /* is ERC165, is ERC721 but overide it's Design by contract specifications */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `msg.value` < `getTransferFee(_tokenId)`.
    ///  If the fee is not to be paid in ETH, then token publishers SHOULD provide a way to pay the
    ///  fee when calling this function or it's overloads, and throwing if said fee is not paid.
    ///  Throws if `_to` is the zero address. Throws if `_tokenId` is not a valid NFT.
    ///  When transfer is complete, this function checks if `_to` is a smart
    ///  contract (code size > 0). If so, it calls `onERC2665Received` on `_to`
    ///  and throws if the return value is not
    ///  `bytes4(keccak256("onERC2665Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. Throws if `msg.value` < `getTransferFee(_tokenId)`.
    ///  If the fee is not to be paid in ETH, then token publishers SHOULD provide a way to pay the
    ///  fee when calling this function and throw if said fee is not paid.
    ///  Throws if `_to` is the zero address. Throws if `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner. After a successful call and if
    ///  `msg.value == getTransferFee(_tokenId)`, then a subsequent atomic call to
    ///  `getTransferFee(_tokenId)` would eval to 0. If the fee is not to be paid in ETH,
    ///  then token publishers MUST provide a way to pay the fee when calling this function,
    ///  and throw if the fee is not paid.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);

    /// @notice Query what is the transfer fee for a specific token
    /// @dev If a call would returns 0, then any subsequent calls witht the same argument
    /// must also return 0 until the Transfer event has been emitted.
    /// @param _tokenId The NFT to find the Transfer Fee amount for
    /// @return The amount of Wei that need to be sent along a call to a transfer function
    function getTransferFee(uint256 _tokenId) external view returns (uint256);

    /// @notice Query what is the transfer fee for a specific token if the fee is to be paid
    /// @dev If a call would returns 0, then any subsequent calls with the same arguments
    /// must also return 0 until the Transfer event has been emitted. If _currencySymbol == 'ETH',
    /// then this function must return the same result as if `getTransferFee(uint256 _tokenId)` was called.
    /// @param _tokenId The NFT to find the Transfer Fee amount for
    /// @param _currencySymbol The currency in which the fee is to be paid
    /// @return The amount of Wei that need to be sent along a call to a transfer function
    function getTransferFee(uint256 _tokenId, string calldata _currencySymbol) external view returns (uint256);

}


interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

/// @dev Note: the ERC-165 identifier for this interface is 0xac3cf292.
interface ERC2665TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC2665 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC2665Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC2665Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface ERC721Metadata /* is ERC721 */ {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns(string memory _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns(string memory _symbol);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns(string memory);
}

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x780e9d63.
interface ERC721Enumerable /* is ERC721 */ {
    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256);

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256);

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

contract ERC2665HeaderV1 {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved);
}

contract ERC2665StorageInternalV1 {
    address payable internal auctionHouse;
    address internal indexCry;

    mapping(address => bool) internal isACryptograph;

    mapping(address => uint256) internal balanceOfVar;

    uint256 internal totalSupplyVar;
    mapping(uint256 => address) internal index2665ToAddress;

    mapping(address => uint256[]) internal indexedOwnership; //[Owner][index] = cryptographID
    mapping(uint256 => uint256) internal cryptographPositionInOwnershipArray; // [cryptographID] = index
    mapping(uint256 => uint256) internal lastSoldFor; //Value last sold on the cryptograph platform
    mapping(uint256 => uint256) internal transferFees; //Pending transfer fee
    mapping(uint256 => bool) internal transferFeePrepaid; //Have the next transfer fee be prepaid ?
    mapping(uint256 => address) public approvedTransferAddress; //Address allowed to Transfer a token
    mapping(address => mapping(address => bool)) internal approvedOperator; //Approved operators mapping

}

contract ERC2665StoragePublicV1 {
    address payable public auctionHouse;
    address public indexCry;

    mapping(address => bool) public isACryptograph;

    mapping(address => uint256) public balanceOfVar;

    uint256 public totalSupplyVar;
    mapping(uint256 => address) public index2665ToAddress;

    mapping(address => uint256[]) public indexedOwnership; //[Owner][index] = cryptographID
    mapping(uint256 => uint256) public cryptographPositionInOwnershipArray; // [cryptographID] = index
    mapping(uint256 => uint256) public lastSoldFor; // Value last sold on the cryptograph platform
    mapping(uint256 => uint256) public transferFees; // Pending transfer fee
    mapping(uint256 => bool) public transferFeePrepaid; //Have the next transfer fee be prepaid ?
    mapping(uint256 => address) public approvedTransferAddress; //Address allowed to Transfer a token
    mapping(address => mapping(address => bool)) public approvedOperator; //Approved operators mapping
}

