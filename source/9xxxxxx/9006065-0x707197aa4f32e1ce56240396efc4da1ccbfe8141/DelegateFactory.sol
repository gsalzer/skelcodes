pragma solidity 0.5.12;
pragma experimental ABIEncoderV2;
// File: @airswap/types/contracts/Types.sol
/*
  Copyright 2019 Swap Holdings Ltd.
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
    uint256 param;                // Value (ERC-20) or ID (ERC-721)
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
    "uint256 param",
    ")"
  ));
  bytes32 constant internal PARTY_TYPEHASH = keccak256(abi.encodePacked(
    "Party(",
    "bytes4 kind,",
    "address wallet,",
    "address token,",
    "uint256 param",
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
          order.signer.param
        )),
        keccak256(abi.encode(
          PARTY_TYPEHASH,
          order.sender.kind,
          order.sender.wallet,
          order.sender.token,
          order.sender.param
        )),
        keccak256(abi.encode(
          PARTY_TYPEHASH,
          order.affiliate.kind,
          order.affiliate.wallet,
          order.affiliate.token,
          order.affiliate.param
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
// File: @airswap/delegate/contracts/interfaces/IDelegate.sol
/*
  Copyright 2019 Swap Holdings Ltd.
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
    uint256 senderParam,
    address senderToken,
    address signerToken
  ) external view returns (
    uint256 signerParam
  );
  function getSenderSideQuote(
    uint256 signerParam,
    address signerToken,
    address senderToken
  ) external view returns (
    uint256 senderParam
  );
  function getMaxQuote(
    address senderToken,
    address signerToken
  ) external view returns (
    uint256 senderParam,
    uint256 signerParam
  );
  function owner()
    external view returns (address);
  function tradeWallet()
    external view returns (address);
}
// File: @airswap/indexer/contracts/interfaces/IIndexer.sol
/*
  Copyright 2019 Swap Holdings Ltd.
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
interface IIndexer {
  event CreateIndex(
    address indexed signerToken,
    address indexed senderToken,
    address indexAddress
  );
  event Stake(
    address indexed staker,
    address indexed signerToken,
    address indexed senderToken,
    uint256 stakeAmount
  );
  event Unstake(
    address indexed staker,
    address indexed signerToken,
    address indexed senderToken,
    uint256 stakeAmount
  );
  event AddTokenToBlacklist(
    address token
  );
  event RemoveTokenFromBlacklist(
    address token
  );
  function setLocatorWhitelist(
    address newLocatorWhitelist
  ) external;
  function createIndex(
    address signerToken,
    address senderToken
  ) external returns (address);
  function addTokenToBlacklist(
    address token
  ) external;
  function removeTokenFromBlacklist(
    address token
  ) external;
  function setIntent(
    address signerToken,
    address senderToken,
    uint256 stakingAmount,
    bytes32 locator
  ) external;
  function unsetIntent(
    address signerToken,
    address senderToken
  ) external;
  function stakingToken() external view returns (address);
  function indexes(address, address) external view returns (address);
  function tokenBlacklist(address) external view returns (bool);
  function getStakedAmount(
    address user,
    address signerToken,
    address senderToken
  ) external view returns (uint256);
  function getLocators(
    address signerToken,
    address senderToken,
    address cursor,
    uint256 limit
  ) external view returns (
    bytes32[] memory,
    uint256[] memory,
    address
  );
}
// File: @airswap/swap/contracts/interfaces/ISwap.sol
/*
  Copyright 2019 Swap Holdings Ltd.
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
    uint256 signerParam,
    address signerToken,
    address indexed senderWallet,
    uint256 senderParam,
    address senderToken,
    address affiliateWallet,
    uint256 affiliateParam,
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
}
// File: openzeppelin-solidity/contracts/ownership/Ownable.sol
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
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
        return msg.sender == _owner;
    }
    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
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
// File: openzeppelin-solidity/contracts/math/SafeMath.sol
/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}
// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol
/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);
    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);
    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);
    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: @airswap/delegate/contracts/Delegate.sol
/*
  Copyright 2019 Swap Holdings Ltd.
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
  * @title Delegate: Deployable Trading Rules for the Swap Protocol
  * @notice Supports fungible tokens (ERC-20)
  * @dev inherits IDelegate, Ownable uses SafeMath library
  */
