pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;


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

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
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

library LibEIP712 {
    string internal constant DOMAIN_NAME = "Mai Protocol";

    struct OrderSignature {
        bytes32 config;
        bytes32 r;
        bytes32 s;
    }

    /**
     * Hash of the EIP712 Domain Separator Schema
     */
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked("EIP712Domain(string name)"));

    bytes32 private constant DOMAIN_SEPARATOR = keccak256(
        abi.encodePacked(EIP712_DOMAIN_TYPEHASH, keccak256(bytes(DOMAIN_NAME)))
    );

    /**
     * Calculates EIP712 encoding for a hash struct in this EIP712 Domain.
     *
     * @param eip712hash The EIP712 hash struct.
     * @return EIP712 hash applied to this EIP712 Domain.
     */
    function hashEIP712Message(bytes32 eip712hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, eip712hash));
    }
}

library LibSignature {
    enum SignatureMethod {ETH_SIGN, EIP712}

    struct OrderSignature {
        bytes32 config;
        bytes32 r;
        bytes32 s;
    }

    /**
     * Validate a signature given a hash calculated from the order data, the signer, and the
     * signature data passed in with the order.
     *
     * This function will revert the transaction if the signature method is invalid.
     *
     * @param signature The signature data passed along with the order to validate against
     * @param hash Hash bytes calculated by taking the EIP712 hash of the passed order data
     * @param signerAddress The address of the signer
     * @return True if the calculated signature matches the order signature data, false otherwise.
     */
    function isValidSignature(OrderSignature memory signature, bytes32 hash, address signerAddress)
        internal
        pure
        returns (bool)
    {
        uint8 method = uint8(signature.config[1]);
        address recovered;
        uint8 v = uint8(signature.config[0]);

        if (method == uint8(SignatureMethod.ETH_SIGN)) {
            recovered = ecrecover(
                keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),
                v,
                signature.r,
                signature.s
            );
        } else if (method == uint8(SignatureMethod.EIP712)) {
            recovered = ecrecover(hash, v, signature.r, signature.s);
        } else {
            revert("invalid sign method");
        }

        return signerAddress == recovered;
    }
}

