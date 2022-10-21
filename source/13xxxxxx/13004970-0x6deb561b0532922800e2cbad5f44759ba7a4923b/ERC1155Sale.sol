pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./Roles.sol";
import "./ERC1155.sol";
import "./AbstractSale.sol";
import "./TransferProxy.sol";

/// @title ERC1155SaleNonceHolder
/// @notice The contract manages nonce values for the sales.
contract ERC1155SaleNonceHolder is OwnableOperatorRole {
    /// @notice Token nonces.
    /// @dev keccak256(token, owner, tokenId) => nonce
    mapping(bytes32 => uint256) public nonces;

    /// @notice The amount of selled tokens for the tokenId.
    /// @dev keccak256(token, owner, tokenId, nonce) => completed amount
    mapping(bytes32 => uint256) public completed;

    /// @notice Get nonce value for the token.
    /// @param token - Token's contract address.
    /// @param tokenId - Token id.
    /// @param owner - The address of the token owner.
    /// @return The nonce value.
    function getNonce(address token, uint256 tokenId, address owner) view public returns (uint256) {
        return nonces[getNonceKey(token, tokenId, owner)];
    }

    /// @notice Sets new nonce value for the token. Can only be called by the operator.
    /// @param token - Token's contract address.
    /// @param tokenId - Token id.
    /// @param owner - The address of the token owner.
    /// @param nonce - The new value for the nonce.
    function setNonce(address token, uint256 tokenId, address owner, uint256 nonce) public onlyOperator {
        nonces[getNonceKey(token, tokenId, owner)] = nonce;
    }

    /// @notice Encode the token info to use as a key for `nonces` mapping.
    /// @param token - Token's contract address.
    /// @param tokenId - Token id.
    /// @param owner - The address of the token owner.
    /// @return Encoded key for the token.
    function getNonceKey(address token, uint256 tokenId, address owner) pure public returns (bytes32) {
        return keccak256(abi.encodePacked(token, tokenId, owner));
    }

    /// @notice Get the amount of selled tokens.
    /// @param token - Token's contract address.
    /// @param tokenId - Token id.
    /// @param owner - The address of the token owner.
    /// @param nonce - The nonce value of the sale.
    /// @return Selled tokens count for the sale with specific nonce.
    function getCompleted(address token, uint256 tokenId, address owner, uint256 nonce) view public returns (uint256) {
        return completed[getCompletedKey(token, tokenId, owner, nonce)];
    }

    /// @notice Sets the new amount of selled tokens. Can be called only by the contract operator.
    /// @param token - Token's contract address.
    /// @param tokenId - Token id.
    /// @param owner - The address of the token owner.
    /// @param nonce - The nonce value of the sale.
    /// @param _completed - The new completed value to set.
    function setCompleted(address token, uint256 tokenId, address owner, uint256 nonce, uint256 _completed) public onlyOperator {
        completed[getCompletedKey(token, tokenId, owner, nonce)] = _completed;
    }

    /// @notice Encode order key to use as a key of `completed` mapping.
    /// @param token - Token's contract address.
    /// @param tokenId - Token id.
    /// @param owner - The address of the token owner.
    /// @param nonce - The nonce value of the sale.
    /// @return Encoded key.
    function getCompletedKey(address token, uint256 tokenId, address owner, uint256 nonce) pure public returns (bytes32) {
        return keccak256(abi.encodePacked(token, tokenId, owner, nonce));
    }
}

