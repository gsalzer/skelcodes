// File: @openzeppelin\contracts\utils\introspection\IERC165.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin\contracts\token\ERC1155\IERC1155.sol

// SPDX_License_Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: contracts\model\IERC1155Views.sol

// SPDX_License_Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @title IERC1155Views - An optional utility interface to improve the ERC-1155 Standard.
 * @dev This interface introduces some additional capabilities for ERC-1155 Tokens.
 */
interface IERC1155Views {

    /**
     * @dev Returns the total supply of the given token id
     * @param itemId the id of the token whose availability you want to know 
     */
    function totalSupply(uint256 itemId) external view returns (uint256);

    /**
     * @dev Returns the name of the given token id
     * @param itemId the id of the token whose name you want to know 
     */
    function name(uint256 itemId) external view returns (string memory);

    /**
     * @dev Returns the symbol of the given token id
     * @param itemId the id of the token whose symbol you want to know 
     */
    function symbol(uint256 itemId) external view returns (string memory);

    /**
     * @dev Returns the decimals of the given token id
     * @param itemId the id of the token whose decimals you want to know 
     */
    function decimals(uint256 itemId) external view returns (uint256);

    /**
     * @dev Returns the uri of the given token id
     * @param itemId the id of the token whose uri you want to know 
     */
    function uri(uint256 itemId) external view returns (string memory);
}

// File: contracts\model\Item.sol

//SPDX_License_Identifier: MIT

pragma solidity >=0.7.0;
pragma abicoder v2;


struct Header {
    address host;
    string name;
    string symbol;
    string uri;
}

struct CreateItem {
    Header header;
    bytes32 collectionId;
    uint256 id;
    address[] accounts;
    uint256[] amounts;
}

interface Item is IERC1155, IERC1155Views {

    event CollectionItem(bytes32 indexed fromCollectionId, bytes32 indexed toCollectionId, uint256 indexed itemId);

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint256);

    function burn(address account, uint256 itemId, uint256 amount) external;
    function burnBatch(address account, uint256[] calldata itemIds, uint256[] calldata amounts) external;

    function burn(address account, uint256 itemId, uint256 amount, bytes calldata data) external;
    function burnBatch(address account, uint256[] calldata itemIds, uint256[] calldata amounts, bytes calldata data) external;

    function mintItems(CreateItem[] calldata items) external returns(uint256[] memory itemIds);
    function setItemsCollection(uint256[] calldata itemIds, bytes32[] calldata collectionIds) external returns(bytes32[] memory oldCollectionIds);
    function setItemsMetadata(uint256[] calldata itemIds, Header[] calldata newValues) external returns(Header[] memory oldValues);

    function interoperableOf(uint256 itemId) external view returns(address);
}

// File: @ethereansos\swissknife\contracts\generic\model\ILazyInitCapableElement.sol

// SPDX_License_Identifier: MIT
pragma solidity >=0.7.0;

interface ILazyInitCapableElement is IERC165 {

    function lazyInit(bytes calldata lazyInitData) external returns(bytes memory initResponse);
    function initializer() external view returns(address);

    event Host(address indexed from, address indexed to);

    function host() external view returns(address);
    function setHost(address newValue) external returns(address oldValue);

    function subjectIsAuthorizedFor(address subject, address location, bytes4 selector, bytes calldata payload, uint256 value) external view returns(bool);
}

// File: contracts\projection\IItemProjection.sol

//SPDX_License_Identifier: MIT

pragma solidity >=0.7.0;
//pragma abicoder v2;


interface IItemProjection is Item, ILazyInitCapableElement {

    function mainInterface() external view returns(address);

    function collectionId() external view returns(bytes32);
    function uri() external view returns(string memory);
    function plainUri() external view returns(string memory);
    function itemPlainUri(uint256 itemId) external view returns(string memory);
    function setHeader(Header calldata value) external returns(Header memory oldValue);

    function toInteroperableInterfaceAmount(uint256 amount, uint256 itemId, address account) external view returns(uint256);
    function toMainInterfaceAmount(uint256 amount, uint256 itemId) external view returns(uint256);
}

// File: contracts\projection\multiOperatorHost\model\IMultiOperatorHost.sol

//SPDX_License_Identifier: MIT

pragma solidity >=0.7.0;
//pragma abicoder v2;

interface IMultiOperatorHost is IItemProjection {

    event Operator(uint256 indexed op, address indexed from, address indexed to);

    function operator(uint256 op) external view returns (address);

    function setOperator(uint256 op, address newValue) external returns(address oldValue);
}

// File: contracts\model\IItemMainInterface.sol

//SPDX_License_Identifier: MIT
pragma solidity >=0.7.0;

struct ItemData {
    bytes32 collectionId;
    Header header;
    bytes32 domainSeparator;
    uint256 totalSupply;
    mapping(address => uint256) balanceOf;
    mapping(address => mapping(address => uint256)) allowance;
    mapping(address => uint256) nonces;
}