library LibMathSigned {
    int256 private constant _WAD = 10**18;
    int256 private constant _INT256_MIN = -2**255;

    function WAD() internal pure returns (int256) {
        return _WAD;
    }

    // additive inverse
    function neg(int256 a) internal pure returns (int256) {
        return sub(int256(0), a);
    }

    /**
     * @dev wmultiplies two signed integers, reverts on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }
        require(!(a == -1 && b == _INT256_MIN), "wmultiplication overflow");

        int256 c = a * b;
        require(c / a == b, "wmultiplication overflow");

        return c;
    }

    /**
     * @dev Integer wdivision of two signed integers truncating the quotient, reverts on wdivision by zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "wdivision by zero");
        require(!(b == -1 && a == _INT256_MIN), "wdivision overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Subtracts two signed integers, reverts on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "subtraction overflow");

        return c;
    }

    /**
     * @dev Adds two signed integers, reverts on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "addition overflow");

        return c;
    }

    function wmul(int256 x, int256 y) internal pure returns (int256 z) {
        z = roundHalfUp(mul(x, y), _WAD) / _WAD;
    }

    // solium-disable-next-line security/no-assign-params
    function wdiv(int256 x, int256 y) internal pure returns (int256 z) {
        if (y < 0) {
            y = -y;
            x = -x;
        }
        z = roundHalfUp(mul(x, _WAD), y) / y;
    }

    // solium-disable-next-line security/no-assign-params
    function wfrac(int256 x, int256 y, int256 z) internal pure returns (int256 r) {
        int256 t = mul(x, y);
        if (z < 0) {
            z = -z;
            t = -t;
        }
        r = roundHalfUp(t, z) / z;
    }

    function min(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function max(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    // quotient and remainder
    function pwdiv(int256 x, int256 y) internal pure returns (int256 z, int256 m) {
        z = wdiv(x, y);
        m = sub(wmul(y, z), x);
    }

    function toUint256(int256 x) internal pure returns (uint256) {
        require(x >= 0, "int overflow");
        return uint256(x);
    }

    // x ^ n
    // NOTE: n is a normal integer, do not shift 18 decimals
    // solium-disable-next-line security/no-assign-params
    function wpowi(int256 x, int256 n) internal pure returns (int256 z) {
        z = n % 2 != 0 ? x : _WAD;

        for (n /= 2; n != 0; n /= 2) {
            x = wmul(x, x);

            if (n % 2 != 0) {
                z = wmul(z, x);
            }
        }
    }

    uint8 internal constant fixed_digits = 18;
    int256 internal constant fixed_1 = 1000000000000000000;
    int256 internal constant fixed_e = 2718281828459045235;
    uint8 internal constant longer_digits = 36;
    int256 internal constant longer_fixed_log_e_1_5 = 405465108108164381978013115464349137;
    int256 internal constant longer_fixed_1 = 1000000000000000000000000000000000000;
    int256 internal constant longer_fixed_log_e_10 = 2302585092994045684017991454684364208;

    // ROUND_HALF_UP rule helper. 0.5 ≈ 1, 0.4 ≈ 0, -0.5 ≈ -1, -0.4 ≈ 0
    function roundHalfUp(int256 x, int256 y) internal pure returns (int256) {
        require(y > 0, "roundHalfUp only supports y > 0");
        if (x >= 0) {
            return add(x, y / 2);
        }
        return sub(x, y / 2);
    }

    // function roundFloor(int256 x, int256 y) internal pure returns (int256) {
    //     require(y > 0, "roundHalfUp only supports y > 0");
    //     if (x >= 0 || x % _WAD == 0) {
    //         return x;
    //     }
    //     return sub(x, y);
    // }

    // function roundCeil(int256 x, int256 y) internal pure returns (int256) {
    //     require(y > 0, "roundHalfUp only supports y > 0");
    //     if (x <= 0 || x % _WAD == 0) {
    //         return x;
    //     }
    //     return add(x, y);
    // }

    // Log(e, x)
    // solium-disable-next-line security/no-assign-params
    function wln(int256 x) internal pure returns (int256) {
        require(x > 0, "logE of negative number");
        require(x <= 10000000000000000000000000000000000000000, "logE only accepts v <= 1e22 * 1e18"); // in order to prevent using safe-math
        int256 r = 0;
        uint8 extra_digits = longer_digits - fixed_digits;
        int256 t = int256(uint256(10)**uint256(extra_digits));

        while (x <= fixed_1 / 10) {
            x = x * 10;
            r -= longer_fixed_log_e_10;
        }
        while (x >= 10 * fixed_1) {
            x = x / 10;
            r += longer_fixed_log_e_10;
        }
        while (x < fixed_1) {
            x = wmul(x, fixed_e);
            r -= longer_fixed_1;
        }
        while (x > fixed_e) {
            x = wdiv(x, fixed_e);
            r += longer_fixed_1;
        }
        if (x == fixed_1) {
            return roundHalfUp(r, t) / t;
        }
        if (x == fixed_e) {
            return fixed_1 + roundHalfUp(r, t) / t;
        }
        x *= t;

        //               x^2   x^3   x^4
        // Ln(1+x) = x - --- + --- - --- + ...
        //                2     3     4
        // when -1 < x < 1, O(x^n) < ε => when n = 36, 0 < x < 0.316
        //
        //                    2    x           2    x          2    x
        // Ln(a+x) = Ln(a) + ---(------)^1  + ---(------)^3 + ---(------)^5 + ...
        //                    1   2a+x         3   2a+x        5   2a+x
        //
        // Let x = v - a
        //                  2   v-a         2   v-a        2   v-a
        // Ln(v) = Ln(a) + ---(-----)^1  + ---(-----)^3 + ---(-----)^5 + ...
        //                  1   v+a         3   v+a        5   v+a
        // when n = 36, 1 < v < 3.423
        r = r + longer_fixed_log_e_1_5;
        int256 a1_5 = (3 * longer_fixed_1) / 2;
        int256 m = (longer_fixed_1 * (x - a1_5)) / (x + a1_5);
        r = r + 2 * m;
        int256 m2 = (m * m) / longer_fixed_1;
        uint8 i = 3;
        while (true) {
            m = (m * m2) / longer_fixed_1;
            r = r + (2 * m) / int256(i);
            i += 2;
            if (i >= 3 + 2 * fixed_digits) {
                break;
            }
        }
        return roundHalfUp(r, t) / t;
    }

    // Log(b, x)
    function logBase(int256 base, int256 x) internal pure returns (int256) {
        return wdiv(wln(x), wln(base));
    }

    function ceil(int256 x, int256 m) internal pure returns (int256) {
        require(x >= 0, "ceil need x >= 0");
        require(m > 0, "ceil need m > 0");
        return (sub(add(x, m), 1) / m) * m;
    }
}

library LibMathUnsigned {
    uint256 private constant _WAD = 10**18;
    uint256 private constant _UINT256_MAX = 2**255 - 1;

    function WAD() internal pure returns (uint256) {
        return _WAD;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Unaddition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Unsubtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "Unmultiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "Undivision by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), _WAD / 2) / _WAD;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, _WAD), y / 2) / y;
    }

    function wfrac(uint256 x, uint256 y, uint256 z) internal pure returns (uint256 r) {
        r = mul(x, y) / z;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    // quotient and remainder
    function pwdiv(uint256 x, uint256 y) internal pure returns (uint256 z, uint256 m) {
        z = wdiv(x, y);
        m = sub(wmul(y, z), x);
    }

    function toInt256(uint256 x) internal pure returns (int256) {
        require(x <= _UINT256_MAX, "uint256 overflow");
        return int256(x);
    }

    function mod(uint256 x, uint256 m) internal pure returns (uint256) {
        require(m != 0, "mod by zero");
        return x % m;
    }

    function ceil(uint256 x, uint256 m) internal pure returns (uint256) {
        require(m > 0, "ceil need m > 0");
        return (sub(add(x, m), 1) / m) * m;
    }
}

library LibOrder {
    using LibMathSigned for int256;
    using LibMathUnsigned for uint256;

    bytes32 public constant EIP712_ORDER_TYPE = keccak256(
        abi.encodePacked(
            "Order(address trader,address broker,address perpetual,uint256 amount,uint256 price,bytes32 data)"
        )
    );

    int256 public constant FEE_RATE_BASE = 100000;
    uint256 public constant ONE = 1e18;

    struct Order {
        address trader;
        address broker;
        address perpetual;
        uint256 amount;
        uint256 price;
        /**
         * Data contains the following values packed into 32 bytes
         * ╔════════════════════╤═══════════════════════════════════════════════════════════╗
         * ║                    │ length(bytes)   desc                                      ║
         * ╟────────────────────┼───────────────────────────────────────────────────────────╢
         * ║ version            │ 1               order version                             ║
         * ║ side               │ 1               0: buy (long), 1: sell (short)            ║
         * ║ isMarketOrder      │ 1               0: limitOrder, 1: marketOrder             ║
         * ║ expiredAt          │ 5               order expiration time in seconds          ║
         * ║ asMakerFeeRate     │ 2               maker fee rate (base 100,000)             ║
         * ║ asTakerFeeRate     │ 2               taker fee rate (base 100,000)             ║
         * ║ (d) makerRebateRate│ 2               rebate rate for maker (base 100)          ║
         * ║ salt               │ 8               salt                                      ║
         * ║ isMakerOnly        │ 1               is maker only                             ║
         * ║ isInversed         │ 1               is inversed contract                      ║
         * ║                    │ 8               reserved                                  ║
         * ╚════════════════════╧═══════════════════════════════════════════════════════════╝
         */
        bytes32 data;
    }

    struct OrderParam {
        address trader;
        uint256 amount;
        uint256 price;
        bytes32 data;
        LibSignature.OrderSignature signature;
    }

    function getOrderHash(OrderParam memory orderParam, address perpetual, address broker)
        internal
        pure
        returns (bytes32 orderHash)
    {
        Order memory order = getOrder(orderParam, perpetual, broker);
        orderHash = LibEIP712.hashEIP712Message(hashOrder(order));
        return orderHash;
    }

    function getOrderHash(Order memory order) internal pure returns (bytes32 orderHash) {
        orderHash = LibEIP712.hashEIP712Message(hashOrder(order));
        return orderHash;
    }

    function getOrder(OrderParam memory orderParam, address perpetual, address broker)
        internal
        pure
        returns (LibOrder.Order memory order)
    {
        order.trader = orderParam.trader;
        order.broker = broker;
        order.perpetual = perpetual;
        order.amount = orderParam.amount;
        order.price = orderParam.price;
        order.data = orderParam.data;
    }

    function hashOrder(Order memory order) internal pure returns (bytes32 result) {
        bytes32 orderType = EIP712_ORDER_TYPE;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let start := sub(order, 32)
            let tmp := mload(start)
            mstore(start, orderType)
            result := keccak256(start, 224)
            mstore(start, tmp)
        }
        return result;
    }

    function getOrderVersion(OrderParam memory orderParam) internal pure returns (uint256) {
        return uint256(uint8(bytes1(orderParam.data)));
    }

    function getExpiredAt(OrderParam memory orderParam) internal pure returns (uint256) {
        return uint256(uint40(bytes5(orderParam.data << (8 * 3))));
    }

    function isSell(OrderParam memory orderParam) internal pure returns (bool) {
        bool sell = uint8(orderParam.data[1]) == 1;
        return isInversed(orderParam) ? !sell : sell;
    }

    function getPrice(OrderParam memory orderParam) internal pure returns (uint256) {
        return isInversed(orderParam) ? ONE.wdiv(orderParam.price) : orderParam.price;
    }

    function isMarketOrder(OrderParam memory orderParam) internal pure returns (bool) {
        return uint8(orderParam.data[2]) == 1;
    }

    function isMarketBuy(OrderParam memory orderParam) internal pure returns (bool) {
        return !isSell(orderParam) && isMarketOrder(orderParam);
    }

    function isMakerOnly(OrderParam memory orderParam) internal pure returns (bool) {
        return uint8(orderParam.data[22]) == 1;
    }

    function isInversed(OrderParam memory orderParam) internal pure returns (bool) {
        return uint8(orderParam.data[23]) == 1;
    }

    function side(OrderParam memory orderParam) internal pure returns (LibTypes.Side) {
        return isSell(orderParam) ? LibTypes.Side.SHORT : LibTypes.Side.LONG;
    }

    function makerFeeRate(OrderParam memory orderParam) internal pure returns (int256) {
        return int256(int16(bytes2(orderParam.data << (8 * 8)))).mul(LibMathSigned.WAD()).div(FEE_RATE_BASE);
    }

    function takerFeeRate(OrderParam memory orderParam) internal pure returns (int256) {
        return int256(int16(bytes2(orderParam.data << (8 * 10)))).mul(LibMathSigned.WAD()).div(FEE_RATE_BASE);
    }
}

