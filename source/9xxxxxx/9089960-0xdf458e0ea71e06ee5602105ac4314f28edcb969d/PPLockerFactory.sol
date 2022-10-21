pragma solidity ^0.5.13;

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

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

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

contract ChargesFee is Ownable {
  using SafeERC20 for IERC20;

  event SetFeeManager(address addr);
  event SetFeeCollector(address addr);
  event SetEthFee(uint256 ethFee);
  event SetGaltFee(uint256 ethFee);
  event WithdrawEth(address indexed to, uint256 amount);
  event WithdrawErc20(address indexed to, address indexed tokenAddress, uint256 amount);
  event WithdrawErc721(address indexed to, address indexed tokenAddress, uint256 tokenId);

  uint256 public ethFee;
  uint256 public galtFee;

  address public feeManager;
  address public feeCollector;

  modifier onlyFeeManager() {
    require(msg.sender == feeManager, "ChargesFee: caller is not the feeManager");
    _;
  }

  modifier onlyFeeCollector() {
    require(msg.sender == feeCollector, "ChargesFee: caller is not the feeCollector");
    _;
  }

  constructor(uint256 _ethFee, uint256 _galtFee) public {
    ethFee = _ethFee;
    galtFee = _galtFee;
  }

  function _galtToken() internal view returns (IERC20);

  // Setters

  function setFeeManager(address _addr) external onlyOwner {
    feeManager = _addr;

    emit SetFeeManager(_addr);
  }

  function setFeeCollector(address _addr) external onlyOwner {
    feeCollector = _addr;

    emit SetFeeCollector(_addr);
  }

  function setEthFee(uint256 _ethFee) external onlyFeeManager {
    ethFee = _ethFee;

    emit SetEthFee(_ethFee);
  }

  function setGaltFee(uint256 _galtFee) external onlyFeeManager {
    galtFee = _galtFee;

    emit SetGaltFee(_galtFee);
  }

  // Withdrawers

  function withdrawErc20(address _tokenAddress, address _to) external onlyFeeCollector {
    uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));

    IERC20(_tokenAddress).transfer(_to, balance);

    emit WithdrawErc20(_to, _tokenAddress, balance);
  }

  function withdrawErc721(address _tokenAddress, address _to, uint256 _tokenId) external onlyFeeCollector {
    IERC721(_tokenAddress).transferFrom(address(this), _to, _tokenId);

    emit WithdrawErc721(_to, _tokenAddress, _tokenId);
  }

  function withdrawEth(address payable _to) external onlyFeeCollector {
    uint256 balance = address(this).balance;

    _to.transfer(balance);

    emit WithdrawEth(_to, balance);
  }

  // INTERNAL

  function _acceptPayment() internal {
    if (msg.value == 0) {
      _galtToken().transferFrom(msg.sender, address(this), galtFee);
    } else {
      require(msg.value == ethFee, "Fee and msg.value not equal");
    }
  }
}

interface IACL {
  function setRole(bytes32 _role, address _candidate, bool _allow) external;
  function hasRole(address _candidate, bytes32 _role) external view returns (bool);
}

interface IPPGlobalRegistry {
  function setContract(bytes32 _key, address _value) external;

  // GETTERS
  function getContract(bytes32 _key) external view returns (address);
  function getACL() external view returns (IACL);
  function getGaltTokenAddress() external view returns (address);
  function getPPTokenRegistryAddress() external view returns (address);
  function getPPLockerRegistryAddress() external view returns (address);
  function getPPMarketAddress() external view returns (address);
}

interface IPPTokenController {
  event SetGeoDataManager(address indexed geoDataManager);
  event SetFeeManager(address indexed geoDataManager);
  event NewProposal(
    uint256 indexed proposalId,
    uint256 indexed tokenId,
    address indexed creator
  );
  event ProposalExecuted(uint256 indexed proposalId);
  event ProposalExecutionFailed(uint256 indexed proposalId);
  event ProposalApproval(
    uint256 indexed proposalId,
    uint256 indexed tokenId
  );
  event ProposalRejection(
    uint256 indexed proposalId,
    uint256 indexed tokenId
  );
  event ProposalCancellation(
    uint256 indexed proposalId,
    uint256 indexed tokenId
  );
  event SetBurner(address burner);
  event SetBurnTimeout(uint256 indexed tokenId, uint256 timeout);
  event InitiateTokenBurn(uint256 indexed tokenId, uint256 timeoutAt);
  event BurnTokenByTimeout(uint256 indexed tokenId);
  event CancelTokenBurn(uint256 indexed tokenId);
  event SetFee(bytes32 indexed key, uint256 value);
  event WithdrawEth(address indexed to, uint256 amount);
  event WithdrawErc20(address indexed to, address indexed tokenAddress, uint256 amount);

