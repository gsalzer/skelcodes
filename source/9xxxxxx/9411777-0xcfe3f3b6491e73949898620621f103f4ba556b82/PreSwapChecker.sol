pragma solidity 0.5.12;
pragma experimental ABIEncoderV2;
// File: @airswap/types/contracts/Types.sol
/*
  Copyright 2020 Swap Holdings Ltd.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
/**
  * @title Types: Library of Swap Protocol Types and Hashes
  */
library Types {
  bytes constant internal EIP191_HEADER = "\x19\x01";
  struct Order {
    uint256 nonce;                // Unique per order and should be sequential
    uint256 expiry;               // Expiry in seconds since 1 January 1970
    Party signer;                 // Party to the trade that sets terms
    Party sender;                 // Party to the trade that accepts terms
    Party affiliate;              // Party compensated for facilitating (optional)
    Signature signature;          // Signature of the order
  }
  struct Party {
    bytes4 kind;                  // Interface ID of the token
    address wallet;               // Wallet address of the party
    address token;                // Contract address of the token
    uint256 amount;               // Amount for ERC-20 or ERC-1155
    uint256 id;                   // ID for ERC-721 or ERC-1155
  }
  struct Signature {
    address signatory;            // Address of the wallet used to sign
    address validator;            // Address of the intended swap contract
    bytes1 version;               // EIP-191 signature version
    uint8 v;                      // `v` value of an ECDSA signature
    bytes32 r;                    // `r` value of an ECDSA signature
    bytes32 s;                    // `s` value of an ECDSA signature
  }
  bytes32 constant internal DOMAIN_TYPEHASH = keccak256(abi.encodePacked(
    "EIP712Domain(",
    "string name,",
    "string version,",
    "address verifyingContract",
    ")"
  ));
  bytes32 constant internal ORDER_TYPEHASH = keccak256(abi.encodePacked(
    "Order(",
    "uint256 nonce,",
    "uint256 expiry,",
    "Party signer,",
    "Party sender,",
    "Party affiliate",
    ")",
    "Party(",
    "bytes4 kind,",
    "address wallet,",
    "address token,",
    "uint256 amount,",
    "uint256 id",
    ")"
  ));
  bytes32 constant internal PARTY_TYPEHASH = keccak256(abi.encodePacked(
    "Party(",
    "bytes4 kind,",
    "address wallet,",
    "address token,",
    "uint256 amount,",
    "uint256 id",
    ")"
  ));
  /**
    * @notice Hash an order into bytes32
    * @dev EIP-191 header and domain separator included
    * @param order Order The order to be hashed
    * @param domainSeparator bytes32
    * @return bytes32 A keccak256 abi.encodePacked value
    */
  function hashOrder(
    Order calldata order,
    bytes32 domainSeparator
  ) external pure returns (bytes32) {
    return keccak256(abi.encodePacked(
      EIP191_HEADER,
      domainSeparator,
      keccak256(abi.encode(
        ORDER_TYPEHASH,
        order.nonce,
        order.expiry,
        keccak256(abi.encode(
          PARTY_TYPEHASH,
          order.signer.kind,
          order.signer.wallet,
          order.signer.token,
          order.signer.amount,
          order.signer.id
        )),
        keccak256(abi.encode(
          PARTY_TYPEHASH,
          order.sender.kind,
          order.sender.wallet,
          order.sender.token,
          order.sender.amount,
          order.sender.id
        )),
        keccak256(abi.encode(
          PARTY_TYPEHASH,
          order.affiliate.kind,
          order.affiliate.wallet,
          order.affiliate.token,
          order.affiliate.amount,
          order.affiliate.id
        ))
      ))
    ));
  }
  /**
    * @notice Hash domain parameters into bytes32
    * @dev Used for signature validation (EIP-712)
    * @param name bytes
    * @param version bytes
    * @param verifyingContract address
    * @return bytes32 returns a keccak256 abi.encodePacked value
    */
  function hashDomain(
    bytes calldata name,
    bytes calldata version,
    address verifyingContract
  ) external pure returns (bytes32) {
    return keccak256(abi.encode(
      DOMAIN_TYPEHASH,
      keccak256(name),
      keccak256(version),
      verifyingContract
    ));
  }
}
// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol
/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);
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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
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
// File: openzeppelin-solidity/contracts/introspection/IERC165.sol
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
// File: openzeppelin-solidity/contracts/token/ERC721/IERC721.sol
/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);
    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}