library LibTypes {
    enum Side {FLAT, SHORT, LONG}

    enum Status {NORMAL, SETTLING, SETTLED}

    function counterSide(Side side) internal pure returns (Side) {
        if (side == Side.LONG) {
            return Side.SHORT;
        } else if (side == Side.SHORT) {
            return Side.LONG;
        }
        return side;
    }

    //////////////////////////////////////////////////////////////////////////
    // Perpetual
    //////////////////////////////////////////////////////////////////////////
    struct PerpGovernanceConfig {
        uint256 initialMarginRate;
        uint256 maintenanceMarginRate;
        uint256 liquidationPenaltyRate;
        uint256 penaltyFundRate;
        int256 takerDevFeeRate;
        int256 makerDevFeeRate;
        uint256 lotSize;
        uint256 tradingLotSize;
    }

    // CollateralAccount represents cash account of user
    struct CollateralAccount {
        // currernt deposited erc20 token amount, representing in decimals 18
        int256 balance;
        // the amount of withdrawal applied by user
        // which allowed to withdraw in the future but not available in trading
        int256 appliedBalance;
        // applied balance will be appled only when the block height below is reached
        uint256 appliedHeight;
    }

    struct PositionAccount {
        LibTypes.Side side;
        uint256 size;
        uint256 entryValue;
        int256 entrySocialLoss;
        int256 entryFundingLoss;
    }

    struct BrokerRecord {
        address broker;
        uint256 appliedHeight;
    }

    struct Broker {
        BrokerRecord previous;
        BrokerRecord current;
    }

    //////////////////////////////////////////////////////////////////////////
    // AMM
    //////////////////////////////////////////////////////////////////////////
    struct AMMGovernanceConfig {
        uint256 poolFeeRate;
        uint256 poolDevFeeRate;
        int256 emaAlpha;
        uint256 updatePremiumPrize;
        int256 markPremiumLimit;
        int256 fundingDampener;
    }

    struct FundingState {
        uint256 lastFundingTime;
        int256 lastPremium;
        int256 lastEMAPremium;
        uint256 lastIndexPrice;
        int256 accumulatedFundingPerContract;
    }
}

contract Collateral {
    using LibMathSigned for int256;
    using LibMathUnsigned for uint256;
    using SafeERC20 for IERC20;

    uint256 private constant MAX_DECIMALS = 18;
    int256 private scaler;

    address public collateral;
    mapping(address => LibTypes.CollateralAccount) internal cashBalances;

    event Deposit(address indexed guy, int256 wadAmount, int256 balance);
    event Withdraw(address indexed guy, int256 wadAmount, int256 balance, int256 appliedBalance);
    event ApplyForWithdrawal(address indexed guy, int256 wadAmount, uint256 appliedHeight);
    event Transfer(address indexed from, address indexed to, int256 wadAmount, int256 balanceFrom, int256 balanceTo);
    event InternalUpdateBalance(address indexed guy, int256 wadAmount, int256 balance);

    constructor(address _collateral, uint256 decimals) public {
        require(decimals <= MAX_DECIMALS, "decimals out of range");
        require(_collateral != address(0x0) || (_collateral == address(0x0) && decimals == 18), "invalid decimals");

        collateral = _collateral;
        scaler = (decimals == MAX_DECIMALS ? 1 : 10**(MAX_DECIMALS - decimals)).toInt256();
    }

    // Public functions
    function getCashBalance(address guy) public view returns (LibTypes.CollateralAccount memory) {
        return cashBalances[guy];
    }

    // Internal functions
    function isTokenizedCollateral() internal view returns (bool) {
        return collateral != address(0x0);
    }

    function deposit(address guy, uint256 rawAmount) internal {
        if (rawAmount == 0) {
            return;
        }
        if (isTokenizedCollateral()) {
            IERC20(collateral).safeTransferFrom(guy, address(this), rawAmount);
        }
        int256 wadAmount = toWad(rawAmount);
        cashBalances[guy].balance = cashBalances[guy].balance.add(wadAmount);

        emit Deposit(guy, wadAmount, cashBalances[guy].balance);
    }

    function applyForWithdrawal(address guy, uint256 rawAmount, uint256 delay) internal {
        int256 wadAmount = toWad(rawAmount);
        cashBalances[guy].appliedBalance = wadAmount;
        cashBalances[guy].appliedHeight = block.number.add(delay);

        emit ApplyForWithdrawal(guy, wadAmount, cashBalances[guy].appliedHeight);
    }

    function _withdraw(address payable guy, int256 wadAmount, bool forced) private {
        require(wadAmount > 0, "negtive amount");
        require(wadAmount <= cashBalances[guy].balance, "insufficient balance");
        if (!forced) {
            require(block.number >= cashBalances[guy].appliedHeight, "applied height not reached");
            require(wadAmount <= cashBalances[guy].appliedBalance, "insufficient applied balance");
            cashBalances[guy].appliedBalance = cashBalances[guy].appliedBalance.sub(wadAmount);
        } else {
            cashBalances[guy].appliedBalance = cashBalances[guy].appliedBalance.sub(
                wadAmount.min(cashBalances[guy].appliedBalance)
            );
        }
        cashBalances[guy].balance = cashBalances[guy].balance.sub(wadAmount);
        uint256 rawAmount = toCollateral(wadAmount);
        if (isTokenizedCollateral()) {
            IERC20(collateral).safeTransfer(guy, rawAmount);
        } else {
            guy.transfer(rawAmount);
        }
        emit Withdraw(guy, wadAmount, cashBalances[guy].balance, cashBalances[guy].appliedBalance);
    }

    function withdraw(address payable guy, uint256 rawAmount, bool force) internal {
        if (rawAmount == 0) {
            return;
        }
        int256 wadAmount = toWad(rawAmount);
        _withdraw(guy, wadAmount, force);
    }

    function depositToProtocol(address guy, uint256 rawAmount) internal returns (int256) {
        if (rawAmount == 0) {
            return 0;
        }
        if (isTokenizedCollateral()) {
            IERC20(collateral).safeTransferFrom(guy, address(this), rawAmount);
        }
        return toWad(rawAmount);
    }

    function withdrawFromProtocol(address payable guy, uint256 rawAmount) internal returns (int256) {
        if (rawAmount == 0) {
            return 0;
        }
        if (isTokenizedCollateral()) {
            IERC20(collateral).safeTransfer(guy, rawAmount);
        } else {
            guy.transfer(rawAmount);
        }
        return toWad(rawAmount);
    }

    function withdrawAll(address payable guy) internal {
        if (cashBalances[guy].balance == 0) {
            return;
        }
        require(cashBalances[guy].balance > 0, "insufficient balance");
        _withdraw(guy, cashBalances[guy].balance, true);
    }

    function updateBalance(address guy, int256 wadAmount) internal {
        cashBalances[guy].balance = cashBalances[guy].balance.add(wadAmount);
        emit InternalUpdateBalance(guy, wadAmount, cashBalances[guy].balance);
    }

    // ensure balance >= 0
    function ensurePositiveBalance(address guy) internal returns (uint256 loss) {
        if (cashBalances[guy].balance < 0) {
            loss = cashBalances[guy].balance.neg().toUint256();
            cashBalances[guy].balance = 0;
        }
    }

    function transferBalance(address from, address to, int256 wadAmount) internal {
        if (wadAmount == 0) {
            return;
        }
        require(wadAmount > 0, "bug: invalid transfer amount");

        cashBalances[from].balance = cashBalances[from].balance.sub(wadAmount); // may be negative balance
        cashBalances[to].balance = cashBalances[to].balance.add(wadAmount);

        emit Transfer(from, to, wadAmount, cashBalances[from].balance, cashBalances[to].balance);
    }

    function toWad(uint256 rawAmount) private view returns (int256) {
        return rawAmount.toInt256().mul(scaler);
    }

    function toCollateral(int256 wadAmount) private view returns (uint256) {
        return wadAmount.div(scaler).toUint256();
    }
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(msg.sender);
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(msg.sender), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(msg.sender);
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

contract WhitelistedRole is WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender), "WhitelistedRole: caller does not have the Whitelisted role");
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(msg.sender);
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}

