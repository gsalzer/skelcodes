pragma solidity 0.5.12;


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
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard {
    // counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * NOTE: This call _does not revert_ if the signature is invalid, or
     * if the signer is otherwise unable to be retrieved. In those scenarios,
     * the zero address is returned.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        // If the signature is valid (and not malleable), return the signer address
        return ecrecover(hash, v, r, s);
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------
library DateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        uint year;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        uint year;
        uint month;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        uint fromYear;
        uint fromMonth;
        uint fromDay;
        uint toYear;
        uint toMonth;
        uint toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        uint fromYear;
        uint fromMonth;
        uint fromDay;
        uint toYear;
        uint toMonth;
        uint toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

contract BaseSubscription is ReentrancyGuard, Initializable {
  using SafeMath for uint;
  using ECDSA for bytes32;
  enum Plan { Invalid, Standard, Pro, Premium, Enterprise }
  enum TransactionType { Subscribe, Unsubscribe, UpgradePlan, DowngradePlan, ExtendSubscription }

  struct Subscription {
    uint startTimestamp;
    uint depositValue;
    bool canceled;
    Plan plan;
    uint index;
  }
  mapping(address => Subscription) public subscriptions;
  address[] public sortedSubscriptions;
  uint startIndex;

  struct Billing {
    uint previousClearingDate;
    uint incomeSpeed;
  }
  Billing public billing;

  address payable public transactionSplitBox;
  address payable public serviceProvider;
  address public ticketProvider;
  uint public duration;
  uint internal constant MULTI = 10**18;

  modifier onlyServiceProvider() {
    require(msg.sender == serviceProvider, 'only serviceProvider');
    _;
  }

  event Subscribed(address indexed user, Plan plan, uint price);
  event Unsubscribed(address indexed user, uint refund);
  event UpgradedPlan(address indexed user, Plan plan);
  event DowngradedPlan(address indexed user, Plan plan, uint refund);
  event ExtendedSubscription(address indexed user, uint newExpiration);
  event Transaction(address indexed wallet, TransactionType indexed transactionType, Plan plan, uint amount, uint timestamp);

  function initialize(
    address payable _serviceProvider,
    address payable _transactionSplitBox,
    address _ticketProvider,
    uint _duration
  ) public initializer {
    require(_ticketProvider != address(0), "ticketProvider cannot be empty");
    require(_duration != 0 && _duration % 365 days == 0, "should be multiple of the year");
    serviceProvider = _serviceProvider;
    transactionSplitBox = _transactionSplitBox;
    ticketProvider = _ticketProvider;
    duration = _duration;
  }

  function subscribe(
    Plan _plan,
    uint _price,
    uint _ticketExpiration,
    address _contractAddress,
    bytes calldata _signature
  ) external payable {
    _validateTicket(_plan, _price, _ticketExpiration, _contractAddress, _signature);
    Subscription storage subscription = subscriptions[msg.sender];
    require(subscription.startTimestamp == 0 || subscription.canceled, "you still have going subscription");
    subscription.depositValue = _price;
    subscription.startTimestamp = currentTime();
    subscription.plan = _plan;

    _subscribe(_price);

    if (subscription.canceled) {
      subscription.canceled = false;
      sortedSubscriptions[subscription.index] = address(0);
    }

    // update subscriptions list
    subscription.index = sortedSubscriptions.length;
    sortedSubscriptions.push(msg.sender);

    // if it's first customer we should initialize timestamp that takes part of billing caclulations
    if (billing.previousClearingDate == 0) {
      billing.previousClearingDate = currentTime();
    }

    emit Subscribed(msg.sender, _plan, _price);
    emit Transaction(msg.sender, TransactionType.Subscribe, _plan, _price, now);
  }

  function _subscribe(uint _price) internal;

  function getSubscriptionStatus(address _account) public view returns(
    uint leftMonths,
    uint usedMonths,
    uint monthlyPayment,
    uint balance,
    Plan plan,
    uint expiration,
    bool isCanceled
  ) {
    uint totalMonths = duration / 365 days * 12;
    Subscription storage subscription = subscriptions[_account];
    if (subscription.startTimestamp == 0) {
      // subscription does not exist
      return (leftMonths, usedMonths, monthlyPayment, balance, plan, expiration, isCanceled);
    }
    expiration = _getExpiration(subscription);
    if (currentTime() >= subscription.startTimestamp && currentTime() < expiration) {
      // this subscription goes
      leftMonths = _diffMonths(currentTime(), expiration);
      usedMonths = totalMonths.sub(leftMonths);
    } else { // if (currentTime() >= expiration)
      // this subscription is expired
      leftMonths = 0;
      usedMonths = totalMonths;
    }
    monthlyPayment = subscription.depositValue.div(totalMonths);
    if (subscription.canceled) {
      balance = 0;
    } else {
      balance = subscription.depositValue.sub(usedMonths.mul(monthlyPayment));
    }
    plan = subscription.plan;
    isCanceled = subscription.canceled;
  }

  function _diffMonths(uint from, uint to) internal pure returns(uint numberOfMonths) {
    numberOfMonths = DateTimeLibrary.diffMonths(from, to);
    (,,uint fromDay, uint fromHour, uint fromMinute, uint fromSecond) = DateTimeLibrary.timestampToDateTime(from);
    (,,uint toDay, uint toHour, uint toMinute, uint toSecond) = DateTimeLibrary.timestampToDateTime(to);
    if (numberOfMonths != 0) {
      if (fromDay > toDay) {
        numberOfMonths--;
      } else if(fromDay >= toDay && fromHour > toHour) {
        numberOfMonths--;
      } else if(fromDay >= toDay && fromHour >= toHour && fromMinute > toMinute) {
        numberOfMonths--;
      } else if(fromDay >= toDay && fromHour >= toHour && fromMinute >= toMinute && fromSecond > toSecond) {
        numberOfMonths--;
      }
    }
  }

  function currentTime() public view returns(uint) {
    return block.timestamp;
  }

  function unsubscribe() external {
    (,,,uint balance,,,) = getSubscriptionStatus(msg.sender);
    Subscription storage subscription = subscriptions[msg.sender];
    require(!subscription.canceled, "subscription is canceled");
    _cancelSubscription(subscription);

    // first of all we do withdraw to send all earned ether before
    // it also makes `billing.previousClearingDate` equal `currentTime()`
    withdraw();

    // calculate how match ether user still should be charged for current month
    uint vaultOutcomeSpeed = subscription.depositValue.mul(MULTI).div(duration);
    uint paidTime = currentTime().sub(subscription.startTimestamp);
    uint paidEther = vaultOutcomeSpeed.mul(paidTime).div(MULTI);
    uint etherToCharge = subscription.depositValue.sub(balance).sub(paidEther);

    // then we update incomeSpeed
    billing.incomeSpeed = billing.incomeSpeed.sub(vaultOutcomeSpeed);

    _payToOwner(etherToCharge);
    _payToUser(balance);

    emit Unsubscribed(msg.sender, balance);
    emit Transaction(msg.sender, TransactionType.Unsubscribe, subscription.plan, balance, now);
  }

  function upgradePlan(
    Plan _plan,
    uint _price,
    uint _ticketExpiration,
    address _contractAddress,
    bytes calldata _signature
  ) external payable {
    _validateTicket(_plan, _price, _ticketExpiration, _contractAddress, _signature);
    Subscription storage subscription = subscriptions[msg.sender];
    uint expiration = _getExpiration(subscription);
    require(!subscription.canceled, "subscription is canceled");
    require(expiration > currentTime(), "cannot upgrade. Subscription is over");
    require(_plan > subscription.plan, "cannot upgrade to the same or lower plan, use downgradePlan");
    // first of all we do withdraw to send all earned ether before
    // it also makes `billing.previousClearingDate` equal `currentTime()`
    withdraw();

    _upgradePlan(_price);

    // then we update the subscription
    subscription.depositValue = _price;
    subscription.plan = _plan;

    emit UpgradedPlan(msg.sender, _plan);
    emit Transaction(msg.sender, TransactionType.UpgradePlan, _plan, _price, now);
  }

  function _upgradePlan(uint _price) internal;

  /// @dev negative paymentDiff means refund
  function planPriceDifference(address _user, uint _price) public view returns(
    uint payment,
    uint refund,
    uint incomeSpeedDiff
  ) {
    Subscription storage subscription = subscriptions[_user];
    uint expiration = _getExpiration(subscription);
    uint oldIncomeSpeed = subscription.depositValue.mul(MULTI).div(duration);
    uint newIncomeSpeed = _price.mul(MULTI).div(duration);
    if (oldIncomeSpeed <= newIncomeSpeed) {
      incomeSpeedDiff = newIncomeSpeed.sub(oldIncomeSpeed);
      payment = expiration.sub(currentTime()).mul(incomeSpeedDiff).div(MULTI);
    } else {
      incomeSpeedDiff = oldIncomeSpeed.sub(newIncomeSpeed);
      refund = expiration.sub(currentTime()).mul(incomeSpeedDiff).div(MULTI);
    }
  }

  function downgradePlan(
    Plan _plan,
    uint _price,
    uint _ticketExpiration,
    address _contractAddress,
    bytes calldata _signature
  ) external {
    _validateTicket(_plan, _price, _ticketExpiration, _contractAddress, _signature);
    Subscription storage subscription = subscriptions[msg.sender];
    uint expiration = _getExpiration(subscription);
    require(!subscription.canceled, "subscription is canceled");
    require(expiration > currentTime(), "cannot downgrade. Subscription is over");
    require(_plan < subscription.plan, "cannot downgrade to the same or plan above, use upgradePlan");

    // first of all we do withdraw to send all earned ether before
    // it also makes `billing.previousClearingDate` equal `currentTime()`
    withdraw();

    // calculate how match ether contact should return
    (uint payment, uint refund, uint incomeSpeedDiff) = planPriceDifference(msg.sender, _price);
    require(payment == 0, "New plan should be less expensive");

    // then we update incomeSpeed and subscription
    billing.incomeSpeed = billing.incomeSpeed.sub(incomeSpeedDiff);
    subscription.depositValue = _price;
    subscription.plan = _plan;

    _payToUser(refund);
    emit DowngradedPlan(msg.sender, _plan, refund);
    emit Transaction(msg.sender, TransactionType.DowngradePlan, _plan, refund, now);
  }

  function extensionPayment(address _user, uint _price) public view returns(
    uint payment,
    uint incomeSpeedDiff,
    uint newDepositValue
  ) {
    Subscription storage subscription = subscriptions[_user];
    uint passedTime = currentTime().sub(subscription.startTimestamp);
    uint oldIncomeSpeed = subscription.depositValue.mul(MULTI).div(duration);
    uint newIncomeSpeed = _price.mul(MULTI).div(duration);

    uint paidEther = passedTime.mul(oldIncomeSpeed).div(MULTI);
    payment = passedTime.mul(newIncomeSpeed).div(MULTI);
    newDepositValue = subscription.depositValue.sub(paidEther).add(payment);
    uint extensionIncomeSpeed = newDepositValue.mul(MULTI).div(duration);

    if (oldIncomeSpeed <= extensionIncomeSpeed) {
      // new price is higher, so we should add this diff to the total income speed.
      // See the _extendSubscription func
      incomeSpeedDiff = extensionIncomeSpeed.sub(oldIncomeSpeed);
    } else {
      // new price is lower, so we should sub this diff from the total income speed.
      // See the _extendSubscription func
      incomeSpeedDiff = oldIncomeSpeed.sub(extensionIncomeSpeed);
    }
  }
  /// @dev The function allows a user to prolong a subscription up to `duration`.
  /// e.g. A user bought a subscription using `subscribe` func 7 months ago and he still has a 5-month service.
  /// Today the user can call `extendSubscription` to extend the subscription for 7 months (that passed so far).
  /// Today's `_price` could be higher, lower or the same.
  /// So for SubscriptionETH the user should always send a msg.value that equals to `_price` * extension_time .
  /// For SubscriptionVGT the payment will be withdrawn automatically.
  function extendSubscription(
    Plan _plan,
    uint _price,
    uint _ticketExpiration,
    address _contractAddress,
    bytes calldata _signature
  ) external payable {
    _validateTicket(_plan, _price, _ticketExpiration, _contractAddress, _signature);
    Subscription storage subscription = subscriptions[msg.sender];
    uint expiration = _getExpiration(subscription);
    require(!subscription.canceled, "subscription is canceled");
    require(expiration > currentTime(), "cannot extend. Subscription is over");
    require(_plan == subscription.plan, "cannot extend. The plan should be the same as current one");

    // first of all we do withdraw to send all earned ether before
    // it also makes `billing.previousClearingDate` equal `currentTime()`
    withdraw();

    _extendSubscription(subscription, _price);

    uint newExpiration = currentTime().add(duration);
    emit ExtendedSubscription(msg.sender, newExpiration);
    emit Transaction(msg.sender, TransactionType.ExtendSubscription, _plan, _price, now);
  }

  function _extendSubscription(Subscription storage subscription, uint _price) internal;

  function disableOldestSubsription() public {
    require(startIndex < sortedSubscriptions.length, "there is no subscriptions to disable");
    address _account = sortedSubscriptions[startIndex];
    if (_account != address(0)) {
      Subscription storage subscription = subscriptions[_account];
      require(_getExpiration(subscription) < currentTime(), "it's still going subscription");
      if (!subscription.canceled) {
        // how many ether left to charge for this particular subscription ?
        uint incomeSpeed = subscription.depositValue.mul(MULTI).div(duration);
        uint paidTime;
        if (billing.previousClearingDate <= subscription.startTimestamp) {
          paidTime = 0;
        } else {
          paidTime = billing.previousClearingDate.sub(subscription.startTimestamp);
        }
        uint chargedEther = incomeSpeed.mul(paidTime).div(MULTI);
        uint etherToCharge = subscription.depositValue.sub(chargedEther);

        // descrease total incomeSpeed
        billing.incomeSpeed = billing.incomeSpeed.sub(incomeSpeed);

        _payToOwner(etherToCharge);
      } // else: subscription was canceled so all the money has been already withdrawn

      _clearSubscription(_account);
      sortedSubscriptions[startIndex] = address(0);
    } // else: subscription was extended so we just skip it
    startIndex++;
  }

  function disableBatchOfSubsriptions(uint count) external {
    for(uint i = 0; i < count; i++) {
      disableOldestSubsription();
    }
  }

  /**
    * @return the address of the Vault12 signing Oracle
    * @dev msgLength = 1 + 32 + 32 + 20 = 85
    */
  function getSignerAddress(
    Plan _plan,
    uint256 _price,
    uint256 _ticketExpiration,
    address _contractAddress,
    bytes memory signature
  )
    public
    pure
    returns (address signer)
  {
    bytes32 hash = keccak256(abi.encodePacked(_plan, _price, _ticketExpiration, _contractAddress));
    bytes32 hashedMsg = hash.toEthSignedMessageHash();
    signer = hashedMsg.recover(signature);
  }

  function withdraw() public {
    while(isOldestSubscriptionExpired()) {
      disableOldestSubsription();
    }
    uint income = approximateIncome();
    billing.previousClearingDate = currentTime();
    _payToOwner(income);
  }

  /// @dev this function gives approximate results
  // if the `isOldestSubscriptionExpired` returns `true` then the result is totally wrong
  // exact values and leftovers for particular subscription are calculated during the `disableOldestSubsription` call
  function approximateIncome() public view returns(uint income) {
    income = currentTime().sub(billing.previousClearingDate).mul(billing.incomeSpeed).div(MULTI);
  }

  function _validateTicket(
    Plan _plan,
    uint _price,
    uint _ticketExpiration,
    address _contractAddress,
    bytes memory _signature
  ) internal view {
    require(address(this) == _contractAddress, "ticket is signed for different address");
    require(_ticketExpiration > currentTime(), "ticket is expired");
    address _ticketProvider = getSignerAddress(_plan, _price, _ticketExpiration, _contractAddress, _signature);
    require(_ticketProvider == ticketProvider, "ticket signer is invalid");
  }

  /// @dev don't forget to apply the nonReentrant modifier
  function _payToOwner(uint value) internal;

  /// @dev don't forget to apply the nonReentrant modifier
  function _payToUser(uint _balance) internal;

  function _clearSubscription(address _user) internal {
    delete subscriptions[_user];
  }

  function _cancelSubscription(Subscription storage subscription) internal {
    subscription.canceled = true;
  }

  function _getExpiration(Subscription storage subscription) internal view returns(uint) {
    return subscription.startTimestamp.add(duration);
  }

  function isOldestSubscriptionExpired() public view returns(bool) {
    if (startIndex >= sortedSubscriptions.length) {
      return false;
    }
    address user = sortedSubscriptions[startIndex];
    if (user == address(0)) {
      // subscription was extended so it was moved within sortedSubscriptions
      return true;
    }
    Subscription storage closestSubscriptionToFinish = subscriptions[user];
    return _getExpiration(closestSubscriptionToFinish) < currentTime();
  }
}

contract SubscriptionETH is BaseSubscription {

  function _subscribe(uint _price) internal {
    require(msg.value == _price, "provided ETH amount is invalid");

    billing.incomeSpeed = billing.incomeSpeed.add(
      msg.value.mul(MULTI).div(duration)
    );
  }

  function _upgradePlan(uint _price) internal {
    // calculate how match ether user should send
    (uint payment, uint refund, uint incomeSpeedDiff) = planPriceDifference(msg.sender, _price);
    if (payment > 0) {
      billing.incomeSpeed = billing.incomeSpeed.add(incomeSpeedDiff);

      uint change = msg.value.sub(payment, "not enough ETH");
      if (change > 0) {
        _payToUser(change);
      }
    } else if (refund > 0) {
      require(msg.value == 0, "new price is lower, additional payment is not needed");
      billing.incomeSpeed = billing.incomeSpeed.sub(incomeSpeedDiff);
      _payToUser(refund);
    } else {
      require(refund == 0 && payment == 0);
      require(msg.value == 0, "new price is equal to old one, additional payment is not needed");
    }
  }

  function _extendSubscription(Subscription storage subscription, uint _price) internal {
    (uint payment, uint incomeSpeedDiff, uint newDepositValue) = extensionPayment(msg.sender, _price);
    require(msg.value >= payment, "not enough ETH");

    // then we update incomeSpeed and subscription
    if(newDepositValue > subscription.depositValue) {
      billing.incomeSpeed = billing.incomeSpeed.add(incomeSpeedDiff);
    } else if(newDepositValue < subscription.depositValue) {
      billing.incomeSpeed = billing.incomeSpeed.sub(incomeSpeedDiff);
    } // else billing.incomeSpeed is remained the same

    subscription.startTimestamp = currentTime();
    subscription.depositValue = newDepositValue;

    // update subscriptions list
    sortedSubscriptions.push(msg.sender);
    sortedSubscriptions[subscription.index] = address(0);
    subscription.index = sortedSubscriptions.length - 1;

    uint change = msg.value.sub(payment);
    if (change > 0) {
      _payToUser(change);
    }
  }

  function _payToOwner(uint value) internal nonReentrant {
    uint splitedValue = value.div(5); // take 20%
    (bool success, ) = transactionSplitBox.call.value(splitedValue)("");
    require(success, "payment to transactionSplitBox didnt go thru");
    (bool success2, ) = serviceProvider.call.value(value.sub(splitedValue))("");
    require(success2, "payment to serviceProvider didnt go thru");
  }

  function _payToUser(uint value) internal nonReentrant {
    (bool success, ) = msg.sender.call.value(value)("");
    require(success, "payment to User didnot go thru");
  }

}