/// @title ERC1155Sale
/// @notice Allows users to exchange ERC1155Sale tokens for the Ether.
contract ERC1155Sale is Ownable, AbstractSale {
    using StringLibrary for string;

    event CloseOrder(address indexed token, uint256 indexed tokenId, address owner, uint256 nonce);
    event Buy(address indexed token, uint256 indexed tokenId, address owner, uint256 price, address buyer, uint256 value);

    bytes constant EMPTY = "";

    /// @notice The address of a transfer proxy for ERC721 and ERC1155 tokens.
    TransferProxy public transferProxy;
    /// @notice The address of a nonce manager contract.
    ERC1155SaleNonceHolder public nonceHolder;

    /// @param _transferProxy - The address of a deployed TransferProxy contract.
    /// @param _nonceHolder - The address of a deployed ERC1155SaleNonceHolder contract.
    /// @param beneficiary - The address of a fee recipient.
    constructor(TransferProxy _transferProxy, ERC1155SaleNonceHolder _nonceHolder, address payable beneficiary) AbstractSale(beneficiary) public {
        transferProxy = _transferProxy;
        nonceHolder = _nonceHolder;
    }

    /// @notice This function is called to buy ERC1151 token in exchange for ETH.
    /// @notice ERC1155 token must be approved for this contract before calling this function.
    /// @notice To pay with ETH, transaction must send ether within the calling transaction.
    /// @notice Buyer's payment value is calculated as `price * buying + buyerFee%`. `buyerFee` can be obtaind by calling buyerFee() function of this contract (inherited from AbstractSale).
    /// @param token - ERC1151 token contracy address.
    /// @param tokenId - ERC1151 token id for sale.
    /// @param owner - The address of the ERC1151 token owner.
    /// @param selling - The total amount of ERC1155 token for sale.
    /// @param buying - The amount of ERC1155 tokens to buy in this function call.
    /// @param price - The price of ERC1151 token in WEI.
    /// @param sellerFee - Amount for seller's fee. Represented as percents * 100 (100% => 10000. 1% => 100).
    /// @param signature - Signed message with parameters of the format: `${token.address.toLowerCase()}. tokenId: ${tokenId}. price: ${price}. nonce: ${nonce}. fee: ${sellerFee}. value: ${selling}`
    ///        If sellerFee is zero, than the format is `${token.address.toLowerCase()}. tokenId: ${tokenId}. price: ${price}. nonce: ${nonce}. value: ${selling}`
    ///        Where token.address.toLowerCase() is the address of the ERC1151 token contract (parameter `value`).
    ///        The `nonce` can be obtained from the nonceHolder with `getNonce` function.
    ///        Message must be prefixed with: `"\x19Ethereum Signed Message:\n" + message.length`.
    ///        Some libraries, for example web3.accounts.sign, will automatically prefix the message.
    function buy(IERC1155 token, uint256 tokenId, address payable owner, uint256 selling, uint256 buying, uint256 price, uint256 sellerFee, Sig memory signature) public payable {
        uint256 nonce = verifySignature(address(token), tokenId, owner, selling, price, sellerFee, signature);
        uint256 total = price.mul(buying);
        uint256 buyerFeeValue = total.mul(buyerFee).div(10000);
        require(total + buyerFeeValue == msg.value, "msg.value is incorrect");
        bool closed = verifyOpenAndModifyState(address(token), tokenId, owner, nonce, selling, buying);

        transferProxy.erc1155safeTransferFrom(token, owner, msg.sender, tokenId, buying, EMPTY);

        transferEther(token, tokenId, owner, total, sellerFee);
        emit Buy(address(token), tokenId, owner, price, msg.sender, buying);
        if (closed) {
            emit CloseOrder(address(token), tokenId, owner, nonce + 1);
        }
    }

    /// @notice Cancel the token sale order. Can be called only by the token owner.
    ///         The function makes signed buy message invalid by increasing the nonce for the token.
    /// @param token - The address of the token contract.
    /// @param tokenId - The token id.
    function cancel(address token, uint256 tokenId) public payable {
        uint nonce = nonceHolder.getNonce(token, tokenId, msg.sender);
        nonceHolder.setNonce(token, tokenId, msg.sender, nonce + 1);

        emit CloseOrder(token, tokenId, msg.sender, nonce + 1);
    }

    function verifySignature(address token, uint256 tokenId, address payable owner, uint256 selling, uint256 price, uint256 sellerFee, Sig memory signature) view internal returns (uint256 nonce) {
        nonce = nonceHolder.getNonce(token, tokenId, owner);
        require(prepareMessage(token, tokenId, price, selling, sellerFee, nonce).recover(signature.v, signature.r, signature.s) == owner, "incorrect signature");
    }

    function verifyOpenAndModifyState(address token, uint256 tokenId, address payable owner, uint256 nonce, uint256 selling, uint256 buying) internal returns (bool) {
        uint comp = nonceHolder.getCompleted(token, tokenId, owner, nonce).add(buying);
        require(comp <= selling);
        nonceHolder.setCompleted(token, tokenId, owner, nonce, comp);

        if (comp == selling) {
            nonceHolder.setNonce(token, tokenId, owner, nonce + 1);
            return true;
        }
        return false;
    }

    function prepareMessage(address token, uint256 tokenId, uint256 price, uint256 value, uint256 fee, uint256 nonce) internal pure returns (string memory) {
        return prepareMessage(token, tokenId, price, fee, nonce).append(". value: ", value.toString());
    }
}