interface IPerpetualProxy {
    // a gas-optimized version of position*
    struct PoolAccount {
        uint256 positionSize;
        uint256 positionEntryValue;
        int256 cashBalance;
        int256 socialLossPerContract;
        int256 positionEntrySocialLoss;
        int256 positionEntryFundingLoss;
    }

    function self() external view returns (address);

    function perpetual() external view returns (address);

    function devAddress() external view returns (address);

    function currentBroker(address guy) external view returns (address);

    function markPrice() external returns (uint256);

    function settlementPrice() external view returns (uint256);

    function availableMargin(address guy) external returns (int256);

    function getPoolAccount() external view returns (PoolAccount memory pool);

    function cashBalance() external view returns (int256);

    function positionSize() external view returns (uint256);

    function positionSide() external view returns (LibTypes.Side);

    function positionEntryValue() external view returns (uint256);

    function positionEntrySocialLoss() external view returns (int256);

    function positionEntryFundingLoss() external view returns (int256);

    // function isEmergency() external view returns (bool);

    // function isGlobalSettled() external view returns (bool);

    function status() external view returns (LibTypes.Status);

    function socialLossPerContract(LibTypes.Side side) external view returns (int256);

    function transferBalanceIn(address from, uint256 amount) external;

    function transferBalanceOut(address to, uint256 amount) external;

    function transferBalanceTo(address from, address to, uint256 amount) external;

    function trade(address guy, LibTypes.Side side, uint256 price, uint256 amount) external returns (uint256);

    function setBrokerFor(address guy, address broker) external;

    function depositFor(address guy, uint256 amount) external;

    function depositEtherFor(address guy) external payable;

    function withdrawFor(address payable guy, uint256 amount) external;

    function isSafe(address guy) external returns (bool);

    function isSafeWithPrice(address guy, uint256 currentMarkPrice) external returns (bool);

    function isProxySafe() external returns (bool);

    function isProxySafeWithPrice(uint256 currentMarkPrice) external returns (bool);

    function isIMSafe(address guy) external returns (bool);

    function isIMSafeWithPrice(address guy, uint256 currentMarkPrice) external returns (bool);

    function lotSize() external view returns (uint256);

    function tradingLotSize() external view returns (uint256);
}

interface IAMM {
    function shareTokenAddress() external view returns (address);

    function lastFundingState() external view returns (LibTypes.FundingState memory);

    function getGovernance() external view returns (LibTypes.AMMGovernanceConfig memory);

    function perpetualProxy() external view returns (IPerpetualProxy);

    function currentMarkPrice() external returns (uint256);

    function currentAvailableMargin() external returns (uint256);

    function currentFairPrice() external returns (uint256);

    function positionSize() external returns (uint256);

    function currentAccumulatedFundingPerContract() external returns (int256);

    function settleShare(uint256 shareAmount) external;

    function buy(uint256 amount, uint256 limitPrice, uint256 deadline) external returns (uint256);

    function sell(uint256 amount, uint256 limitPrice, uint256 deadline) external returns (uint256);

    function buyFromWhitelisted(address trader, uint256 amount, uint256 limitPrice, uint256 deadline)
        external
        returns (uint256);

    function sellFromWhitelisted(address trader, uint256 amount, uint256 limitPrice, uint256 deadline)
        external
        returns (uint256);

    function buyFrom(address trader, uint256 amount, uint256 limitPrice, uint256 deadline) external returns (uint256);

    function sellFrom(address trader, uint256 amount, uint256 limitPrice, uint256 deadline) external returns (uint256);
}

interface IGlobalConfig {
    function withdrawalLockBlockCount() external view returns (uint256);

    function brokerLockBlockCount() external view returns (uint256);
}

