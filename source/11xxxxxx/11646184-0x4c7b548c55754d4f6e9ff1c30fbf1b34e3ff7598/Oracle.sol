pragma experimental ABIEncoderV2;
// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol
pragma solidity >=0.5.0;
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol
pragma solidity >=0.5.0;
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}
// File: @uniswap/lib/contracts/libraries/Babylonian.sol
pragma solidity >=0.4.0;
// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}
// File: @uniswap/lib/contracts/libraries/FixedPoint.sol
pragma solidity >=0.4.0;
// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }
    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint _x;
    }
    uint8 private constant RESOLUTION = 112;
    uint private constant Q112 = uint(1) << RESOLUTION;
    uint private constant Q224 = Q112 << RESOLUTION;
    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }
    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }
    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }
    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }
    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }
    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }
    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }
    // take the reciprocal of a UQ112x112
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, 'FixedPoint: ZERO_RECIPROCAL');
        return uq112x112(uint224(Q224 / self._x));
    }
    // square root of a UQ112x112
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x)) << 56));
    }
}
// File: contracts/external/UniswapV2OracleLibrary.sol
pragma solidity >=0.5.0;
// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;
    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }
    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(address pair)
    internal
    view
    returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();
        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}
// File: @openzeppelin/contracts/math/SafeMath.sol
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
// File: contracts/external/UniswapV2Library.sol
pragma solidity >=0.5.0;
library UniswapV2Library {
    using SafeMath for uint;
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }
    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }
    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }
}
// File: contracts/external/Require.sol
/*
    Copyright 2019 dYdX Trading Inc.
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
 * @title Require
 * @author dYdX
 *
 * Stringifies parameters to pretty-print revert messages. Costs more gas than regular require()
 */