// File: openzeppelin-solidity/contracts/introspection/ERC165Checker.sol
/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function _supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return _supportsERC165Interface(account, _INTERFACE_ID_ERC165) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }
    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function _supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return _supportsERC165(account) &&
            _supportsERC165Interface(account, interfaceId);
    }
    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function _supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!_supportsERC165(account)) {
            return false;
        }
        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }
        // all interfaces supported
        return true;
    }
    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with the `supportsERC165` method in this library.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // success determines whether the staticcall succeeded and result determines
        // whether the contract at account indicates support of _interfaceId
        (bool success, bool result) = _callERC165SupportsInterface(account, interfaceId);
        return (success && result);
    }
    /**
     * @notice Calls the function with selector 0x01ffc9a7 (ERC165) and suppresses throw
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return success true if the STATICCALL succeeded, false otherwise
     * @return result true if the STATICCALL succeeded and the contract at account
     * indicates support of the interface with identifier interfaceId, false otherwise
     */
    function _callERC165SupportsInterface(address account, bytes4 interfaceId)
        private
        view
        returns (bool success, bool result)
    {
        bytes memory encodedParams = abi.encodeWithSelector(_INTERFACE_ID_ERC165, interfaceId);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let encodedParams_data := add(0x20, encodedParams)
            let encodedParams_size := mload(encodedParams)
            let output := mload(0x40)    // Find empty storage location using "free memory pointer"
            mstore(output, 0x0)
            success := staticcall(
                30000,                   // 30k gas
                account,                 // To addr
                encodedParams_data,
                encodedParams_size,
                output,
                0x20                     // Outputs are 32 bytes long
            )
            result := mload(output)      // Load the result
        }
    }
}
// File: @airswap/transfers/contracts/interfaces/ITransferHandler.sol
/*
  Copyright 2020 Swap Holdings Ltd.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
/**
  * @title ITransferHandler: interface for token transfers
  */
interface ITransferHandler {
 /**
  * @notice Function to wrap token transfer for different token types
  * @param from address Wallet address to transfer from
  * @param to address Wallet address to transfer to
  * @param amount uint256 Amount for ERC-20
  * @param id token ID for ERC-721
  * @param token address Contract address of token
  * @return bool on success of the token transfer
  */
  function transferTokens(
    address from,
    address to,
    uint256 amount,
    uint256 id,
    address token
  ) external returns (bool);
}
// File: openzeppelin-solidity/contracts/GSN/Context.sol
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
// File: openzeppelin-solidity/contracts/ownership/Ownable.sol
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }
    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
// File: @airswap/transfers/contracts/TransferHandlerRegistry.sol
/*
  Copyright 2020 Swap Holdings Ltd.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
/**
  * @title TransferHandlerRegistry: holds registry of contract to
  * facilitate token transfers
  */