contract PerpetualGovernance is WhitelistedRole {
    using LibMathSigned for int256;
    using LibMathUnsigned for uint256;

    IGlobalConfig public globalConfig;
    IAMM public amm;
    address public devAddress;

    LibTypes.Status public status;
    uint256 public settlementPrice;
    LibTypes.PerpGovernanceConfig internal governance;
    int256[3] internal socialLossPerContracts;

    event BeginGlobalSettlement(uint256 price);
    event UpdateGovernanceParameter(bytes32 indexed key, int256 value);
    event UpdateGovernanceAddress(bytes32 indexed key, address value);

    modifier ammRequired() {
        require(address(amm) != address(0x0), "no automated market maker");
        _;
    }

    function getGovernance() public view returns (LibTypes.PerpGovernanceConfig memory) {
        return governance;
    }

    function setGovernanceParameter(bytes32 key, int256 value) public onlyWhitelistAdmin {
        if (key == "initialMarginRate") {
            governance.initialMarginRate = value.toUint256();
            require(governance.initialMarginRate > 0, "require im > 0");
            require(governance.initialMarginRate < 10**18, "require im < 1");
            require(governance.maintenanceMarginRate < governance.initialMarginRate, "require mm < im");
        } else if (key == "maintenanceMarginRate") {
            governance.maintenanceMarginRate = value.toUint256();
            require(governance.maintenanceMarginRate > 0, "require mm > 0");
            require(governance.maintenanceMarginRate < governance.initialMarginRate, "require mm < im");
            require(governance.liquidationPenaltyRate < governance.maintenanceMarginRate, "require lpr < mm");
            require(governance.penaltyFundRate < governance.maintenanceMarginRate, "require pfr < mm");
        } else if (key == "liquidationPenaltyRate") {
            governance.liquidationPenaltyRate = value.toUint256();
            require(governance.liquidationPenaltyRate < governance.maintenanceMarginRate, "require lpr < mm");
        } else if (key == "penaltyFundRate") {
            governance.penaltyFundRate = value.toUint256();
            require(governance.penaltyFundRate < governance.maintenanceMarginRate, "require pfr < mm");
        } else if (key == "takerDevFeeRate") {
            governance.takerDevFeeRate = value;
        } else if (key == "makerDevFeeRate") {
            governance.makerDevFeeRate = value;
        } else if (key == "lotSize") {
            require(
                governance.tradingLotSize == 0 || governance.tradingLotSize.mod(value.toUint256()) == 0,
                "require tls % ls == 0"
            );
            governance.lotSize = value.toUint256();
        } else if (key == "tradingLotSize") {
            require(governance.lotSize == 0 || value.toUint256().mod(governance.lotSize) == 0, "require tls % ls == 0");
            governance.tradingLotSize = value.toUint256();
        } else if (key == "longSocialLossPerContracts") {
            require(status == LibTypes.Status.SETTLING, "wrong perpetual status");
            socialLossPerContracts[uint256(LibTypes.Side.LONG)] = value;
        } else if (key == "shortSocialLossPerContracts") {
            require(status == LibTypes.Status.SETTLING, "wrong perpetual status");
            socialLossPerContracts[uint256(LibTypes.Side.SHORT)] = value;
        } else {
            revert("key not exists");
        }
        emit UpdateGovernanceParameter(key, value);
    }

    function setGovernanceAddress(bytes32 key, address value) public onlyWhitelistAdmin {
        require(value != address(0x0), "invalid address");
        if (key == "dev") {
            devAddress = value;
        } else if (key == "amm") {
            amm = IAMM(value);
        } else if (key == "globalConfig") {
            globalConfig = IGlobalConfig(value);
        } else {
            revert("key not exists");
        }
        emit UpdateGovernanceAddress(key, value);
    }

    function beginGlobalSettlement(uint256 price) public onlyWhitelistAdmin {
        require(status != LibTypes.Status.SETTLED, "already settled");
        settlementPrice = price;
        status = LibTypes.Status.SETTLING;
        emit BeginGlobalSettlement(price);
    }
}