interface IItemMainInterface is Item {

    event Collection(address indexed from, address indexed to, bytes32 indexed collectionId);

    function interoperableInterfaceModel() external view returns(address);

    function uri() external view returns(string memory);
    function plainUri() external view returns(string memory);
    function dynamicUriResolver() external view returns(address);
    function hostInitializer() external view returns(address);

    function collection(bytes32 collectionId) external view returns(address host, string memory name, string memory symbol, string memory uri);
    function collectionUri(bytes32 collectionId) external view returns(string memory);
    function createCollection(Header calldata _collection, CreateItem[] calldata items) external returns(bytes32 collectionId, uint256[] memory itemIds);
    function setCollectionsMetadata(bytes32[] calldata collectionIds, Header[] calldata values) external returns(Header[] memory oldValues);

    function setApprovalForAllByCollectionHost(bytes32 collectionId, address account, address operator, bool approved) external;

    function item(uint256 itemId) external view returns(bytes32 collectionId, Header memory header, bytes32 domainSeparator, uint256 totalSupply);

    function mintTransferOrBurn(bool isMulti, bytes calldata data) external;

    function allowance(address account, address spender, uint256 itemId) external view returns(uint256);
    function approve(address account, address spender, uint256 amount, uint256 itemId) external;
    function TYPEHASH_PERMIT() external view returns (bytes32);
    function EIP712_PERMIT_DOMAINSEPARATOR_NAME_AND_VERSION() external view returns(string memory domainSeparatorName, string memory domainSeparatorVersion);
    function permit(uint256 itemId, address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function nonces(address owner, uint256 itemId) external view returns(uint256);
}

// File: @openzeppelin\contracts\token\ERC1155\IERC1155Receiver.sol

// SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

// SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @ethereansos\swissknife\contracts\lib\GeneralUtilities.sol

// SPDX_License_Identifier: MIT
pragma solidity >=0.7.0;

library BehaviorUtilities {

    function randomKey(uint256 i) internal view returns (bytes32) {
        return keccak256(abi.encode(i, block.timestamp, block.number, tx.origin, tx.gasprice, block.coinbase, block.difficulty, msg.sender, blockhash(block.number - 5)));
    }

    function calculateProjectedArraySizeAndLoopUpperBound(uint256 arraySize, uint256 start, uint256 offset) internal pure returns(uint256 projectedArraySize, uint256 projectedArrayLoopUpperBound) {
        if(arraySize != 0 && start < arraySize && offset != 0) {
            uint256 length = start + offset;
            if(start < (length = length > arraySize ? arraySize : length)) {
                projectedArraySize = (projectedArrayLoopUpperBound = length) - start;
            }
        }
    }
}

library ReflectionUtilities {

    function read(address subject, bytes memory inputData) internal view returns(bytes memory returnData) {
        bool result;
        (result, returnData) = subject.staticcall(inputData);
        if(!result) {
            assembly {
                revert(add(returnData, 0x20), mload(returnData))
            }
        }
    }

    function submit(address subject, uint256 value, bytes memory inputData) internal returns(bytes memory returnData) {
        bool result;
        (result, returnData) = subject.call{value : value}(inputData);
        if(!result) {
            assembly {
                revert(add(returnData, 0x20), mload(returnData))
            }
        }
    }

    function isContract(address subject) internal view returns (bool) {
        if(subject == address(0)) {
            return false;
        }
        uint256 codeLength;
        assembly {
            codeLength := extcodesize(subject)
        }
        return codeLength > 0;
    }

    function clone(address originalContract) internal returns(address copyContract) {
        assembly {
            mstore(
                0,
                or(
                    0x5880730000000000000000000000000000000000000000803b80938091923cF3,
                    mul(originalContract, 0x1000000000000000000)
                )
            )
            copyContract := create(0, 0, 32)
            switch extcodesize(copyContract)
                case 0 {
                    invalid()
                }
        }
    }
}

library BytesUtilities {

    bytes private constant ALPHABET = "0123456789abcdef";
    string internal constant BASE64_ENCODER_DATA = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function asAddress(bytes memory b) internal pure returns(address) {
        if(b.length == 0) {
            return address(0);
        }
        if(b.length == 20) {
            address addr;
            assembly {
                addr := mload(add(b, 20))
            }
            return addr;
        }
        return abi.decode(b, (address));
    }

    function asAddressArray(bytes memory b) internal pure returns(address[] memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (address[]));
        }
    }

    function asBool(bytes memory bs) internal pure returns(bool) {
        return asUint256(bs) != 0;
    }

    function asBoolArray(bytes memory b) internal pure returns(bool[] memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (bool[]));
        }
    }

    function asBytesArray(bytes memory b) internal pure returns(bytes[] memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (bytes[]));
        }
    }

    function asString(bytes memory b) internal pure returns(string memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (string));
        }
    }

    function asStringArray(bytes memory b) internal pure returns(string[] memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (string[]));
        }
    }

    function asUint256(bytes memory bs) internal pure returns(uint256 x) {
        if (bs.length >= 32) {
            assembly {
                x := mload(add(bs, add(0x20, 0)))
            }
        }
    }

    function asUint256Array(bytes memory b) internal pure returns(uint256[] memory callResult) {
        if(b.length > 0) {
            return abi.decode(b, (uint256[]));
        }
    }

    function toString(bytes memory data) internal pure returns(string memory) {
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2+i*2] = ALPHABET[uint256(uint8(data[i] >> 4))];
            str[3+i*2] = ALPHABET[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function asSingletonArray(bytes memory a) internal pure returns(bytes[] memory array) {
        array = new bytes[](1);
        array[0] = a;
    }

    function toBase64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        string memory table = BASE64_ENCODER_DATA;

        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        string memory result = new string(encodedLen + 32);

        assembly {
            mstore(result, encodedLen)

            let tablePtr := add(table, 1)

            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            let resultPtr := add(result, 32)

            for {} lt(dataPtr, endPtr) {}
            {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }
}

library StringUtilities {

    bytes1 private constant CHAR_0 = bytes1('0');
    bytes1 private constant CHAR_A = bytes1('A');
    bytes1 private constant CHAR_a = bytes1('a');
    bytes1 private constant CHAR_f = bytes1('f');

    bytes  internal constant BASE64_DECODER_DATA = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                                   hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                                   hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                                   hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function isEmpty(string memory test) internal pure returns (bool) {
        return equals(test, "");
    }

    function equals(string memory a, string memory b) internal pure returns(bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function toLowerCase(string memory str) internal pure returns(string memory) {
        bytes memory bStr = bytes(str);
        for (uint256 i = 0; i < bStr.length; i++) {
            bStr[i] = bStr[i] >= 0x41 && bStr[i] <= 0x5A ? bytes1(uint8(bStr[i]) + 0x20) : bStr[i];
        }
        return string(bStr);
    }

    function asBytes(string memory str) internal pure returns(bytes memory toDecode) {
        bytes memory data = abi.encodePacked(str);
        if(data.length == 0 || data[0] != "0" || (data[1] != "x" && data[1] != "X")) {
            return "";
        }
        uint256 start = 2;
        toDecode = new bytes((data.length - 2) / 2);

        for(uint256 i = 0; i < toDecode.length; i++) {
            toDecode[i] = bytes1(_fromHexChar(uint8(data[start++])) + _fromHexChar(uint8(data[start++])) * 16);
        }
    }

    function toBase64(string memory input) internal pure returns(string memory) {
        return BytesUtilities.toBase64(abi.encodePacked(input));
    }

    function fromBase64(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        bytes memory table = BASE64_DECODER_DATA;

        uint256 decodedLen = (data.length / 4) * 3;

        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            mstore(result, decodedLen)

            let tablePtr := add(table, 1)

            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            let resultPtr := add(result, 32)

            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }

    function _fromHexChar(uint8 c) private pure returns (uint8) {
        bytes1 charc = bytes1(c);
        return charc < CHAR_0 || charc > CHAR_f ? 0 : (charc < CHAR_A ? 0 : 10) + c - uint8(charc < CHAR_A ? CHAR_0 : charc < CHAR_a ? CHAR_A : CHAR_a);
    }
}

library Uint256Utilities {
    function asSingletonArray(uint256 n) internal pure returns(uint256[] memory array) {
        array = new uint256[](1);
        array[0] = n;
    }

    function toHex(uint256 _i) internal pure returns (string memory) {
        return BytesUtilities.toString(abi.encodePacked(_i));
    }

    function toString(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function sum(uint256[] memory arr) internal pure returns (uint256 result) {
        for(uint256 i = 0; i < arr.length; i++) {
            result += arr[i];
        }
    }
}

library AddressUtilities {
    function asSingletonArray(address a) internal pure returns(address[] memory array) {
        array = new address[](1);
        array[0] = a;
    }

    function toString(address _addr) internal pure returns (string memory) {
        return _addr == address(0) ? "0x0000000000000000000000000000000000000000" : BytesUtilities.toString(abi.encodePacked(_addr));
    }
}

library Bytes32Utilities {

    function asSingletonArray(bytes32 a) internal pure returns(bytes32[] memory array) {
        array = new bytes32[](1);
        array[0] = a;
    }

    function toString(bytes32 bt) internal pure returns (string memory) {
        return bt == bytes32(0) ?  "0x0000000000000000000000000000000000000000000000000000000000000000" : BytesUtilities.toString(abi.encodePacked(bt));
    }
}

library TransferUtilities {
    using ReflectionUtilities for address;

    function balanceOf(address erc20TokenAddress, address account) internal view returns(uint256) {
        if(erc20TokenAddress == address(0)) {
            return account.balance;
        }
        return abi.decode(erc20TokenAddress.read(abi.encodeWithSelector(IERC20(erc20TokenAddress).balanceOf.selector, account)), (uint256));
    }

    function allowance(address erc20TokenAddress, address account, address spender) internal view returns(uint256) {
        if(erc20TokenAddress == address(0)) {
            return 0;
        }
        return abi.decode(erc20TokenAddress.read(abi.encodeWithSelector(IERC20(erc20TokenAddress).allowance.selector, account, spender)), (uint256));
    }

    function safeApprove(address erc20TokenAddress, address spender, uint256 value) internal {
        bytes memory returnData = erc20TokenAddress.submit(0, abi.encodeWithSelector(IERC20(erc20TokenAddress).approve.selector, spender, value));
        require(returnData.length == 0 || abi.decode(returnData, (bool)), 'APPROVE_FAILED');
    }

    function safeTransfer(address erc20TokenAddress, address to, uint256 value) internal {
        if(value == 0) {
            return;
        }
        if(erc20TokenAddress == address(0)) {
            to.submit(value, "");
            return;
        }
        bytes memory returnData = erc20TokenAddress.submit(0, abi.encodeWithSelector(IERC20(erc20TokenAddress).transfer.selector, to, value));
        require(returnData.length == 0 || abi.decode(returnData, (bool)), 'TRANSFER_FAILED');
    }

    function safeTransferFrom(address erc20TokenAddress, address from, address to, uint256 value) internal {
        if(value == 0) {
            return;
        }
        if(erc20TokenAddress == address(0)) {
            to.submit(value, "");
            return;
        }
        bytes memory returnData = erc20TokenAddress.submit(0, abi.encodeWithSelector(IERC20(erc20TokenAddress).transferFrom.selector, from, to, value));
        require(returnData.length == 0 || abi.decode(returnData, (bool)), 'TRANSFERFROM_FAILED');
    }
}

// File: @ethereansos\swissknife\contracts\generic\impl\LazyInitCapableElement.sol

// SPDX_License_Identifier: MIT
pragma solidity >=0.7.0;


abstract contract LazyInitCapableElement is ILazyInitCapableElement {
    using ReflectionUtilities for address;

    address public override initializer;
    address public override host;

    constructor(bytes memory lazyInitData) {
        if(lazyInitData.length > 0) {
            _privateLazyInit(lazyInitData);
        }
    }

    function lazyInit(bytes calldata lazyInitData) override external returns (bytes memory lazyInitResponse) {
        return _privateLazyInit(lazyInitData);
    }

    function supportsInterface(bytes4 interfaceId) override external view returns(bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == this.supportsInterface.selector ||
            interfaceId == type(ILazyInitCapableElement).interfaceId ||
            interfaceId == this.lazyInit.selector ||
            interfaceId == this.initializer.selector ||
            interfaceId == this.subjectIsAuthorizedFor.selector ||
            interfaceId == this.host.selector ||
            interfaceId == this.setHost.selector ||
            _supportsInterface(interfaceId);
    }

    function setHost(address newValue) external override authorizedOnly returns(address oldValue) {
        oldValue = host;
        host = newValue;
        emit Host(oldValue, newValue);
    }

    function subjectIsAuthorizedFor(address subject, address location, bytes4 selector, bytes calldata payload, uint256 value) public override virtual view returns(bool) {
        (bool chidlElementValidationIsConsistent, bool chidlElementValidationResult) = _subjectIsAuthorizedFor(subject, location, selector, payload, value);
        if(chidlElementValidationIsConsistent) {
            return chidlElementValidationResult;
        }
        if(subject == host) {
            return true;
        }
        if(!host.isContract()) {
            return false;
        }
        (bool result, bytes memory resultData) = host.staticcall(abi.encodeWithSelector(ILazyInitCapableElement(host).subjectIsAuthorizedFor.selector, subject, location, selector, payload, value));
        return result && abi.decode(resultData, (bool));
    }

    function _privateLazyInit(bytes memory lazyInitData) private returns (bytes memory lazyInitResponse) {
        require(initializer == address(0), "init");
        initializer = msg.sender;
        (host, lazyInitResponse) = abi.decode(lazyInitData, (address, bytes));
        emit Host(address(0), host);
        lazyInitResponse = _lazyInit(lazyInitResponse);
    }

    function _lazyInit(bytes memory) internal virtual returns (bytes memory) {
        return "";
    }

    function _supportsInterface(bytes4 selector) internal virtual view returns (bool);

    function _subjectIsAuthorizedFor(address, address, bytes4, bytes calldata, uint256) internal virtual view returns(bool, bool) {
    }

    modifier authorizedOnly {
        require(_authorizedOnly(), "unauthorized");
        _;
    }

    function _authorizedOnly() internal returns(bool) {
        return subjectIsAuthorizedFor(msg.sender, address(this), msg.sig, msg.data, msg.value);
    }
}

// File: contracts\util\ERC1155CommonLibrary.sol

//SPDX_License_Identifier: MIT
pragma solidity >=0.7.0;


library ERC1155CommonLibrary {
    using ReflectionUtilities for address;

    function doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) internal {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver(to).onERC1155Received.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) internal {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response !=
                    IERC1155Receiver(to).onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }
}

// File: contracts\projection\ItemProjection.sol

//SPDX_License_Identifier: MIT

pragma solidity >=0.7.0;
//pragma abicoder v2;







abstract contract ItemProjection is IItemProjection, LazyInitCapableElement {
    using AddressUtilities for address;
    using BytesUtilities for bytes;

    address public override mainInterface;
    bytes32 public override collectionId;

    constructor(bytes memory lazyInitData) LazyInitCapableElement(lazyInitData) {
    }

    function _lazyInit(bytes memory lazyInitParams) override virtual internal returns(bytes memory lazyInitResponse) {
        (mainInterface, lazyInitResponse) = abi.decode(lazyInitParams, (address, bytes));
        Header memory header;
        CreateItem[] memory items;
        (collectionId, header, items, lazyInitResponse) = abi.decode(lazyInitResponse, (bytes32, Header, CreateItem[], bytes));
        if(collectionId == bytes32(0)) {
            header.host = address(this);
            (collectionId,) = IItemMainInterface(mainInterface).createCollection(header, items);
        } else if(items.length > 0) {
            IItemMainInterface(mainInterface).mintItems(items);
        }
        lazyInitResponse = _projectionLazyInit(lazyInitResponse);
    }

    function _supportsInterface(bytes4 interfaceId) override internal pure returns (bool) {
        return
            interfaceId == type(IItemProjection).interfaceId ||
            interfaceId == 0xeac989f8 ||//uri()
            interfaceId == this.mainInterface.selector ||
            interfaceId == this.collectionId.selector ||
            interfaceId == this.plainUri.selector ||
            interfaceId == this.itemPlainUri.selector ||
            interfaceId == this.setHeader.selector ||
            interfaceId == this.toInteroperableInterfaceAmount.selector ||
            interfaceId == this.toMainInterfaceAmount.selector ||
            interfaceId == this.balanceOf.selector ||
            interfaceId == this.balanceOfBatch.selector ||
            interfaceId == this.setApprovalForAll.selector ||
            interfaceId == this.isApprovedForAll.selector ||
            interfaceId == this.safeTransferFrom.selector ||
            interfaceId == this.safeBatchTransferFrom.selector ||
            interfaceId == 0xd9b67a26 ||//OpenSea Standard
            interfaceId == type(IERC1155Views).interfaceId ||
            interfaceId == this.totalSupply.selector ||
            interfaceId == 0x00ad800c ||//name(uint256)
            interfaceId == 0x4e41a1fb ||//symbol(uint256)
            interfaceId == 0x3f47e662 ||//decimals(uint256)
            interfaceId == 0x313ce567 ||//decimals()
            interfaceId == 0x0e89341c ||//uri(uint256)
            interfaceId == type(Item).interfaceId ||
            interfaceId == 0x06fdde03 ||//name()
            interfaceId == 0x95d89b41 ||//symbol()
            interfaceId == 0xf5298aca ||//burn(address,uint256,uint256)
            interfaceId == 0x6b20c454 ||//burnBatch(address,uint256[],uint256[])
            interfaceId == 0x8a94b05f ||//burn(address,uint256,uint256,bytes)
            interfaceId == 0x5473422e ||//burnBatch(address,uint256[],uint256[],bytes)
            interfaceId == this.mintItems.selector ||
            interfaceId == this.setItemsCollection.selector ||
            interfaceId == this.setItemsMetadata.selector ||
            interfaceId == this.interoperableOf.selector;
    }

    function _projectionLazyInit(bytes memory) internal virtual returns (bytes memory) {
        return "";
    }

    function setHeader(Header calldata value) authorizedOnly override external virtual returns(Header memory oldValue) {
        Header[] memory values = new Header[](1);
        values[0] = value;
        bytes32[] memory collectionIds = new bytes32[](1);
        collectionIds[0] = collectionId;
        return IItemMainInterface(mainInterface).setCollectionsMetadata(collectionIds, values)[0];
    }

    function setItemsMetadata(uint256[] calldata itemIds, Header[] calldata values) authorizedOnly override external virtual returns(Header[] memory oldValues) {
        return IItemMainInterface(mainInterface).setItemsMetadata(itemIds, values);
    }

    function mintItems(CreateItem[] memory items) authorizedOnly virtual override public returns(uint256[] memory itemIds) {
        uint256 multiplier = 10 ** (18 - decimals(0));
        for(uint256 i = 0; i < items.length; i++) {
            items[i].collectionId = collectionId;
            uint256[] memory amounts = items[i].amounts;
            for(uint256 z = 0; z < amounts.length; z++) {
                amounts[z] = amounts[z] * multiplier;
            }
            items[i].amounts = amounts;
        }
        return IItemMainInterface(mainInterface).mintItems(items);
    }

    function setItemsCollection(uint256[] calldata itemIds, bytes32[] calldata collectionIds) authorizedOnly virtual override external returns(bytes32[] memory oldCollectionIds) {
        return IItemMainInterface(mainInterface).setItemsCollection(itemIds, collectionIds);
    }

    function name() override external view returns(string memory value) {
        (,value,,) = IItemMainInterface(mainInterface).collection(collectionId);
    }

    function symbol() override external view returns(string memory value) {
        (,,value,) = IItemMainInterface(mainInterface).collection(collectionId);
    }

    function plainUri() override public view returns(string memory value) {
        (,,,value) = IItemMainInterface(mainInterface).collection(collectionId);
    }

    function uri() override public view returns(string memory) {
        return IItemMainInterface(mainInterface).collectionUri(collectionId);
    }

    function interoperableOf(uint256 itemId) override public pure returns(address) {
        return address(uint160(itemId));
    }

    function name(uint256 itemId) override external view returns(string memory) {
        (,Header memory header,,) = IItemMainInterface(mainInterface).item(itemId);
        return header.name;
    }

    function symbol(uint256 itemId) override external view returns(string memory) {
        (,Header memory header,,) = IItemMainInterface(mainInterface).item(itemId);
        return header.symbol;
    }

    function decimals(uint256) override public virtual view returns(uint256) {
        return 18;
    }

    function decimals() external override view returns(uint256) {
        return 18;
    }

    function toMainInterfaceAmount(uint256 interoperableInterfaceAmount, uint256 itemId) override public view returns(uint256) {
        if(interoperableInterfaceAmount == 0) {
            return 0;
        }
        uint256 itemDecimals = decimals(itemId);
        if(itemDecimals == 18) {
            return interoperableInterfaceAmount;
        }
        uint256 interoperableTotalSupply = IERC20(interoperableOf(itemId)).totalSupply();
        uint256 interoperableUnity = 1e18;
        uint256 interoperableHalfUnity = (interoperableUnity / 51) * 100;
        uint256 mainInterfaceUnity = 10 ** itemDecimals;
        if(interoperableTotalSupply <= interoperableUnity && interoperableInterfaceAmount <= interoperableUnity) {
            return interoperableInterfaceAmount < interoperableHalfUnity ? 0 : mainInterfaceUnity;
        }
        return (interoperableInterfaceAmount * mainInterfaceUnity) / interoperableUnity;
    }

    function toInteroperableInterfaceAmount(uint256 mainInterfaceAmount, uint256 itemId, address account) override public view returns(uint256) {
        if(mainInterfaceAmount == 0) {
            return 0;
        }
        if(decimals(itemId) == 18) {
            return mainInterfaceAmount;
        }
        uint256 interoperableInterfaceAmount = mainInterfaceAmount * 10 ** (18 - decimals(itemId));
        if(account == address(0)) {
            return interoperableInterfaceAmount;
        }
        uint256 interoperableBalance = IItemMainInterface(mainInterface).balanceOf(account, itemId);
        if(interoperableBalance == 0) {
            return interoperableInterfaceAmount;
        }
        uint256 interoperableTotalSupply = IERC20(interoperableOf(itemId)).totalSupply();
        uint256 interoperableUnity = 1e18;
        uint256 interoperableHalfUnity = (interoperableUnity / 51) * 100;
        if(interoperableTotalSupply <= interoperableUnity && interoperableInterfaceAmount == interoperableUnity && interoperableBalance >= interoperableHalfUnity) {
            return interoperableBalance < interoperableInterfaceAmount ? interoperableBalance : interoperableInterfaceAmount;
        }
        return interoperableInterfaceAmount;
    }

    function uri(uint256 itemId) override external view returns(string memory) {
        return IItemMainInterface(mainInterface).uri(itemId);
    }

    function itemPlainUri(uint256 itemId) override external view returns(string memory) {
        (, Header memory header,,) = IItemMainInterface(mainInterface).item(itemId);
        return header.uri;
    }

    function totalSupply(uint256 itemId) override external view returns (uint256) {
        return IItemMainInterface(mainInterface).totalSupply(itemId);
    }

    function balanceOf(address account, uint256 itemId) override external view returns (uint256) {
        return toMainInterfaceAmount(IItemMainInterface(mainInterface).balanceOf(account, itemId), itemId);
    }

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata itemIds) override external view returns (uint256[] memory balances) {
        balances = IItemMainInterface(mainInterface).balanceOfBatch(accounts, itemIds);
        for(uint256 i = 0; i < itemIds.length; i++) {
            balances[i] = toMainInterfaceAmount(balances[i], itemIds[i]);
        }
    }

    function isApprovedForAll(address account, address operator) override external view returns (bool) {
        return IItemMainInterface(mainInterface).isApprovedForAll(account, operator);
    }

    function setApprovalForAll(address operator, bool approved) override external virtual {
        IItemMainInterface(mainInterface).setApprovalForAllByCollectionHost(collectionId, msg.sender, operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 itemId, uint256 amount, bytes calldata data) override external virtual {
        require(from != address(0), "required from");
        require(to != address(0), "required to");
        IItemMainInterface(mainInterface).mintTransferOrBurn(false, abi.encode(msg.sender, from, to, itemId, toInteroperableInterfaceAmount(amount, itemId, from)));
        ERC1155CommonLibrary.doSafeTransferAcceptanceCheck(msg.sender, from, to, itemId, amount, data);
        emit TransferSingle(msg.sender, from, to, itemId, amount);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] calldata itemIds, uint256[] calldata amounts, bytes calldata data) override external virtual {
        require(from != address(0), "required from");
        require(to != address(0), "required to");
        uint256[] memory interoperableInterfaceAmounts = new uint256[](amounts.length);
        for(uint256 i = 0 ; i < interoperableInterfaceAmounts.length; i++) {
            interoperableInterfaceAmounts[i] = toInteroperableInterfaceAmount(amounts[i], itemIds[i], from);
        }
        IItemMainInterface(mainInterface).mintTransferOrBurn(true, abi.encode(true, abi.encode(abi.encode(msg.sender, from, to, itemIds, interoperableInterfaceAmounts).asSingletonArray())));
        ERC1155CommonLibrary.doSafeBatchTransferAcceptanceCheck(msg.sender, from, to, itemIds, amounts, data);
        emit TransferBatch(msg.sender, from, to, itemIds, amounts);
    }

    function burn(address account, uint256 itemId, uint256 amount) override external {
        burn(account, itemId, amount, "");
    }

    function burnBatch(address account, uint256[] calldata itemIds, uint256[] calldata amounts) override external {
        burnBatch(account, itemIds, amounts, "");
    }

    function burn(address account, uint256 itemId, uint256 amount, bytes memory) override virtual public {
        require(account != address(0), "required account");
        IItemMainInterface(mainInterface).mintTransferOrBurn(false, abi.encode(msg.sender, account, address(0), itemId, toInteroperableInterfaceAmount(amount, itemId, account)));
        emit TransferSingle(msg.sender, account, address(0), itemId, amount);
    }

    function burnBatch(address account, uint256[] calldata itemIds, uint256[] calldata amounts, bytes memory) override virtual public {
        require(account != address(0), "required account");
        uint256[] memory interoperableInterfaceAmounts = new uint256[](amounts.length);
        for(uint256 i = 0 ; i < interoperableInterfaceAmounts.length; i++) {
            interoperableInterfaceAmounts[i] = toInteroperableInterfaceAmount(amounts[i], itemIds[i], account);
        }
        IItemMainInterface(mainInterface).mintTransferOrBurn(true, abi.encode(true, abi.encode(abi.encode(msg.sender, account, address(0), itemIds, interoperableInterfaceAmounts).asSingletonArray())));
        emit TransferBatch(msg.sender, account, address(0), itemIds, amounts);
    }
}

// File: contracts\projection\multiOperatorHost\impl\MultiOperatorHost.sol

//SPDX_License_Identifier: MIT

pragma solidity >=0.7.0;
//pragma abicoder v2;


contract MultiOperatorHost is IMultiOperatorHost, ItemProjection {
    using BytesUtilities for bytes;

    mapping(uint256 => address) public override operator;

    constructor(bytes memory lazyInitData) ItemProjection(lazyInitData) {
    }

    function _projectionLazyInit(bytes memory lazyInitData) internal override returns(bytes memory) {
        require(host == address(0), "No host allowed");
        (uint256[] memory ops, address[] memory authorized) = abi.decode(lazyInitData, (uint256[], address[]));
        for(uint256 i = 0; i < ops.length; i++) {
            _setOperator(ops[i], authorized[i]);
        }
        return "";
    }

    function setOperator(uint256 op, address newValue) external override returns(address oldValue) {
        require(operator[op] == msg.sender, "Unauthorized");
        return _setOperator(op, newValue);
    }

    function setApprovalForAll(address, bool) authorizedOnly override(ItemProjection, IERC1155) external {
        revert();
    }

    function setHeader(Header memory value) authorizedOnly override(IItemProjection, ItemProjection) external returns(Header memory oldValue) {
        value.host = address(this);
        Header[] memory values = new Header[](1);
        values[0] = value;
        bytes32[] memory collectionIds = new bytes32[](1);
        collectionIds[0] = collectionId;
        oldValue = IItemMainInterface(mainInterface).setCollectionsMetadata(collectionIds, values)[0];
        (address currentHost,,,) =  IItemMainInterface(mainInterface).collection(collectionId);
        require(currentHost == address(this), "Invalid change");
        return oldValue;
    }

    function safeTransferFrom(address from, address to, uint256 itemId, uint256 amount, bytes calldata data) authorizedOnly override(ItemProjection, IERC1155) external {
        require(from != address(0), "required from");
        require(to != address(0), "required to");
        IItemMainInterface(mainInterface).mintTransferOrBurn(false, abi.encode(from, from, to, itemId, toInteroperableInterfaceAmount(amount, itemId, from)));
        ERC1155CommonLibrary.doSafeTransferAcceptanceCheck(msg.sender, from, to, itemId, amount, data);
        emit TransferSingle(msg.sender, from, to, itemId, amount);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] calldata itemIds, uint256[] calldata amounts, bytes calldata data) authorizedOnly override(ItemProjection, IERC1155) external {
        require(from != address(0), "required from");
        require(to != address(0), "required to");
        uint256[] memory interoperableInterfaceAmounts = new uint256[](amounts.length);
        for(uint256 i = 0 ; i < interoperableInterfaceAmounts.length; i++) {
            interoperableInterfaceAmounts[i] = toInteroperableInterfaceAmount(amounts[i], itemIds[i], from);
        }
        IItemMainInterface(mainInterface).mintTransferOrBurn(true, abi.encode(true, abi.encode(abi.encode(from, from, to, itemIds, interoperableInterfaceAmounts).asSingletonArray())));
        ERC1155CommonLibrary.doSafeBatchTransferAcceptanceCheck(msg.sender, from, to, itemIds, amounts, data);
        emit TransferBatch(msg.sender, from, to, itemIds, amounts);
    }

    function burn(address account, uint256 itemId, uint256 amount, bytes memory) authorizedOnly override(ItemProjection, Item) public {
        require(account != address(0), "required account");
        IItemMainInterface(mainInterface).mintTransferOrBurn(false, abi.encode(account, account, address(0), itemId, toInteroperableInterfaceAmount(amount, itemId, account)));
        emit TransferSingle(msg.sender, account, address(0), itemId, amount);
    }

    function burnBatch(address account, uint256[] calldata itemIds, uint256[] calldata amounts, bytes memory) authorizedOnly override(ItemProjection, Item) public {
        require(account != address(0), "required account");
        uint256[] memory interoperableInterfaceAmounts = new uint256[](amounts.length);
        for(uint256 i = 0 ; i < interoperableInterfaceAmounts.length; i++) {
            interoperableInterfaceAmounts[i] = toInteroperableInterfaceAmount(amounts[i], itemIds[i], account);
        }
        IItemMainInterface(mainInterface).mintTransferOrBurn(true, abi.encode(true, abi.encode(abi.encode(account, account, address(0), itemIds, interoperableInterfaceAmounts).asSingletonArray())));
        emit TransferBatch(msg.sender, account, address(0), itemIds, amounts);
    }

    function _setOperator(uint256 op, address newValue) private returns(address oldValue) {
        require(op > 0, "invalid op");
        oldValue = operator[op];
        operator[op] = newValue;
        emit Operator(op, oldValue, newValue);
    }

    function _subjectIsAuthorizedFor(address subject, address location, bytes4 selector, bytes calldata, uint256) internal virtual override view returns(bool, bool) {
        //1 = mintItems, 2 = burn, 3 = transfer, 4 = setMetadata, 5 = itemsCollection
        uint256 op = selector == this.mintItems.selector ? 1 :
            /*(
                selector == 0xf5298aca ||//burn(address,uint256,uint256)
                selector == 0x6b20c454 ||//burnBatch(address,uint256[],uint256[])
                selector == 0x8a94b05f ||//burn(address,uint256,uint256,bytes)
                selector == 0x5473422e   //burnBatch(address,uint256[],uint256[],bytes)
            ) ? 2 :
            (selector == this.safeTransferFrom.selector || selector == this.safeBatchTransferFrom.selector) ? 3 :*/
            (selector == this.setHeader.selector || selector == this.setItemsMetadata.selector) ? 4 : 0;
            //selector == this.setItemsCollection.selector ? 5 : 0;
        return(true, op > 0 && location == address(this) && operator[op] == subject);
    }
}
