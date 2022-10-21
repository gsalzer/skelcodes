pragma solidity 0.4.23;

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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract SuterToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract SuterLock {
    using SafeMath for uint256;

    SuterToken public token;

    address public admin_address = 0x0713591DBdA93C1E5F407aBEF044a0FaF9F2f212; 
    uint256 public user_release_time = 1665331200; // 2022/10/10 0:0:0 UTC+8
    uint256 public contract_release_time = 1625068800; // 2021/7/1 0:0:0 UTC+8
    uint256 public release_ratio = 278;
    uint256 ratio_base = 100000;
    uint256 public amount_per_day = 4104000 ether;
    uint256 day_time = 86400; // Seconds of one day.
    uint256 public day_amount = 360;
    uint256 public start_time;
    uint256 public releasedAmount;
    uint256 public user_lock_amount;
    uint256 public contract_lock_amount;
    uint256 valid_amount;
 
    mapping(address => uint256) public lockedAmount;
    // Events.
    event LockToken(address indexed target, uint256 amount);
    event ReleaseToken(address indexed target, uint256 amount); 

    constructor() public {
        token = SuterToken(0xBA8c0244FBDEB10f19f6738750dAeEDF7a5081eb);
        start_time = now;
        valid_amount = (contract_release_time.sub(start_time)).div(day_time).mul(amount_per_day);
    }

    // Lock tokens for the specified address.
    function lockToken(address _target, uint256 _amount) public admin_only {
        require(_target != address(0), "target is a zero address");
        require(now < user_release_time, "Current time is greater than lock time");
        // Check if the token is enough.
        if (contract_lock_amount == 0) {
            uint256 num = (now.sub(start_time)).div(day_time).mul(amount_per_day);
            if (num > valid_amount) {
                num = valid_amount;
            }
            require(token.balanceOf(address(this)).sub(num).sub(user_lock_amount) >= _amount, "Not enough balance");
        } else {
            require(token.balanceOf(address(this)).add(releasedAmount).sub(contract_lock_amount).sub(user_lock_amount) >= _amount, "Not enough balance");
        }
        lockedAmount[_target] = lockedAmount[_target].add(_amount);
        user_lock_amount = user_lock_amount.add(_amount);
        emit LockToken(_target, _amount);
    }

    // Release the lock-up token at the specified address.
    function releaseTokenToUser(address _target) public {
        uint256 releasable_amount = releasableAmountOfUser(_target);
        if (releasable_amount == 0) {
            return;
        } else {
            token.transfer(_target, releasable_amount);
            emit ReleaseToken(_target, releasable_amount);
            lockedAmount[_target] = 0;
            user_lock_amount = user_lock_amount.sub(releasable_amount);
        }
    }

    // Release the tokens locked in the contract to the address 'admin_address'.
    function releaseTokenToAdmin() public admin_only {
        require(now > contract_release_time, "Release time not reached");
        if(contract_lock_amount == 0) {
            contract_lock_amount = token.balanceOf(address(this)).sub(user_lock_amount);
            if (contract_lock_amount > valid_amount) {
                contract_lock_amount = valid_amount;
            }
        }
        uint256 amount = releasableAmountOfContract();
        require(token.transfer(msg.sender, amount));
        releasedAmount = releasedAmount.add(amount);
        emit ReleaseToken(msg.sender, amount);
    }

    // This function is used to withdraw the extra Suter tokens in the contract, the caller must be 'admin_address'.
    function withdrawSuter() public admin_only {
        require(contract_lock_amount > 0, "The number of token releases has not been determined");
        uint256 lockAmount_ = user_lock_amount.add(contract_lock_amount).sub(releasedAmount); // The amount of tokens locked.
        uint256 remainingAmount_ =  token.balanceOf(address(this)).sub(lockAmount_); // The amount of extra tokens in the contract.
        require(remainingAmount_ > 0, "No extra tokens");
        require(token.transfer(msg.sender, remainingAmount_));
    }

    modifier admin_only() {
        require(msg.sender==admin_address);
        _;
    }

    function setAdmin( address new_admin_address ) public admin_only returns (bool) {
        require(new_admin_address != address(0), "New admin is a zero address");
        admin_address = new_admin_address;
        return true;
    }

    function withDraw() public admin_only {
        require(address(this).balance > 0, "Contract eth balance is 0");
        admin_address.transfer(address(this).balance);
    }

    function () external payable {    

    }

    // The releasable tokens of specified address at the current time.
    function releasableAmountOfUser(address _target) public view returns (uint256) {
        if(now < user_release_time) {
            return 0;
        } else {
            return lockedAmount[_target];
        }
    }

    // The releasable tokens of contract.
    function releasableAmountOfContract() public view returns (uint256) {
        if(now < contract_release_time) {
            return 0;
        } else {
            uint256 num = contract_lock_amount;
            if (contract_lock_amount == 0) {
                num = token.balanceOf(address(this)).sub(user_lock_amount);
                if (num > valid_amount) {
                    num = valid_amount;
                }
            }
            uint256 _days =(now.sub(contract_release_time)).div(day_time);
            uint256 _amount = num.mul(release_ratio).mul(_days).div(ratio_base);
            if (_amount > num) {
                _amount = num;
            }
            return _amount.sub(releasedAmount);
        }
    }

    // Get the amount of tokens used for contract lockup.
    function getContractLockAmount() public view returns(uint256 num2) {
        if (contract_lock_amount == 0) {
            uint256 num1 = (now.sub(start_time)).div(day_time).mul(amount_per_day);
            num2 = token.balanceOf(address(this)).sub(user_lock_amount);
            if (num2 > num1) {
                num2 = num1;
            } 
        } else {
            num2 = contract_lock_amount;
        }
    }
}