contract Position is Collateral, PerpetualGovernance {
    using LibMathSigned for int256;
    using LibMathUnsigned for uint256;
    using LibTypes for LibTypes.Side;

    int256 public insuranceFundBalance;
    uint256[3] internal totalSizes;
    mapping(address => LibTypes.PositionAccount) internal positions;

    event SocialLoss(LibTypes.Side side, int256 newVal);
    event UpdatePositionAccount(
        address indexed guy,
        LibTypes.PositionAccount account,
        uint256 perpetualTotalSize,
        uint256 price
    );
    event UpdateInsuranceFund(int256 newVal);

    constructor(address collateral, uint256 collateralDecimals) public Collateral(collateral, collateralDecimals) {}

    // Public functions
    function socialLossPerContract(LibTypes.Side side) public view returns (int256) {
        return socialLossPerContracts[uint256(side)];
    }

    function totalSize(LibTypes.Side side) public view returns (uint256) {
        return totalSizes[uint256(side)];
    }

    function getPosition(address guy) public view returns (LibTypes.PositionAccount memory) {
        return positions[guy];
    }

    function calculateLiquidateAmount(address guy, uint256 liquidationPrice) public returns (uint256) {
        if (positions[guy].size == 0) {
            return 0;
        }
        LibTypes.PositionAccount memory account = positions[guy];
        int256 liquidationAmount = cashBalances[guy].balance.add(account.entrySocialLoss);
        liquidationAmount = liquidationAmount.sub(marginWithPrice(guy, liquidationPrice).toInt256()).sub(
            socialLossPerContract(account.side).wmul(account.size.toInt256())
        );
        int256 tmp = account
            .entryValue
            .toInt256()
            .sub(account.entryFundingLoss)
            .add(amm.currentAccumulatedFundingPerContract().wmul(account.size.toInt256()))
            .sub(account.size.wmul(liquidationPrice).toInt256());
        if (account.side == LibTypes.Side.LONG) {
            liquidationAmount = liquidationAmount.sub(tmp);
        } else if (account.side == LibTypes.Side.SHORT) {
            liquidationAmount = liquidationAmount.add(tmp);
        } else {
            return 0;
        }
        int256 denominator = governance
            .liquidationPenaltyRate
            .add(governance.penaltyFundRate)
            .toInt256()
            .sub(governance.initialMarginRate.toInt256())
            .wmul(liquidationPrice.toInt256());
        liquidationAmount = liquidationAmount.wdiv(denominator);
        liquidationAmount = liquidationAmount.max(0);
        liquidationAmount = liquidationAmount.min(account.size.toInt256());
        return liquidationAmount.toUint256();
    }

    // Internal functions
    function addSocialLossPerContract(LibTypes.Side side, int256 amount) internal {
        require(amount >= 0, "negtive social loss");
        int256 newVal = socialLossPerContracts[uint256(side)].add(amount);
        socialLossPerContracts[uint256(side)] = newVal;
        emit SocialLoss(side, newVal);
    }
    function marginBalanceWithPrice(address guy, uint256 markPrice) internal returns (int256) {
        return cashBalances[guy].balance.add(pnlWithPrice(guy, markPrice));
    }

    function availableMarginWithPrice(address guy, uint256 markPrice) internal returns (int256) {
        int256 p = marginBalanceWithPrice(guy, markPrice);
        p = p.sub(marginWithPrice(guy, markPrice).toInt256());
        p = p.sub(cashBalances[guy].appliedBalance);
        return p;
    }

    function marginWithPrice(address guy, uint256 markPrice) internal view returns (uint256) {
        return positions[guy].size.wmul(markPrice).wmul(governance.initialMarginRate);
    }

    function maintenanceMarginWithPrice(address guy, uint256 markPrice) internal view returns (uint256) {
        return positions[guy].size.wmul(markPrice).wmul(governance.maintenanceMarginRate);
    }

    function drawableBalanceWithPrice(address guy, uint256 markPrice) internal returns (int256) {
        return
            marginBalanceWithPrice(guy, markPrice).sub(marginWithPrice(guy, markPrice).toInt256()).min(
                cashBalances[guy].appliedBalance
            );
    }

    function pnlWithPrice(address guy, uint256 markPrice) internal returns (int256) {
        LibTypes.PositionAccount memory account = positions[guy];
        return calculatePnl(account, markPrice, account.size);
    }

    // Internal functions
    function increaseTotalSize(LibTypes.Side side, uint256 amount) internal {
        totalSizes[uint256(side)] = totalSizes[uint256(side)].add(amount);
    }

    function decreaseTotalSize(LibTypes.Side side, uint256 amount) internal {
        totalSizes[uint256(side)] = totalSizes[uint256(side)].sub(amount);
    }

    function socialLoss(LibTypes.PositionAccount memory account) internal view returns (int256) {
        return socialLossWithAmount(account, account.size);
    }

    function socialLossWithAmount(LibTypes.PositionAccount memory account, uint256 amount)
        internal
        view
        returns (int256)
    {
        int256 loss = socialLossPerContract(account.side).wmul(amount.toInt256());
        if (amount == account.size) {
            loss = loss.sub(account.entrySocialLoss);
        } else {
            // loss = loss.sub(account.entrySocialLoss.wmul(amount).wdiv(account.size));
            loss = loss.sub(account.entrySocialLoss.wfrac(amount.toInt256(), account.size.toInt256()));
            // prec error
            if (loss != 0) {
                loss = loss.add(1);
            }
        }
        return loss;
    }

    function fundingLoss(LibTypes.PositionAccount memory account) internal returns (int256) {
        return fundingLossWithAmount(account, account.size);
    }

    function fundingLossWithAmount(LibTypes.PositionAccount memory account, uint256 amount) internal returns (int256) {
        int256 loss = amm.currentAccumulatedFundingPerContract().wmul(amount.toInt256());
        if (amount == account.size) {
            loss = loss.sub(account.entryFundingLoss);
        } else {
            // loss = loss.sub(account.entryFundingLoss.wmul(amount.toInt256()).wdiv(account.size.toInt256()));
            loss = loss.sub(account.entryFundingLoss.wfrac(amount.toInt256(), account.size.toInt256()));
        }
        if (account.side == LibTypes.Side.SHORT) {
            loss = loss.neg();
        }
        if (loss != 0 && amount != account.size) {
            loss = loss.add(1);
        }
        return loss;
    }

    function remargin(address guy, uint256 markPrice) internal {
        LibTypes.PositionAccount storage account = positions[guy];
        if (account.size == 0) {
            return;
        }
        int256 rpnl = calculatePnl(account, markPrice, account.size);
        account.entryValue = markPrice.wmul(account.size);
        account.entrySocialLoss = socialLossPerContract(account.side).wmul(account.size.toInt256());
        account.entryFundingLoss = amm.currentAccumulatedFundingPerContract().wmul(account.size.toInt256());
        updateBalance(guy, rpnl);
        emit UpdatePositionAccount(guy, account, totalSize(LibTypes.Side.LONG), markPrice);
    }

    function calculatePnl(LibTypes.PositionAccount memory account, uint256 tradePrice, uint256 amount)
        internal
        returns (int256)
    {
        if (account.size == 0) {
            return 0;
        }
        int256 p1 = tradePrice.wmul(amount).toInt256();
        int256 p2;
        if (amount == account.size) {
            p2 = account.entryValue.toInt256();
        } else {
            // p2 = account.entryValue.wmul(amount).wdiv(account.size).toInt256();
            p2 = account.entryValue.wfrac(amount, account.size).toInt256();
        }
        int256 profit = account.side == LibTypes.Side.LONG ? p1.sub(p2) : p2.sub(p1);
        // prec error
        if (profit != 0) {
            profit = profit.sub(1);
        }
        int256 loss1 = socialLossWithAmount(account, amount);
        int256 loss2 = fundingLossWithAmount(account, amount);
        return profit.sub(loss1).sub(loss2);
    }

    function open(LibTypes.PositionAccount memory account, LibTypes.Side side, uint256 price, uint256 amount) internal {
        require(amount > 0, "open: invald amount");
        if (account.size == 0) {
            account.side = side;
        }
        account.size = account.size.add(amount);
        account.entryValue = account.entryValue.add(price.wmul(amount));
        account.entrySocialLoss = account.entrySocialLoss.add(socialLossPerContract(side).wmul(amount.toInt256()));
        account.entryFundingLoss = account.entryFundingLoss.add(
            amm.currentAccumulatedFundingPerContract().wmul(amount.toInt256())
        );
        increaseTotalSize(side, amount);
    }

    function close(LibTypes.PositionAccount memory account, uint256 price, uint256 amount) internal returns (int256) {
        int256 rpnl = calculatePnl(account, price, amount);
        account.entrySocialLoss = account.entrySocialLoss.wmul(account.size.sub(amount).toInt256()).wdiv(
            account.size.toInt256()
        );
        account.entryFundingLoss = account.entryFundingLoss.wmul(account.size.sub(amount).toInt256()).wdiv(
            account.size.toInt256()
        );
        account.entryValue = account.entryValue.wmul(account.size.sub(amount)).wdiv(account.size);
        account.size = account.size.sub(amount);
        decreaseTotalSize(account.side, amount);
        if (account.size == 0) {
            account.side = LibTypes.Side.FLAT;
        }
        return rpnl;
    }

    function trade(address guy, LibTypes.Side side, uint256 price, uint256 amount) internal returns (uint256) {
        int256 rpnl;
        uint256 opened = amount;
        uint256 closed;
        LibTypes.PositionAccount memory account = positions[guy];
        if (account.size > 0 && account.side != side) {
            closed = account.size.min(opened);
            rpnl = close(account, price, closed);
            opened = opened.sub(closed);
        }
        if (opened > 0) {
            open(account, side, price, opened);
        }
        updateBalance(guy, rpnl);
        positions[guy] = account;
        emit UpdatePositionAccount(guy, account, totalSize(LibTypes.Side.LONG), price);
        return opened;
    }

    function handleSocialLoss(LibTypes.Side side, int256 loss) internal {
        int256 newSocialLoss = loss.wdiv(totalSize(side).toInt256());
        addSocialLossPerContract(side, newSocialLoss);
    }

    function liquidate(address liquidator, address guy, uint256 liquidationPrice, uint256 liquidationAmount)
        internal
        returns (uint256)
    {
        // liquidiated trader
        LibTypes.PositionAccount memory account = positions[guy];
        LibTypes.Side liquidationSide = account.side;
        uint256 liquidationValue = liquidationPrice.wmul(liquidationAmount);
        int256 penaltyToLiquidator = governance.liquidationPenaltyRate.wmul(liquidationValue).toInt256();
        int256 penaltyToFund = governance.penaltyFundRate.wmul(liquidationValue).toInt256();
        int256 rpnl = close(account, liquidationPrice, liquidationAmount);
        positions[guy] = account;
        emit UpdatePositionAccount(guy, account, totalSize(LibTypes.Side.LONG), liquidationPrice);

        rpnl = rpnl.sub(penaltyToLiquidator).sub(penaltyToFund);
        updateBalance(guy, rpnl);
        int256 liquidationLoss = ensurePositiveBalance(guy).toInt256();

        // liquidator, penalty + poisition
        updateBalance(liquidator, penaltyToLiquidator);
        uint256 opened = trade(liquidator, liquidationSide, liquidationPrice, liquidationAmount);

        // fund, fund penalty - possible social loss
        insuranceFundBalance = insuranceFundBalance.add(penaltyToFund);
        if (insuranceFundBalance >= liquidationLoss) {
            insuranceFundBalance = insuranceFundBalance.sub(liquidationLoss);
        } else {
            int256 newSocialLoss = liquidationLoss.sub(insuranceFundBalance);
            insuranceFundBalance = 0;
            handleSocialLoss(liquidationSide, newSocialLoss);
        }
        require(insuranceFundBalance >= 0, "negtive insurance fund");

        emit UpdateInsuranceFund(insuranceFundBalance);
        return opened;
    }
}

