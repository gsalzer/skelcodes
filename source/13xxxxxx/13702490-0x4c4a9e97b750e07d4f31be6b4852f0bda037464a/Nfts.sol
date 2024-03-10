pragma solidity 0.8.4;

abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		return msg.data;
	}
}

// File @openzeppelin/contracts/access/Ownable.sol@v4.3.1pragma solidity 0.8.4;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(
		address indexed previousOwner,
		address indexed newOwner
	);

	/**
	 * @dev Initializes the contract setting the deployer as the initial owner.
	 */
	constructor() {
		_setOwner(_msgSender());
	}

	/**
	 * @dev Returns the address of the current owner.
	 */
	function owner() public view virtual returns (address) {
		return _owner;
	}

	/**
	 * @dev Throws if called by any account other than the owner.
	 */
	modifier onlyOwner() {
		require(owner() == _msgSender(), 'Ownable: caller is not the owner');
		_;
	}

	/**
	 * @dev Leaves the contract without owner. It will not be possible to call
	 * `onlyOwner` functions anymore. Can only be called by the current owner.
	 *
	 * NOTE: Renouncing ownership will leave the contract without an owner,
	 * thereby removing any functionality that is only available to the owner.
	 */
	function renounceOwnership() public virtual onlyOwner {
		_setOwner(address(0));
	}

	/**
	 * @dev Transfers ownership of the contract to a new account (`newOwner`).
	 * Can only be called by the current owner.
	 */
	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(
			newOwner != address(0),
			'Ownable: new owner is the zero address'
		);
		_setOwner(newOwner);
	}

	function _setOwner(address newOwner) private {
		address oldOwner = _owner;
		_owner = newOwner;
		emit OwnershipTransferred(oldOwner, newOwner);
	}
}

// File @openzeppelin/contracts/utils/math/SafeMath.sol@v4.3.1

pragma solidity 0.8.4; // CAUTION

// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
	/**
	 * @dev Returns the addition of two unsigned integers, with an overflow flag.
	 *
	 * _Available since v3.4._
	 */
	function tryAdd(uint256 a, uint256 b)
		internal
		pure
		returns (bool, uint256)
	{
		unchecked {
			uint256 c = a + b;
			if (c < a) return (false, 0);
			return (true, c);
		}
	}

	/**
	 * @dev Returns the substraction of two unsigned integers, with an overflow flag.
	 *
	 * _Available since v3.4._
	 */
	function trySub(uint256 a, uint256 b)
		internal
		pure
		returns (bool, uint256)
	{
		unchecked {
			if (b > a) return (false, 0);
			return (true, a - b);
		}
	}

	/**
	 * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
	 *
	 * _Available since v3.4._
	 */
	function tryMul(uint256 a, uint256 b)
		internal
		pure
		returns (bool, uint256)
	{
		unchecked {
			// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
			// benefit is lost if 'b' is also tested.
			// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
			if (a == 0) return (true, 0);
			uint256 c = a * b;
			if (c / a != b) return (false, 0);
			return (true, c);
		}
	}

	/**
	 * @dev Returns the division of two unsigned integers, with a division by zero flag.
	 *
	 * _Available since v3.4._
	 */
	function tryDiv(uint256 a, uint256 b)
		internal
		pure
		returns (bool, uint256)
	{
		unchecked {
			if (b == 0) return (false, 0);
			return (true, a / b);
		}
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
	 *
	 * _Available since v3.4._
	 */
	function tryMod(uint256 a, uint256 b)
		internal
		pure
		returns (bool, uint256)
	{
		unchecked {
			if (b == 0) return (false, 0);
			return (true, a % b);
		}
	}

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
		return a + b;
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
		return a - b;
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
		return a * b;
	}

	/**
	 * @dev Returns the integer division of two unsigned integers, reverting on
	 * division by zero. The result is rounded towards zero.
	 *
	 * Counterpart to Solidity's `/` operator.
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return a / b;
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	 * reverting when dividing by zero.
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
		return a % b;
	}

	/**
	 * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
	 * overflow (when the result is negative).
	 *
	 * CAUTION: This function is deprecated because it requires allocating memory for the error
	 * message unnecessarily. For custom revert reasons use {trySub}.
	 *
	 * Counterpart to Solidity's `-` operator.
	 *
	 * Requirements:
	 *
	 * - Subtraction cannot overflow.
	 */
	function sub(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		unchecked {
			require(b <= a, errorMessage);
			return a - b;
		}
	}

	/**
	 * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
	function div(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		unchecked {
			require(b > 0, errorMessage);
			return a / b;
		}
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	 * reverting with custom message when dividing by zero.
	 *
	 * CAUTION: This function is deprecated because it requires allocating memory for the error
	 * message unnecessarily. For custom revert reasons use {tryMod}.
	 *
	 * Counterpart to Solidity's `%` operator. This function uses a `revert`
	 * opcode (which leaves remaining gas untouched) while Solidity uses an
	 * invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function mod(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		unchecked {
			require(b > 0, errorMessage);
			return a % b;
		}
	}
}

interface IReferral {
	/**
	 * @dev Record referral.
	 */
	function recordReferral(address user, address referrer) external;

	/**
	 * @dev Record referral share.
	 */
	function recordReferralShare(address referrer, uint256 share) external;

	/**
	 * @dev Get the referrer address that referred the user.
	 */
	function getReferrer(address user) external view returns (address);
}

