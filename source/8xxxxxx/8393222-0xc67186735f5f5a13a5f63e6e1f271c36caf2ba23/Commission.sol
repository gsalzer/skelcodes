// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

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

// File: contracts/Commission.sol

pragma solidity ^0.5.0;



contract Commission is Ownable {
	using SafeMath for uint256;

	address payable public wallet;

	constructor(address payable _wallet) public {
		require(_wallet != address(0), "missing wallet");

		wallet = _wallet;
	}

	// Holdex wallet ===============================================================================

	event HoldexWalletChanged(address indexed wallet);

	function changeHoldexWallet(address payable _wallet) external onlyOwner {
		// Inputs validation
		require(_wallet != address(0), "missing wallet");
		require(_wallet != wallet, "wallets are the same");

		// Change wallet
		wallet = _wallet;
		emit HoldexWalletChanged(_wallet);
	}

	// Customers ===================================================================================

	event CustomerAdded(address indexed customer, address indexed wallet, uint256 commission);
	event CustomerUpdated(address indexed customer, address indexed wallet, uint256 commission);
	event CustomerRemoved(address indexed customer);

	mapping(address => Customer) public customers;

	struct Customer {
		address payable wallet;
		uint256 commissionPercent;
		mapping(bytes32 => Partner) partners;
	}

	function addCustomer(address _customer, address payable _wallet, uint256 _commissionPercent) external onlyOwner {
		// Inputs validation
		require(_customer != address(0), "missing customer address");
		require(_wallet != address(0), "missing wallet address");
		require(_commissionPercent < 100, "invalid commission percent");

		// Check if customer already exists
		if (customers[_customer].wallet == address(0)) {
			// Customer does not exist, add it
			customers[_customer].wallet = _wallet;
			customers[_customer].commissionPercent = _commissionPercent;
			emit CustomerAdded(_customer, _wallet, _commissionPercent);
		} else {
			// Customer already exists, update it
			customers[_customer].wallet = _wallet;
			customers[_customer].commissionPercent = _commissionPercent;
			emit CustomerUpdated(_customer, _wallet, _commissionPercent);
		}
	}

	function customerExists(address _customer) internal view {
		require(customers[_customer].wallet != address(0), "customer does not exist");
	}

	function removeCustomer(address _customer) external onlyOwner {
		// Inputs validation
		require(_customer != address(0), "missing customer address");

		// Check if customer exists
		customerExists(_customer);

		// Remove customer
		delete customers[_customer];
		emit CustomerRemoved(_customer);
	}

	// Partners ====================================================================================

	event PartnerAdded(address indexed customer, bytes32 partner, address indexed wallet, uint256 commission);
	event PartnerUpdated(address indexed customer, bytes32 partner, address indexed wallet, uint256 commission);
	event PartnerRemoved(address indexed customer, bytes32 partner);

	struct Partner {
		address payable wallet;
		uint256 commissionPercent;
	}

	function addPartner(address _customer, bytes32 _partner, address payable _wallet, uint256 _commissionPercent) external onlyOwner {
		// Inputs validation
		require(_customer != address(0), "missing customer address");
		require(_partner[0] != 0, "missing partner id");
		require(_wallet != address(0), "missing wallet address");
		require(_commissionPercent > 0 && _commissionPercent < 100, "invalid commission percent");

		// Check if customer exists
		customerExists(_customer);

		// Check if partner already exists
		if (customers[_customer].partners[_partner].wallet == address(0)) {
			// Partner does not exist, add it
			customers[_customer].partners[_partner] = Partner(_wallet, _commissionPercent);
			emit PartnerAdded(_customer, _partner, _wallet, _commissionPercent);
		} else {
			// Partner already exists, update it
			customers[_customer].partners[_partner].wallet = _wallet;
			customers[_customer].partners[_partner].commissionPercent = _commissionPercent;
			emit PartnerUpdated(_customer, _partner, _wallet, _commissionPercent);
		}
	}

	function removePartner(address _customer, bytes32 _partner) external onlyOwner {
		// Inputs validation
		require(_customer != address(0), "missing customer address");
		require(_partner[0] != 0, "missing partner id");

		// Check if customer exists
		customerExists(_customer);
		// Check if partner exists
		require(customers[_customer].partners[_partner].wallet != address(0), "partner does not exist");

		// Remove partner
		delete customers[_customer].partners[_partner];
		emit PartnerRemoved(_customer, _partner);
	}

	// Transfer Funds ==============================================================================

	function transfer(bool holdex, bytes32[] calldata _partners) external payable {
		// Inputs validation
		require(msg.value > 0, "transaction value is 0");

		// Check if customer exists
		customerExists(msg.sender);

		// Check if customer pays any commission
		if (customers[msg.sender].commissionPercent == 0 || !holdex && _partners.length == 0) {
			// No commission. Transfer all funds
			customers[msg.sender].wallet.transfer(msg.value);
			return;
		}

		// Check if customer should pay some commission on this transaction
		if (holdex || _partners.length > 0) {
			// Commission applies. Calculate each's revenues

			// Customer revenue
			uint256 customerRevenue = msg.value.div(100).mul(100 - customers[msg.sender].commissionPercent);
			// Transfer revenue to customer
			customers[msg.sender].wallet.transfer(customerRevenue);

			// Calculate Holdex revenue
			uint256 holdexRevenue = msg.value.sub(customerRevenue);
			uint256 alreadySentPercent = 0;
			// Calculate partners revenues
			for (uint256 i = 0; i < _partners.length; i++) {
				Partner memory p = customers[msg.sender].partners[_partners[i]];
				require(p.commissionPercent > 0, "invalid partner");

				// Calculate partner revenue
				uint256 partnerRevenue = holdexRevenue.div(100 - alreadySentPercent).mul(p.commissionPercent);
				p.wallet.transfer(partnerRevenue);

				// Subtract partner revenue from Holdex revenue
				alreadySentPercent = alreadySentPercent.add(p.commissionPercent);
				holdexRevenue = holdexRevenue.sub(partnerRevenue);
			}

			require(holdexRevenue > 0, "holdex revenue is 0");
			// Transfer Holdex remained revenue
			wallet.transfer(holdexRevenue);
			return;
		}

		revert("can not transfer");
	}
}
