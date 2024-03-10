pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./Roles.sol";
import "./ERC721.sol";
import "./ERC1155.sol";
import "./AbstractSale.sol";
import "./TransferProxy.sol";

/// @title IERC721Sale
contract IERC721Sale {
    function getNonce(IERC721 token, uint256 tokenId) view public returns (uint256);
}

/// @title ERC721SaleNonceHolder
/// @notice The contract manages nonce values for the sales.
contract ERC721SaleNonceHolder is OwnableOperatorRole {
    /// @notice token nonces
    mapping(bytes32 => uint256) public nonces;
    /// @notice Previous nonce manager contract address.
    IERC721Sale public previous;

    /// @notice The contract constructor.
    /// @param _previous - The value of the previous nonce manager contract.
    constructor(IERC721Sale _previous) public {
        previous = _previous;
    }

    /// @notice Get nonce value for the token.
    /// @param token - Token's contract address.
    /// @param tokenId - Token id.
    /// @return The nonce value.
    function getNonce(IERC721 token, uint256 tokenId) view public returns (uint256) {
        uint256 newNonce = nonces[getPositionKey(token, tokenId)];
        if (newNonce != 0) {
            return newNonce;
        }
        if (address(previous) == address(0x0)) {
            return 0;
        }
        return previous.getNonce(token, tokenId);
    }

    /// @notice Sets new nonce value for the token. Can only be called by the operator.
    /// @param token - Token's contract address.
    /// @param tokenId - Token id.
    /// @param nonce - The new value for the nonce.
    function setNonce(IERC721 token, uint256 tokenId, uint256 nonce) public onlyOperator {
        nonces[getPositionKey(token, tokenId)] = nonce;
    }

    /// @notice Encode the token info to use as a mapping key.
    /// @param token - Token's contract address.
    /// @param tokenId - Token id.
    /// @return Encoded key for the token.
    function getPositionKey(IERC721 token, uint256 tokenId) pure public returns (bytes32) {
        return keccak256(abi.encodePacked(token, tokenId));
    }
}

/// @title ERC721Sale
/// @notice Allows users to exchange ERC721 tokens for the Ether.
contract ERC721Sale is Ownable, IERC721Receiver, AbstractSale {
    using AddressLibrary for address;
    using UintLibrary for uint256;
    using StringLibrary for string;

    event Cancel(address indexed token, uint256 indexed tokenId, address owner, uint256 nonce);
    event Buy(address indexed token, uint256 indexed tokenId, address seller, address buyer, uint256 price, uint256 nonce);

    /// @notice The address of a transfer proxy for ERC721 and ERC1155 tokens.
    TransferProxy public transferProxy;
    /// @notice The address of a nonce manager contract.
    ERC721SaleNonceHolder public nonceHolder;

    /// @param _transferProxy - The address of a deployed TransferProxy contract.
    /// @param _nonceHolder - The address of a deployed ERC721SaleNonceHolder contract.
    /// @param beneficiary - The address of a fee recipient.
    constructor(TransferProxy _transferProxy, ERC721SaleNonceHolder _nonceHolder, address payable beneficiary) AbstractSale(beneficiary) public {
        transferProxy = _transferProxy;
        nonceHolder = _nonceHolder;
    }

    /// @notice Cancel the token sale order. Can be called only by the token owner.
    ///         The function makes signed buy message invalid by increasing the nonce for the token.
    /// @param token - The address of the token contract.
    /// @param tokenId - The token id.
    function cancel(IERC721 token, uint256 tokenId) public {
        address owner = token.ownerOf(tokenId);
        require(owner == msg.sender, "not an owner");
        uint256 nonce = nonceHolder.getNonce(token, tokenId) + 1;
        nonceHolder.setNonce(token, tokenId, nonce);
        emit Cancel(address(token), tokenId, owner, nonce);
    }

    /// @notice This function is called to buy ERC721 token in exchange for ETH.
    /// @notice ERC721 token must be approved for this contract before calling this function.
    /// @notice To pay with ETH, transaction must send ether within the calling transaction.
    /// @notice Buyer's payment value is calculated as `price + buyerFee%`. `buyerFee` can be obtaind by calling buyerFee() function of this contract (inherited from AbstractSale).
    /// @param token - ERC721 token contracy address.
    /// @param tokenId - ERC721 token id for sale.
    /// @param price - The price of ERC721 token in WEI.
    /// @param sellerFee - Amount for seller's fee. Represented as percents * 100 (100% => 10000. 1% => 100).
    /// @param signature - Signed message with parameters of the format: `${token.address.toLowerCase()}. tokenId: ${tokenId}. price: ${price}. nonce: ${nonce}. fee: ${sellerFee}`
    ///        If sellerFee is zero, than the format is `${token.address.toLowerCase()}. tokenId: ${tokenId}. price: ${price}. nonce: ${nonce}`
    ///        Where token.address.toLowerCase() is the address of the ERC721 token contract (parameter `value`).
    ///        The `nonce` can be obtained from the nonceHolder with `getNonce` function.
    ///        Message must be prefixed with: `"\x19Ethereum Signed Message:\n" + message.length`.
    ///        Some libraries, for example web3.accounts.sign, will automatically prefix the message.
    function buy(IERC721 token, uint256 tokenId, uint256 price, uint256 sellerFee, Sig memory signature) public payable {
        address payable owner = address(uint160(token.ownerOf(tokenId)));
        uint256 nonce = nonceHolder.getNonce(token, tokenId);
        uint256 buyerFeeValue = price.mul(buyerFee).div(10000);
        require(msg.value == price + buyerFeeValue, "msg.value is incorrect");
        require(owner == prepareMessage(address(token), tokenId, price, sellerFee, nonce).recover(signature.v, signature.r, signature.s), "owner should sign correct message");
        transferProxy.erc721safeTransferFrom(token, owner, msg.sender, tokenId);
        transferEther(token, tokenId, owner, price, sellerFee);
        nonceHolder.setNonce(token, tokenId, nonce + 1);
        emit Buy(address(token), tokenId, owner, msg.sender, price, nonce + 1);
    }

    /// @notice Standard ERC721 receiver function implementation.
    function onERC721Received(address, address, uint256, bytes memory) public returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