contract Delegate is IDelegate, Ownable {
  using SafeMath for uint256;
  // The Swap contract to be used to settle trades
  ISwap public swapContract;
  // The Indexer to stake intent to trade on
  IIndexer public indexer;
  // Maximum integer for token transfer approval
  uint256 constant internal MAX_INT =  2**256 - 1;
  // Address holding tokens that will be trading through this delegate
  address public tradeWallet;
  // Mapping of senderToken to signerToken for rule lookup
  mapping (address => mapping (address => Rule)) public rules;
  // ERC-20 (fungible token) interface identifier (ERC-165)
  bytes4 constant internal ERC20_INTERFACE_ID = 0x36372b07;
  /**
    * @notice Contract Constructor
    * @dev owner defaults to msg.sender if delegateContractOwner is provided as address(0)
    * @param delegateSwap address Swap contract the delegate will deploy with
    * @param delegateIndexer address Indexer contract the delegate will deploy with
    * @param delegateContractOwner address Owner of the delegate
    * @param delegateTradeWallet address Wallet the delegate will trade from
    */
  constructor(
    ISwap delegateSwap,
    IIndexer delegateIndexer,
    address delegateContractOwner,
    address delegateTradeWallet
  ) public {
    swapContract = delegateSwap;
    indexer = delegateIndexer;
    // If no delegate owner is provided, the deploying address is the owner.
    if (delegateContractOwner != address(0)) {
      transferOwnership(delegateContractOwner);
    }
    // If no trade wallet is provided, the owner's wallet is the trade wallet.
    if (delegateTradeWallet != address(0)) {
      tradeWallet = delegateTradeWallet;
    } else {
      tradeWallet = owner();
    }
    // Ensure that the indexer can pull funds from delegate account.
    require(
      IERC20(indexer.stakingToken())
      .approve(address(indexer), MAX_INT), "STAKING_APPROVAL_FAILED"
    );
  }
  /**
    * @notice Set a Trading Rule
    * @dev only callable by the owner of the contract
    * @dev 1 senderToken = priceCoef * 10^(-priceExp) * signerToken
    * @param senderToken address Address of an ERC-20 token the delegate would send
    * @param signerToken address Address of an ERC-20 token the consumer would send
    * @param maxSenderAmount uint256 Maximum amount of ERC-20 token the delegate would send
    * @param priceCoef uint256 Whole number that will be multiplied by 10^(-priceExp) - the price coefficient
    * @param priceExp uint256 Exponent of the price to indicate location of the decimal priceCoef * 10^(-priceExp)
    */
  function setRule(
    address senderToken,
    address signerToken,
    uint256 maxSenderAmount,
    uint256 priceCoef,
    uint256 priceExp
  ) external onlyOwner {
    _setRule(
      senderToken,
      signerToken,
      maxSenderAmount,
      priceCoef,
      priceExp
    );
  }
  /**
    * @notice Unset a Trading Rule
    * @dev only callable by the owner of the contract, removes from a mapping
    * @param senderToken address Address of an ERC-20 token the delegate would send
    * @param signerToken address Address of an ERC-20 token the consumer would send
    */
  function unsetRule(
    address senderToken,
    address signerToken
  ) external onlyOwner {
    _unsetRule(
      senderToken,
      signerToken
    );
  }
  /**
    * @notice sets a rule on the delegate and an intent on the indexer
    * @dev only callable by owner
    * @dev delegate needs to be given allowance from msg.sender for the newStakeAmount
    * @dev swap needs to be given permission to move funds from the delegate
    * @param senderToken address Token the delgeate will send
    * @param signerToken address Token the delegate will receive
    * @param rule Rule Rule to set on a delegate
    * @param newStakeAmount uint256 Amount to stake for an intent
    */
  function setRuleAndIntent(
    address senderToken,
    address signerToken,
    Rule calldata rule,
    uint256 newStakeAmount
  ) external onlyOwner {
    _setRule(
      senderToken,
      signerToken,
      rule.maxSenderAmount,
      rule.priceCoef,
      rule.priceExp
    );
    // get currentAmount staked or 0 if never staked
    uint256 oldStakeAmount = indexer.getStakedAmount(address(this), signerToken, senderToken);
    if (oldStakeAmount == newStakeAmount && oldStakeAmount > 0) {
      return; // forgo trying to reset intent with non-zero same stake amount
    } else if (oldStakeAmount < newStakeAmount) {
      // transfer only the difference from the sender to the Delegate.
      require(
        IERC20(indexer.stakingToken())
        .transferFrom(msg.sender, address(this), newStakeAmount - oldStakeAmount), "STAKING_TRANSFER_FAILED"
      );
    }
    indexer.setIntent(
      signerToken,
      senderToken,
      newStakeAmount,
      bytes32(uint256(address(this)) << 96) //NOTE: this will pad 0's to the right
    );
    if (oldStakeAmount > newStakeAmount) {
      // return excess stake back
      require(
        IERC20(indexer.stakingToken())
        .transfer(msg.sender, oldStakeAmount - newStakeAmount), "STAKING_RETURN_FAILED"
      );
    }
  }
  /**
    * @notice unsets a rule on the delegate and removes an intent on the indexer
    * @dev only callable by owner
    * @param senderToken address Maker token in the token pair for rules and intents
    * @param signerToken address Taker token  in the token pair for rules and intents
    */
  function unsetRuleAndIntent(
    address senderToken,
    address signerToken
  ) external onlyOwner {
    _unsetRule(senderToken, signerToken);
    // Query the indexer for the amount staked.
    uint256 stakedAmount = indexer.getStakedAmount(address(this), signerToken, senderToken);
    indexer.unsetIntent(signerToken, senderToken);
    // Upon unstaking, the Delegate will be given the staking amount.
    // This is returned to the msg.sender.
    if (stakedAmount > 0) {
      require(
        IERC20(indexer.stakingToken())
          .transfer(msg.sender, stakedAmount),"STAKING_RETURN_FAILED"
      );
    }
  }
  /**
    * @notice Provide an Order
    * @dev Rules get reset with new maxSenderAmount
    * @param order Types.Order Order a user wants to submit to Swap.
    */
  function provideOrder(
    Types.Order calldata order
  ) external {
    Rule memory rule = rules[order.sender.token][order.signer.token];
    require(order.signer.wallet == msg.sender,
      "SIGNER_MUST_BE_SENDER");
    // Ensure the order is for the trade wallet.
    require(order.sender.wallet == tradeWallet,
      "INVALID_SENDER_WALLET");
    // Ensure the tokens are valid ERC20 tokens.
    require(order.signer.kind == ERC20_INTERFACE_ID,
      "SIGNER_KIND_MUST_BE_ERC20");
    require(order.sender.kind == ERC20_INTERFACE_ID,
      "SENDER_KIND_MUST_BE_ERC20");
    // Ensure that a rule exists.
    require(rule.maxSenderAmount != 0,
      "TOKEN_PAIR_INACTIVE");
    // Ensure the order does not exceed the maximum amount.
    require(order.sender.param <= rule.maxSenderAmount,
      "AMOUNT_EXCEEDS_MAX");
    // Ensure the order is priced according to the rule.
    require(order.sender.param <= _calculateSenderParam(order.signer.param, rule.priceCoef, rule.priceExp),
      "PRICE_INVALID");
    // Overwrite the rule with a decremented maxSenderAmount.
    rules[order.sender.token][order.signer.token] = Rule({
      maxSenderAmount: (rule.maxSenderAmount).sub(order.sender.param),
      priceCoef: rule.priceCoef,
      priceExp: rule.priceExp
    });
    // Perform the swap.
    swapContract.swap(order);
    emit ProvideOrder(
      owner(),
      tradeWallet,
      order.sender.token,
      order.signer.token,
      order.sender.param,
      rule.priceCoef,
      rule.priceExp
    );
  }
  /**
    * @notice Set a new trade wallet
    * @param newTradeWallet address Address of the new trade wallet
    */
  function setTradeWallet(address newTradeWallet) external onlyOwner {
    require(newTradeWallet != address(0), "TRADE_WALLET_REQUIRED");
    tradeWallet = newTradeWallet;
  }
  /**
    * @notice Get a Signer-Side Quote from the Delegate
    * @param senderParam uint256 Amount of ERC-20 token the delegate would send
    * @param senderToken address Address of an ERC-20 token the delegate would send
    * @param signerToken address Address of an ERC-20 token the consumer would send
    * @return uint256 signerParam Amount of ERC-20 token the consumer would send
    */
  function getSignerSideQuote(
    uint256 senderParam,
    address senderToken,
    address signerToken
  ) external view returns (
    uint256 signerParam
  ) {
    Rule memory rule = rules[senderToken][signerToken];
    // Ensure that a rule exists.
    if(rule.maxSenderAmount > 0) {
      // Ensure the senderParam does not exceed maximum for the rule.
      if(senderParam <= rule.maxSenderAmount) {
        signerParam = _calculateSignerParam(senderParam, rule.priceCoef, rule.priceExp);
        // Return the quote.
        return signerParam;
      }
    }
    return 0;
  }
  /**
    * @notice Get a Sender-Side Quote from the Delegate
    * @param signerParam uint256 Amount of ERC-20 token the consumer would send
    * @param signerToken address Address of an ERC-20 token the consumer would send
    * @param senderToken address Address of an ERC-20 token the delegate would send
    * @return uint256 senderParam Amount of ERC-20 token the delegate would send
    */
  function getSenderSideQuote(
    uint256 signerParam,
    address signerToken,
    address senderToken
  ) external view returns (
    uint256 senderParam
  ) {
    Rule memory rule = rules[senderToken][signerToken];
    // Ensure that a rule exists.
    if(rule.maxSenderAmount > 0) {
      // Calculate the senderParam.
      senderParam = _calculateSenderParam(signerParam, rule.priceCoef, rule.priceExp);
      // Ensure the senderParam does not exceed the maximum trade amount.
      if(senderParam <= rule.maxSenderAmount) {
        return senderParam;
      }
    }
    return 0;
  }
  /**
    * @notice Get a Maximum Quote from the Delegate
    * @param senderToken address Address of an ERC-20 token the delegate would send
    * @param signerToken address Address of an ERC-20 token the consumer would send
    * @return uint256 senderParam Amount the delegate would send
    * @return uint256 signerParam Amount the consumer would send
    */
  function getMaxQuote(
    address senderToken,
    address signerToken
  ) external view returns (
    uint256 senderParam,
    uint256 signerParam
  ) {
    Rule memory rule = rules[senderToken][signerToken];
    senderParam = rule.maxSenderAmount;
    // Ensure that a rule exists.
    if (senderParam > 0) {
      // calculate the signerParam
      signerParam = _calculateSignerParam(senderParam, rule.priceCoef, rule.priceExp);
      // Return the maxSenderAmount and calculated signerParam.
      return (
        senderParam,
        signerParam
      );
    }
    return (0, 0);
  }
  /**
    * @notice Set a Trading Rule
    * @dev only callable by the owner of the contract
    * @dev 1 senderToken = priceCoef * 10^(-priceExp) * signerToken
    * @param senderToken address Address of an ERC-20 token the delegate would send
    * @param signerToken address Address of an ERC-20 token the consumer would send
    * @param maxSenderAmount uint256 Maximum amount of ERC-20 token the delegate would send
    * @param priceCoef uint256 Whole number that will be multiplied by 10^(-priceExp) - the price coefficient
    * @param priceExp uint256 Exponent of the price to indicate location of the decimal priceCoef * 10^(-priceExp)
    */
  function _setRule(
    address senderToken,
    address signerToken,
    uint256 maxSenderAmount,
    uint256 priceCoef,
    uint256 priceExp
  ) internal {
    require(priceCoef > 0, "INVALID_PRICE_COEF");
    rules[senderToken][signerToken] = Rule({
      maxSenderAmount: maxSenderAmount,
      priceCoef: priceCoef,
      priceExp: priceExp
    });
    emit SetRule(
      owner(),
      senderToken,
      signerToken,
      maxSenderAmount,
      priceCoef,
      priceExp
    );
  }
  /**
    * @notice Unset a Trading Rule
    * @param senderToken address Address of an ERC-20 token the delegate would send
    * @param signerToken address Address of an ERC-20 token the consumer would send
    */
  function _unsetRule(
    address senderToken,
    address signerToken
  ) internal {
    // using non-zero rule.priceCoef for rule existence check
    if (rules[senderToken][signerToken].priceCoef > 0) {
      // Delete the rule.
      delete rules[senderToken][signerToken];
      emit UnsetRule(
        owner(),
        senderToken,
        signerToken
    );
    }
  }
  /**
    * @notice Calculate the signer param (amount) for a given sender param and price
    * @param senderParam uint256 The amount the delegate would send in the swap
    * @param priceCoef uint256 Coefficient of the token price defined in the rule
    * @param priceExp uint256 Exponent of the token price defined in the rule
    */
  function _calculateSignerParam(
    uint256 senderParam,
    uint256 priceCoef,
    uint256 priceExp
  ) internal pure returns (
    uint256 signerParam
  ) {
    // Calculate the param using the price formula
    uint256 multiplier = senderParam.mul(priceCoef);
    signerParam = multiplier.div(10 ** priceExp);
    // If the div rounded down, round up
    if (multiplier.mod(10 ** priceExp) > 0) {
      signerParam++;
    }
  }
  /**
    * @notice Calculate the sender param (amount) for a given signer param and price
    * @param signerParam uint256 The amount the signer would send in the swap
    * @param priceCoef uint256 Coefficient of the token price defined in the rule
    * @param priceExp uint256 Exponent of the token price defined in the rule
    */
  function _calculateSenderParam(
    uint256 signerParam,
    uint256 priceCoef,
    uint256 priceExp
  ) internal pure returns (
    uint256 senderParam
  ) {
    // Calculate the param using the price formula
    senderParam = signerParam
      .mul(10 ** priceExp)
      .div(priceCoef);
  }
}
// File: @airswap/indexer/contracts/interfaces/ILocatorWhitelist.sol
/*
  Copyright 2019 Swap Holdings Ltd.
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
interface ILocatorWhitelist {
  function has(
    bytes32 locator
  ) external view returns (bool);
}
// File: @airswap/delegate-factory/contracts/interfaces/IDelegateFactory.sol
/*
  Copyright 2019 Swap Holdings Ltd.
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
interface IDelegateFactory {
  event CreateDelegate(
    address indexed delegateContract,
    address swapContract,
    address indexerContract,
    address indexed delegateContractOwner,
    address delegateTradeWallet
  );
  /**
    * @notice Deploy a trusted delegate contract
    * @param delegateTradeWallet the wallet the delegate will trade from
    * @return delegateContractAddress address of the delegate contract created
    */
  function createDelegate(
    address delegateTradeWallet
  ) external returns (address delegateContractAddress);
}
// File: contracts/DelegateFactory.sol
/*
  Copyright 2019 Swap Holdings Ltd.
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
contract DelegateFactory is IDelegateFactory, ILocatorWhitelist {
  // Mapping specifying whether an address was deployed by this factory
  mapping(address => bool) internal _deployedAddresses;
  // The swap and indexer contracts to use in the deployment of Delegates
  ISwap public swapContract;
  IIndexer public indexerContract;
  /**
    * @notice Create a new Delegate contract
    * @dev swapContract is unable to be changed after the factory sets it
    * @param factorySwapContract address Swap contract the delegate will deploy with
    * @param factoryIndexerContract address Indexer contract the delegate will deploy with
    */
  constructor(ISwap factorySwapContract, IIndexer factoryIndexerContract) public {
    swapContract = factorySwapContract;
    indexerContract = factoryIndexerContract;
  }
  /**
    * @param delegateTradeWallet address Wallet the delegate will trade from
    * @return address delegateContractAddress Address of the delegate contract created
    */
  function createDelegate(
    address delegateTradeWallet
  ) external returns (address delegateContractAddress) {
    delegateContractAddress = address(
      new Delegate(swapContract, indexerContract, msg.sender, delegateTradeWallet)
    );
    _deployedAddresses[delegateContractAddress] = true;
    emit CreateDelegate(
      delegateContractAddress,
      address(swapContract),
      address(indexerContract),
      msg.sender,
      delegateTradeWallet
    );
    return delegateContractAddress;
  }
  /**
    * @notice To check whether a locator was deployed
    * @dev Implements ILocatorWhitelist.has
    * @param locator bytes32 Locator of the delegate in question
    * @return bool True if the delegate was deployed by this contract
    */
  function has(bytes32 locator) external view returns (bool) {
    return _deployedAddresses[address(bytes20(locator))];
  }
}