contract TransferHandlerRegistry is Ownable {
  event AddTransferHandler(
    bytes4 kind,
    address contractAddress
  );
  // Mapping of bytes4 to contract interface type
  mapping (bytes4 => ITransferHandler) public transferHandlers;
  /**
  * @notice Adds handler to mapping
  * @param kind bytes4 Key value that defines a token type
  * @param transferHandler ITransferHandler
  */
  function addTransferHandler(bytes4 kind, ITransferHandler transferHandler)
    external onlyOwner {
      require(address(transferHandlers[kind]) == address(0), "HANDLER_EXISTS_FOR_KIND");
      transferHandlers[kind] = transferHandler;
      emit AddTransferHandler(kind, address(transferHandler));
    }
}
// File: @airswap/swap/contracts/interfaces/ISwap.sol
/*
  Copyright 2020 Swap Holdings Ltd.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
interface ISwap {
  event Swap(
    uint256 indexed nonce,
    uint256 timestamp,
    address indexed signerWallet,
    uint256 signerAmount,
    uint256 signerId,
    address signerToken,
    address indexed senderWallet,
    uint256 senderAmount,
    uint256 senderId,
    address senderToken,
    address affiliateWallet,
    uint256 affiliateAmount,
    uint256 affiliateId,
    address affiliateToken
  );
  event Cancel(
    uint256 indexed nonce,
    address indexed signerWallet
  );
  event CancelUpTo(
    uint256 indexed nonce,
    address indexed signerWallet
  );
  event AuthorizeSender(
    address indexed authorizerAddress,
    address indexed authorizedSender
  );
  event AuthorizeSigner(
    address indexed authorizerAddress,
    address indexed authorizedSigner
  );
  event RevokeSender(
    address indexed authorizerAddress,
    address indexed revokedSender
  );
  event RevokeSigner(
    address indexed authorizerAddress,
    address indexed revokedSigner
  );
  /**
    * @notice Atomic Token Swap
    * @param order Types.Order
    */
  function swap(
    Types.Order calldata order
  ) external;
  /**
    * @notice Cancel one or more open orders by nonce
    * @param nonces uint256[]
    */
  function cancel(
    uint256[] calldata nonces
  ) external;
  /**
    * @notice Cancels all orders below a nonce value
    * @dev These orders can be made active by reducing the minimum nonce
    * @param minimumNonce uint256
    */
  function cancelUpTo(
    uint256 minimumNonce
  ) external;
  /**
    * @notice Authorize a delegated sender
    * @param authorizedSender address
    */
  function authorizeSender(
    address authorizedSender
  ) external;
  /**
    * @notice Authorize a delegated signer
    * @param authorizedSigner address
    */
  function authorizeSigner(
    address authorizedSigner
  ) external;
  /**
    * @notice Revoke an authorization
    * @param authorizedSender address
    */
  function revokeSender(
    address authorizedSender
  ) external;
  /**
    * @notice Revoke an authorization
    * @param authorizedSigner address
    */
  function revokeSigner(
    address authorizedSigner
  ) external;
  function senderAuthorizations(address, address) external view returns (bool);
  function signerAuthorizations(address, address) external view returns (bool);
  function signerNonceStatus(address, uint256) external view returns (byte);
  function signerMinimumNonce(address) external view returns (uint256);
  function registry() external view returns (TransferHandlerRegistry);
}
// File: @airswap/tokens/contracts/interfaces/IWETH.sol
interface IWETH {
  function deposit() external payable;
  function withdraw(uint256) external;
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: @airswap/delegate/contracts/interfaces/IDelegate.sol
/*
  Copyright 2020 Swap Holdings Ltd.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
interface IDelegate {
  struct Rule {
    uint256 maxSenderAmount;      // The maximum amount of ERC-20 token the delegate would send
    uint256 priceCoef;            // Number to be multiplied by 10^(-priceExp) - the price coefficient
    uint256 priceExp;             // Indicates location of the decimal priceCoef * 10^(-priceExp)
  }
  event SetRule(
    address indexed owner,
    address indexed senderToken,
    address indexed signerToken,
    uint256 maxSenderAmount,
    uint256 priceCoef,
    uint256 priceExp
  );
  event UnsetRule(
    address indexed owner,
    address indexed senderToken,
    address indexed signerToken
  );
  event ProvideOrder(
    address indexed owner,
    address tradeWallet,
    address indexed senderToken,
    address indexed signerToken,
    uint256 senderAmount,
    uint256 priceCoef,
    uint256 priceExp
  );
  function setRule(
    address senderToken,
    address signerToken,
    uint256 maxSenderAmount,
    uint256 priceCoef,
    uint256 priceExp
  ) external;
  function unsetRule(
    address senderToken,
    address signerToken
  ) external;
  function provideOrder(
    Types.Order calldata order
  ) external;
  function rules(address, address) external view returns (Rule memory);
  function getSignerSideQuote(
    uint256 senderAmount,
    address senderToken,
    address signerToken
  ) external view returns (
    uint256 signerAmount
  );
  function getSenderSideQuote(
    uint256 signerAmount,
    address signerToken,
    address senderToken
  ) external view returns (
    uint256 senderAmount
  );
  function getMaxQuote(
    address senderToken,
    address signerToken
  ) external view returns (
    uint256 senderAmount,
    uint256 signerAmount
  );
  function owner()
    external view returns (address);
  function tradeWallet()
    external view returns (address);
}
// File: contracts/PreSwapChecker.sol
/**
  * @title PreSwapChecker: Helper contract to Swap protocol
  * @notice contains several helper methods that check whether
  * a Swap.order is well-formed and counterparty criteria is met
  */
contract PreSwapChecker {
  using ERC165Checker for address;
  bytes constant internal DOM_NAME = "SWAP";
  bytes constant internal DOM_VERSION = "2";
  bytes4 constant internal ERC721_INTERFACE_ID = 0x80ac58cd;
  bytes4 constant internal ERC20_INTERFACE_ID = 0x36372b07;
  IWETH public wethContract;
  /**
    * @notice Contract Constructor
    * @param preSwapCheckerWethContract address
    */
  constructor(
    address preSwapCheckerWethContract
  ) public {
    wethContract = IWETH(preSwapCheckerWethContract);
  }
  /**
    * @notice If order is going through delegate via provideOrder
    * ensure necessary checks are set
    * @param order Types.Order
    * @param delegate IDelegate
    * @return uint256 errorCount if any
    * @return bytes32[] memory array of error messages
    */
  function checkSwapDelegate(
    Types.Order calldata order,
    IDelegate delegate
    ) external view returns (uint256, bytes32[] memory ) {
    bytes32[] memory errors = new bytes32[](20);
    uint256 errorCount;
    address swap = order.signature.validator;
    IDelegate.Rule memory rule = delegate.rules(order.sender.token,order.signer.token);
    (uint256 swapErrorCount, bytes32[] memory swapErrors) = checkSwapSwap(order, false);
    if (swapErrorCount > 0) {
      errorCount = swapErrorCount;
      // copies over errors from checkSwapSwap to be outputted
      for (uint256 i = 0; i < swapErrorCount; i++) {
        errors[i] = swapErrors[i];
      }
    }
    // signature must be filled in order to use the Delegate
    if (order.signature.v == 0) {
      errors[errorCount] = "SIGNATURE_MUST_BE_SENT";
      errorCount++;
    }
    // check that the sender.wallet == tradewallet
    if (order.sender.wallet != delegate.tradeWallet()) {
      errors[errorCount] = "SENDER_WALLET_INVALID";
      errorCount++;
    }
    // ensure signer kind is ERC20
    if (order.signer.kind != ERC20_INTERFACE_ID) {
      errors[errorCount] = "SIGNER_KIND_MUST_BE_ERC20";
      errorCount++;
    }
    // ensure sender kind is ERC20
    if (order.sender.kind != ERC20_INTERFACE_ID) {
      errors[errorCount] = "SENDER_KIND_MUST_BE_ERC20";
      errorCount++;
    }
    // ensure that token pair is active with non-zero maxSenderAmount
    if (rule.maxSenderAmount == 0) {
      errors[errorCount] = "TOKEN_PAIR_INACTIVE";
      errorCount++;
    }
    if (order.sender.amount > rule.maxSenderAmount) {
      errors[errorCount] = "ORDER_AMOUNT_EXCEEDS_MAX";
      errorCount++;
    }
    // calls the getSenderSize quote to determine how much needs to be paid
    uint256 senderAmount = delegate.getSenderSideQuote(order.signer.amount, order.signer.token, order.sender.token);
    if (senderAmount == 0) {
      errors[errorCount] = "DELEGATE_UNABLE_TO_PRICE";
      errorCount++;
    } else if (order.sender.amount > senderAmount) {
      errors[errorCount] = "PRICE_INVALID";
      errorCount++;
    }
    // ensure that tradeWallet has approved delegate contract on swap
    if (!ISwap(swap).senderAuthorizations(order.sender.wallet, address(delegate))) {
      errors[errorCount] = "SENDER_UNAUTHORIZED";
      errorCount++;
    }
    return (errorCount, errors);
  }
  /**
    * @notice If order is going through wrapper to swap
    * @param order Types.Order
    * @param fromAddress address
    * @param wrapper address
    * @return uint256 errorCount if any
    * @return bytes32[] memory array of error messages
    */
  function checkSwapWrapper(
    Types.Order calldata order,
    address fromAddress,
    address wrapper
    ) external view returns (uint256, bytes32[] memory ) {
    address swap = order.signature.validator;
    // max size of the number of errors that could exist
    bytes32[] memory errors = new bytes32[](20);
    uint256 errorCount;
    (uint256 swapErrorCount, bytes32[] memory swapErrors) = checkSwapSwap(order, true);
    if (swapErrorCount > 0) {
      errorCount = swapErrorCount;
      // copies over errors from checkSwapSwap to be outputted
      for (uint256 i = 0; i < swapErrorCount; i++) {
        errors[i] = swapErrors[i];
      }
    }
    if (order.sender.wallet != fromAddress) {
      errors[errorCount] = "MSG_SENDER_MUST_BE_ORDER_SENDER";
      errorCount++;
    }
    // ensure that sender has approved wrapper contract on swap
    if (!ISwap(swap).senderAuthorizations(order.sender.wallet, wrapper)) {
      errors[errorCount] = "SENDER_UNAUTHORIZED";
      errorCount++;
    }
    // signature must be filled in order to use the Wrapper
    if (order.signature.v == 0) {
      errors[errorCount] = "SIGNATURE_MUST_BE_SENT";
      errorCount++;
    }
    // if sender has WETH token, ensure sufficient ETH balance
    if (order.sender.token == address(wethContract)) {
      if (address(order.sender.wallet).balance < order.sender.amount) {
        errors[errorCount] = "SENDER_INSUFFICIENT_ETH";
        errorCount++;
      }
    }
    // ensure that sender wallet if receiving weth has approved
    // the wrapper to transfer weth and deliver eth to the sender
    if (order.signer.token == address(wethContract)) {
      uint256 allowance = wethContract.allowance(order.sender.wallet, wrapper);
      if (allowance < order.signer.amount) {
        errors[errorCount] = "LOW_SENDER_ALLOWANCE_ON_WRAPPER";
        errorCount++;
      }
    }
    return (errorCount, errors);
  }
  /**
    * @notice Takes in an order and outputs any
    * errors that Swap would revert on
    * @param order Types.Order Order to settle
    * @return uint256 errorCount if any
    * @return bytes32[] memory array of error messages
    */
  function checkSwapSwap(
    Types.Order memory order,
    bool usingWrapper
  ) public view returns (uint256, bytes32[] memory) {
    address swap = order.signature.validator;
    bytes32 domainSeparator = Types.hashDomain(DOM_NAME, DOM_VERSION, swap);
    // max size of the number of errors that could exist
    bytes32[] memory errors = new bytes32[](14);
    uint256 errorCount;
    // Check self transfer
    if (order.signer.wallet == order.sender.wallet) {
      errors[errorCount] = "SELF_TRANSFER_INVALID";
      errorCount++;
    }
    // Check expiry
    if (order.expiry < block.timestamp) {
      errors[errorCount] = "ORDER_EXPIRED";
      errorCount++;
    }
    if (ISwap(swap).signerNonceStatus(order.signer.wallet, order.nonce) != 0x00) {
      errors[errorCount] = "ORDER_TAKEN_OR_CANCELLED";
      errorCount++;
    }
    if (order.nonce < ISwap(swap).signerMinimumNonce(order.signer.wallet)) {
      errors[errorCount] = "NONCE_TOO_LOW";
      errorCount++;
    }
    // check if ERC721 or ERC20 only amount or id set for sender
    if (order.sender.kind == ERC20_INTERFACE_ID && order.sender.id != 0) {
      errors[errorCount] = "SENDER_INVALID_ID";
      errorCount++;
    } else if (order.sender.kind == ERC721_INTERFACE_ID && order.sender.amount != 0) {
      errors[errorCount] = "SENDER_INVALID_AMOUNT";
      errorCount++;
    }
    // check if ERC721 or ERC20 only amount or id set for signer
    if (order.signer.kind == ERC20_INTERFACE_ID && order.signer.id != 0) {
      errors[errorCount] = "SIGNER_INVALID_ID";
      errorCount++;
    } else if (order.signer.kind == ERC721_INTERFACE_ID && order.signer.amount != 0) {
      errors[errorCount] = "SIGNER_INVALID_AMOUNT";
      errorCount++;
    }
    // Check valid token registry handler for sender
    if (hasValidKind(order.sender.kind, swap)) {
      // Check the order sender
      if (order.sender.wallet != address(0)) {
        // The sender was specified
        // Check if sender kind interface can correctly check balance
        if (order.sender.kind == ERC721_INTERFACE_ID && !hasValidERC71Interface(order.sender.token)) {
          errors[errorCount] = "SENDER_INVALID_ERC721";
          errorCount++;
        } else {
          // Check the order sender token balance
          if ((usingWrapper && order.sender.token != address(wethContract)) || !usingWrapper) {
            //do the balance check
            if (!hasBalance(order.sender)) {
              errors[errorCount] = "SENDER_BALANCE";
              errorCount++;
            }
          }
          // Check their approval
          if (!isApproved(order.sender, swap)) {
            errors[errorCount] = "SENDER_ALLOWANCE";
            errorCount++;
          }
        }
      }
    } else {
      errors[errorCount] = "SENDER_TOKEN_KIND_UNKNOWN";
      errorCount++;
    }
     // Check valid token registry handler for signer
    if (hasValidKind(order.signer.kind, swap)) {
      // Check if sender kind interface can correctly check balance
      if (order.signer.kind == ERC721_INTERFACE_ID && !hasValidERC71Interface(order.signer.token)) {
        errors[errorCount] = "SIGNER_INVALID_ERC721";
        errorCount++;
      } else {
        // Check the order signer token balance
        if (!hasBalance(order.signer)) {
          errors[errorCount] = "SIGNER_BALANCE";
          errorCount++;
        }
        // Check their approval
        if (!isApproved(order.signer, swap)) {
          errors[errorCount] = "SIGNER_ALLOWANCE";
          errorCount++;
        }
      }
    } else {
      errors[errorCount] = "SIGNER_TOKEN_KIND_UNKNOWN";
      errorCount++;
    }
    if (!isValid(order, domainSeparator)) {
      errors[errorCount] = "SIGNATURE_INVALID";
      errorCount++;
    }
    if (order.signature.signatory != order.signer.wallet) {
      if(!ISwap(swap).signerAuthorizations(order.signer.wallet, order.signature.signatory)) {
        errors[errorCount] = "SIGNER_UNAUTHORIZED";
        errorCount++;
      }
    }
    return (errorCount, errors);
  }
  /**
    * @notice Checks if kind is found in
    * Swap's Token Registry
    * @param kind bytes4 token type to search for
    * @param swap address Swap contract address
    * @return bool whether kind inserted is valid
    */
  function hasValidKind(
    bytes4 kind,
    address swap
  ) internal view returns (bool) {
    TransferHandlerRegistry tokenRegistry = ISwap(swap).registry();
    return (address(tokenRegistry.transferHandlers(kind)) != address(0));
  }
  /**
    * @notice Checks token has valid ERC721 interface
    * @param tokenAddress address potential ERC721 token address
    * @return bool whether address has valid interface
    */
  function hasValidERC71Interface(
    address tokenAddress
  ) internal view returns (bool) {
    return (tokenAddress._supportsInterface(ERC721_INTERFACE_ID));
  }
  /**
    * @notice Check a party has enough balance to swap
    * for ERC721 and ERC20 tokens
    * @param party Types.Party party to check balance for
    * @return bool whether party has enough balance
    */
  function hasBalance(
    Types.Party memory party
  ) internal view returns (bool) {
    if (party.kind == ERC721_INTERFACE_ID) {
      address owner = IERC721(party.token).ownerOf(party.id);
      return (owner == party.wallet);
    }
    uint256 balance = IERC20(party.token).balanceOf(party.wallet);
    return (balance >= party.amount);
  }
  /**
    * @notice Check a party has enough allowance to swap
    * for ERC721 and ERC20 tokens
    * @param party Types.Party party to check allowance for
    * @param swap address Swap address
    * @return bool whether party has sufficient allowance
    */
  function isApproved(
    Types.Party memory party,
    address swap
  ) internal view returns (bool) {
    if (party.kind == ERC721_INTERFACE_ID) {
      address approved = IERC721(party.token).getApproved(party.id);
      return (swap == approved);
    }
    uint256 allowance = IERC20(party.token).allowance(party.wallet, swap);
    return (allowance >= party.amount);
  }
  /**
    * @notice Check order signature is valid
    * @param order Types.Order Order to validate
    * @param domainSeparator bytes32 Domain identifier used in signatures (EIP-712)
    * @return bool True if order has a valid signature
    */
  function isValid(
    Types.Order memory order,
    bytes32 domainSeparator
  ) internal pure returns (bool) {
    if (order.signature.v == 0) {
      return true;
    }
    if (order.signature.version == byte(0x01)) {
      return order.signature.signatory == ecrecover(
        Types.hashOrder(
          order,
          domainSeparator
        ),
        order.signature.v,
        order.signature.r,
        order.signature.s
      );
    }
    if (order.signature.version == byte(0x45)) {
      return order.signature.signatory == ecrecover(
        keccak256(
          abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            Types.hashOrder(order, domainSeparator)
          )
        ),
        order.signature.v,
        order.signature.r,
        order.signature.s
      );
    }
    return false;
  }
}