contract Brokerage {
    using LibMathUnsigned for uint256;

    event BrokerUpdate(address indexed account, address indexed guy, uint256 appliedHeight);

    mapping(address => LibTypes.Broker) public brokers;

    // delay set: set the newBroker after n blocks (including the current block)
    // rules:
    // 1. new user => set immediately
    // 2. last broker change is waiting for delay => overwrite the delayed broker and timer
    // 3. last broker change has taken effect
    // 3.1 newBroker is the same => ignore
    // 3.2 newBroker is changing => push the current broker, set the delayed broker and timer
    //
    // delay: during this n blocks (including setBroker() itself), current broker does not change
    function setBroker(address trader, address newBroker, uint256 delay) internal {
        require(trader != address(0), "invalid trader");
        require(newBroker != address(0), "invalid guy");
        LibTypes.Broker memory broker = brokers[trader];
        if (broker.current.appliedHeight == 0) {
            // condition 1
            broker.current.broker = newBroker;
            broker.current.appliedHeight = block.number;
        } else {
            bool isPreviousChangeApplied = block.number >= broker.current.appliedHeight;
            if (isPreviousChangeApplied) {
                if (broker.current.broker == newBroker) {
                    // condition 3.1
                    return;
                } else {
                    // condition 3.2
                    broker.previous.broker = broker.current.broker;
                    broker.previous.appliedHeight = broker.current.appliedHeight;
                }
            }
            // condition 2, 3.2
            broker.current.broker = newBroker;
            broker.current.appliedHeight = block.number.add(delay);
        }
        // condition 1, 2, 3.2
        brokers[trader] = broker;
        emit BrokerUpdate(trader, newBroker, broker.current.appliedHeight);
    }

    // note: do NOT call this function in a non-transaction request, unless you do not care about the broker appliedHeight.
    // because in a call(), block.number is the on-chain height, and it will be 1 more in a transaction
    function currentBroker(address trader) public view returns (address) {
        LibTypes.Broker storage broker = brokers[trader];
        return block.number >= broker.current.appliedHeight ? broker.current.broker : broker.previous.broker;
    }

    function getBroker(address trader) public view returns (LibTypes.Broker memory) {
        return brokers[trader];
    }
}

interface IPriceFeeder {
    function price() external view returns (uint256 lastPrice, uint256 lastTimestamp);
}