  function fees(bytes32) external returns (uint256);
  function setBurner(address _burner) external;
  function setGeoDataManager(address _geoDataManager) external;
  function setBurnTimeoutDuration(uint256 _tokenId, uint256 _duration) external;
  function setFee(bytes32 _key, uint256 _value) external;
  function withdrawErc20(address _tokenAddress, address _to) external;
  function withdrawEth(address payable _to) external;
  function initiateTokenBurn(uint256 _tokenId) external;
  function cancelTokenBurn(uint256 _tokenId) external;
  function burnTokenByTimeout(uint256 _tokenId) external;
  function propose(bytes calldata _data, string calldata _dataLink) external payable;
  function approve(uint256 _proposalId) external;
  function execute(uint256 _proposalId) external;
  function fetchTokenId(bytes calldata _data) external pure returns (uint256 tokenId);
  function() external payable;
}

interface IPPTokenRegistry {
  event AddToken(address indexed token, address indexed owener, address indexed factory);
  event SetFactory(address factory);
  event SetLockerRegistry(address lockerRegistry);

  function tokenList(uint256 _index) external view returns (address);
  function isValid(address _tokenContract) external view returns (bool);
  function requireValidToken(address _token) external view;
  function addToken(address _privatePropertyToken) external;
  function getAllTokens() external view returns (address[] memory);
}

interface IPPToken {
  event SetMinter(address indexed minter);
  event SetBaseURI(string baseURI);
  event SetDataLink(string indexed dataLink);
  event SetLegalAgreementIpfsHash(bytes32 legalAgreementIpfsHash);
  event SetController(address indexed controller);
  event SetDetails(
    address indexed geoDataManager,
    uint256 indexed privatePropertyId
  );
  event SetContour(
    address indexed geoDataManager,
    uint256 indexed privatePropertyId
  );
  event SetExtraData(bytes32 indexed key, bytes32 value);
  event SetPropertyExtraData(uint256 indexed propertyId, bytes32 indexed key, bytes32 value);
  event Mint(address indexed to, uint256 indexed privatePropertyId);
  event Burn(address indexed from, uint256 indexed privatePropertyId);

  enum PropertyInitialSetupStage {
    PENDING,
    DETAILS,
    DONE
  }

  enum AreaSource {
    USER_INPUT,
    CONTRACT
  }

  enum TokenType {
    NULL,
    LAND_PLOT,
    BUILDING,
    ROOM,
    PACKAGE
  }

  // ERC20 METHOD
  function transferFrom(address from, address to, uint256 tokenId) external;
  function approve(address to, uint256 tokenId) external;

  // PERMISSIONED METHODS

  function setMinter(address _minter) external;
  function setDataLink(string calldata _dataLink) external;
  function setLegalAgreementIpfsHash(bytes32 _legalAgreementIpfsHash) external;
  function setController(address payable _controller) external;
  function setDetails(
    uint256 _privatePropertyId,
    TokenType _tokenType,
    AreaSource _areaSource,
    uint256 _area,
    bytes32 _ledgerIdentifier,
    string calldata _humanAddress,
    string calldata _dataLink
  )
    external;

  function setContour(
    uint256 _privatePropertyId,
    uint256[] calldata _contour,
    int256 _highestPoint
  )
    external;

  function mint(address _to) external;
  function burn(uint256 _tokenId) external;

  // GETTERS
  function controller() external view returns (address payable);
  function minter() external view returns (address);

  function tokensOfOwner(address _owner) external view returns (uint256[] memory);
  function ownerOf(uint256 _tokenId) external view returns (address);
  function exists(uint256 _tokenId) external view returns (bool);
  function getType(uint256 _tokenId) external view returns (TokenType);
  function getContour(uint256 _tokenId) external view returns (uint256[] memory);
  function getContourLength(uint256 _tokenId) external view returns (uint256);
  function getHighestPoint(uint256 _tokenId) external view returns (int256);
  function getHumanAddress(uint256 _tokenId) external view returns (string memory);
  function getArea(uint256 _tokenId) external view returns (uint256);
  function getAreaSource(uint256 _tokenId) external view returns (AreaSource);
  function getLedgerIdentifier(uint256 _tokenId) external view returns (bytes32);
  function getDataLink(uint256 _tokenId) external view returns (string memory);
  function getDetails(uint256 _privatePropertyId)
    external
    view
    returns (
      TokenType tokenType,
      uint256[] memory contour,
      int256 highestPoint,
      AreaSource areaSource,
      uint256 area,
      bytes32 ledgerIdentifier,
      string memory humanAddress,
      string memory dataLink,
      PropertyInitialSetupStage setupStage
    );
}

