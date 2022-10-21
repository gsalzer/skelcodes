pragma solidity 0.6.11;
// SPDX-License-Identifier: BSD-3-Clause

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
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

interface Token {
    function approve(address, uint) external returns (bool);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

/**
 * @title Governance
 * @dev Governance smart contract
 * Takes in Governance Token as votes
 * Allows addition and removal of votes during a proposal is open
 * Allows withdrawal of all Governance Token once the latest voted proposal of a user is closed
 * CONTRACT VARIABLES must be changed to appropriate values before live deployment
 */
contract Governance is Ownable {
    using SafeMath for uint;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    // Contracts are not allowed to deposit, claim or withdraw
    modifier noContractsAllowed() {
        require(!(address(msg.sender).isContract()) && tx.origin == msg.sender, "No Contracts Allowed!");
        _;
    }
    
    // ============== CONTRACT VARIABLES ==============
    
    // voting token contract address
    address public constant TRUSTED_TOKEN_ADDRESS = 0xf4CD3d3Fda8d7Fd6C5a500203e38640A70Bf9577;
    
    
    // duration since proposal creation till users can vote
    uint public constant VOTE_DURATION = 3 days;
    
    uint public constant MIN_DEPOSIT_FOR_ONE_VOTE = 2e18;
    
    uint public constant MAX_VOTES_DEPOSIT = 20 * MIN_DEPOSIT_FOR_ONE_VOTE;
    
    
    // ============ END CONTRACT VARIABLES ============
    
    enum Action {
        TEXT_PROPOSAL
    }
    enum Option {
        ONE, // yes
        TWO  // no
    }
    
    // proposal id => action
    mapping (uint => Action) public actions;
    
    // proposal id => option one votes
    mapping (uint => uint) public optionOneVotes;
    
    // proposal id => option two votes
    mapping (uint => uint) public optionTwoVotes;
    
    // proposal id => unix time for proposal start
    mapping (uint => uint) public proposalStartTime;
    
    mapping (uint => string) public proposalTexts;
    
    // proposal id => voters set
    mapping (uint => EnumerableSet.AddressSet) private voters;
 
    // address user => total deposited Governance Token
    mapping (address => uint) public totalDepositedTokens;
    
    // address user => uint proposal id => uint vote amounts
    mapping (address => mapping (uint => uint)) public votesForProposalByAddress;
    
    // address user => uint proposal id => Option voted for option
    mapping (address => mapping (uint => Option)) public votedForOption;
    
    // address user => uint proposal id for the latest proposal the user voted on
    mapping (address => uint) public lastVotedProposalStartTime;
  
    
    // uint last proposal id
    // proposal ids start at 1
    uint public lastIndex = 0;
    
    // view function to get proposal details
    function getProposal(uint proposalId) external view returns (
        uint _proposalId, 
        Action _proposalAction,
        uint _optionOneVotes,
        uint _optionTwoVotes,
        uint _proposalStartTime,
        string memory _proposalText
        ) {
        _proposalId = proposalId;
        _proposalAction = actions[proposalId];
        _optionOneVotes = optionOneVotes[proposalId];
        _optionTwoVotes = optionTwoVotes[proposalId];
        _proposalStartTime = proposalStartTime[proposalId];
        _proposalText = proposalTexts[proposalId];
        
    }
    
    function initProposal(string memory text) external noContractsAllowed onlyOwner {
        lastIndex = lastIndex.add(1);
        proposalTexts[lastIndex] = text;
        proposalStartTime[lastIndex] = now;
        actions[lastIndex] = Action.TEXT_PROPOSAL;
    }
    
    
    // Any Governance Token holder may add votes for a particular open proposal, 
    // with options YES / NO | ONE / TWO
    // with `amount` Governance Token, two Governance Token unit corresponds to one vote unit
    
    // If user has already voted for a proposal with an option,
    // user may not add votes with another option, 
    // they will need to add votes for the same option
    function addVotes(uint proposalId, Option option, uint amount) external noContractsAllowed {
        require(amount > 0, "Cannot add 0 votes!");
        require(isProposalOpen(proposalId), "Proposal is closed!");
        
        require(isVoteAmountValid(amount), "Invalid Vote Amount!");
        
        require(Token(TRUSTED_TOKEN_ADDRESS).transferFrom(msg.sender, address(this), amount), "transferFrom failed!");
        
        // if user is voting for this proposal first time
        if (votesForProposalByAddress[msg.sender][proposalId] == 0) {
            votedForOption[msg.sender][proposalId] = option;
        } else {
            if (votedForOption[msg.sender][proposalId] != option) {
                revert("Cannot vote for both options!");
            }
        }
        
        if (option == Option.ONE) {
            optionOneVotes[proposalId] = optionOneVotes[proposalId].add(amount);
        } else {
            optionTwoVotes[proposalId] = optionTwoVotes[proposalId].add(amount);
        }
        totalDepositedTokens[msg.sender] = totalDepositedTokens[msg.sender].add(amount);
        votesForProposalByAddress[msg.sender][proposalId] = votesForProposalByAddress[msg.sender][proposalId].add(amount);
        
        require(votesForProposalByAddress[msg.sender][proposalId] <= MAX_VOTES_DEPOSIT, "MAX Votes Exceeded!");
        
        if (lastVotedProposalStartTime[msg.sender] < proposalStartTime[proposalId]) {
            lastVotedProposalStartTime[msg.sender] = proposalStartTime[proposalId];
        }
        
        if (!voters[proposalId].contains(msg.sender)) {
            voters[proposalId].add(msg.sender);
        }
    }
    
    function getDepositorsList(uint proposalId, uint startIndex, uint endIndex) 
        public 
        view 
        returns (
            address[] memory _depositors, 
            uint[] memory _votes, 
            Option[] memory _votedForOption
        ) {
        require (startIndex < endIndex);
        
        uint length = endIndex.sub(startIndex);
        _depositors = new address[](length);
        _votes = new uint[](length);
        _votedForOption = new Option[](length);
       
        for (uint i = startIndex; i < endIndex; i = i.add(1)) {
            address depositor = voters[proposalId].at(i);
            uint listIndex = i.sub(startIndex);
            _depositors[listIndex] = depositor;
            _votes[listIndex] = votesForProposalByAddress[depositor][proposalId];
            _votedForOption[listIndex] = votedForOption[depositor][proposalId];
        }
    }
    
    function getNumberOfDepositors(uint proposalId) public view returns (uint) {
        return voters[proposalId].length();
    }
    
    // Any voter may remove their votes (Governance Token) from any proposal they voted for 
    // only when the proposal is open - removing votes refund Governance Token to user and deduct their votes
    function removeVotes(uint proposalId, uint amount) external noContractsAllowed {
        require(amount > 0, "Cannot remove 0 votes!");
        require(isProposalOpen(proposalId), "Proposal is closed!");
        
        require(isVoteAmountValid(amount), "Invalid Vote Amount!");
        
        require(amount <= votesForProposalByAddress[msg.sender][proposalId], "Cannot remove more tokens than deposited!");
        
        votesForProposalByAddress[msg.sender][proposalId] = votesForProposalByAddress[msg.sender][proposalId].sub(amount);
        totalDepositedTokens[msg.sender] = totalDepositedTokens[msg.sender].sub(amount);
        
        if (votedForOption[msg.sender][proposalId] == Option.ONE) {
            optionOneVotes[proposalId] = optionOneVotes[proposalId].sub(amount);
        } else {
            optionTwoVotes[proposalId] = optionTwoVotes[proposalId].sub(amount);
        }
        
        require(Token(TRUSTED_TOKEN_ADDRESS).transfer(msg.sender, amount), "transfer failed");
        
        if (voters[proposalId].contains(msg.sender) && votesForProposalByAddress[msg.sender][proposalId] == 0) {
            voters[proposalId].remove(msg.sender);
        }
    }
    
    function isVoteAmountValid(uint amount) public pure returns (bool) {
        if (amount < MIN_DEPOSIT_FOR_ONE_VOTE) {
            return false;
        }
        
        uint amount_div_1E18 = amount.div(1e18);
        
        // make sure no fractional deposit is done!
        if (amount_div_1E18.mul(1e18) != amount) {
            return false;
        }
        
        if (amount_div_1E18.mod(2) > 0) {
            return false;
        }
        
        return true;
    }

    // After the latest proposal the user voted for, is closed for voting,
    // The user may remove all Governance Token they added to this contract
    function withdrawAllTokens() external noContractsAllowed {
        require(now > lastVotedProposalStartTime[msg.sender].add(VOTE_DURATION), "Tokens are still in voting!");
        require(Token(TRUSTED_TOKEN_ADDRESS).transfer(msg.sender, totalDepositedTokens[msg.sender]), "transfer failed!");
        totalDepositedTokens[msg.sender] = 0;
    }
    
    // view function to know whether voting for a particular proposal is open
    function isProposalOpen(uint proposalId) public view returns (bool) {
        if (now < proposalStartTime[proposalId].add(VOTE_DURATION)) {
            return true;
        }
        return false;
    }
    
}