contract Perpetual is Brokerage, Position {
    using LibMathSigned for int256;
    using LibMathUnsigned for uint256;
    using LibOrder for LibTypes.Side;
    using SafeERC20 for IERC20;
    uint256 public totalAccounts;
    address[] public accountList;
    mapping(address => bool) private accountCreated;

    event CreatePerpetual();
    event CreateAccount(uint256 indexed id, address indexed guy);
    event Buy(address indexed guy, uint256 price, uint256 amount);
    event Sell(address indexed guy, uint256 price, uint256 amount);
    event Liquidate(address indexed keeper, address indexed guy, uint256 price, uint256 amount);
    event EndGlobalSettlement();

    constructor(address globalConfig, address devAddress, address collateral, uint256 collateralDecimals)
        public
        Position(collateral, collateralDecimals)
    {
        setGovernanceAddress("globalConfig", globalConfig);
        setGovernanceAddress("dev", devAddress);
        emit CreatePerpetual();
    }

    // Admin functions
    function setCashBalance(address guy, int256 amount) public onlyWhitelistAdmin {
        require(status == LibTypes.Status.SETTLING, "wrong perpetual status");
        int256 deltaAmount = amount.sub(cashBalances[guy].balance);
        cashBalances[guy].balance = amount;
        emit InternalUpdateBalance(guy, deltaAmount, amount);
    }

    // Public functions
    function() external payable {
        revert("no payable");
    }

    function markPrice() public ammRequired returns (uint256) {
        return status == LibTypes.Status.NORMAL ? amm.currentMarkPrice() : settlementPrice;
    }

    function setBroker(address broker) public {
        setBroker(msg.sender, broker, globalConfig.brokerLockBlockCount());
    }

    function setBrokerFor(address guy, address broker) public onlyWhitelisted {
        setBroker(guy, broker, globalConfig.brokerLockBlockCount());
    }

    function depositToAccount(address guy, uint256 amount) private {
        require(guy != address(0), "invalid guy");
        deposit(guy, amount);

        // append to the account list. make the account trackable
        if (!accountCreated[guy]) {
            emit CreateAccount(totalAccounts, guy);
            accountList.push(guy);
            totalAccounts++;
            accountCreated[guy] = true;
        }
    }

    function depositFor(address guy, uint256 amount) public onlyWhitelisted {
        require(isTokenizedCollateral(), "ether not acceptable");

        depositToAccount(guy, amount);
    }

    function depositEtherFor(address guy) public payable onlyWhitelisted {
        require(!isTokenizedCollateral(), "token not acceptable");

        depositToAccount(guy, msg.value);
    }

    function deposit(uint256 amount) public {
        require(isTokenizedCollateral(), "ether not acceptable");

        depositToAccount(msg.sender, amount);
    }

    function depositEther() public payable {
        require(!isTokenizedCollateral(), "token not acceptable");

        depositToAccount(msg.sender, msg.value);
    }

    // this is a composite function of perp.deposit + perp.setBroker
    // composite functions accept amount = 0
    function depositAndSetBroker(uint256 amount, address broker) public {
        setBroker(broker);
        if (amount > 0) {
            deposit(amount);
        }
    }

    // this is a composite function of perp.deposit + perp.setBroker
    // composite functions accept amount = 0
    function depositEtherAndSetBroker(address broker) public payable {
        setBroker(broker);
        if (msg.value > 0) {
            depositEther();
        }
    }

    function applyForWithdrawal(uint256 amount) public {
        applyForWithdrawal(msg.sender, amount, globalConfig.withdrawalLockBlockCount());
    }

    function settleFor(address guy) private {
        uint256 currentMarkPrice = markPrice();
        LibTypes.PositionAccount memory account = positions[guy];
        if (account.size > 0) {
            int256 pnl = close(account, currentMarkPrice, account.size);
            updateBalance(guy, pnl);
            positions[guy] = account;
        }
        emit UpdatePositionAccount(guy, account, totalSize(LibTypes.Side.LONG), currentMarkPrice);
    }

    function settle() public {
        require(status == LibTypes.Status.SETTLED, "wrong perpetual status");

        address payable guy = msg.sender;
        settleFor(guy);
        withdrawAll(guy);
    }

    function endGlobalSettlement() public onlyWhitelistAdmin {
        require(status == LibTypes.Status.SETTLING, "wrong perpetual status");

        address guy = address(amm.perpetualProxy());
        settleFor(guy);
        status = LibTypes.Status.SETTLED;

        emit EndGlobalSettlement();
    }

    function withdrawFromAccount(address payable guy, uint256 amount) private {
        require(guy != address(0), "invalid guy");
        require(status != LibTypes.Status.SETTLING, "wrong perpetual status");

        uint256 currentMarkPrice = markPrice();
        require(isSafeWithPrice(guy, currentMarkPrice), "unsafe before withdraw");
        remargin(guy, currentMarkPrice);
        address broker = currentBroker(guy);
        bool forced = broker == address(amm.perpetualProxy()) || broker == address(0);
        withdraw(guy, amount, forced);

        require(isSafeWithPrice(guy, currentMarkPrice), "unsafe after withdraw");
        require(availableMarginWithPrice(guy, currentMarkPrice) >= 0, "withdraw margin");
    }

    function withdrawFor(address payable guy, uint256 amount) public onlyWhitelisted {
        require(status == LibTypes.Status.NORMAL, "wrong perpetual status");
        withdrawFromAccount(guy, amount);
    }

    function withdraw(uint256 amount) public {
        withdrawFromAccount(msg.sender, amount);
    }

    function depositToInsuranceFund(uint256 rawAmount) public {
        require(isTokenizedCollateral(), "ether not acceptable");
        require(rawAmount > 0, "invalid amount");

        int256 wadAmount = depositToProtocol(msg.sender, rawAmount);
        insuranceFundBalance = insuranceFundBalance.add(wadAmount);

        require(insuranceFundBalance >= 0, "negtive insurance fund");

        emit UpdateInsuranceFund(insuranceFundBalance);
    }

    function depositEtherToInsuranceFund() public payable {
        require(!isTokenizedCollateral(), "token not acceptable");
        require(msg.value > 0, "invalid amount");

        int256 wadAmount = depositToProtocol(msg.sender, msg.value);
        insuranceFundBalance = insuranceFundBalance.add(wadAmount);

        require(insuranceFundBalance >= 0, "negtive insurance fund");

        emit UpdateInsuranceFund(insuranceFundBalance);
    }

    function withdrawFromInsuranceFund(uint256 rawAmount) public onlyWhitelistAdmin {
        require(rawAmount > 0, "invalid amount");
        require(insuranceFundBalance > 0, "insufficient funds");
        require(rawAmount.toInt256() <= insuranceFundBalance, "insufficient funds");

        int256 wadAmount = withdrawFromProtocol(msg.sender, rawAmount);
        insuranceFundBalance = insuranceFundBalance.sub(wadAmount);

        require(insuranceFundBalance >= 0, "negtive insurance fund");

        emit UpdateInsuranceFund(insuranceFundBalance);
    }

    function positionMargin(address guy) public returns (uint256) {
        return Position.marginWithPrice(guy, markPrice());
    }

    function maintenanceMargin(address guy) public returns (uint256) {
        return maintenanceMarginWithPrice(guy, markPrice());
    }

    function marginBalance(address guy) public returns (int256) {
        return marginBalanceWithPrice(guy, markPrice());
    }

    function pnl(address guy) public returns (int256) {
        return pnlWithPrice(guy, markPrice());
    }

    function availableMargin(address guy) public returns (int256) {
        return availableMarginWithPrice(guy, markPrice());
    }

    function drawableBalance(address guy) public returns (int256) {
        return drawableBalanceWithPrice(guy, markPrice());
    }

    // safe for liquidation
    function isSafe(address guy) public returns (bool) {
        uint256 currentMarkPrice = markPrice();
        return isSafeWithPrice(guy, currentMarkPrice);
    }

    // safe for liquidation
    function isSafeWithPrice(address guy, uint256 currentMarkPrice) public returns (bool) {
        return
            marginBalanceWithPrice(guy, currentMarkPrice) >=
            maintenanceMarginWithPrice(guy, currentMarkPrice).toInt256();
    }

    function isBankrupt(address guy) public returns (bool) {
        return marginBalanceWithPrice(guy, markPrice()) < 0;
    }

    // safe for opening positions
    function isIMSafe(address guy) public returns (bool) {
        uint256 currentMarkPrice = markPrice();
        return isIMSafeWithPrice(guy, currentMarkPrice);
    }

    // safe for opening positions
    function isIMSafeWithPrice(address guy, uint256 currentMarkPrice) public returns (bool) {
        return availableMarginWithPrice(guy, currentMarkPrice) >= 0;
    }

    function liquidateFrom(address from, address guy, uint256 maxAmount) public returns (uint256, uint256) {
        require(maxAmount.mod(governance.lotSize) == 0, "invalid lot size");
        require(!isSafe(guy), "safe account");

        uint256 liquidationPrice = markPrice();
        uint256 liquidationAmount = calculateLiquidateAmount(guy, liquidationPrice);
        uint256 totalPositionSize = positions[guy].size;
        uint256 liquidatableAmount = totalPositionSize.sub(totalPositionSize.mod(governance.lotSize));
        liquidationAmount = liquidationAmount.ceil(governance.lotSize).min(maxAmount).min(liquidatableAmount);
        require(liquidationAmount > 0, "nothing to liquidate");

        uint256 opened = liquidate(from, guy, liquidationPrice, liquidationAmount);
        if (opened > 0) {
            require(availableMarginWithPrice(from, liquidationPrice) >= 0, "liquidator margin");
        } else {
            require(isSafe(from), "liquidator unsafe");
        }

        emit Liquidate(from, guy, liquidationPrice, liquidationAmount);
    }

    function liquidate(address guy, uint256 maxAmount) public returns (uint256, uint256) {
        require(status != LibTypes.Status.SETTLED, "wrong perpetual status");
        return liquidateFrom(msg.sender, guy, maxAmount);
    }

    function tradePosition(address trader, LibTypes.Side side, uint256 price, uint256 amount)
        public
        onlyWhitelisted
        returns (uint256)
    {
        require(status != LibTypes.Status.SETTLING, "wrong perpetual status");
        require(side == LibTypes.Side.LONG || side == LibTypes.Side.SHORT, "invalid side");

        uint256 opened = Position.trade(trader, side, price, amount);
        if (side == LibTypes.Side.LONG) {
            emit Buy(trader, price, amount);
        } else if (side == LibTypes.Side.SHORT) {
            emit Sell(trader, price, amount);
        }
        return opened;
    }

    function transferCashBalance(address from, address to, uint256 amount) public onlyWhitelisted {
        require(status != LibTypes.Status.SETTLING, "wrong perpetual status");
        transferBalance(from, to, amount.toInt256());
    }
}