interface IRA {
  // ERC20 compatible
  function balanceOf(address owner) external view returns (uint256);

  // ERC20 compatible
  function totalSupply() external view returns (uint256);

  // Ping-Pong Handshake
  function ping() external pure returns (bytes32);
}

interface IPPLocker {
  function deposit(IPPToken _tokenContract, uint256 _tokenId) external payable;
  function withdraw() external;
  function approveMint(IRA _tra) external;
  function burn(IRA _tra) external;
  function isMinted(address _tra) external view returns (bool);
  function getTras() external view returns (address[] memory);
  function getTrasCount() external view returns (uint256);
  function isOwner() external view returns (bool);
  function owner() external view returns(address);
  function tokenId() external view returns(uint256);
  function reputation() external view returns(uint256);
  function tokenContract() external view returns(IPPToken);
}

library ArraySet {
  struct AddressSet {
    address[] array;
    mapping(address => uint256) map;
    mapping(address => bool) exists;
  }

  struct Bytes32Set {
    bytes32[] array;
    mapping(bytes32 => uint256) map;
    mapping(bytes32 => bool) exists;
  }

  // AddressSet
  function add(AddressSet storage _set, address _v) internal {
    require(_set.exists[_v] == false, "Element already exists");

    _set.map[_v] = _set.array.length;
    _set.exists[_v] = true;
    _set.array.push(_v);
  }

  function addSilent(AddressSet storage _set, address _v) internal returns (bool) {
    if (_set.exists[_v] == true) {
      return false;
    }

    _set.map[_v] = _set.array.length;
    _set.exists[_v] = true;
    _set.array.push(_v);

    return true;
  }

  function remove(AddressSet storage _set, address _v) internal {
    require(_set.array.length > 0, "Array is empty");
    require(_set.exists[_v] == true, "Element doesn't exist");

    _remove(_set, _v);
  }

  function removeSilent(AddressSet storage _set, address _v) internal returns (bool) {
    if (_set.exists[_v] == false) {
      return false;
    }

    _remove(_set, _v);
    return true;
  }

  function _remove(AddressSet storage _set, address _v) internal {
    uint256 lastElementIndex = _set.array.length - 1;
    uint256 currentElementIndex = _set.map[_v];
    address lastElement = _set.array[lastElementIndex];

    _set.array[currentElementIndex] = lastElement;
    delete _set.array[lastElementIndex];

    _set.array.length = _set.array.length - 1;
    delete _set.map[_v];
    delete _set.exists[_v];
    _set.map[lastElement] = currentElementIndex;
  }

  function clear(AddressSet storage _set) internal {
    for (uint256 i = 0; i < _set.array.length; i++) {
      address v = _set.array[i];
      delete _set.map[v];
      _set.exists[v] = false;
    }

    delete _set.array;
  }

  function has(AddressSet storage _set, address _v) internal view returns (bool) {
    return _set.exists[_v];
  }

  function elements(AddressSet storage _set) internal view returns (address[] storage) {
    return _set.array;
  }

  function size(AddressSet storage _set) internal view returns (uint256) {
    return _set.array.length;
  }

  function isEmpty(AddressSet storage _set) internal view returns (bool) {
    return _set.array.length == 0;
  }

  // Bytes32Set
  function add(Bytes32Set storage _set, bytes32 _v) internal {
    require(_set.exists[_v] == false, "Element already exists");

    _add(_set, _v);
  }

  function addSilent(Bytes32Set storage _set, bytes32 _v) internal returns (bool) {
    if (_set.exists[_v] == true) {
      return false;
    }

    _add(_set, _v);

    return true;
  }

  function _add(Bytes32Set storage _set, bytes32 _v) internal {
    _set.map[_v] = _set.array.length;
    _set.exists[_v] = true;
    _set.array.push(_v);
  }

  function remove(Bytes32Set storage _set, bytes32 _v) internal {
    require(_set.array.length > 0, "Array is empty");
    require(_set.exists[_v] == true, "Element doesn't exist");

    _remove(_set, _v);
  }

  function removeSilent(Bytes32Set storage _set, bytes32 _v) internal returns (bool) {
    if (_set.exists[_v] == false) {
      return false;
    }

    _remove(_set, _v);
    return true;
  }

  function _remove(Bytes32Set storage _set, bytes32 _v) internal {
    uint256 lastElementIndex = _set.array.length - 1;
    uint256 currentElementIndex = _set.map[_v];
    bytes32 lastElement = _set.array[lastElementIndex];

    _set.array[currentElementIndex] = lastElement;
    delete _set.array[lastElementIndex];

    _set.array.length = _set.array.length - 1;
    delete _set.map[_v];
    delete _set.exists[_v];
    _set.map[lastElement] = currentElementIndex;
  }

  function clear(Bytes32Set storage _set) internal {
    for (uint256 i = 0; i < _set.array.length; i++) {
      _set.exists[_set.array[i]] = false;
    }

    delete _set.array;
  }

  function has(Bytes32Set storage _set, bytes32 _v) internal view returns (bool) {
    return _set.exists[_v];
  }

  function elements(Bytes32Set storage _set) internal view returns (bytes32[] storage) {
    return _set.array;
  }

  function size(Bytes32Set storage _set) internal view returns (uint256) {
    return _set.array.length;
  }

  function isEmpty(Bytes32Set storage _set) internal view returns (bool) {
    return _set.array.length == 0;
  }

  ///////////////////////////// Uint256Set /////////////////////////////////////////
  struct Uint256Set {
    uint256[] array;
    mapping(uint256 => uint256) map;
    mapping(uint256 => bool) exists;
  }

  function add(Uint256Set storage _set, uint256 _v) internal {
    require(_set.exists[_v] == false, "Element already exists");

    _add(_set, _v);
  }

  function addSilent(Uint256Set storage _set, uint256 _v) internal returns (bool) {
    if (_set.exists[_v] == true) {
      return false;
    }

    _add(_set, _v);

    return true;
  }

  function _add(Uint256Set storage _set, uint256 _v) internal {
    _set.map[_v] = _set.array.length;
    _set.exists[_v] = true;
    _set.array.push(_v);
  }

  function remove(Uint256Set storage _set, uint256 _v) internal {
    require(_set.array.length > 0, "Array is empty");
    require(_set.exists[_v] == true, "Element doesn't exist");

    _remove(_set, _v);
  }

  function removeSilent(Uint256Set storage _set, uint256 _v) internal returns (bool) {
    if (_set.exists[_v] == false) {
      return false;
    }

    _remove(_set, _v);
    return true;
  }

  function _remove(Uint256Set storage _set, uint256 _v) internal {
    uint256 lastElementIndex = _set.array.length - 1;
    uint256 currentElementIndex = _set.map[_v];
    uint256 lastElement = _set.array[lastElementIndex];

    _set.array[currentElementIndex] = lastElement;
    delete _set.array[lastElementIndex];

    _set.array.length = _set.array.length - 1;
    delete _set.map[_v];
    delete _set.exists[_v];
    _set.map[lastElement] = currentElementIndex;
  }

  function clear(Uint256Set storage _set) internal {
    for (uint256 i = 0; i < _set.array.length; i++) {
      _set.exists[_set.array[i]] = false;
    }

    delete _set.array;
  }

  function has(Uint256Set storage _set, uint256 _v) internal view returns (bool) {
    return _set.exists[_v];
  }

  function elements(Uint256Set storage _set) internal view returns (uint256[] storage) {
    return _set.array;
  }

  function size(Uint256Set storage _set) internal view returns (uint256) {
    return _set.array.length;
  }

  function isEmpty(Uint256Set storage _set) internal view returns (bool) {
    return _set.array.length == 0;
  }
}