library Require {
    // ============ Constants ============
    uint256 constant ASCII_ZERO = 48; // '0'
    uint256 constant ASCII_RELATIVE_ZERO = 87; // 'a' - 10
    uint256 constant ASCII_LOWER_EX = 120; // 'x'
    bytes2 constant COLON = 0x3a20; // ': '
    bytes2 constant COMMA = 0x2c20; // ', '
    bytes2 constant LPAREN = 0x203c; // ' <'
    byte constant RPAREN = 0x3e; // '>'
    uint256 constant FOUR_BIT_MASK = 0xf;
    // ============ Library Functions ============
    function that(
        bool must,
        bytes32 file,
        bytes32 reason
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason)
                    )
                )
            );
        }
    }
    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
                    )
                )
            );
        }
    }
    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA,
        uint256 payloadB
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        RPAREN
                    )
                )
            );
        }
    }
    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
                    )
                )
            );
        }
    }
    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        RPAREN
                    )
                )
            );
        }
    }
    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB,
        uint256 payloadC
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        COMMA,
                        stringify(payloadC),
                        RPAREN
                    )
                )
            );
        }
    }
    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        bytes32 payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
                    )
                )
            );
        }
    }
    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        bytes32 payloadA,
        uint256 payloadB,
        uint256 payloadC
    )
    internal
    pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        COMMA,
                        stringify(payloadC),
                        RPAREN
                    )
                )
            );
        }
    }
    // ============ Private Functions ============
    function stringifyTruncated(
        bytes32 input
    )
    private
    pure
    returns (bytes memory)
    {
        // put the input bytes into the result
        bytes memory result = abi.encodePacked(input);
        // determine the length of the input by finding the location of the last non-zero byte
        for (uint256 i = 32; i > 0; ) {
            // reverse-for-loops with unsigned integer
            /* solium-disable-next-line security/no-modify-for-iter-var */
            i--;
            // find the last non-zero byte in order to determine the length
            if (result[i] != 0) {
                uint256 length = i + 1;
                /* solium-disable-next-line security/no-inline-assembly */
                assembly {
                    mstore(result, length) // r.length = length;
                }
                return result;
            }
        }
        // all bytes are zero
        return new bytes(0);
    }
    function stringify(
        uint256 input
    )
    private
    pure
    returns (bytes memory)
    {
        if (input == 0) {
            return "0";
        }
        // get the final string length
        uint256 j = input;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        // allocate the string
        bytes memory bstr = new bytes(length);
        // populate the string starting with the least-significant character
        j = input;
        for (uint256 i = length; i > 0; ) {
            // reverse-for-loops with unsigned integer
            /* solium-disable-next-line security/no-modify-for-iter-var */
            i--;
            // take last decimal digit
            bstr[i] = byte(uint8(ASCII_ZERO + (j % 10)));
            // remove the last decimal digit
            j /= 10;
        }
        return bstr;
    }
    function stringify(
        address input
    )
    private
    pure
    returns (bytes memory)
    {
        uint256 z = uint256(input);
        // addresses are "0x" followed by 20 bytes of data which take up 2 characters each
        bytes memory result = new bytes(42);
        // populate the result with "0x"
        result[0] = byte(uint8(ASCII_ZERO));
        result[1] = byte(uint8(ASCII_LOWER_EX));
        // for each byte (starting from the lowest byte), populate the result with two characters
        for (uint256 i = 0; i < 20; i++) {
            // each byte takes two characters
            uint256 shift = i * 2;
            // populate the least-significant character
            result[41 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;
            // populate the most-significant character
            result[40 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;
        }
        return result;
    }
    function stringify(
        bytes32 input
    )
    private
    pure
    returns (bytes memory)
    {
        uint256 z = uint256(input);
        // bytes32 are "0x" followed by 32 bytes of data which take up 2 characters each
        bytes memory result = new bytes(66);
        // populate the result with "0x"
        result[0] = byte(uint8(ASCII_ZERO));
        result[1] = byte(uint8(ASCII_LOWER_EX));
        // for each byte (starting from the lowest byte), populate the result with two characters
        for (uint256 i = 0; i < 32; i++) {
            // each byte takes two characters
            uint256 shift = i * 2;
            // populate the least-significant character
            result[65 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;
            // populate the most-significant character
            result[64 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;
        }
        return result;
    }
    function char(
        uint256 input
    )
    private
    pure
    returns (byte)
    {
        // return ASCII digit (0-9)
        if (input < 10) {
            return byte(uint8(input + ASCII_ZERO));
        }
        // return ASCII letter (a-f)
        return byte(uint8(input + ASCII_RELATIVE_ZERO));
    }
}
// File: contracts/external/Decimal.sol
/*
    Copyright 2019 dYdX Trading Inc.
    Copyright 2021 Empty Apple Dev <bigemptyapple@protonmail.com>
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
 * @title Decimal
 * @author dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    using SafeMath for uint256;
    // ============ Constants ============
    uint256 constant BASE = 10**18;
    // ============ Structs ============
    struct D256 {
        uint256 value;
    }
    // ============ Static Functions ============
    function zero()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: 0 });
    }
    function one()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: BASE });
    }
    function from(
        uint256 a
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: a.mul(BASE) });
    }
    function ratio(
        uint256 a,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(a, BASE, b) });
    }
    // ============ Self Functions ============
    function add(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.add(b.mul(BASE)) });
    }
    function sub(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.mul(BASE)) });
    }
    function sub(
        D256 memory self,
        uint256 b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.mul(BASE), reason) });
    }
    function mul(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.mul(b) });
    }
    function div(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.div(b) });
    }
    function pow(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        if (b == 0) {
            return from(1);
        }
        D256 memory temp = D256({ value: self.value });
        for (uint256 i = 1; i < b; i++) {
            temp = mul(temp, self);
        }
        return temp;
    }
    function add(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.add(b.value) });
    }
    function sub(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.value) });
    }
    function sub(
        D256 memory self,
        D256 memory b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.value, reason) });
    }
    function mul(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, b.value, BASE) });
    }
    function div(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, BASE, b.value) });
    }
    function equals(D256 memory self, D256 memory b) internal pure returns (bool) {
        return self.value == b.value;
    }
    function greaterThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 2;
    }
    function lessThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 0;
    }
    function greaterThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) > 0;
    }
    function lessThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) < 2;
    }
    function isZero(D256 memory self) internal pure returns (bool) {
        return self.value == 0;
    }
    function asUint256(D256 memory self) internal pure returns (uint256) {
        return self.value.div(BASE);
    }
    // ============ Core Methods ============
    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
    private
    pure
    returns (uint256)
    {
        return target.mul(numerator).div(denominator);
    }
    function compareTo(
        D256 memory a,
        D256 memory b
    )
    private
    pure
    returns (uint256)
    {
        if (a.value == b.value) {
            return 1;
        }
        return a.value > b.value ? 2 : 0;
    }
}
// File: contracts/oracle/IOracle.sol
/*
    Copyright 2021 Empty Apple Dev <bigemptyapple@protonmail.com>
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
contract IOracle {
    function setup() public;
    function capture() public returns (Decimal.D256 memory, bool);
    function pair() external view returns (address);
}
// File: contracts/oracle/IUSDC.sol
/*
    Copyright 2021 Empty Apple Dev <bigemptyapple@protonmail.com>
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
contract IUSDC {
    function isBlacklisted(address _account) external view returns (bool);
}
// File: contracts/Constants.sol
/*
    Copyright 2021 Empty Apple Dev <bigemptyapple@protonmail.com>
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
library Constants {
    /* Chain */
    uint256 private constant CHAIN_ID = 1; // Mainnet
    /* Bootstrapping */
    uint256 private constant BOOTSTRAPPING_PERIOD = 48;
    uint256 private constant BOOTSTRAPPING_PRICE = 12e17; // 1.20 USDC
    uint256 private constant BOOTSTRAPPING_SPEEDUP_FACTOR = 2; // 8 days @ 4 hours
    // /* Oracle */ 
    address private constant USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address private constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    // address private constant USDC = address(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);
    // address private constant WETH = address(0xc778417E063141139Fce010982780140Aa0cD5Ab);
    uint256 private constant ORACLE_RESERVE_MINIMUM = 1e10; // 10,000 USDC
    /* Bonding */
    uint256 private constant INITIAL_STAKE_MULTIPLE = 1e6; // 100 BEA -> 100M BEAS
    /* Epoch */
    uint256 private constant EPOCH_PERIOD = 86400/3; // 1/3 day
    /* Governance */
    uint256 private constant GOVERNANCE_PERIOD = 9;
    uint256 private constant GOVERNANCE_QUORUM = 20e16; // 20%
    uint256 private constant GOVERNANCE_PROPOSAL_THRESHOLD = 5e15; // 0.5%
    uint256 private constant GOVERNANCE_SUPER_MAJORITY = 66e16; // 66%
    uint256 private constant GOVERNANCE_EMERGENCY_DELAY = 6; // 6 epochs
    /* DAO */
    uint256 private constant ADVANCE_INCENTIVE = 1e20; // 100 BEA
    uint256 private constant DAO_EXIT_LOCKUP_EPOCHS = 9; // 9 pochs fluid
    /* Pool */
    uint256 private constant POOL_EXIT_LOCKUP_EPOCHS = 3; // 3 epochs fluid
    /* Market */
    uint256 private constant COUPON_EXPIRATION = 48;
    uint256 private constant DEBT_RATIO_CAP = 35e16; // 35%
    /* Regulator */
    uint256 private constant SUPPLY_CHANGE_LIMIT = 2e17; // 20%
    uint256 private constant ORACLE_POOL_RATIO_BOOTSTRAPING = 15; // 15%
    uint256 private constant ORACLE_POOL_RATIO = 30; // 30%
    uint256 private constant COUPON_SUPPLY_CHANGE_LIMIT = 10e16; // 10%
    /**
     * Getters
     */
    function getUsdc() internal pure returns (address) {
        return USDC;
    }
    function getWeth() internal pure returns (address) {
        return WETH;
    }
    function getOracleReserveMinimum() internal pure returns (uint256) {
        return ORACLE_RESERVE_MINIMUM;
    }
    function getEpochPeriod() internal pure returns (uint256) {
        return EPOCH_PERIOD;
    }
    function getInitialStakeMultiple() internal pure returns (uint256) {
        return INITIAL_STAKE_MULTIPLE;
    }
    function getBootstrappingPeriod() internal pure returns (uint256) {
        return BOOTSTRAPPING_PERIOD;
    }
    function getBootstrappingPrice() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: BOOTSTRAPPING_PRICE});
    }
    function getBootstrappingSpeedupFactor() internal pure returns (uint256) {
        return BOOTSTRAPPING_SPEEDUP_FACTOR;
    }
    function getGovernancePeriod() internal pure returns (uint256) {
        return GOVERNANCE_PERIOD;
    }
    function getGovernanceQuorum() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_QUORUM});
    }
    function getAdvanceIncentive() internal pure returns (uint256) {
        return ADVANCE_INCENTIVE;
    }
    function getCouponExpiration() internal pure returns (uint256) {
        return COUPON_EXPIRATION;
    }
    function getSupplyChangeLimit() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: SUPPLY_CHANGE_LIMIT});
    }
    function getOraclePoolRatio() internal pure returns (uint256) {
        return ORACLE_POOL_RATIO;
    }
    function getOraclePoolRatioBoot() internal pure returns (uint256) {
        return ORACLE_POOL_RATIO_BOOTSTRAPING;
    }
    function getChainId() internal pure returns (uint256) {
        return CHAIN_ID;
    }
    function getDAOExitLockupEpochs() internal pure returns (uint256) {
        return DAO_EXIT_LOCKUP_EPOCHS;
    }
    function getPoolExitLockupEpochs() internal pure returns (uint256) {
        return POOL_EXIT_LOCKUP_EPOCHS;
    }
    function getGovernanceProposalThreshold() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_PROPOSAL_THRESHOLD});
    }
    function getGovernanceEmergencyDelay() internal pure returns (uint256) {
        return GOVERNANCE_EMERGENCY_DELAY;
    }
    function getGovernanceSuperMajority() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_SUPER_MAJORITY});
    }
    function getDebtRatioCap() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: DEBT_RATIO_CAP});
    }
    function getCouponSupplyChangeLimit() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: COUPON_SUPPLY_CHANGE_LIMIT});
    }
}
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
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
// File: contracts/token/IDollar.sol
/*
    Copyright 2021 Empty Apple Dev <bigemptyapple@protonmail.com>
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
contract IDollar is IERC20 {
    function burn(uint256 amount) public;
    function burnFrom(address account, uint256 amount) public;
    function mint(address account, uint256 amount) public returns (bool);
}
// File: contracts/dao/State.sol
/*
    Copyright 2021 Empty Apple Dev <bigemptyapple@protonmail.com>
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
contract Account {
    enum Status {
        Frozen,
        Fluid,
        Locked
    }
    struct State {
        uint256 staged;
        uint256 balance;
        mapping(uint256 => uint256) coupons;
        mapping(address => uint256) couponAllowances;
        uint256 fluidUntil;
        uint256 lockedUntil;
    }
}
contract Epoch {
    struct Global {
        uint256 start;
        uint256 period;
        uint256 current;
    }
    struct Coupons {
        uint256 outstanding;
        uint256 expiration;
        uint256[] expiring;
    }
    struct State {
        uint256 bonded;
        Coupons coupons;
        // uint256 eth_usdc_price;
    }
}
contract Candidate {
    enum Vote {
        UNDECIDED,
        APPROVE,
        REJECT
    }
    struct State {
        uint256 start;
        uint256 period;
        uint256 approve;
        uint256 reject;
        mapping(address => Vote) votes;
        bool initialized;
    }
}
contract Storage {
    struct Provider {
        IDollar dollar;
        IOracle oracle;
        address pool;
    }
    struct Balance {
        uint256 supply;
        uint256 bonded;
        uint256 staged;
        uint256 redeemable;
        uint256 debt;
        uint256 coupons;
    }
    struct State {
        Epoch.Global epoch;
        Balance balance;
        Provider provider;
        mapping(address => Account.State) accounts;
        mapping(uint256 => Epoch.State) epochs;
        mapping(address => Candidate.State) candidates;
    }
}
contract State {
    Storage.State _state;
}
// File: contracts/oracle/IDAO.sol
/*
    Copyright 2021 Empty Apple Dev <bigemptyapple@protonmail.com>
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
contract IDAO {
    function epoch() external view returns (uint256){}
}
// File: contracts/oracle/PoolState.sol
/*
    Copyright 2021 Empty Apple Dev <bigemptyapple@protonmail.com>
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
contract PoolAccount {
    enum Status {
        Frozen,
        Fluid,
        Locked
    }
    struct State {
        uint256 staged;
        uint256 claimable;
        uint256 bonded;
        uint256 phantom;
        uint256 fluidUntil;
    }
}
contract PoolStorage {
    struct Provider {
        IDAO dao;
        IDollar dollar;
        IERC20 univ2;
    }
    struct Balance {
        uint256 staged;
        uint256 claimable;
        uint256 bonded;
        uint256 phantom;
    }
    struct State {
        Balance balance;
        Provider provider;
        mapping(address => PoolAccount.State) accounts;
        mapping(uint256 => PoolEpoch.State) epochs;
    }
}
contract PoolEpoch {
    struct State {
        uint256 eth_usdc_price;
    }
}
contract PoolState {
    PoolStorage.State _state;
}
// File: contracts/oracle/PoolGetters.sol
/*
    Copyright 2021 Empty Apple Dev <bigemptyapple@protonmail.com>
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
contract PoolGetters is PoolState {
    using SafeMath for uint256;
    /**
     * Global
     */
    function dao() public view returns (IDAO) {
        return _state.provider.dao;
    }
    function dollar() public view returns (IDollar) {
        return _state.provider.dollar;
    }
    function univ2() public view returns (IERC20) {
        return _state.provider.univ2;
    }
    function totalBonded() public view returns (uint256) {
        return _state.balance.bonded;
    }
    function totalStaged() public view returns (uint256) {
        return _state.balance.staged;
    }
    function totalClaimable() public view returns (uint256) {
        return _state.balance.claimable;
    }
    function totalPhantom() public view returns (uint256) {
        return _state.balance.phantom;
    }
    function totalRewarded() public view returns (uint256) {
        return dollar().balanceOf(address(this)).sub(totalClaimable());
    }
    /**
     * Account
     */
    function balanceOfStaged(address account) public view returns (uint256) {
        return _state.accounts[account].staged;
    }
    function balanceOfClaimable(address account) public view returns (uint256) {
        return _state.accounts[account].claimable;
    }
    function balanceOfBonded(address account) public view returns (uint256) {
        return _state.accounts[account].bonded;
    }
    function balanceOfPhantom(address account) public view returns (uint256) {
        return _state.accounts[account].phantom;
    }
    function balanceOfRewarded(address account) public view returns (uint256) {
        uint256 totalBonded = totalBonded();
        if (totalBonded == 0) {
            return 0;
        }
        uint256 totalRewardedWithPhantom = totalRewarded().add(totalPhantom());
        uint256 balanceOfRewardedWithPhantom = totalRewardedWithPhantom
            .mul(balanceOfBonded(account))
            .div(totalBonded);
        return balanceOfRewardedWithPhantom.sub(balanceOfPhantom(account));
    }
    function statusOf(address account) public view returns (PoolAccount.Status) {
        return epoch() >= _state.accounts[account].fluidUntil ?
            PoolAccount.Status.Frozen :
            PoolAccount.Status.Fluid;
    }
    /**
     * Epoch
     */
    function epoch() public view returns (uint256) {
        return dao().epoch();
    }
    /**
     * price
     */
    function reservedPrice(uint256 epoch) public view returns (uint256) {
        uint256 window_price;
        bool valid=true;
        if(epoch<2){
            valid=false;
            return 0;
        }
        for (uint256 i = epoch-2; i <= epoch; i++) {
            window_price+=_state.epochs[i].eth_usdc_price;
        }
        window_price = window_price/3;
        return window_price;
    } 
}
// File: contracts/oracle/PoolSetters.sol
/*
    Copyright 2021 Empty Apple Dev <bigemptyapple@protonmail.com>
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
contract PoolSetters is PoolState, PoolGetters {
    using SafeMath for uint256;
    /**
     * Account
     */
    function incrementBalanceOfBonded(address account, uint256 amount) internal {
        _state.accounts[account].bonded = _state.accounts[account].bonded.add(amount);
        _state.balance.bonded = _state.balance.bonded.add(amount);
    }
    function decrementBalanceOfBonded(address account, uint256 amount, string memory reason) internal {
        _state.accounts[account].bonded = _state.accounts[account].bonded.sub(amount, reason);
        _state.balance.bonded = _state.balance.bonded.sub(amount, reason);
    }
    function incrementBalanceOfStaged(address account, uint256 amount) internal {
        _state.accounts[account].staged = _state.accounts[account].staged.add(amount);
        _state.balance.staged = _state.balance.staged.add(amount);
    }
    function decrementBalanceOfStaged(address account, uint256 amount, string memory reason) internal {
        _state.accounts[account].staged = _state.accounts[account].staged.sub(amount, reason);
        _state.balance.staged = _state.balance.staged.sub(amount, reason);
    }
    function incrementBalanceOfClaimable(address account, uint256 amount) internal {
        _state.accounts[account].claimable = _state.accounts[account].claimable.add(amount);
        _state.balance.claimable = _state.balance.claimable.add(amount);
    }
    function decrementBalanceOfClaimable(address account, uint256 amount, string memory reason) internal {
        _state.accounts[account].claimable = _state.accounts[account].claimable.sub(amount, reason);
        _state.balance.claimable = _state.balance.claimable.sub(amount, reason);
    }
    function incrementBalanceOfPhantom(address account, uint256 amount) internal {
        _state.accounts[account].phantom = _state.accounts[account].phantom.add(amount);
        _state.balance.phantom = _state.balance.phantom.add(amount);
    }
    function decrementBalanceOfPhantom(address account, uint256 amount, string memory reason) internal {
        _state.accounts[account].phantom = _state.accounts[account].phantom.sub(amount, reason);
        _state.balance.phantom = _state.balance.phantom.sub(amount, reason);
    }
    function unfreeze(address account) internal {
        _state.accounts[account].fluidUntil = epoch().add(Constants.getPoolExitLockupEpochs());
    }
    function updateReservedPrice(uint256 epoch, uint256 ethPrice) internal {
        _state.epochs[epoch].eth_usdc_price = ethPrice;
    }
}
// File: contracts/oracle/Oracle.sol
/*
    Copyright 2021 Empty Apple Dev <bigemptyapple@protonmail.com>
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
contract Oracle is IOracle,PoolSetters {
    using Decimal for Decimal.D256;
    using SafeMath for uint256;
    bytes32 private constant FILE = "Oracle";
    address private constant UNISWAP_FACTORY = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    address internal _dao;
    address internal _dollar;
    bool internal _initialized;
    IUniswapV2Pair internal _pair;
    IUniswapV2Pair internal _pair2;
    uint256 internal _index;
    uint256 internal _index3;
    uint256 internal _cumulative;
    uint256 internal _cumulative2;
    uint32 internal _timestamp;
    uint32 internal _timestamp2;
    uint256 internal _reserve;
    uint256 internal _ethPrice;
    // uint256 priceCumulative;
    // uint256 priceCumulative3;
    struct PriceInfo {
    uint32 timeElapsed;
    uint32 timeElapsed2;
    uint256 priceCumulative;
    uint256 priceCumulative3;
    }
    constructor (address dollar) public {
        _dao = msg.sender;
        _dollar = dollar;
        _state.provider.dao = IDAO(msg.sender);
    }
    function setup() public onlyDao {
        _pair = IUniswapV2Pair(IUniswapV2Factory(UNISWAP_FACTORY).createPair(_dollar, usdc()));
        _pair2 = IUniswapV2Pair(IUniswapV2Factory(UNISWAP_FACTORY).getPair(weth(), usdc()));
        (address token0, address token1) = (_pair.token0(), _pair.token1());
        _index = _dollar == token0 ? 0 : 1;
        (address token3, address token4) = (_pair2.token0(), _pair2.token1());
        _index3 = weth() == token3 ? 0 : 1;
        Require.that(
            _index == 0 || _dollar == token1,
            FILE,
            "Døllar not found"
        );
    }
    /**
     * Trades/Liquidity: (1) Initializes reserve and blockTimestampLast (can calculate a price)
     *                   (2) Has non-zero cumulative prices
     *
     * Steps: (1) Captures a reference blockTimestampLast
     *        (2) First reported value
     */
    function capture() public onlyDao returns (Decimal.D256 memory, bool) {
        if (_initialized) {
            return updateOracle();
        } else {
            initializeOracle();
            return (Decimal.one(), false);
        }
    }
    function initializeOracle() private {
        IUniswapV2Pair pair = _pair;
        IUniswapV2Pair pair2 = _pair2;
        uint256 priceCumulative = _index == 0 ?
            pair.price0CumulativeLast() :
            pair.price1CumulativeLast();
        uint256 priceCumulative2 = _index == 0 ?
            pair2.price0CumulativeLast() :
            pair2.price1CumulativeLast();
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = pair.getReserves();
        (uint112 reserve3, uint112 reserve4, uint32 blockTimestampLast2) = pair2.getReserves();
        if(reserve0 != 0 && reserve1 != 0 && blockTimestampLast != 0) {
            _cumulative = priceCumulative;
            _cumulative2 = priceCumulative2;
            _timestamp = blockTimestampLast;
            _timestamp2 = blockTimestampLast2;
            _initialized = true;
            _reserve = _index == 0 ? reserve1 : reserve0; // get counter's reserve
        }
    }
    function updateOracle() private returns (Decimal.D256 memory, bool) {
        Decimal.D256 memory price = updatePrice();
        uint256 lastReserve = updateReserve();
        bool isBlacklisted = IUSDC(usdc()).isBlacklisted(address(_pair));
        bool valid = true;
        if (lastReserve < Constants.getOracleReserveMinimum()) {
            valid = false;
        }
        if (_reserve < Constants.getOracleReserveMinimum()) {
            valid = false;
        }
        if (isBlacklisted) {
            valid = false;
        }
        return (price, valid);
    }
    function updatePrice() private returns (Decimal.D256 memory) {
        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) =
        UniswapV2OracleLibrary.currentCumulativePrices(address(_pair));
        (uint256 price3Cumulative, uint256 price4Cumulative, uint32 blockTimestamp2) =
        UniswapV2OracleLibrary.currentCumulativePrices(address(_pair2));
        PriceInfo memory pricesinfo;
        pricesinfo.timeElapsed = blockTimestamp - _timestamp; // overflow is desired
        pricesinfo.timeElapsed2 = blockTimestamp2 - _timestamp2; // overflow is desired
        pricesinfo.priceCumulative = _index == 0 ? price0Cumulative : price1Cumulative;
        pricesinfo.priceCumulative3 = _index3 == 0 ? price3Cumulative : price4Cumulative;
        _ethPrice = (pricesinfo.priceCumulative3 - _cumulative2)/pricesinfo.timeElapsed2;
        updateReservedPrice(epoch(), _ethPrice); 
        uint256 windowEthPrice = PoolGetters.reservedPrice(epoch());
        uint256 windowEthPriceLast = PoolGetters.reservedPrice(epoch()-1);
        Decimal.D256 memory one = Decimal.one();
        Decimal.D256 memory shadowEthPrice = one;
        if (windowEthPriceLast>0){
            shadowEthPrice = windowEthPrice>=windowEthPriceLast ? one.add(Decimal.ratio(sqrt(windowEthPrice-windowEthPriceLast),
            sqrt(windowEthPriceLast))) : one.sub(Decimal.ratio(sqrt(windowEthPriceLast-windowEthPrice),sqrt(windowEthPriceLast)));
            }
        Decimal.D256 memory price1 = Decimal.ratio((pricesinfo.priceCumulative - _cumulative)
            / pricesinfo.timeElapsed, 2**112);
        Decimal.D256 memory price = price1.mul(Decimal.ratio(90, 100)).add(shadowEthPrice.div(1e12).mul(Decimal.ratio(10, 100)));
        _timestamp = blockTimestamp;
        _timestamp2 = blockTimestamp2;
        _cumulative = pricesinfo.priceCumulative;
        _cumulative2 = pricesinfo.priceCumulative3;
        return price.mul(1e12);
    }
    function updateReserve() private returns (uint256) {
        uint256 lastReserve = _reserve;
        (uint112 reserve0, uint112 reserve1,) = _pair.getReserves();
        _reserve = _index == 0 ? reserve1 : reserve0; // get counter's reserve
        return lastReserve;
    }
    function usdc() internal view returns (address) {
        return Constants.getUsdc();
    }
    function weth() internal view returns (address) {
        return Constants.getWeth();
    }
    function pair() external view returns (address) {
        return address(_pair);
    }
    function reserve() external view returns (uint256) {
        return _reserve;
    }
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
    modifier onlyDao() {
        Require.that(
            msg.sender == _dao,
            FILE,
            "Not dao"
        );
        _;
    }
}