contract Nfts is Ownable {
	using SafeMath for uint256;

	uint256 public price = 10000000 gwei;
	uint256 public priceStep = 10000000 gwei;
	uint256 public maxSupply = 100;
	uint256 public premint = 30;
    uint256 public totalSupply = premint;
	uint16 public refShare = 1000; // in basis points, so it's 10%
	uint256 public startTime = 0;
	IReferral public referralContract;

    event Mint(
        address indexed user,
		uint256 fromId,
        uint256 amount
    );

	event ReferralSharePaid(
		address indexed user,
		address indexed referrer,
		uint256 shareAmount
	);
	
	function getNextPrice() internal returns (uint) {
	    return price + priceStep * (totalSupply - premint);
	}

	function mint(address _referrer) external payable {
	    require(block.timestamp >= startTime);
	    
		if (
			msg.value > 0 &&
			address(referralContract) != address(0) &&
			_referrer != address(0) &&
			_referrer != msg.sender
		) {
			referralContract.recordReferral(msg.sender, _referrer);
		}
		
		uint rest = msg.value;
		uint currentPrice = getNextPrice();

		uint prevTotalSupply = totalSupply;

		while (currentPrice <= rest) {
		    require(this.totalSupply() < maxSupply, 'Sold out');

            totalSupply++;
			
			rest -= currentPrice;
			currentPrice = getNextPrice();
		}

		uint256 amount = totalSupply - prevTotalSupply;

		if (amount > 0) {
			emit Mint(msg.sender, prevTotalSupply, amount);
		}
		
		payable(msg.sender).transfer(rest);
		payReferral(msg.sender, msg.value - rest);
	}

	// Update the referral contract address by the owner
	function setReferralAddress(IReferral _referralAddress) public onlyOwner {
		referralContract = _referralAddress;
	}

	// Pay referral share to the referrer who referred this user.
	function payReferral(address _to, uint256 _amount) internal {
		if (address(referralContract) != address(0) && refShare > 0) {
			address referrer = referralContract.getReferrer(_to);
			uint256 shareAmount = _amount.mul(refShare).div(10000);

			if (referrer != address(0) && shareAmount > 0) {
				payable(referrer).transfer(shareAmount);

				referralContract.recordReferralShare(referrer, shareAmount);
				emit ReferralSharePaid(_to, referrer, shareAmount);
			}
		}
	}
}

contract Referral is IReferral, Ownable {
	mapping(address => bool) public operators;
	mapping(address => address) public referrers; // user address => referrer address
	mapping(address => uint256) public referralsCount; // referrer address => referrals count
	mapping(address => uint256) public totalReferralShares; // referrer address => total referral commissions

	event ReferralRecorded(address indexed user, address indexed referrer);
	event ReferralShareRecorded(address indexed referrer, uint256 commission);
	event OperatorUpdated(address indexed operator, bool indexed status);

	modifier onlyOperator() {
		require(operators[msg.sender], 'Operator: caller is not the operator');
		_;
	}

	function recordReferral(address _user, address _referrer)
		public
		override
		onlyOperator
	{
		if (
			_user != address(0) &&
			_referrer != address(0) &&
			_user != _referrer &&
			referrers[_user] == address(0)
		) {
			referrers[_user] = _referrer;
			referralsCount[_referrer] += 1;
			emit ReferralRecorded(_user, _referrer);
		}
	}

	function recordReferralShare(address _referrer, uint256 _share)
		public
		override
		onlyOperator
	{
		if (_referrer != address(0) && _share > 0) {
			totalReferralShares[_referrer] += _share;
			emit ReferralShareRecorded(_referrer, _share);
		}
	}

	// Get the referrer address that referred the user
	function getReferrer(address _user) public view override returns (address) {
		return referrers[_user];
	}

	// Update the status of the operator
	function updateOperator(address _operator, bool _status)
		external
		onlyOwner
	{
		operators[_operator] = _status;
		emit OperatorUpdated(_operator, _status);
	}
}
