pragma solidity ^0.5.0;

interface BlockchainCutiesERC1155Interface {
    function mintNonFungibleSingleShort(uint128 _type, address _to) external;
    function mintNonFungibleSingle(uint256 _type, address _to) external;
    function mintNonFungibleShort(uint128 _type, address[] calldata _to) external;
    function mintNonFungible(uint256 _type, address[] calldata _to) external;
    function mintFungibleSingle(uint256 _id, address _to, uint256 _quantity) external;
    function mintFungible(uint256 _id, address[] calldata _to, uint256[] calldata _quantities) external;
    function isNonFungible(uint256 _id) external pure returns(bool);
    function ownerOf(uint256 _id) external view returns (address);
    function totalSupplyNonFungible(uint256 _type) view external returns (uint256);
    function totalSupplyNonFungibleShort(uint128 _type) view external returns (uint256);

    /**
        @notice A distinct Uniform Resource Identifier (URI) for a given token.
        @dev URIs are defined in RFC 3986.
        The URI may point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
        @return URI string
    */
    function uri(uint256 _id) external view returns (string memory);
    function proxyTransfer721(address _from, address _to, uint256 _tokenId, bytes calldata _data) external;
    function proxyTransfer20(address _from, address _to, uint256 _tokenId, uint256 _value) external;
    /**
        @notice Get the balance of an account's Tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the Token
        @return        The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
}

