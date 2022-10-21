pragma solidity ^0.5.6;

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

/**
 * @dev A token holder contract that will allow a set of beneficiaries to
 * extract the tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract TokenTimelock {
    using SafeMath for uint256;

    IERC20                       private _token;
    mapping (address => uint256) private _payments;
    mapping (address => bool)    private _revokers;
    address                      private _fallback;
    address[]                    private _beneficiaries;
    uint256                      private _releaseTime;

    constructor (IERC20           token,
                 address          fallback,
                 address[] memory revokers,
                 address[] memory beneficiaries,
                 uint256[] memory amounts,
                 uint256          releaseTime
                 ) public {
        require(beneficiaries.length == amounts.length,
                "TokenTimelock: different number of beneficiaries vs amounts");
        // solhint-disable-next-line not-rely-on-time
        require(releaseTime > block.timestamp,
                "TokenTimelock: release time is before current time");

        _token = token;
        _fallback = fallback;
        _releaseTime = releaseTime;
        for (uint i = 0; i < revokers.length; i++) {
            _revokers[revokers[i]] = true;
        }
        // If the same beneficiary is mentioned twice the amounts are summed.
        for (uint i = 0; i < beneficiaries.length; i++) {
            bool isDuplicate = _payments[beneficiaries[i]] > 0;
            _payments[beneficiaries[i]] = _payments[beneficiaries[i]].add(amounts[i]);
            if (!isDuplicate) {
                _beneficiaries.push(beneficiaries[i]);
            }
        }
    }

    function token() public view returns (IERC20) {
        return _token;
    }

    function amount() public view returns (uint256) {
        return _payments[msg.sender];
    }

    function releaseTime() public view returns (uint256) {
        return _releaseTime;
    }

    /**
     * @dev Check that the contract has sufficient available tokens to honour
     * the payments to the beneficiaries.
     */
    function valid() public view returns (bool) {
        uint256 available = _token.balanceOf(address(this));
        uint256 owing = 0;
        for (uint i = 0; i < _beneficiaries.length; i++) {
            owing = owing.add(_payments[_beneficiaries[i]]);
        }
        return owing <= available;
    }

    /**
     * @dev Emitted when the release time has passed and the tokens are
     * transferred.
     */
    event Release(address indexed owner);

    /*
     * @dev Transfer the held tokens to the beneficiaries who have not had their
     * payments revoked if the release time has passed.  If there are any tokens
     * remaining in the contract they are transferred to the fallback account.
     */
    function release() public {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= _releaseTime,
                "TokenTimelock: current time is before release time");
        uint256 remaining = _token.balanceOf(address(this));
        require(remaining > 0,
                "TokenTimelock: no tokens to release");
        for (uint i = 0; i < _beneficiaries.length; i++) {
            if (_payments[_beneficiaries[i]] > 0) {
                _token.transfer(_beneficiaries[i], _payments[_beneficiaries[i]]);
                remaining = remaining.sub(_payments[_beneficiaries[i]]);
                _payments[_beneficiaries[i]] = 0;
            }
        }
        if (remaining > 0) {
            _token.transfer(_fallback, remaining);
        }
        emit Release(address(this));
    }

    /*
     * @dev Prevent a beneficiary from receiving their amount of tokens if they
     * haven't already received them.  The tokens that the beneficiary would
     * have received are instead immediately transferred to the fallback
     * address.
     */
    function revoke(address beneficiary) public {
        require(_revokers[msg.sender],
                "TokenTimelock: sender not allowed to revoke payment");
        if (_payments[beneficiary] > 0) {
            _token.transfer(_fallback, _payments[beneficiary]);
            _payments[beneficiary] = 0;
        }
    }
}