contract PPLocker is IPPLocker {
  using ArraySet for ArraySet.AddressSet;

  event ReputationMint(address indexed sra);
  event ReputationBurn(address indexed sra);
  event Deposit(uint256 reputation);
  event Withdrawal(uint256 reputation);

  bytes32 public constant LOCKER_TYPE = bytes32("REPUTATION");
  bytes32 public constant GALT_FEE_KEY = bytes32("LOCKER_GALT");
  bytes32 public constant ETH_FEE_KEY = bytes32("LOCKER_ETH");

  IPPGlobalRegistry public globalRegistry;

  address public owner;
  uint256 public tokenId;
  uint256 public reputation;
  bool public tokenDeposited;
  IPPToken public tokenContract;

  // Token Reputation Accounting Contracts
  ArraySet.AddressSet internal traSet;

  modifier onlyOwner() {
    require(isOwner(), "Not the locker owner");
    _;
  }

  modifier onlyValidTokenContract(IPPToken _tokenContract) {
    IPPTokenRegistry(globalRegistry.getPPTokenRegistryAddress()).requireValidToken(address(_tokenContract));
    _;
  }

  constructor(IPPGlobalRegistry _globalRegistry, address _owner) public {
    globalRegistry = _globalRegistry;
    owner = _owner;
  }

  function deposit(
    IPPToken _tokenContract,
    uint256 _tokenId
  )
    external
    payable
    onlyOwner
    onlyValidTokenContract(_tokenContract)
  {
    require(!tokenDeposited, "Token already deposited");
    _acceptPayment(_tokenContract);

    tokenContract = _tokenContract;
    tokenId = _tokenId;
    reputation = _tokenContract.getArea(_tokenId);
    tokenDeposited = true;

    _tokenContract.transferFrom(msg.sender, address(this), _tokenId);

    emit Deposit(reputation);
  }

  function _acceptPayment(IPPToken _tokenContract) internal {
    if (msg.value == 0) {
      uint256 fee = IPPTokenController(_tokenContract.controller()).fees(GALT_FEE_KEY);

      IERC20 galtToken = IERC20(globalRegistry.getGaltTokenAddress());
      galtToken.transferFrom(msg.sender, _tokenContract.controller(), fee);
    } else {
      uint256 fee = IPPTokenController(_tokenContract.controller()).fees(ETH_FEE_KEY);

      require(msg.value == fee, "Invalid ETH fee");

      _tokenContract.controller().transfer(msg.value);
    }
  }

  function withdraw() external onlyOwner {
    require(tokenDeposited, "Token not deposited");
    require(traSet.size() == 0, "RAs counter should be 0");

    IPPToken previousTokenContract = tokenContract;
    uint256 previousTokenId = tokenId;

    tokenContract = IPPToken(address(0));
    tokenId = 0;
    reputation = 0;
    tokenDeposited = false;

    previousTokenContract.transferFrom(address(this), msg.sender, previousTokenId);

    emit Withdrawal(reputation);
  }

  function approveMint(IRA _tra) external onlyOwner {
    require(!traSet.has(address(_tra)), "Already minted to this RA");
    require(_tra.ping() == bytes32("pong"), "Handshake failed");

    traSet.add(address(_tra));

    emit ReputationMint(address(_tra));
  }

  function burn(IRA _tra) external onlyOwner {
    require(traSet.has(address(_tra)), "Not minted to the RA");
    require(_tra.balanceOf(msg.sender) == 0, "Reputation not completely burned");

    traSet.remove(address(_tra));

    emit ReputationBurn(address(_tra));
  }

  function cancelTokenBurn() external onlyOwner {
    IPPTokenController(tokenContract.controller()).cancelTokenBurn(tokenId);
  }

  // GETTERS

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function getTokenInfo()
    public
    view
    returns (
      address _owner,
      uint256 _tokenId,
      uint256 _reputation,
      bool _tokenDeposited,
      address _tokenContract
    )
  {
    return (
      owner,
      tokenId,
      reputation,
      tokenDeposited,
      address(tokenContract)
    );
  }

  function isMinted(address _tra) external view returns (bool) {
    return traSet.has(_tra);
  }

  function getTras() external view returns (address[] memory) {
    return traSet.elements();
  }

  function getTrasCount() external view returns (uint256) {
    return traSet.size();
  }
}

interface IPPLockerRegistry {
  event AddLocker(address indexed locker, address indexed owner, address indexed factory);
  event SetFactory(address factory);

  function addLocker(address _locker) external;
  function requireValidLocker(address _locker) external view;
  function isValid(address _locker) external view returns (bool);
}

contract PPLockerFactory is Ownable, ChargesFee {
  event NewPPLocker(address indexed owner, address locker);

  IPPGlobalRegistry public globalRegistry;

  constructor(
    IPPGlobalRegistry _globalRegistry,
    uint256 _ethFee,
    uint256 _galtFee
  )
    public
    ChargesFee(_ethFee, _galtFee)
  {
    globalRegistry = _globalRegistry;
  }

  function build() external payable returns (IPPLocker) {
    _acceptPayment();

    IPPLocker locker = new PPLocker(globalRegistry, msg.sender);

    IPPLockerRegistry(globalRegistry.getPPLockerRegistryAddress()).addLocker(address(locker));

    emit NewPPLocker(msg.sender, address(locker));

    return IPPLocker(locker);
  }

  // INTERNAL

  function _galtToken() internal view returns (IERC20) {
    return IERC20(globalRegistry.getGaltTokenAddress());
  }
}
