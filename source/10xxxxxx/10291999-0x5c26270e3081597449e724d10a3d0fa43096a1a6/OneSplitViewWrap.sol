// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

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

// File: contracts/IOneSplit.sol

pragma solidity ^0.5.0;


//
//  [ msg.sender ]
//       | |
//       | |
//       \_/
// +---------------+ ________________________________
// | OneSplitAudit | _______________________________  \
// +---------------+                                 \ \
//       | |                      ______________      | | (staticcall)
//       | |                    /  ____________  \    | |
//       | | (call)            / /              \ \   | |
//       | |                  / /               | |   | |
//       \_/                  | |               \_/   \_/
// +--------------+           | |           +----------------------+
// | OneSplitWrap |           | |           |   OneSplitViewWrap   |
// +--------------+           | |           +----------------------+
//       | |                  | |                     | |
//       | | (delegatecall)   | | (staticcall)        | | (staticcall)
//       \_/                  | |                     \_/
// +--------------+           | |             +------------------+
// |   OneSplit   |           | |             |   OneSplitView   |
// +--------------+           | |             +------------------+
//       | |                  / /
//        \ \________________/ /
//         \__________________/
//


contract IOneSplitConsts {
    // flags = FLAG_DISABLE_UNISWAP + FLAG_DISABLE_KYBER + ...
    uint256 public constant FLAG_DISABLE_UNISWAP = 0x01;
    uint256 public constant FLAG_DISABLE_KYBER = 0x02;
    uint256 public constant FLAG_ENABLE_KYBER_UNISWAP_RESERVE = 0x100000000; // Turned off by default
    uint256 public constant FLAG_ENABLE_KYBER_OASIS_RESERVE = 0x200000000; // Turned off by default
    uint256 public constant FLAG_ENABLE_KYBER_BANCOR_RESERVE = 0x400000000; // Turned off by default
    uint256 public constant FLAG_DISABLE_BANCOR = 0x04;
    uint256 public constant FLAG_DISABLE_OASIS = 0x08;
    uint256 public constant FLAG_DISABLE_COMPOUND = 0x10;
    uint256 public constant FLAG_DISABLE_FULCRUM = 0x20;
    uint256 public constant FLAG_DISABLE_CHAI = 0x40;
    uint256 public constant FLAG_DISABLE_AAVE = 0x80;
    uint256 public constant FLAG_DISABLE_SMART_TOKEN = 0x100;
    uint256 public constant FLAG_ENABLE_MULTI_PATH_ETH = 0x200; // Turned off by default
    uint256 public constant FLAG_DISABLE_BDAI = 0x400;
    uint256 public constant FLAG_DISABLE_IEARN = 0x800;
    uint256 public constant FLAG_DISABLE_CURVE_COMPOUND = 0x1000;
    uint256 public constant FLAG_DISABLE_CURVE_USDT = 0x2000;
    uint256 public constant FLAG_DISABLE_CURVE_Y = 0x4000;
    uint256 public constant FLAG_DISABLE_CURVE_BINANCE = 0x8000;
    uint256 public constant FLAG_ENABLE_MULTI_PATH_DAI = 0x10000; // Turned off by default
    uint256 public constant FLAG_ENABLE_MULTI_PATH_USDC = 0x20000; // Turned off by default
    uint256 public constant FLAG_DISABLE_CURVE_SYNTHETIX = 0x40000;
    uint256 public constant FLAG_DISABLE_WETH = 0x80000;
    uint256 public constant FLAG_ENABLE_UNISWAP_COMPOUND = 0x100000; // Works only when one of assets is ETH or FLAG_ENABLE_MULTI_PATH_ETH
    uint256 public constant FLAG_ENABLE_UNISWAP_CHAI = 0x200000; // Works only when ETH<>DAI or FLAG_ENABLE_MULTI_PATH_ETH
    uint256 public constant FLAG_ENABLE_UNISWAP_AAVE = 0x400000; // Works only when one of assets is ETH or FLAG_ENABLE_MULTI_PATH_ETH
    uint256 public constant FLAG_DISABLE_IDLE = 0x800000;
    uint256 public constant FLAG_DISABLE_MOONISWAP = 0x1000000;
    uint256 public constant FLAG_DISABLE_UNISWAP_V2_ALL = 0x1E000000;
    uint256 public constant FLAG_DISABLE_UNISWAP_V2 = 0x2000000;
    uint256 public constant FLAG_DISABLE_UNISWAP_V2_ETH = 0x4000000;
    uint256 public constant FLAG_DISABLE_UNISWAP_V2_DAI = 0x8000000;
    uint256 public constant FLAG_DISABLE_UNISWAP_V2_USDC = 0x10000000;
    uint256 public constant FLAG_DISABLE_ALL_SPLIT_SOURCES = 0x20000000;
    uint256 public constant FLAG_DISABLE_ALL_WRAP_SOURCES = 0x40000000;
    uint256 public constant FLAG_DISABLE_CURVE_PAX = 0x80000000;
    uint256 internal constant FLAG_DISABLE_CURVE_RENBTC = 0x100000000;
    uint256 internal constant FLAG_DISABLE_CURVE_TBTC = 0x200000000;
    uint256 internal constant FLAG_ENABLE_MULTI_PATH_USDT = 0x400000000; // Turned off by default
    uint256 internal constant FLAG_ENABLE_MULTI_PATH_WBTC = 0x800000000; // Turned off by default
    uint256 internal constant FLAG_ENABLE_MULTI_PATH_TBTC = 0x1000000000; // Turned off by default
    uint256 internal constant FLAG_ENABLE_MULTI_PATH_RENBTC = 0x2000000000; // Turned off by default
    uint256 internal constant FLAG_DISABLE_DFORCE_SWAP = 0x4000000000;
    uint256 internal constant FLAG_DISABLE_SHELL = 0x8000000000;
    uint256 internal constant FLAG_ENABLE_CHI_BURN = 0x10000000000;
    uint256 internal constant FLAG_DISABLE_MSTABLE_MUSD = 0x20000000000;

    uint256 public constant FLAG_DISABLE_UNISWAP_POOL_TOKEN = 0x40000000000;
    uint256 public constant FLAG_DISABLE_BALANCER_POOL_TOKEN = 0x80000000000;
    uint256 public constant FLAG_DISABLE_CURVE_ZAP = 0x100000000000;
    uint256 public constant FLAG_DISABLE_UNISWAP_V2_POOL_TOKEN = 0x200000000000;
}


contract IOneSplit is IOneSplitConsts {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
    )
    public
    view
    returns(
        uint256 returnAmount,
        uint256[] memory distribution
    );

    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags, // See constants in IOneSplit.sol
        uint256 destTokenEthPriceTimesGasPrice
    )
    public
    view
    returns(
        uint256 returnAmount,
        uint256 estimateGasAmount,
        uint256[] memory distribution
    );

    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 flags
    )
    public
    payable
    returns(uint256 returnAmount);
}

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

// File: contracts/interface/IUniswapExchange.sol

pragma solidity ^0.5.0;



interface IUniswapExchange {
    function getEthToTokenInputPrice(uint256 ethSold) external view returns (uint256 tokensBought);

    function getTokenToEthInputPrice(uint256 tokensSold) external view returns (uint256 ethBought);

    function ethToTokenSwapInput(uint256 minTokens, uint256 deadline)
        external
        payable
        returns (uint256 tokensBought);

    function tokenToEthSwapInput(uint256 tokensSold, uint256 minEth, uint256 deadline)
        external
        returns (uint256 ethBought);

    function tokenToTokenSwapInput(
        uint256 tokensSold,
        uint256 minTokensBought,
        uint256 minEthBought,
        uint256 deadline,
        address tokenAddr
    ) external returns (uint256 tokensBought);

    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);

    function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
}

// File: contracts/interface/IUniswapFactory.sol

pragma solidity ^0.5.0;



interface IUniswapFactory {
    function getExchange(IERC20 token) external view returns (IUniswapExchange exchange);

    function getToken(address exchange) external view returns (IERC20 token);
}

// File: contracts/interface/IKyberNetworkContract.sol

pragma solidity ^0.5.0;



interface IKyberNetworkContract {
    function searchBestRate(IERC20 src, IERC20 dest, uint256 srcAmount, bool usePermissionless)
        external
        view
        returns (address reserve, uint256 rate);
}

// File: contracts/interface/IKyberNetworkProxy.sol

pragma solidity ^0.5.0;



interface IKyberNetworkProxy {
    function getExpectedRate(IERC20 src, IERC20 dest, uint256 srcQty)
        external
        view
        returns (uint256 expectedRate, uint256 slippageRate);

    function tradeWithHint(
        IERC20 src,
        uint256 srcAmount,
        IERC20 dest,
        address destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address walletId,
        bytes calldata hint
    ) external payable returns (uint256);

    function kyberNetworkContract() external view returns (IKyberNetworkContract);

    // TODO: Limit usage by tx.gasPrice
    // function maxGasPrice() external view returns (uint256);

    // TODO: Limit usage by user cap
    // function getUserCapInWei(address user) external view returns (uint256);
    // function getUserCapInTokenWei(address user, IERC20 token) external view returns (uint256);
}

// File: contracts/interface/IKyberUniswapReserve.sol

pragma solidity ^0.5.0;


interface IKyberUniswapReserve {
    function uniswapFactory() external view returns (address);
}

// File: contracts/interface/IKyberOasisReserve.sol

pragma solidity ^0.5.0;


interface IKyberOasisReserve {
    function otc() external view returns (address);
}

// File: contracts/interface/IKyberBancorReserve.sol

pragma solidity ^0.5.0;


contract IKyberBancorReserve {
    function bancorEth() public view returns (address);
}

// File: contracts/interface/IBancorNetwork.sol

pragma solidity ^0.5.0;


interface IBancorNetwork {
    function getReturnByPath(address[] calldata path, uint256 amount)
        external
        view
        returns (uint256 returnAmount, uint256 conversionFee);

    function claimAndConvert(address[] calldata path, uint256 amount, uint256 minReturn)
        external
        returns (uint256);

    function convert(address[] calldata path, uint256 amount, uint256 minReturn)
        external
        payable
        returns (uint256);
}

// File: contracts/interface/IBancorContractRegistry.sol

pragma solidity ^0.5.0;


contract IBancorContractRegistry {
    function addressOf(bytes32 contractName) external view returns (address);
}

// File: contracts/interface/IBancorConverterRegistry.sol

pragma solidity ^0.5.0;



interface IBancorConverterRegistry {

    function getConvertibleTokenSmartTokenCount(IERC20 convertibleToken)
        external view returns(uint256);

    function getConvertibleTokenSmartTokens(IERC20 convertibleToken)
        external view returns(address[] memory);

    function getConvertibleTokenSmartToken(IERC20 convertibleToken, uint256 index)
        external view returns(address);

    function isConvertibleTokenSmartToken(IERC20 convertibleToken, address value)
        external view returns(bool);
}

// File: contracts/interface/IBancorEtherToken.sol

pragma solidity ^0.5.0;



contract IBancorEtherToken is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// File: contracts/interface/IOasisExchange.sol

pragma solidity ^0.5.0;



interface IOasisExchange {
    function getBuyAmount(IERC20 buyGem, IERC20 payGem, uint256 payAmt)
        external
        view
        returns (uint256 fillAmt);

    function sellAllAmount(IERC20 payGem, uint256 payAmt, IERC20 buyGem, uint256 minFillAmount)
        external
        returns (uint256 fillAmt);
}

// File: contracts/interface/IWETH.sol

pragma solidity ^0.5.0;



contract IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// File: contracts/interface/ICurve.sol

pragma solidity ^0.5.0;


interface ICurve {
    // solium-disable-next-line mixedcase
    function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns(uint256 dy);

    // solium-disable-next-line mixedcase
    function get_dy(int128 i, int128 j, uint256 dx) external view returns(uint256 dy);

    function get_virtual_price() external view returns(uint256);

    // solium-disable-next-line mixedcase
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 minDy) external;

    // solium-disable-next-line mixedcase
    function exchange(int128 i, int128 j, uint256 dx, uint256 minDy) external;

    function coins(int128 arg0) external view returns (address);

    function balances(int128 arg0) external view returns (uint256);
}

// File: contracts/interface/IChai.sol

pragma solidity ^0.5.0;



interface IPot {
    function dsr() external view returns (uint256);

    function chi() external view returns (uint256);

    function rho() external view returns (uint256);

    function drip() external returns (uint256);

    function join(uint256) external;

    function exit(uint256) external;
}


contract IChai is IERC20 {
    function POT() public view returns (IPot);

    function join(address dst, uint256 wad) external;

    function exit(address src, uint256 wad) external;
}


library ChaiHelper {
    IPot private constant POT = IPot(0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
    uint256 private constant RAY = 10**27;

    function _mul(uint256 x, uint256 y) private pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function _rmul(uint256 x, uint256 y) private pure returns (uint256 z) {
        // always rounds down
        z = _mul(x, y) / RAY;
    }

    function _rdiv(uint256 x, uint256 y) private pure returns (uint256 z) {
        // always rounds down
        z = _mul(x, RAY) / y;
    }

    function rpow(uint256 x, uint256 n, uint256 base) private pure returns (uint256 z) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            switch x
                case 0 {
                    switch n
                        case 0 {
                            z := base
                        }
                        default {
                            z := 0
                        }
                }
                default {
                    switch mod(n, 2)
                        case 0 {
                            z := base
                        }
                        default {
                            z := x
                        }
                    let half := div(base, 2) // for rounding.
                    for {
                        n := div(n, 2)
                    } n {
                        n := div(n, 2)
                    } {
                        let xx := mul(x, x)
                        if iszero(eq(div(xx, x), x)) {
                            revert(0, 0)
                        }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) {
                            revert(0, 0)
                        }
                        x := div(xxRound, base)
                        if mod(n, 2) {
                            let zx := mul(z, x)
                            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                                revert(0, 0)
                            }
                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) {
                                revert(0, 0)
                            }
                            z := div(zxRound, base)
                        }
                    }
                }
        }
    }

    function potDrip() private view returns (uint256) {
        return _rmul(rpow(POT.dsr(), now - POT.rho(), RAY), POT.chi());
    }

    function chaiPrice(IChai chai) internal view returns(uint256) {
        return chaiToDai(chai, 1e18);
    }

    function daiToChai(
        IChai /*chai*/,
        uint256 amount
    ) internal view returns (uint256) {
        uint256 chi = (now > POT.rho()) ? potDrip() : POT.chi();
        return _rdiv(amount, chi);
    }

    function chaiToDai(
        IChai /*chai*/,
        uint256 amount
    ) internal view returns (uint256) {
        uint256 chi = (now > POT.rho()) ? potDrip() : POT.chi();
        return _rmul(chi, amount);
    }
}

// File: contracts/interface/ICompound.sol

pragma solidity ^0.5.0;



contract ICompound {
    function markets(address cToken)
        external
        view
        returns (bool isListed, uint256 collateralFactorMantissa);
}


contract ICompoundToken is IERC20 {
    function underlying() external view returns (address);

    function exchangeRateStored() external view returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);
}


contract ICompoundEther is IERC20 {
    function mint() external payable;

    function redeem(uint256 redeemTokens) external returns (uint256);
}

// File: contracts/interface/IAaveToken.sol

pragma solidity ^0.5.0;



contract IAaveToken is IERC20 {
    function underlyingAssetAddress() external view returns (IERC20);

    function redeem(uint256 amount) external;
}


interface IAaveLendingPool {
    function core() external view returns (address);

    function deposit(IERC20 token, uint256 amount, uint16 refCode) external payable;
}

// File: contracts/interface/IMooniswap.sol

pragma solidity ^0.5.0;



interface IMooniswapRegistry {
    function target() external view returns(IMooniswap);
}


interface IMooniswap {
    function getReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    )
        external
        view
        returns(uint256 returnAmount);

    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 minReturn
    )
        external
        payable
        returns(uint256 returnAmount);
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.5.5;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
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

// File: contracts/UniversalERC20.sol

pragma solidity ^0.5.0;





library UniversalERC20 {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private constant ZERO_ADDRESS = IERC20(0x0000000000000000000000000000000000000000);
    IERC20 private constant ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function universalTransfer(IERC20 token, address to, uint256 amount) internal returns(bool) {
        if (amount == 0) {
            return true;
        }

        if (isETH(token)) {
            address(uint160(to)).transfer(amount);
        } else {
            token.safeTransfer(to, amount);
            return true;
        }
    }

    function universalTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            require(from == msg.sender && msg.value >= amount, "Wrong useage of ETH.universalTransferFrom()");
            if (to != address(this)) {
                address(uint160(to)).transfer(amount);
            }
            if (msg.value > amount) {
                msg.sender.transfer(msg.value.sub(amount));
            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalTransferFromSenderToThis(IERC20 token, uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            if (msg.value > amount) {
                // Return remainder if exist
                msg.sender.transfer(msg.value.sub(amount));
            }
        } else {
            token.safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    function universalApprove(IERC20 token, address to, uint256 amount) internal {
        if (!isETH(token)) {
            if (amount == 0) {
                token.safeApprove(to, 0);
                return;
            }

            uint256 allowance = token.allowance(address(this), to);
            if (allowance < amount) {
                if (allowance > 0) {
                    token.safeApprove(to, 0);
                }
                token.safeApprove(to, amount);
            }
        }
    }

    function universalBalanceOf(IERC20 token, address who) internal view returns (uint256) {
        if (isETH(token)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }

    function universalDecimals(IERC20 token) internal view returns (uint256) {

        if (isETH(token)) {
            return 18;
        }

        (bool success, bytes memory data) = address(token).staticcall.gas(10000)(
            abi.encodeWithSignature("decimals()")
        );
        if (!success || data.length == 0) {
            (success, data) = address(token).staticcall.gas(10000)(
                abi.encodeWithSignature("DECIMALS()")
            );
        }

        return (success && data.length > 0) ? abi.decode(data, (uint256)) : 18;
    }

    function isETH(IERC20 token) internal pure returns(bool) {
        return (address(token) == address(ZERO_ADDRESS) || address(token) == address(ETH_ADDRESS));
    }

    function notExist(IERC20 token) internal pure returns(bool) {
        return (address(token) == address(-1));
    }
}

// File: contracts/interface/IUniswapV2Exchange.sol

pragma solidity ^0.5.0;





interface IUniswapV2Exchange {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}


library UniswapV2ExchangeLib {
    using SafeMath for uint256;
    using UniversalERC20 for IERC20;

    function getReturn(
        IUniswapV2Exchange exchange,
        IERC20 fromToken,
        IERC20 destToken,
        uint amountIn
    ) internal view returns (uint256) {
        uint256 reserveIn = fromToken.universalBalanceOf(address(exchange));
        uint256 reserveOut = destToken.universalBalanceOf(address(exchange));

        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        return (denominator == 0) ? 0 : numerator.div(denominator);
    }
}

// File: contracts/interface/IUniswapV2Factory.sol

pragma solidity ^0.5.0;



interface IUniswapV2Factory {
    function getPair(IERC20 tokenA, IERC20 tokenB) external view returns (IUniswapV2Exchange pair);
}

// File: contracts/interface/IDForceSwap.sol

pragma solidity ^0.5.0;



interface IDForceSwap {
    function getAmountByInput(IERC20 input, IERC20 output, uint256 amount) external view returns(uint256);
    function swap(IERC20 input, IERC20 output, uint256 amount) external;
}

// File: contracts/interface/IShell.sol

pragma solidity ^0.5.0;


interface IShell {
    function viewOriginTrade(
        address origin,
        address target,
        uint256 originAmount
    ) external view returns (uint256);

    function swapByOrigin(
        address origin,
        address target,
        uint256 originAmount,
        uint256 minTargetAmount,
        uint256 deadline
    ) external returns (uint256);
}

// File: contracts/interface/IMStable.sol

pragma solidity ^0.5.0;



contract IMStable is IERC20 {
    function getSwapOutput(
        IERC20 _input,
        IERC20 _output,
        uint256 _quantity
    )
        external
        view
        returns (bool, string memory, uint256 output);

    function swap(
        IERC20 _input,
        IERC20 _output,
        uint256 _quantity,
        address _recipient
    )
        external
        returns (uint256 output);

    function redeem(
        IERC20 _basset,
        uint256 _bassetQuantity
    )
        external
        returns (uint256 massetRedeemed);
}

interface IMassetRedemptionValidator {
    function getRedeemValidity(
        IERC20 _mAsset,
        uint256 _mAssetQuantity,
        IERC20 _outputBasset
    )
        external
        view
        returns (bool, string memory, uint256 output);
}

// File: contracts/OneSplitBase.sol

pragma solidity ^0.5.0;









//import "./interface/IBancorNetworkPathFinder.sol";

















contract IOneSplitView is IOneSplitConsts {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        );

    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        );
}


library DisableFlags {
    function check(uint256 flags, uint256 flag) internal pure returns(bool) {
        return (flags & flag) != 0;
    }
}


contract OneSplitRoot {
    using SafeMath for uint256;
    using DisableFlags for uint256;

    using UniversalERC20 for IERC20;
    using UniversalERC20 for IWETH;
    using UniversalERC20 for IBancorEtherToken;
    using UniswapV2ExchangeLib for IUniswapV2Exchange;
    using ChaiHelper for IChai;

    uint256 constant public DEXES_COUNT = 23;
    IERC20 constant internal ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    IERC20 constant internal dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 constant internal bnt = IERC20(0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C);
    IERC20 constant internal usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 constant internal usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 constant internal tusd = IERC20(0x0000000000085d4780B73119b644AE5ecd22b376);
    IERC20 constant internal busd = IERC20(0x4Fabb145d64652a948d72533023f6E7A623C7C53);
    IERC20 constant internal susd = IERC20(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
    IERC20 constant internal pax = IERC20(0x8E870D67F660D95d5be530380D0eC0bd388289E1);
    IWETH constant internal weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IBancorEtherToken constant internal bancorEtherToken = IBancorEtherToken(0xc0829421C1d260BD3cB3E0F06cfE2D52db2cE315);
    IChai constant internal chai = IChai(0x06AF07097C9Eeb7fD685c692751D5C66dB49c215);
    IERC20 constant internal renbtc = IERC20(0x93054188d876f558f4a66B2EF1d97d16eDf0895B);
    IERC20 constant internal wbtc = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    IERC20 constant internal tbtc = IERC20(0x1bBE271d15Bb64dF0bc6CD28Df9Ff322F2eBD847);
    IERC20 constant internal hbtc = IERC20(0x0316EB71485b0Ab14103307bf65a021042c6d380);

    IKyberNetworkProxy constant internal kyberNetworkProxy = IKyberNetworkProxy(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
    IUniswapFactory constant internal uniswapFactory = IUniswapFactory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);
    IBancorContractRegistry constant internal bancorContractRegistry = IBancorContractRegistry(0x52Ae12ABe5D8BD778BD5397F99cA900624CfADD4);
    //IBancorNetworkPathFinder constant internal bancorNetworkPathFinder = IBancorNetworkPathFinder(0x6F0cD8C4f6F06eAB664C7E3031909452b4B72861);
    //IBancorConverterRegistry constant internal bancorConverterRegistry = IBancorConverterRegistry(0xf6E2D7F616B67E46D708e4410746E9AAb3a4C518);
    IOasisExchange constant internal oasisExchange = IOasisExchange(0x794e6e91555438aFc3ccF1c5076A74F42133d08D);
    ICurve constant internal curveCompound = ICurve(0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56);
    ICurve constant internal curveUsdt = ICurve(0x52EA46506B9CC5Ef470C5bf89f17Dc28bB35D85C);
    ICurve constant internal curveY = ICurve(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51);
    ICurve constant internal curveBinance = ICurve(0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27);
    ICurve constant internal curveSynthetix = ICurve(0xA5407eAE9Ba41422680e2e00537571bcC53efBfD);
    ICurve constant internal curvePax = ICurve(0x06364f10B501e868329afBc005b3492902d6C763);
    ICurve constant internal curveRenBtc = ICurve(0x8474c1236F0Bc23830A23a41aBB81B2764bA9f4F);
    ICurve constant internal curveTBtc = ICurve(0x9726e9314eF1b96E45f40056bEd61A088897313E);
    IShell constant internal shell = IShell(0xA8253a440Be331dC4a7395B73948cCa6F19Dc97D);
    IAaveLendingPool constant internal aave = IAaveLendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);
    ICompound constant internal compound = ICompound(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    ICompoundEther constant internal cETH = ICompoundEther(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);
    IMooniswapRegistry constant internal mooniswapRegistry = IMooniswapRegistry(0x7079E8517594e5b21d2B9a0D17cb33F5FE2bca70);
    IUniswapV2Factory constant internal uniswapV2 = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IDForceSwap constant internal dforceSwap = IDForceSwap(0x03eF3f37856bD08eb47E2dE7ABc4Ddd2c19B60F2);
    IMStable constant internal musd = IMStable(0xe2f2a5C287993345a840Db3B0845fbC70f5935a5);
    IMassetRedemptionValidator constant internal musd_helper = IMassetRedemptionValidator(0xe7e41f1b97F3EB2f218d99ecB22351Fa669D5944);

    function _buildBancorPath(
        IERC20 fromToken,
        IERC20 destToken
    ) internal view returns(address[] memory path) {
        if (fromToken == destToken) {
            return new address[](0);
        }

        if (fromToken.isETH()) {
            fromToken = ETH_ADDRESS;
        }
        if (destToken.isETH()) {
            destToken = ETH_ADDRESS;
        }

        if (fromToken == bnt || destToken == bnt) {
            path = new address[](3);
        } else {
            path = new address[](5);
        }

        address fromConverter;
        address toConverter;

        IBancorConverterRegistry bancorConverterRegistry = IBancorConverterRegistry(bancorContractRegistry.addressOf("BancorConverterRegistry"));

        if (fromToken != bnt) {
            (bool success, bytes memory data) = address(bancorConverterRegistry).staticcall.gas(100000)(abi.encodeWithSelector(
                bancorConverterRegistry.getConvertibleTokenSmartToken.selector,
                fromToken.isETH() ? ETH_ADDRESS : fromToken,
                0
            ));
            if (!success) {
                return new address[](0);
            }

            fromConverter = abi.decode(data, (address));
            if (fromConverter == address(0)) {
                return new address[](0);
            }
        }

        if (destToken != bnt) {
            (bool success, bytes memory data) = address(bancorConverterRegistry).staticcall.gas(100000)(abi.encodeWithSelector(
                bancorConverterRegistry.getConvertibleTokenSmartToken.selector,
                destToken.isETH() ? ETH_ADDRESS : destToken,
                0
            ));
            if (!success) {
                return new address[](0);
            }

            toConverter = abi.decode(data, (address));
            if (toConverter == address(0)) {
                return new address[](0);
            }
        }

        if (destToken == bnt) {
            path[0] = address(fromToken);
            path[1] = fromConverter;
            path[2] = address(bnt);
            return path;
        }

        if (fromToken == bnt) {
            path[0] = address(bnt);
            path[1] = toConverter;
            path[2] = address(destToken);
            return path;
        }

        path[0] = address(fromToken);
        path[1] = fromConverter;
        path[2] = address(bnt);
        path[3] = toConverter;
        path[4] = address(destToken);
        return path;
    }

    function _getCompoundToken(IERC20 token) internal pure returns(ICompoundToken) {
        if (token.isETH()) { // ETH
            return ICompoundToken(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);
        }
        if (token == IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F)) { // DAI
            return ICompoundToken(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
        }
        if (token == IERC20(0x0D8775F648430679A709E98d2b0Cb6250d2887EF)) { // BAT
            return ICompoundToken(0x6C8c6b02E7b2BE14d4fA6022Dfd6d75921D90E4E);
        }
        if (token == IERC20(0x1985365e9f78359a9B6AD760e32412f4a445E862)) { // REP
            return ICompoundToken(0x158079Ee67Fce2f58472A96584A73C7Ab9AC95c1);
        }
        if (token == IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)) { // USDC
            return ICompoundToken(0x39AA39c021dfbaE8faC545936693aC917d5E7563);
        }
        if (token == IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599)) { // WBTC
            return ICompoundToken(0xC11b1268C1A384e55C48c2391d8d480264A3A7F4);
        }
        if (token == IERC20(0xE41d2489571d322189246DaFA5ebDe1F4699F498)) { // ZRX
            return ICompoundToken(0xB3319f5D18Bc0D84dD1b4825Dcde5d5f7266d407);
        }
        if (token == IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7)) { // USDT
            return ICompoundToken(0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9);
        }

        return ICompoundToken(0);
    }

    function _getAaveToken(IERC20 token) internal pure returns(IAaveToken) {
        if (token.isETH()) { // ETH
            return IAaveToken(0x3a3A65aAb0dd2A17E3F1947bA16138cd37d08c04);
        }
        if (token == IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F)) { // DAI
            return IAaveToken(0xfC1E690f61EFd961294b3e1Ce3313fBD8aa4f85d);
        }
        if (token == IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)) { // USDC
            return IAaveToken(0x9bA00D6856a4eDF4665BcA2C2309936572473B7E);
        }
        if (token == IERC20(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51)) { // SUSD
            return IAaveToken(0x625aE63000f46200499120B906716420bd059240);
        }
        if (token == IERC20(0x4Fabb145d64652a948d72533023f6E7A623C7C53)) { // BUSD
            return IAaveToken(0x6Ee0f7BB50a54AB5253dA0667B0Dc2ee526C30a8);
        }
        if (token == IERC20(0x0000000000085d4780B73119b644AE5ecd22b376)) { // TUSD
            return IAaveToken(0x4DA9b813057D04BAef4e5800E36083717b4a0341);
        }
        if (token == IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7)) { // USDT
            return IAaveToken(0x71fc860F7D3A592A4a98740e39dB31d25db65ae8);
        }
        if (token == IERC20(0x0D8775F648430679A709E98d2b0Cb6250d2887EF)) { // BAT
            return IAaveToken(0xE1BA0FB44CCb0D11b80F92f4f8Ed94CA3fF51D00);
        }
        if (token == IERC20(0xdd974D5C2e2928deA5F71b9825b8b646686BD200)) { // KNC
            return IAaveToken(0x9D91BE44C06d373a8a226E1f3b146956083803eB);
        }
        if (token == IERC20(0x80fB784B7eD66730e8b1DBd9820aFD29931aab03)) { // LEND
            return IAaveToken(0x7D2D3688Df45Ce7C552E19c27e007673da9204B8);
        }
        if (token == IERC20(0x514910771AF9Ca656af840dff83E8264EcF986CA)) { // LINK
            return IAaveToken(0xA64BD6C70Cb9051F6A9ba1F163Fdc07E0DfB5F84);
        }
        if (token == IERC20(0x0F5D2fB29fb7d3CFeE444a200298f468908cC942)) { // MANA
            return IAaveToken(0x6FCE4A401B6B80ACe52baAefE4421Bd188e76F6f);
        }
        if (token == IERC20(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2)) { // MKR
            return IAaveToken(0x7deB5e830be29F91E298ba5FF1356BB7f8146998);
        }
        if (token == IERC20(0x1985365e9f78359a9B6AD760e32412f4a445E862)) { // REP
            return IAaveToken(0x71010A9D003445aC60C4e6A7017c1E89A477B438);
        }
        if (token == IERC20(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F)) { // SNX
            return IAaveToken(0x328C4c80BC7aCa0834Db37e6600A6c49E12Da4DE);
        }
        if (token == IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599)) { // WBTC
            return IAaveToken(0xFC4B8ED459e00e5400be803A9BB3954234FD50e3);
        }
        if (token == IERC20(0xE41d2489571d322189246DaFA5ebDe1F4699F498)) { // ZRX
            return IAaveToken(0x6Fb0855c404E09c47C3fBCA25f08d4E41f9F062f);
        }

        return IAaveToken(0);
    }
}


contract OneSplitViewWrapBase is IOneSplitView, OneSplitRoot {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        (returnAmount, , distribution) = this.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            0
        );
    }

    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        return _getExpectedReturnRespectingGasFloor(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function _getExpectedReturnRespectingGasFloor(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags, // See constants in IOneSplit.sol
        uint256 destTokenEthPriceTimesGasPrice
    )
        internal
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        );
}


contract OneSplitView is IOneSplitView, OneSplitRoot {
    function _findBestDistribution(
        uint256 s,                            // parts
        int256[][DEXES_COUNT] memory amounts // exchangesReturns
    ) internal pure returns(int256 returnAmount, uint256[] memory distribution) {
        uint256 n = amounts.length;

        int256[][] memory answer = new int256[][](n); // int[n][s+1]
        uint256[][] memory parent = new uint256[][](n); // int[n][s+1]

        for (uint i = 0; i < n; i++) {
            answer[i] = new int256[](s + 1);
            parent[i] = new uint256[](s + 1);
        }

        for (uint j = 0; j <= s; j++) {
            answer[0][j] = amounts[0][j];
            parent[0][j] = 0;
        }

        for (uint i = 1; i < n; i++) {
            for (uint j = 0; j <= s; j++) {
                answer[i][j] = answer[i - 1][j];
                parent[i][j] = j;

                for (uint k = 1; k <= j; k++) {
                    if (answer[i - 1][j - k] + amounts[i][k] > answer[i][j]) {
                        answer[i][j] = answer[i - 1][j - k] + amounts[i][k];
                        parent[i][j] = j - k;
                    }
                }
            }
        }

        distribution = new uint256[](DEXES_COUNT);

        uint256 partsLeft = s;
        for (uint curExchange = n - 1; partsLeft > 0; curExchange--) {
            distribution[curExchange] = partsLeft - parent[curExchange][partsLeft];
            partsLeft = parent[curExchange][partsLeft];
        }

        returnAmount = answer[n - 1][s];
    }

    function getExchangeName(uint256 i) public pure returns(string memory) {
        return [
            "Uniswap",
            "Kyber",
            "Bancor",
            "Oasis",
            "Curve Compound",
            "Curve USDT",
            "Curve Y",
            "Curve Binance",
            "CurveSynthetix",
            "Uniswap Compound",
            "Uniswap CHAI",
            "Uniswap Aave",
            "Mooniswap",
            "Uniswap V2",
            "Uniswap V2 (ETH)",
            "Uniswap V2 (DAI)",
            "Uniswap V2 (USDC)",
            "Curve Pax",
            "Curve RenBTC",
            "Curve tBTC",
            "Dforce XSwap",
            "Shell",
            "mStable"
        ][i];
    }

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        (returnAmount, , distribution) = getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            0
        );
    }

    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags, // See constants in IOneSplit.sol
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        distribution = new uint256[](DEXES_COUNT);

        if (fromToken == destToken) {
            return (amount, 0, distribution);
        }

        function(IERC20,IERC20,uint256,uint256,uint256) view returns(uint256[] memory, uint256)[DEXES_COUNT] memory reserves = _getAllReserves(flags);

        int256[][DEXES_COUNT] memory matrix;
        uint256[DEXES_COUNT] memory gases;
        for (uint i = 0; i < DEXES_COUNT; i++) {
            uint256[] memory rets;
            (rets, gases[i]) = reserves[i](fromToken, destToken, amount, parts, flags);

            // Prepend zero
            matrix[i] = new int256[](parts + 1);
            for (uint j = 0; j < parts; j++) {
                matrix[i][j + 1] = int256(rets[j]);
            }

            // Respect gas in first part
            matrix[i][1] -= int256(gases[i].mul(destTokenEthPriceTimesGasPrice).div(1e18));
        }

        (, distribution) = _findBestDistribution(parts, matrix);

        // Recalculate exact returnAmount
        for (uint i = 0; i < DEXES_COUNT; i++) {
            if (distribution[i] > 0) {
                estimateGasAmount = estimateGasAmount.add(gases[i]);
                returnAmount = returnAmount.add(
                    uint256(matrix[i][distribution[i]])
                );
                if (distribution[i] == 1) {
                    returnAmount = returnAmount.add(
                        gases[i].mul(destTokenEthPriceTimesGasPrice).div(1e18)
                    );
                }
            }
        }
    }

    function _getAllReserves(uint256 flags)
        internal
        pure
        returns(function(IERC20,IERC20,uint256,uint256,uint256) view returns(uint256[] memory, uint256)[DEXES_COUNT] memory)
    {
        bool invert = flags.check(FLAG_DISABLE_ALL_SPLIT_SOURCES);
        return [
            invert != flags.check(FLAG_DISABLE_UNISWAP)          ? _calculateNoReturn : calculateUniswapReturn,
            invert != flags.check(FLAG_DISABLE_KYBER)            ? _calculateNoReturn : calculateKyberReturn,
            invert != flags.check(FLAG_DISABLE_BANCOR)           ? _calculateNoReturn : calculateBancorReturn,
            invert != flags.check(FLAG_DISABLE_OASIS)            ? _calculateNoReturn : calculateOasisReturn,
            invert != flags.check(FLAG_DISABLE_CURVE_COMPOUND)   ? _calculateNoReturn : calculateCurveCompound,
            invert != flags.check(FLAG_DISABLE_CURVE_USDT)       ? _calculateNoReturn : calculateCurveUsdt,
            invert != flags.check(FLAG_DISABLE_CURVE_Y)          ? _calculateNoReturn : calculateCurveY,
            invert != flags.check(FLAG_DISABLE_CURVE_BINANCE)    ? _calculateNoReturn : calculateCurveBinance,
            invert != flags.check(FLAG_DISABLE_CURVE_SYNTHETIX)  ? _calculateNoReturn : calculateCurveSynthetix,
            (true) != flags.check(FLAG_ENABLE_UNISWAP_COMPOUND)  ? _calculateNoReturn : calculateUniswapCompound,
            (true) != flags.check(FLAG_ENABLE_UNISWAP_CHAI)      ? _calculateNoReturn : calculateUniswapChai,
            (true) != flags.check(FLAG_ENABLE_UNISWAP_AAVE)      ? _calculateNoReturn : calculateUniswapAave,
            invert != flags.check(FLAG_DISABLE_MOONISWAP)        ? _calculateNoReturn : calculateMooniswap,
            invert != flags.check(FLAG_DISABLE_UNISWAP_V2)       ? _calculateNoReturn : calculateUniswapV2,
            invert != flags.check(FLAG_DISABLE_UNISWAP_V2_ETH)   ? _calculateNoReturn : calculateUniswapV2ETH,
            invert != flags.check(FLAG_DISABLE_UNISWAP_V2_DAI)   ? _calculateNoReturn : calculateUniswapV2DAI,
            invert != flags.check(FLAG_DISABLE_UNISWAP_V2_USDC)  ? _calculateNoReturn : calculateUniswapV2USDC,
            invert != flags.check(FLAG_DISABLE_CURVE_PAX)        ? _calculateNoReturn : calculateCurvePax,
            invert != flags.check(FLAG_DISABLE_CURVE_RENBTC)     ? _calculateNoReturn : calculateCurveRenBtc,
            invert != flags.check(FLAG_DISABLE_CURVE_TBTC)       ? _calculateNoReturn : calculateCurveTBtc,
            invert != flags.check(FLAG_DISABLE_DFORCE_SWAP)      ? _calculateNoReturn : calculateDforceSwap,
            invert != flags.check(FLAG_DISABLE_SHELL)            ? _calculateNoReturn : calculateShell,
            invert != flags.check(FLAG_DISABLE_MSTABLE_MUSD)     ? _calculateNoReturn : calculateMStableMUSD
        ];
    }

    function _calculateNoGas(
        IERC20 /*fromToken*/,
        IERC20 /*destToken*/,
        uint256 /*amount*/,
        uint256 /*parts*/,
        uint256 /*destTokenEthPriceTimesGasPrice*/,
        uint256 /*flags*/,
        uint256 /*destTokenEthPrice*/
    ) internal view returns(uint256[] memory /*rets*/, uint256 /*gas*/) {
        this;
    }

    // View Helpers

    function _linearInterpolation(
        uint256 value,
        uint256 parts
    ) internal pure returns(uint256[] memory rets) {
        rets = new uint256[](parts);
        for (uint i = 0; i < parts; i++) {
            rets[i] = value.mul(i + 1).div(parts);
        }
    }

    function calculateMStableMUSD(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        rets = new uint256[](parts);

        if ((fromToken != usdc && fromToken != dai && fromToken != usdt && fromToken != tusd) ||
            (destToken != usdc && destToken != dai && destToken != usdt && destToken != tusd))
        {
            return (rets, 0);
        }

        for (uint i = 1; i <= parts; i *= 2) {
            (bool success, bytes memory data) = address(musd).staticcall(abi.encodeWithSelector(
                musd.getSwapOutput.selector,
                fromToken,
                destToken,
                amount.mul(parts.div(i)).div(parts)
            ));

            if (success && data.length > 0) {
                (,, uint256 maxRet) = abi.decode(data, (bool,string,uint256));
                if (maxRet > 0) {
                    for (uint j = 0; j < parts.div(i); j++) {
                        rets[j] = maxRet.mul(j + 1).div(parts.div(i));
                    }
                    break;
                }
            }
        }

        return (
            rets,
            700_000
        );
    }

    function _calculateCurveSelector(
        ICurve curve,
        bytes4 sel,
        IERC20[] memory tokens,
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets) {
        int128 i = 0;
        int128 j = 0;
        for (uint t = 0; t < tokens.length; t++) {
            if (fromToken == tokens[t]) {
                i = int128(t + 1);
            }
            if (destToken == tokens[t]) {
                j = int128(t + 1);
            }
        }

        if (i == 0 || j == 0) {
            return new uint256[](parts);
        }

        // curve.get_dy(i - 1, j - 1, amount);
        // curve.get_dy_underlying(i - 1, j - 1, amount);
        (bool success, bytes memory data) = address(curve).staticcall(abi.encodeWithSelector(sel, i - 1, j - 1, amount));
        uint256 maxRet = (!success || data.length == 0) ? 0 : abi.decode(data, (uint256));

        return _linearInterpolation(maxRet, parts);
    }

    function _calculateCurveUnderlying(
        ICurve curve,
        IERC20[] memory tokens,
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets) {
        return _calculateCurveSelector(
            curve,
            curve.get_dy_underlying.selector,
            tokens,
            fromToken,
            destToken,
            amount,
            parts,
            flags
        );
    }

    function _calculateCurve(
        ICurve curve,
        IERC20[] memory tokens,
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets) {
        return _calculateCurveSelector(
            curve,
            curve.get_dy.selector,
            tokens,
            fromToken,
            destToken,
            amount,
            parts,
            flags
        );
    }

    function calculateCurveCompound(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = dai;
        tokens[1] = usdc;
        return (_calculateCurveUnderlying(
            curveCompound,
            tokens,
            fromToken,
            destToken,
            amount,
            parts,
            flags
        ), 720_000);
    }

    function calculateCurveUsdt(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](3);
        tokens[0] = dai;
        tokens[1] = usdc;
        tokens[2] = usdt;
        return (_calculateCurveUnderlying(
            curveUsdt,
            tokens,
            fromToken,
            destToken,
            amount,
            parts,
            flags
        ), 720_000);
    }

    function calculateCurveY(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](4);
        tokens[0] = dai;
        tokens[1] = usdc;
        tokens[2] = usdt;
        tokens[3] = tusd;
        return (_calculateCurveUnderlying(
            curveY,
            tokens,
            fromToken,
            destToken,
            amount,
            parts,
            flags
        ), 1_400_000);
    }

    function calculateCurveBinance(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](4);
        tokens[0] = dai;
        tokens[1] = usdc;
        tokens[2] = usdt;
        tokens[3] = busd;
        return (_calculateCurveUnderlying(
            curveBinance,
            tokens,
            fromToken,
            destToken,
            amount,
            parts,
            flags
        ), 1_400_000);
    }

    function calculateCurveSynthetix(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](4);
        tokens[0] = dai;
        tokens[1] = usdc;
        tokens[2] = usdt;
        tokens[3] = susd;
        return (_calculateCurveUnderlying(
            curveSynthetix,
            tokens,
            fromToken,
            destToken,
            amount,
            parts,
            flags
        ), 200_000);
    }

    function calculateCurvePax(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](4);
        tokens[0] = dai;
        tokens[1] = usdc;
        tokens[2] = usdt;
        tokens[3] = pax;
        return (_calculateCurveUnderlying(
            curvePax,
            tokens,
            fromToken,
            destToken,
            amount,
            parts,
            flags
        ), 1_000_000);
    }

    function calculateCurveRenBtc(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = renbtc;
        tokens[1] = wbtc;
        return (_calculateCurve(
            curveRenBtc,
            tokens,
            fromToken,
            destToken,
            amount,
            parts,
            flags
        ), 130_000);
    }

    function calculateCurveTBtc(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](3);
        tokens[0] = tbtc;
        tokens[1] = wbtc;
        tokens[2] = hbtc;
        return (_calculateCurve(
            curveTBtc,
            tokens,
            fromToken,
            destToken,
            amount,
            parts,
            flags
        ), 145_000);
    }

    function calculateShell(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        (bool success, bytes memory data) = address(shell).staticcall(abi.encodeWithSelector(
            shell.viewOriginTrade.selector,
            fromToken,
            destToken,
            amount
        ));

        if (!success || data.length == 0) {
            return (new uint256[](parts), 0);
        }

        uint256 maxRet = abi.decode(data, (uint256));
        return (_linearInterpolation(maxRet, parts), 300_000);
    }

    function calculateDforceSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        (bool success, bytes memory data) = address(dforceSwap).staticcall(
            abi.encodeWithSelector(
                dforceSwap.getAmountByInput.selector,
                fromToken,
                destToken,
                amount
            )
        );
        if (!success || data.length == 0) {
            return (new uint256[](parts), 0);
        }

        uint256 maxRet = abi.decode(data, (uint256));
        uint256 available = destToken.universalBalanceOf(address(dforceSwap));
        if (maxRet > available) {
            return (new uint256[](parts), 0);
        }

        return (_linearInterpolation(maxRet, parts), 160_000);
    }

    function _calculateUniswapFormula(uint256 fromBalance, uint256 toBalance, uint256 amount) internal pure returns(uint256) {
        return amount.mul(toBalance).mul(997).div(
            fromBalance.mul(1000).add(amount.mul(997))
        );
    }

    function _calculateUniswapReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256[] memory amounts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        rets = amounts;

        if (!fromToken.isETH()) {
            IUniswapExchange fromExchange = uniswapFactory.getExchange(fromToken);
            if (fromExchange == IUniswapExchange(0)) {
                return (new uint256[](rets.length), 0);
            }

            uint256 fromTokenBalance = fromToken.universalBalanceOf(address(fromExchange));
            uint256 fromEtherBalance = address(fromExchange).balance;

            for (uint i = 0; i < rets.length; i++) {
                rets[i] = _calculateUniswapFormula(fromTokenBalance, fromEtherBalance, rets[i]);
            }
        }

        if (!destToken.isETH()) {
            IUniswapExchange toExchange = uniswapFactory.getExchange(destToken);
            if (toExchange == IUniswapExchange(0)) {
                return (new uint256[](rets.length), 0);
            }

            uint256 toEtherBalance = address(toExchange).balance;
            uint256 toTokenBalance = destToken.universalBalanceOf(address(toExchange));

            for (uint i = 0; i < rets.length; i++) {
                rets[i] = _calculateUniswapFormula(toEtherBalance, toTokenBalance, rets[i]);
            }
        }

        return (rets, fromToken.isETH() || destToken.isETH() ? 60_000 : 100_000);
    }

    function calculateUniswapReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        return _calculateUniswapReturn(
            fromToken,
            destToken,
            _linearInterpolation(amount, parts),
            flags
        );
    }

    function _calculateUniswapWrapped(
        IERC20 fromToken,
        IERC20 midToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 midTokenPrice,
        uint256 flags,
        uint256 gas1,
        uint256 gas2
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        if (!fromToken.isETH() && destToken.isETH()) {
            (rets, gas) = _calculateUniswapReturn(
                midToken,
                destToken,
                _linearInterpolation(amount.mul(1e18).div(midTokenPrice), parts),
                flags
            );
            return (rets, gas + gas1);
        }
        else if (fromToken.isETH() && !destToken.isETH()) {
            (rets, gas) = _calculateUniswapReturn(
                fromToken,
                midToken,
                _linearInterpolation(amount, parts),
                flags
            );

            for (uint i = 0; i < parts; i++) {
                rets[i] = rets[i].mul(midTokenPrice).div(1e18);
            }
            return (rets, gas + gas2);
        }

        return (new uint256[](parts), 0);
    }

    function calculateUniswapCompound(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20 midPreToken;
        if (!fromToken.isETH() && destToken.isETH()) {
            midPreToken = fromToken;
        }
        else if (!destToken.isETH() && fromToken.isETH()) {
            midPreToken = destToken;
        }

        if (!midPreToken.isETH()) {
            ICompoundToken midToken = _getCompoundToken(midPreToken);
            if (midToken != ICompoundToken(0)) {
                return _calculateUniswapWrapped(
                    fromToken,
                    midToken,
                    destToken,
                    amount,
                    parts,
                    midToken.exchangeRateStored(),
                    flags,
                    200_000,
                    200_000
                );
            }
        }

        return (new uint256[](parts), 0);
    }

    function calculateUniswapChai(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        if (fromToken == dai && destToken.isETH() ||
            fromToken.isETH() && destToken == dai)
        {
            return _calculateUniswapWrapped(
                fromToken,
                chai,
                destToken,
                amount,
                parts,
                chai.chaiPrice(),
                flags,
                180_000,
                160_000
            );
        }

        return (new uint256[](parts), 0);
    }

    function calculateUniswapAave(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20 midPreToken;
        if (!fromToken.isETH() && destToken.isETH()) {
            midPreToken = fromToken;
        }
        else if (!destToken.isETH() && fromToken.isETH()) {
            midPreToken = destToken;
        }

        if (!midPreToken.isETH()) {
            IAaveToken midToken = _getAaveToken(midPreToken);
            if (midToken != IAaveToken(0)) {
                return _calculateUniswapWrapped(
                    fromToken,
                    midToken,
                    destToken,
                    amount,
                    parts,
                    1e18,
                    flags,
                    310_000,
                    670_000
                );
            }
        }

        return (new uint256[](parts), 0);
    }

    function _calculateKyberReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal view returns(uint256 returnAmount, uint256 gas) {
        (bool success, bytes memory data) = address(kyberNetworkProxy).staticcall.gas(2300)(abi.encodeWithSelector(
            kyberNetworkProxy.kyberNetworkContract.selector
        ));
        if (!success || data.length == 0) {
            return (0, 0);
        }

        IKyberNetworkContract kyberNetworkContract = IKyberNetworkContract(abi.decode(data, (address)));

        if (fromToken.isETH() || destToken.isETH()) {
            return _calculateKyberReturnWithEth(kyberNetworkContract, fromToken, destToken, amount, flags);
        }

        (uint256 value, uint256 gasFee) = _calculateKyberReturnWithEth(kyberNetworkContract, fromToken, ETH_ADDRESS, amount, flags);
        if (value == 0) {
            return (0, 0);
        }

        (uint256 value2, uint256 gasFee2) =  _calculateKyberReturnWithEth(kyberNetworkContract, ETH_ADDRESS, destToken, value, flags);
        return (value2, gasFee + gasFee2);
    }

    function _calculateKyberReturnWithEth(
        IKyberNetworkContract kyberNetworkContract,
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal view returns(uint256 returnAmount, uint256 gas) {
        require(fromToken.isETH() || destToken.isETH(), "One of the tokens should be ETH");

        (bool success, bytes memory data) = address(kyberNetworkContract).staticcall.gas(1500000)(abi.encodeWithSelector(
            kyberNetworkContract.searchBestRate.selector,
            fromToken.isETH() ? ETH_ADDRESS : fromToken,
            destToken.isETH() ? ETH_ADDRESS : destToken,
            amount,
            true
        ));
        if (!success) {
            return (0, 0);
        }

        (address reserve, uint256 ret) = abi.decode(data, (address,uint256));

        if (ret == 0) {
            return (0, 0);
        }

        if ((reserve == 0x31E085Afd48a1d6e51Cc193153d625e8f0514C7F && !flags.check(FLAG_ENABLE_KYBER_UNISWAP_RESERVE)) ||
            (reserve == 0x1E158c0e93c30d24e918Ef83d1e0bE23595C3c0f && !flags.check(FLAG_ENABLE_KYBER_OASIS_RESERVE)) ||
            (reserve == 0x053AA84FCC676113a57e0EbB0bD1913839874bE4 && !flags.check(FLAG_ENABLE_KYBER_BANCOR_RESERVE)))
        {
            return (0, 0);
        }

        if (!flags.check(FLAG_ENABLE_KYBER_UNISWAP_RESERVE)) {
            (success,) = reserve.staticcall.gas(2300)(abi.encodeWithSelector(
                IKyberUniswapReserve(reserve).uniswapFactory.selector
            ));
            if (success) {
                return (0, 0);
            }
        }

        if (!flags.check(FLAG_ENABLE_KYBER_OASIS_RESERVE)) {
            (success,) = reserve.staticcall.gas(2300)(abi.encodeWithSelector(
                IKyberOasisReserve(reserve).otc.selector
            ));
            if (success) {
                return (0, 0);
            }
        }

        if (!flags.check(FLAG_ENABLE_KYBER_BANCOR_RESERVE)) {
            (success,) = reserve.staticcall.gas(2300)(abi.encodeWithSelector(
                IKyberBancorReserve(reserve).bancorEth.selector
            ));
            if (success) {
                return (0, 0);
            }
        }

        return (
            ret.mul(amount)
                .mul(10 ** IERC20(destToken).universalDecimals())
                .div(10 ** IERC20(fromToken).universalDecimals())
                .div(1e18),
            700_000
        );
    }

    function calculateKyberReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        rets = new uint256[](parts);
        for (uint i = 0; i < parts; i++) {
            (rets[i], gas) = _calculateKyberReturn(fromToken, destToken, amount.mul(i + 1).div(parts), flags);
            if (rets[i] == 0) {
                break;
            }
        }

        return (rets, gas);
    }

    function calculateBancorReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IBancorNetwork bancorNetwork = IBancorNetwork(bancorContractRegistry.addressOf("BancorNetwork"));
        address[] memory path = _buildBancorPath(fromToken, destToken);

        rets = _linearInterpolation(amount, parts);
        for (uint i = 0; i < parts; i++) {
            (bool success, bytes memory data) = address(bancorNetwork).staticcall.gas(500000)(
                abi.encodeWithSelector(
                    bancorNetwork.getReturnByPath.selector,
                    path,
                    rets[i]
                )
            );
            if (!success || data.length == 0) {
                for (; i < parts; i++) {
                    rets[i] = 0;
                }
                break;
            } else {
                (uint256 ret,) = abi.decode(data, (uint256,uint256));
                rets[i] = ret;
            }
        }

        return (rets, path.length.mul(150_000));
    }

    function calculateOasisReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        rets = _linearInterpolation(amount, parts);
        for (uint i = 0; i < parts; i++) {
            (bool success, bytes memory data) = address(oasisExchange).staticcall.gas(500000)(
                abi.encodeWithSelector(
                    oasisExchange.getBuyAmount.selector,
                    destToken.isETH() ? weth : destToken,
                    fromToken.isETH() ? weth : fromToken,
                    rets[i]
                )
            );

            if (!success || data.length == 0) {
                for (; i < parts; i++) {
                    rets[i] = 0;
                }
                break;
            } else {
                rets[i] = abi.decode(data, (uint256));
            }
        }

        return (rets, 500_000);
    }

    function calculateMooniswap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IMooniswap mooniswap = mooniswapRegistry.target();
        (bool success, bytes memory data) = address(mooniswap).staticcall.gas(1000000)(
            abi.encodeWithSelector(
                mooniswap.getReturn.selector,
                fromToken,
                destToken,
                amount
            )
        );

        if (!success || data.length == 0) {
            return (new uint256[](parts), 0);
        }

        uint256 maxRet = abi.decode(data, (uint256));
        return (_linearInterpolation(maxRet, parts), 1_000_000);
    }

    function calculateUniswapV2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        return _calculateUniswapV2(
            fromToken,
            destToken,
            _linearInterpolation(amount, parts),
            flags
        );
    }

    function calculateUniswapV2ETH(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        if (fromToken.isETH() || fromToken == weth || destToken.isETH() || destToken == weth) {
            return (new uint256[](parts), 0);
        }

        return _calculateUniswapV2OverMidToken(
            fromToken,
            weth,
            destToken,
            amount,
            parts,
            flags
        );
    }

    function calculateUniswapV2DAI(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        if (fromToken == dai || destToken == dai) {
            return (new uint256[](parts), 0);
        }

        return _calculateUniswapV2OverMidToken(
            fromToken,
            dai,
            destToken,
            amount,
            parts,
            flags
        );
    }

    function calculateUniswapV2USDC(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        if (fromToken == usdc || destToken == usdc) {
            return (new uint256[](parts), 0);
        }

        return _calculateUniswapV2OverMidToken(
            fromToken,
            usdc,
            destToken,
            amount,
            parts,
            flags
        );
    }

    function _calculateUniswapV2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256[] memory amounts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        rets = new uint256[](amounts.length);

        IERC20 fromTokenReal = fromToken.isETH() ? weth : fromToken;
        IERC20 destTokenReal = destToken.isETH() ? weth : destToken;
        IUniswapV2Exchange exchange = uniswapV2.getPair(fromTokenReal, destTokenReal);
        if (exchange != IUniswapV2Exchange(0)) {
            uint256 fromTokenBalance = fromTokenReal.universalBalanceOf(address(exchange));
            uint256 destTokenBalance = destTokenReal.universalBalanceOf(address(exchange));
            for (uint i = 0; i < amounts.length; i++) {
                rets[i] = _calculateUniswapFormula(fromTokenBalance, destTokenBalance, amounts[i]);
            }
            return (rets, 50_000);
        }
    }

    function _calculateUniswapV2OverMidToken(
        IERC20 fromToken,
        IERC20 midToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        rets = _linearInterpolation(amount, parts);

        uint256 gas1;
        uint256 gas2;
        (rets, gas1) = _calculateUniswapV2(fromToken, midToken, rets, flags);
        (rets, gas2) = _calculateUniswapV2(midToken, destToken, rets, flags);
        return (rets, gas1 + gas2);
    }

    function _calculateNoReturn(
        IERC20 /*fromToken*/,
        IERC20 /*destToken*/,
        uint256 /*amount*/,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        this;
        return (new uint256[](parts), 0);
    }
}


contract OneSplitBaseWrap is IOneSplit, OneSplitRoot {
    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags // See constants in IOneSplit.sol
    ) internal {
        if (fromToken == destToken) {
            return;
        }

        _swapFloor(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }

    function _swapFloor(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 /*flags*/ // See constants in IOneSplit.sol
    ) internal;
}


contract OneSplit is IOneSplit, OneSplitRoot {
    IOneSplitView public oneSplitView;

    constructor(IOneSplitView _oneSplitView) public {
        oneSplitView = _oneSplitView;
    }

    function() external payable {
        // solium-disable-next-line security/no-tx-origin
        require(msg.sender != tx.origin);
    }

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        (returnAmount, , distribution) = getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            0
        );
    }

    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        return oneSplitView.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*minReturn*/,
        uint256[] memory distribution,
        uint256 /*flags*/  // See constants in IOneSplit.sol
    ) public payable returns(uint256 returnAmount) {
        if (fromToken == destToken) {
            return amount;
        }

        function(IERC20,IERC20,uint256) returns(uint256)[DEXES_COUNT] memory reserves = [
            _swapOnUniswap,
            _swapOnKyber,
            _swapOnBancor,
            _swapOnOasis,
            _swapOnCurveCompound,
            _swapOnCurveUsdt,
            _swapOnCurveY,
            _swapOnCurveBinance,
            _swapOnCurveSynthetix,
            _swapOnUniswapCompound,
            _swapOnUniswapChai,
            _swapOnUniswapAave,
            _swapOnMooniswap,
            _swapOnUniswapV2,
            _swapOnUniswapV2ETH,
            _swapOnUniswapV2DAI,
            _swapOnUniswapV2USDC,
            _swapOnCurvePax,
            _swapOnCurveRenBtc,
            _swapOnCurveTBtc,
            _swapOnDforceSwap,
            _swapOnShell,
            _swapOnMStableMUSD
        ];

        require(distribution.length <= reserves.length, "OneSplit: Distribution array should not exceed reserves array size");

        uint256 parts = 0;
        uint256 lastNonZeroIndex = 0;
        for (uint i = 0; i < distribution.length; i++) {
            if (distribution[i] > 0) {
                parts = parts.add(distribution[i]);
                lastNonZeroIndex = i;
            }
        }

        require(parts > 0, "OneSplit: distribution should contain non-zeros");

        uint256 remainingAmount = amount;
        for (uint i = 0; i < distribution.length; i++) {
            if (distribution[i] == 0) {
                continue;
            }

            uint256 swapAmount = amount.mul(distribution[i]).div(parts);
            if (i == lastNonZeroIndex) {
                swapAmount = remainingAmount;
            }
            remainingAmount -= swapAmount;
            reserves[i](fromToken, destToken, swapAmount);
        }

        returnAmount = destToken.universalBalanceOf(address(this));
    }

    // Swap helpers

    function _swapOnCurveCompound(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256) {
        int128 i = (fromToken == dai ? 1 : 0) + (fromToken == usdc ? 2 : 0);
        int128 j = (destToken == dai ? 1 : 0) + (destToken == usdc ? 2 : 0);
        if (i == 0 || j == 0) {
            return 0;
        }

        fromToken.universalApprove(address(curveCompound), amount);
        curveCompound.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurveUsdt(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256) {
        int128 i = (fromToken == dai ? 1 : 0) +
            (fromToken == usdc ? 2 : 0) +
            (fromToken == usdt ? 3 : 0);
        int128 j = (destToken == dai ? 1 : 0) +
            (destToken == usdc ? 2 : 0) +
            (destToken == usdt ? 3 : 0);
        if (i == 0 || j == 0) {
            return 0;
        }

        fromToken.universalApprove(address(curveUsdt), amount);
        curveUsdt.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurveY(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256) {
        int128 i = (fromToken == dai ? 1 : 0) +
            (fromToken == usdc ? 2 : 0) +
            (fromToken == usdt ? 3 : 0) +
            (fromToken == tusd ? 4 : 0);
        int128 j = (destToken == dai ? 1 : 0) +
            (destToken == usdc ? 2 : 0) +
            (destToken == usdt ? 3 : 0) +
            (destToken == tusd ? 4 : 0);
        if (i == 0 || j == 0) {
            return 0;
        }

        fromToken.universalApprove(address(curveY), amount);
        curveY.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurveBinance(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256) {
        int128 i = (fromToken == dai ? 1 : 0) +
            (fromToken == usdc ? 2 : 0) +
            (fromToken == usdt ? 3 : 0) +
            (fromToken == busd ? 4 : 0);
        int128 j = (destToken == dai ? 1 : 0) +
            (destToken == usdc ? 2 : 0) +
            (destToken == usdt ? 3 : 0) +
            (destToken == busd ? 4 : 0);
        if (i == 0 || j == 0) {
            return 0;
        }

        fromToken.universalApprove(address(curveBinance), amount);
        curveBinance.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurveSynthetix(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256) {
        int128 i = (fromToken == dai ? 1 : 0) +
            (fromToken == usdc ? 2 : 0) +
            (fromToken == usdt ? 3 : 0) +
            (fromToken == susd ? 4 : 0);
        int128 j = (destToken == dai ? 1 : 0) +
            (destToken == usdc ? 2 : 0) +
            (destToken == usdt ? 3 : 0) +
            (destToken == susd ? 4 : 0);
        if (i == 0 || j == 0) {
            return 0;
        }

        fromToken.universalApprove(address(curveSynthetix), amount);
        curveSynthetix.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurvePax(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256) {
        int128 i = (fromToken == dai ? 1 : 0) +
            (fromToken == usdc ? 2 : 0) +
            (fromToken == usdt ? 3 : 0) +
            (fromToken == pax ? 4 : 0);
        int128 j = (destToken == dai ? 1 : 0) +
            (destToken == usdc ? 2 : 0) +
            (destToken == usdt ? 3 : 0) +
            (destToken == pax ? 4 : 0);
        if (i == 0 || j == 0) {
            return 0;
        }

        fromToken.universalApprove(address(curvePax), amount);
        curvePax.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    function _swapOnShell(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns (uint256) {
        fromToken.universalApprove(address(shell), amount);
        return shell.swapByOrigin(
            address(fromToken),
            address(destToken),
            amount,
            0,
            now + 50
        );
    }

    function _swapOnMStableMUSD(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns (uint256) {
        fromToken.universalApprove(address(musd), amount);
        return musd.swap(
            fromToken,
            destToken,
            amount,
            address(this)
        );
    }

    function _swapOnCurveRenBtc(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256) {
        int128 i = (fromToken == renbtc ? 1 : 0) +
            (fromToken == wbtc ? 2 : 0);
        int128 j = (destToken == renbtc ? 1 : 0) +
            (destToken == wbtc ? 2 : 0);
        if (i == 0 || j == 0) {
            return 0;
        }

        fromToken.universalApprove(address(curveRenBtc), amount);
        curveRenBtc.exchange(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurveTBtc(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256) {
        int128 i = (fromToken == tbtc ? 1 : 0) +
            (fromToken == wbtc ? 2 : 0) +
            (fromToken == hbtc ? 3 : 0);
        int128 j = (destToken == tbtc ? 1 : 0) +
            (destToken == wbtc ? 2 : 0) +
            (destToken == hbtc ? 3 : 0);
        if (i == 0 || j == 0) {
            return 0;
        }

        fromToken.universalApprove(address(curveTBtc), amount);
        curveTBtc.exchange(i - 1, j - 1, amount, 0);
    }

    function _swapOnDforceSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256) {
        fromToken.universalApprove(address(dforceSwap), amount);
        dforceSwap.swap(fromToken, destToken, amount);
    }

    function _swapOnUniswap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256) {

        uint256 returnAmount = amount;

        if (!fromToken.isETH()) {
            IUniswapExchange fromExchange = uniswapFactory.getExchange(fromToken);
            if (fromExchange != IUniswapExchange(0)) {
                fromToken.universalApprove(address(fromExchange), returnAmount);
                returnAmount = fromExchange.tokenToEthSwapInput(returnAmount, 1, now);
            }
        }

        if (!destToken.isETH()) {
            IUniswapExchange toExchange = uniswapFactory.getExchange(destToken);
            if (toExchange != IUniswapExchange(0)) {
                returnAmount = toExchange.ethToTokenSwapInput.value(returnAmount)(1, now);
            }
        }

        return returnAmount;
    }

    function _swapOnUniswapCompound(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256) {
        if (!fromToken.isETH()) {
            ICompoundToken fromCompound = _getCompoundToken(fromToken);
            fromToken.universalApprove(address(fromCompound), amount);
            fromCompound.mint(amount);
            return _swapOnUniswap(IERC20(fromCompound), destToken, IERC20(fromCompound).universalBalanceOf(address(this)));
        }

        if (!destToken.isETH()) {
            ICompoundToken toCompound = _getCompoundToken(destToken);
            uint256 compoundAmount = _swapOnUniswap(fromToken, IERC20(toCompound), amount);
            toCompound.redeem(compoundAmount);
            return destToken.universalBalanceOf(address(this));
        }

        return 0;
    }

    function _swapOnUniswapChai(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256) {
        if (fromToken == dai) {
            fromToken.universalApprove(address(chai), amount);
            chai.join(address(this), amount);
            return _swapOnUniswap(IERC20(chai), destToken, IERC20(chai).universalBalanceOf(address(this)));
        }

        if (destToken == dai) {
            uint256 chaiAmount = _swapOnUniswap(fromToken, IERC20(chai), amount);
            chai.exit(address(this), chaiAmount);
            return destToken.universalBalanceOf(address(this));
        }

        return 0;
    }

    function _swapOnUniswapAave(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256) {
        if (!fromToken.isETH()) {
            IAaveToken fromAave = _getAaveToken(fromToken);
            fromToken.universalApprove(aave.core(), amount);
            aave.deposit(fromToken, amount, 1101);
            return _swapOnUniswap(IERC20(fromAave), destToken, IERC20(fromAave).universalBalanceOf(address(this)));
        }

        if (!destToken.isETH()) {
            IAaveToken toAave = _getAaveToken(destToken);
            uint256 aaveAmount = _swapOnUniswap(fromToken, IERC20(toAave), amount);
            toAave.redeem(aaveAmount);
            return aaveAmount;
        }

        return 0;
    }

    function _swapOnMooniswap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256) {
        IMooniswap mooniswap = mooniswapRegistry.target();
        fromToken.universalApprove(address(mooniswap), amount);
        return mooniswap.swap.value(fromToken.isETH() ? amount : 0)(
            fromToken,
            destToken,
            amount,
            0
        );
    }

    function _swapOnKyber(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256) {
        fromToken.universalApprove(address(kyberNetworkProxy), amount);
        return kyberNetworkProxy.tradeWithHint.value(fromToken.isETH() ? amount : 0)(
            fromToken.isETH() ? ETH_ADDRESS : fromToken,
            amount,
            destToken.isETH() ? ETH_ADDRESS : destToken,
            address(this),
            1 << 255,
            0,
            0x4D37f28D2db99e8d35A6C725a5f1749A085850a3,
            ""
        );
    }

    function _swapOnBancor(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256) {
        IBancorNetwork bancorNetwork = IBancorNetwork(bancorContractRegistry.addressOf("BancorNetwork"));
        address[] memory path = _buildBancorPath(fromToken, destToken);
        return bancorNetwork.convert.value(fromToken.isETH() ? amount : 0)(path, amount, 1);
    }

    function _swapOnOasis(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256) {
        if (fromToken.isETH()) {
            weth.deposit.value(amount)();
        }

        IERC20 approveToken = fromToken.isETH() ? weth : fromToken;
        approveToken.universalApprove(address(oasisExchange), amount);
        uint256 returnAmount = oasisExchange.sellAllAmount(
            fromToken.isETH() ? weth : fromToken,
            amount,
            destToken.isETH() ? weth : destToken,
            1
        );

        if (destToken.isETH()) {
            weth.withdraw(weth.balanceOf(address(this)));
        }

        return returnAmount;
    }

    function _swapOnUniswapV2Internal(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256 returnAmount) {
        if (fromToken.isETH()) {
            weth.deposit.value(amount)();
        }

        IERC20 fromTokenReal = fromToken.isETH() ? weth : fromToken;
        IERC20 toTokenReal = destToken.isETH() ? weth : destToken;
        IUniswapV2Exchange exchange = uniswapV2.getPair(fromTokenReal, toTokenReal);
        returnAmount = exchange.getReturn(fromTokenReal, toTokenReal, amount);

        fromTokenReal.universalTransfer(address(exchange), amount);
        if (uint256(address(fromTokenReal)) < uint256(address(toTokenReal))) {
            exchange.swap(0, returnAmount, address(this), "");
        } else {
            exchange.swap(returnAmount, 0, address(this), "");
        }

        if (destToken.isETH()) {
            weth.withdraw(weth.balanceOf(address(this)));
        }
    }

    function _swapOnUniswapV2OverMid(
        IERC20 fromToken,
        IERC20 midToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256) {
        return _swapOnUniswapV2Internal(
            midToken,
            destToken,
            _swapOnUniswapV2Internal(
                fromToken,
                midToken,
                amount
            )
        );
    }

    function _swapOnUniswapV2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256) {
        return _swapOnUniswapV2Internal(
            fromToken,
            destToken,
            amount
        );
    }

    function _swapOnUniswapV2ETH(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256) {
        return _swapOnUniswapV2OverMid(
            fromToken,
            weth,
            destToken,
            amount
        );
    }

    function _swapOnUniswapV2DAI(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256) {
        return _swapOnUniswapV2OverMid(
            fromToken,
            dai,
            destToken,
            amount
        );
    }

    function _swapOnUniswapV2USDC(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256) {
        return _swapOnUniswapV2OverMid(
            fromToken,
            usdc,
            destToken,
            amount
        );
    }
}

// File: contracts/OneSplitMultiPath.sol

pragma solidity ^0.5.0;



contract OneSplitMultiPathBase is IOneSplitConsts, OneSplitRoot {
    function _getMultiPathToken(uint256 flags) internal pure returns(IERC20 midToken) {
        uint256[7] memory allFlags = [
            FLAG_ENABLE_MULTI_PATH_ETH,
            FLAG_ENABLE_MULTI_PATH_DAI,
            FLAG_ENABLE_MULTI_PATH_USDC,
            FLAG_ENABLE_MULTI_PATH_USDT,
            FLAG_ENABLE_MULTI_PATH_WBTC,
            FLAG_ENABLE_MULTI_PATH_TBTC,
            FLAG_ENABLE_MULTI_PATH_RENBTC
        ];

        IERC20[7] memory allMidTokens = [
            ETH_ADDRESS,
            dai,
            usdc,
            usdt,
            wbtc,
            tbtc,
            renbtc
        ];

        for (uint i = 0; i < allFlags.length; i++) {
            if (flags.check(allFlags[i])) {
                require(midToken == IERC20(0), "OneSplit: Do not use multipath with each other");
                midToken = allMidTokens[i];
            }
        }
    }
}


contract OneSplitMultiPathView is OneSplitViewWrapBase, OneSplitMultiPathBase {
    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns (
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == destToken) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }

        IERC20 midToken = _getMultiPathToken(flags);

        if (midToken != IERC20(0)) {
            if ((fromToken.isETH() && midToken.isETH()) ||
                (destToken.isETH() && midToken.isETH()) ||
                fromToken == midToken ||
                destToken == midToken)
            {
                return super.getExpectedReturnWithGas(
                    fromToken,
                    destToken,
                    amount,
                    parts,
                    flags,
                    destTokenEthPriceTimesGasPrice
                );
            }

            // Stack too deep
            uint256 _flags = flags;

            (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                fromToken,
                midToken,
                amount,
                parts,
                _flags | FLAG_DISABLE_BANCOR | FLAG_DISABLE_CURVE_COMPOUND | FLAG_DISABLE_CURVE_USDT | FLAG_DISABLE_CURVE_Y | FLAG_DISABLE_CURVE_BINANCE | FLAG_DISABLE_CURVE_PAX,
                destTokenEthPriceTimesGasPrice
            );

            uint256[] memory dist;
            uint256 estimateGasAmount2;
            (returnAmount, estimateGasAmount2, dist) = super.getExpectedReturnWithGas(
                midToken,
                destToken,
                returnAmount,
                parts,
                _flags | FLAG_DISABLE_BANCOR | FLAG_DISABLE_CURVE_COMPOUND | FLAG_DISABLE_CURVE_USDT | FLAG_DISABLE_CURVE_Y | FLAG_DISABLE_CURVE_BINANCE | FLAG_DISABLE_CURVE_PAX,
                destTokenEthPriceTimesGasPrice
            );
            for (uint i = 0; i < distribution.length; i++) {
                distribution[i] = distribution[i].add(dist[i] << 8);
            }
            return (returnAmount, estimateGasAmount + estimateGasAmount2, distribution);
        }

        return super.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }
}


contract OneSplitMultiPath is OneSplitBaseWrap, OneSplitMultiPathBase {
    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        IERC20 midToken = _getMultiPathToken(flags);

        if (midToken != IERC20(0)) {
            uint256[] memory dist = new uint256[](distribution.length);
            for (uint i = 0; i < distribution.length; i++) {
                dist[i] = distribution[i] & 0xFF;
            }
            super._swap(
                fromToken,
                midToken,
                amount,
                dist,
                flags
            );

            for (uint i = 0; i < distribution.length; i++) {
                dist[i] = (distribution[i] >> 8) & 0xFF;
            }
            super._swap(
                midToken,
                destToken,
                midToken.universalBalanceOf(address(this)),
                dist,
                flags
            );
            return;
        }

        super._swap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }
}

// File: contracts/OneSplitCompound.sol

pragma solidity ^0.5.0;




contract OneSplitCompoundBase {
    function _getCompoundUnderlyingToken(IERC20 token) internal pure returns(IERC20) {
        if (token == IERC20(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5)) { // ETH
            return IERC20(0);
        }
        if (token == IERC20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643)) { // DAI
            return IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        }
        if (token == IERC20(0x6C8c6b02E7b2BE14d4fA6022Dfd6d75921D90E4E)) { // BAT
            return IERC20(0x0D8775F648430679A709E98d2b0Cb6250d2887EF);
        }
        if (token == IERC20(0x158079Ee67Fce2f58472A96584A73C7Ab9AC95c1)) { // REP
            return IERC20(0x1985365e9f78359a9B6AD760e32412f4a445E862);
        }
        if (token == IERC20(0x39AA39c021dfbaE8faC545936693aC917d5E7563)) { // USDC
            return IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        }
        if (token == IERC20(0xC11b1268C1A384e55C48c2391d8d480264A3A7F4)) { // WBTC
            return IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
        }
        if (token == IERC20(0xB3319f5D18Bc0D84dD1b4825Dcde5d5f7266d407)) { // ZRX
            return IERC20(0xE41d2489571d322189246DaFA5ebDe1F4699F498);
        }
        if (token == IERC20(0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9)) { // USDT
            return IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        }

        return IERC20(-1);
    }
}


contract OneSplitCompoundView is OneSplitViewWrapBase, OneSplitCompoundBase {
    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        return _compoundGetExpectedReturn(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function _compoundGetExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        private
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == destToken) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_COMPOUND)) {
            IERC20 underlying = _getCompoundUnderlyingToken(fromToken);
            if (underlying != IERC20(-1)) {
                uint256 compoundRate = ICompoundToken(address(fromToken)).exchangeRateStored();
                (returnAmount, estimateGasAmount, distribution) = _compoundGetExpectedReturn(
                    underlying,
                    destToken,
                    amount.mul(compoundRate).div(1e18),
                    parts,
                    flags,
                    destTokenEthPriceTimesGasPrice
                );
                return (returnAmount, estimateGasAmount + 295_000, distribution);
            }

            underlying = _getCompoundUnderlyingToken(destToken);
            if (underlying != IERC20(-1)) {
                uint256 compoundRate = ICompoundToken(address(destToken)).exchangeRateStored();
                (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                    fromToken,
                    underlying,
                    amount,
                    parts,
                    flags,
                    destTokenEthPriceTimesGasPrice
                );
                return (returnAmount.mul(1e18).div(compoundRate), estimateGasAmount + 430_000, distribution);
            }
        }

        return super.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }
}


contract OneSplitCompound is OneSplitBaseWrap, OneSplitCompoundBase {
    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        _compundSwap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }

    function _compundSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {
        if (fromToken == destToken) {
            return;
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_COMPOUND)) {
            IERC20 underlying = _getCompoundUnderlyingToken(fromToken);
            if (underlying != IERC20(-1)) {
                ICompoundToken(address(fromToken)).redeem(amount);
                uint256 underlyingAmount = underlying.universalBalanceOf(address(this));

                return _compundSwap(
                    underlying,
                    destToken,
                    underlyingAmount,
                    distribution,
                    flags
                );
            }

            underlying = _getCompoundUnderlyingToken(destToken);
            if (underlying != IERC20(-1)) {
                super._swap(
                    fromToken,
                    underlying,
                    amount,
                    distribution,
                    flags
                );

                uint256 underlyingAmount = underlying.universalBalanceOf(address(this));

                if (underlying.isETH()) {
                    cETH.mint.value(underlyingAmount)();
                } else {
                    underlying.universalApprove(address(destToken), underlyingAmount);
                    ICompoundToken(address(destToken)).mint(underlyingAmount);
                }
                return;
            }
        }

        return super._swap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.5.0;


/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: contracts/interface/IFulcrum.sol

pragma solidity ^0.5.0;



contract IFulcrumToken is IERC20 {
    function tokenPrice() external view returns (uint256);

    function loanTokenAddress() external view returns (address);

    function mintWithEther(address receiver) external payable returns (uint256 mintAmount);

    function mint(address receiver, uint256 depositAmount) external returns (uint256 mintAmount);

    function burnToEther(address receiver, uint256 burnAmount)
        external
        returns (uint256 loanAmountPaid);

    function burn(address receiver, uint256 burnAmount) external returns (uint256 loanAmountPaid);
}

// File: contracts/OneSplitFulcrum.sol

pragma solidity ^0.5.0;





contract OneSplitFulcrumBase {
    using UniversalERC20 for IERC20;

    function _isFulcrumToken(IERC20 token) public view returns(IERC20) {
        if (token.isETH()) {
            return IERC20(-1);
        }

        (bool success, bytes memory data) = address(token).staticcall.gas(5000)(abi.encodeWithSelector(
            ERC20Detailed(address(token)).name.selector
        ));
        if (!success) {
            return IERC20(-1);
        }

        bool foundBZX = false;
        for (uint i = 0; i + 6 < data.length; i++) {
            if (data[i + 0] == "F" &&
                data[i + 1] == "u" &&
                data[i + 2] == "l" &&
                data[i + 3] == "c" &&
                data[i + 4] == "r" &&
                data[i + 5] == "u" &&
                data[i + 6] == "m")
            {
                foundBZX = true;
                break;
            }
        }
        if (!foundBZX) {
            return IERC20(-1);
        }

        (success, data) = address(token).staticcall.gas(5000)(abi.encodeWithSelector(
            IFulcrumToken(address(token)).loanTokenAddress.selector
        ));
        if (!success) {
            return IERC20(-1);
        }

        return abi.decode(data, (IERC20));
    }
}


contract OneSplitFulcrumView is OneSplitViewWrapBase, OneSplitFulcrumBase {
    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        return _fulcrumGetExpectedReturn(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function _fulcrumGetExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        private
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == destToken) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_FULCRUM)) {
            IERC20 underlying = _isFulcrumToken(fromToken);
            if (underlying != IERC20(-1)) {
                uint256 fulcrumRate = IFulcrumToken(address(fromToken)).tokenPrice();
                (returnAmount, estimateGasAmount, distribution) = _fulcrumGetExpectedReturn(
                    underlying,
                    destToken,
                    amount.mul(fulcrumRate).div(1e18),
                    parts,
                    flags,
                    destTokenEthPriceTimesGasPrice
                );
                return (returnAmount, estimateGasAmount + 381_000, distribution);
            }

            underlying = _isFulcrumToken(destToken);
            if (underlying != IERC20(-1)) {
                uint256 fulcrumRate = IFulcrumToken(address(destToken)).tokenPrice();
                (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                    fromToken,
                    underlying,
                    amount,
                    parts,
                    flags,
                    destTokenEthPriceTimesGasPrice
                );
                return (returnAmount.mul(1e18).div(fulcrumRate), estimateGasAmount + 354_000, distribution);
            }
        }

        return super.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }
}


contract OneSplitFulcrum is OneSplitBaseWrap, OneSplitFulcrumBase {
    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        _fulcrumSwap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }

    function _fulcrumSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {
        if (fromToken == destToken) {
            return;
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_FULCRUM)) {
            IERC20 underlying = _isFulcrumToken(fromToken);
            if (underlying != IERC20(-1)) {
                if (underlying.isETH()) {
                    IFulcrumToken(address(fromToken)).burnToEther(address(this), amount);
                } else {
                    IFulcrumToken(address(fromToken)).burn(address(this), amount);
                }

                uint256 underlyingAmount = underlying.universalBalanceOf(address(this));

                return super._swap(
                    underlying,
                    destToken,
                    underlyingAmount,
                    distribution,
                    flags
                );
            }

            underlying = _isFulcrumToken(destToken);
            if (underlying != IERC20(-1)) {
                super._swap(
                    fromToken,
                    underlying,
                    amount,
                    distribution,
                    flags
                );

                uint256 underlyingAmount = underlying.universalBalanceOf(address(this));

                if (underlying.isETH()) {
                    IFulcrumToken(address(destToken)).mintWithEther.value(underlyingAmount)(address(this));
                } else {
                    underlying.universalApprove(address(destToken), underlyingAmount);
                    IFulcrumToken(address(destToken)).mint(address(this), underlyingAmount);
                }
                return;
            }
        }

        return super._swap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }
}

// File: contracts/OneSplitChai.sol

pragma solidity ^0.5.0;




contract OneSplitChaiView is OneSplitViewWrapBase {
    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == destToken) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_CHAI)) {
            if (fromToken == IERC20(chai)) {
                (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                    dai,
                    destToken,
                    chai.chaiToDai(amount),
                    parts,
                    flags,
                    destTokenEthPriceTimesGasPrice
                );
                return (returnAmount, estimateGasAmount + 197_000, distribution);
            }

            if (destToken == IERC20(chai)) {
                (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                    fromToken,
                    dai,
                    amount,
                    parts,
                    flags,
                    destTokenEthPriceTimesGasPrice
                );
                return (chai.daiToChai(returnAmount), estimateGasAmount + 168_000, distribution);
            }
        }

        return super.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }
}


contract OneSplitChai is OneSplitBaseWrap {
    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        if (fromToken == destToken) {
            return;
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_CHAI)) {
            if (fromToken == IERC20(chai)) {
                chai.exit(address(this), amount);

                return super._swap(
                    dai,
                    destToken,
                    dai.balanceOf(address(this)),
                    distribution,
                    flags
                );
            }

            if (destToken == IERC20(chai)) {
                super._swap(
                    fromToken,
                    dai,
                    amount,
                    distribution,
                    flags
                );

                uint256 daiBalance = dai.balanceOf(address(this));
                dai.universalApprove(address(chai), daiBalance);
                chai.join(address(this), daiBalance);
                return;
            }
        }

        return super._swap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }
}

// File: contracts/interface/IBdai.sol

pragma solidity ^0.5.0;



contract IBdai is IERC20 {
    function join(uint256) external;

    function exit(uint256) external;
}

// File: contracts/OneSplitBdai.sol

pragma solidity ^0.5.0;




contract OneSplitBdaiBase {
    IBdai public bdai = IBdai(0x6a4FFAafa8DD400676Df8076AD6c724867b0e2e8);
    IERC20 public btu = IERC20(0xb683D83a532e2Cb7DFa5275eED3698436371cc9f);
}


contract OneSplitBdaiView is OneSplitViewWrapBase, OneSplitBdaiBase {
    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == destToken) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_BDAI)) {
            if (fromToken == IERC20(bdai)) {
                (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                    dai,
                    destToken,
                    amount,
                    parts,
                    flags,
                    destTokenEthPriceTimesGasPrice
                );
                return (returnAmount, estimateGasAmount + 227_000, distribution);
            }

            if (destToken == IERC20(bdai)) {
                (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                    fromToken,
                    dai,
                    amount,
                    parts,
                    flags,
                    destTokenEthPriceTimesGasPrice
                );
                return (returnAmount, estimateGasAmount + 295_000, distribution);
            }
        }

        return super.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }
}


contract OneSplitBdai is OneSplitBaseWrap, OneSplitBdaiBase {
    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        if (fromToken == destToken) {
            return;
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_BDAI)) {
            if (fromToken == IERC20(bdai)) {
                bdai.exit(amount);

                uint256 btuBalance = btu.balanceOf(address(this));
                if (btuBalance > 0) {
                    (,uint256[] memory btuDistribution) = getExpectedReturn(
                        btu,
                        destToken,
                        btuBalance,
                        1,
                        flags
                    );

                    _swap(
                        btu,
                        destToken,
                        btuBalance,
                        btuDistribution,
                        flags
                    );
                }

                return super._swap(
                    dai,
                    destToken,
                    amount,
                    distribution,
                    flags
                );
            }

            if (destToken == IERC20(bdai)) {
                super._swap(fromToken, dai, amount, distribution, flags);

                uint256 daiBalance = dai.balanceOf(address(this));
                dai.universalApprove(address(bdai), daiBalance);
                bdai.join(daiBalance);
                return;
            }
        }

        return super._swap(fromToken, destToken, amount, distribution, flags);
    }
}

// File: contracts/interface/IIearn.sol

pragma solidity ^0.5.0;



contract IIearn is IERC20 {
    function token() external view returns(IERC20);

    function calcPoolValueInToken() external view returns(uint256);

    function deposit(uint256 _amount) external;

    function withdraw(uint256 _shares) external;
}

// File: contracts/OneSplitIearn.sol

pragma solidity ^0.5.0;




contract OneSplitIearnBase {
    function _yTokens() internal pure returns(IIearn[13] memory) {
        return [
            IIearn(0x16de59092dAE5CcF4A1E6439D611fd0653f0Bd01),
            IIearn(0x04Aa51bbcB46541455cCF1B8bef2ebc5d3787EC9),
            IIearn(0x73a052500105205d34Daf004eAb301916DA8190f),
            IIearn(0x83f798e925BcD4017Eb265844FDDAbb448f1707D),
            IIearn(0xd6aD7a6750A7593E092a9B218d66C0A814a3436e),
            IIearn(0xF61718057901F84C4eEC4339EF8f0D86D2B45600),
            IIearn(0x04bC0Ab673d88aE9dbC9DA2380cB6B79C4BCa9aE),
            IIearn(0xC2cB1040220768554cf699b0d863A3cd4324ce32),
            IIearn(0xE6354ed5bC4b393a5Aad09f21c46E101e692d447),
            IIearn(0x26EA744E5B887E5205727f55dFBE8685e3b21951),
            IIearn(0x99d1Fa417f94dcD62BfE781a1213c092a47041Bc),
            IIearn(0x9777d7E2b60bB01759D0E2f8be2095df444cb07E),
            IIearn(0x1bE5d71F2dA660BFdee8012dDc58D024448A0A59)
        ];
    }
}


contract OneSplitIearnView is OneSplitViewWrapBase, OneSplitIearnBase {
    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        return _iearnGetExpectedReturn(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function _iearnGetExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        private
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == destToken) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }

        if (!flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == !flags.check(FLAG_DISABLE_IEARN)) {
            IIearn[13] memory yTokens = _yTokens();

            for (uint i = 0; i < yTokens.length; i++) {
                if (fromToken == IERC20(yTokens[i])) {
                    (returnAmount, estimateGasAmount, distribution) = _iearnGetExpectedReturn(
                        yTokens[i].token(),
                        destToken,
                        amount
                            .mul(yTokens[i].calcPoolValueInToken())
                            .div(yTokens[i].totalSupply()),
                        parts,
                        flags,
                        destTokenEthPriceTimesGasPrice
                    );
                    return (returnAmount, estimateGasAmount + 260_000, distribution);
                }
            }

            for (uint i = 0; i < yTokens.length; i++) {
                if (destToken == IERC20(yTokens[i])) {
                    (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                        fromToken,
                        yTokens[i].token(),
                        amount,
                        parts,
                        flags,
                        destTokenEthPriceTimesGasPrice
                    );

                    return(
                        returnAmount
                            .mul(yTokens[i].totalSupply())
                            .div(yTokens[i].calcPoolValueInToken()),
                        estimateGasAmount + 743_000,
                        distribution
                    );
                }
            }
        }

        return super.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }
}


contract OneSplitIearn is OneSplitBaseWrap, OneSplitIearnBase {
    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        _iearnSwap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }

    function _iearnSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {
        if (fromToken == destToken) {
            return;
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_IEARN)) {
            IIearn[13] memory yTokens = _yTokens();

            for (uint i = 0; i < yTokens.length; i++) {
                if (fromToken == IERC20(yTokens[i])) {
                    IERC20 underlying = yTokens[i].token();
                    yTokens[i].withdraw(amount);
                    _iearnSwap(underlying, destToken, underlying.balanceOf(address(this)), distribution, flags);
                    return;
                }
            }

            for (uint i = 0; i < yTokens.length; i++) {
                if (destToken == IERC20(yTokens[i])) {
                    IERC20 underlying = yTokens[i].token();
                    super._swap(fromToken, underlying, amount, distribution, flags);

                    uint256 underlyingBalance = underlying.balanceOf(address(this));
                    underlying.universalApprove(address(yTokens[i]), underlyingBalance);
                    yTokens[i].deposit(underlyingBalance);
                    return;
                }
            }
        }

        return super._swap(fromToken, destToken, amount, distribution, flags);
    }
}

// File: contracts/interface/IIdle.sol

pragma solidity ^0.5.0;



contract IIdle is IERC20 {
    function token()
        external view returns (IERC20);

    function tokenPrice()
        external view returns (uint256);

    function mintIdleToken(uint256 _amount, uint256[] calldata _clientProtocolAmounts)
        external returns (uint256 mintedTokens);

    function redeemIdleToken(uint256 _amount, bool _skipRebalance, uint256[] calldata _clientProtocolAmounts)
        external returns (uint256 redeemedTokens);
}

// File: contracts/OneSplitIdle.sol

pragma solidity ^0.5.0;




contract OneSplitIdleBase {
    function _idleTokens() internal pure returns(IIdle[8] memory) {
        // https://developers.idle.finance/contracts-and-codebase
        return [
            // V3
            IIdle(0x78751B12Da02728F467A44eAc40F5cbc16Bd7934),
            IIdle(0x12B98C621E8754Ae70d0fDbBC73D6208bC3e3cA6),
            IIdle(0x63D27B3DA94A9E871222CB0A32232674B02D2f2D),
            IIdle(0x1846bdfDB6A0f5c473dEc610144513bd071999fB),
            IIdle(0xcDdB1Bceb7a1979C6caa0229820707429dd3Ec6C),
            IIdle(0x42740698959761BAF1B06baa51EfBD88CB1D862B),
            // V2
            IIdle(0x10eC0D497824e342bCB0EDcE00959142aAa766dD),
            IIdle(0xeB66ACc3d011056B00ea521F8203580C2E5d3991)
        ];
    }
}


contract OneSplitIdleView is OneSplitViewWrapBase, OneSplitIdleBase {
    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        return _idleGetExpectedReturn(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function _idleGetExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        internal
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == destToken) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }

        if (!flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == !flags.check(FLAG_DISABLE_IDLE)) {
            IIdle[8] memory tokens = _idleTokens();

            for (uint i = 0; i < tokens.length; i++) {
                if (fromToken == IERC20(tokens[i])) {
                    (returnAmount, estimateGasAmount, distribution) = _idleGetExpectedReturn(
                        tokens[i].token(),
                        destToken,
                        amount.mul(tokens[i].tokenPrice()).div(1e18),
                        parts,
                        flags,
                        destTokenEthPriceTimesGasPrice
                    );
                    return (returnAmount, estimateGasAmount + 2_400_000, distribution);
                }
            }

            for (uint i = 0; i < tokens.length; i++) {
                if (destToken == IERC20(tokens[i])) {
                    (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                        fromToken,
                        tokens[i].token(),
                        amount,
                        parts,
                        flags,
                        destTokenEthPriceTimesGasPrice
                    );
                    return (returnAmount.mul(1e18).div(tokens[i].tokenPrice()), estimateGasAmount + 1_300_000, distribution);
                }
            }
        }

        return super.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }
}


contract OneSplitIdle is OneSplitBaseWrap, OneSplitIdleBase {
    function _superOneSplitIdleSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] calldata distribution,
        uint256 flags
    )
        external
    {
        require(msg.sender == address(this));
        return super._swap(fromToken, destToken, amount, distribution, flags);
    }

    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        _idleSwap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }

    function _idleSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) public payable {
        if (!flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == !flags.check(FLAG_DISABLE_IDLE)) {
            IIdle[8] memory tokens = _idleTokens();

            for (uint i = 0; i < tokens.length; i++) {
                if (fromToken == IERC20(tokens[i])) {
                    IERC20 underlying = tokens[i].token();
                    uint256 minted = tokens[i].redeemIdleToken(amount, true, new uint256[](0));
                    _idleSwap(underlying, destToken, minted, distribution, flags);
                    return;
                }
            }

            for (uint i = 0; i < tokens.length; i++) {
                if (destToken == IERC20(tokens[i])) {
                    IERC20 underlying = tokens[i].token();
                    super._swap(fromToken, underlying, amount, distribution, flags);

                    uint256 underlyingBalance = underlying.balanceOf(address(this));
                    underlying.universalApprove(address(tokens[i]), underlyingBalance);
                    tokens[i].mintIdleToken(underlyingBalance, new uint256[](0));
                    return;
                }
            }
        }

        return super._swap(fromToken, destToken, amount, distribution, flags);
    }
}

// File: contracts/OneSplitAave.sol

pragma solidity ^0.5.0;





contract OneSplitAaveBase {
    function _getAaveUnderlyingToken(IERC20 token) internal pure returns(IERC20) {
        if (token == IERC20(0x3a3A65aAb0dd2A17E3F1947bA16138cd37d08c04)) { // ETH
            return IERC20(0);
        }
        if (token == IERC20(0xfC1E690f61EFd961294b3e1Ce3313fBD8aa4f85d)) { // DAI
            return IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        }
        if (token == IERC20(0x9bA00D6856a4eDF4665BcA2C2309936572473B7E)) { // USDC
            return IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        }
        if (token == IERC20(0x625aE63000f46200499120B906716420bd059240)) { // SUSD
            return IERC20(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
        }
        if (token == IERC20(0x6Ee0f7BB50a54AB5253dA0667B0Dc2ee526C30a8)) { // BUSD
            return IERC20(0x4Fabb145d64652a948d72533023f6E7A623C7C53);
        }
        if (token == IERC20(0x4DA9b813057D04BAef4e5800E36083717b4a0341)) { // TUSD
            return IERC20(0x0000000000085d4780B73119b644AE5ecd22b376);
        }
        if (token == IERC20(0x71fc860F7D3A592A4a98740e39dB31d25db65ae8)) { // USDT
            return IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        }
        if (token == IERC20(0xE1BA0FB44CCb0D11b80F92f4f8Ed94CA3fF51D00)) { // BAT
            return IERC20(0x0D8775F648430679A709E98d2b0Cb6250d2887EF);
        }
        if (token == IERC20(0x9D91BE44C06d373a8a226E1f3b146956083803eB)) { // KNC
            return IERC20(0xdd974D5C2e2928deA5F71b9825b8b646686BD200);
        }
        if (token == IERC20(0x7D2D3688Df45Ce7C552E19c27e007673da9204B8)) { // LEND
            return IERC20(0x80fB784B7eD66730e8b1DBd9820aFD29931aab03);
        }
        if (token == IERC20(0xA64BD6C70Cb9051F6A9ba1F163Fdc07E0DfB5F84)) { // LINK
            return IERC20(0x514910771AF9Ca656af840dff83E8264EcF986CA);
        }
        if (token == IERC20(0x6FCE4A401B6B80ACe52baAefE4421Bd188e76F6f)) { // MANA
            return IERC20(0x0F5D2fB29fb7d3CFeE444a200298f468908cC942);
        }
        if (token == IERC20(0x7deB5e830be29F91E298ba5FF1356BB7f8146998)) { // MKR
            return IERC20(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
        }
        if (token == IERC20(0x71010A9D003445aC60C4e6A7017c1E89A477B438)) { // REP
            return IERC20(0x1985365e9f78359a9B6AD760e32412f4a445E862);
        }
        if (token == IERC20(0x328C4c80BC7aCa0834Db37e6600A6c49E12Da4DE)) { // SNX
            return IERC20(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F);
        }
        if (token == IERC20(0xFC4B8ED459e00e5400be803A9BB3954234FD50e3)) { // WBTC
            return IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
        }
        if (token == IERC20(0x6Fb0855c404E09c47C3fBCA25f08d4E41f9F062f)) { // ZRX
            return IERC20(0xE41d2489571d322189246DaFA5ebDe1F4699F498);
        }

        return IERC20(-1);
    }
}


contract OneSplitAaveView is OneSplitViewWrapBase, OneSplitAaveBase {
    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags, // See constants in IOneSplit.sol
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        return _aaveGetExpectedReturn(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function _aaveGetExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        private
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == destToken) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_AAVE)) {
            IERC20 underlying = _getAaveUnderlyingToken(fromToken);
            if (underlying != IERC20(-1)) {
                (returnAmount, estimateGasAmount, distribution) = _aaveGetExpectedReturn(
                    underlying,
                    destToken,
                    amount,
                    parts,
                    flags,
                    destTokenEthPriceTimesGasPrice
                );
                return (returnAmount, estimateGasAmount + 670_000, distribution);
            }

            underlying = _getAaveUnderlyingToken(destToken);
            if (underlying != IERC20(-1)) {
                (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                    fromToken,
                    underlying,
                    amount,
                    parts,
                    flags,
                    destTokenEthPriceTimesGasPrice
                );
                return (returnAmount, estimateGasAmount + 310_000, distribution);
            }
        }

        return super.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }
}


contract OneSplitAave is OneSplitBaseWrap, OneSplitAaveBase {
    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        _aaveSwap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }

    function _aaveSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {
        if (fromToken == destToken) {
            return;
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_AAVE)) {
            IERC20 underlying = _getAaveUnderlyingToken(fromToken);
            if (underlying != IERC20(-1)) {
                IAaveToken(address(fromToken)).redeem(amount);

                return _aaveSwap(
                    underlying,
                    destToken,
                    amount,
                    distribution,
                    flags
                );
            }

            underlying = _getAaveUnderlyingToken(destToken);
            if (underlying != IERC20(-1)) {
                super._swap(
                    fromToken,
                    underlying,
                    amount,
                    distribution,
                    flags
                );

                uint256 underlyingAmount = underlying.universalBalanceOf(address(this));

                underlying.universalApprove(aave.core(), underlyingAmount);
                aave.deposit.value(underlying.isETH() ? underlyingAmount : 0)(
                    underlying.isETH() ? ETH_ADDRESS : underlying,
                    underlyingAmount,
                    1101
                );
                return;
            }
        }

        return super._swap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }
}

// File: contracts/OneSplitWeth.sol

pragma solidity ^0.5.0;




contract OneSplitWethView is OneSplitViewWrapBase {
    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        return _wethGetExpectedReturn(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function _wethGetExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        private
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == destToken) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_WETH)) {
            if (fromToken == weth || fromToken == bancorEtherToken) {
                return super.getExpectedReturnWithGas(ETH_ADDRESS, destToken, amount, parts, flags, destTokenEthPriceTimesGasPrice);
            }

            if (destToken == weth || destToken == bancorEtherToken) {
                return super.getExpectedReturnWithGas(fromToken, ETH_ADDRESS, amount, parts, flags, destTokenEthPriceTimesGasPrice);
            }
        }

        return super.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }
}


contract OneSplitWeth is OneSplitBaseWrap {
    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        _wethSwap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }

    function _wethSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {
        if (fromToken == destToken) {
            return;
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_WETH)) {
            if (fromToken == weth) {
                weth.withdraw(weth.balanceOf(address(this)));
                super._swap(
                    ETH_ADDRESS,
                    destToken,
                    amount,
                    distribution,
                    flags
                );
                return;
            }

            if (fromToken == bancorEtherToken) {
                bancorEtherToken.withdraw(bancorEtherToken.balanceOf(address(this)));
                super._swap(
                    ETH_ADDRESS,
                    destToken,
                    amount,
                    distribution,
                    flags
                );
                return;
            }

            if (destToken == weth) {
                _wethSwap(
                    fromToken,
                    ETH_ADDRESS,
                    amount,
                    distribution,
                    flags
                );
                weth.deposit.value(address(this).balance)();
                return;
            }

            if (destToken == bancorEtherToken) {
                _wethSwap(
                    fromToken,
                    ETH_ADDRESS,
                    amount,
                    distribution,
                    flags
                );
                bancorEtherToken.deposit.value(address(this).balance)();
                return;
            }
        }

        return super._swap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }
}

// File: contracts/interface/IBFactory.sol

pragma solidity ^0.5.0;

interface IBFactory {
    function isBPool(address b) external view returns (bool);
}

// File: contracts/interface/IBPool.sol

pragma solidity ^0.5.0;



contract BConst {
    uint public constant EXIT_FEE = 0;
}


contract IBMath is BConst {
    function calcPoolOutGivenSingleIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountIn,
        uint swapFee
    )
        public
        pure returns (uint poolAmountOut);
}


contract IBPool is IERC20, IBMath {
    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external;

    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut) external;

    function joinswapExternAmountIn(address tokenIn, uint tokenAmountIn, uint minPoolAmountOut) external returns (uint poolAmountOut);

    function getCurrentTokens() external view returns (address[] memory tokens);

    function getBalance(address token) external view returns (uint);

    function getNormalizedWeight(address token) external view returns (uint);

    function getDenormalizedWeight(address token) external view returns (uint);

    function getTotalDenormalizedWeight() external view returns (uint);

    function getSwapFee() external view returns (uint);
}

// File: contracts/OneSplitBalancerPoolToken.sol

pragma solidity ^0.5.0;





contract OneSplitBalancerPoolTokenBase {
    using SafeMath for uint256;

    // todo: factory for Bronze release
    // may be changed in future
    IBFactory bFactory = IBFactory(0x9424B1412450D0f8Fc2255FAf6046b98213B76Bd);

    struct TokenWithWeight {
        IERC20 token;
        uint256 reserveBalance;
        uint256 denormalizedWeight;
    }

    struct PoolTokenDetails {
        TokenWithWeight[] tokens;
        uint256 totalWeight;
        uint256 totalSupply;
    }

    function _getPoolDetails(IBPool poolToken)
    internal
    view
    returns(PoolTokenDetails memory details)
    {
        address[] memory currentTokens = poolToken.getCurrentTokens();
        details.tokens = new TokenWithWeight[](currentTokens.length);
        details.totalWeight = poolToken.getTotalDenormalizedWeight();
        details.totalSupply = poolToken.totalSupply();
        for (uint256 i = 0; i < details.tokens.length; i++) {
            details.tokens[i].token = IERC20(currentTokens[i]);
            details.tokens[i].denormalizedWeight = poolToken.getDenormalizedWeight(currentTokens[i]);
            details.tokens[i].reserveBalance = poolToken.getBalance(currentTokens[i]);
        }
    }

}


contract OneSplitBalancerPoolTokenView is OneSplitViewWrapBase, OneSplitBalancerPoolTokenBase {

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
    public
    view
    returns (
        uint256 returnAmount,
        uint256[] memory distribution
    )
    {
        if (fromToken == toToken) {
            return (amount, new uint256[](DEXES_COUNT));
        }


        if (!flags.check(FLAG_DISABLE_BALANCER_POOL_TOKEN)) {
            bool isPoolTokenFrom = bFactory.isBPool(address(fromToken));
            bool isPoolTokenTo = bFactory.isBPool(address(toToken));

            if (isPoolTokenFrom && isPoolTokenTo) {
                (
                uint256 returnETHAmount,
                uint256[] memory poolTokenFromDistribution
                ) = _getExpectedReturnFromBalancerPoolToken(
                    fromToken,
                    ETH_ADDRESS,
                    amount,
                    parts,
                    FLAG_DISABLE_BALANCER_POOL_TOKEN
                );

                (
                uint256 returnPoolTokenToAmount,
                uint256[] memory poolTokenToDistribution
                ) = _getExpectedReturnToBalancerPoolToken(
                    ETH_ADDRESS,
                    toToken,
                    returnETHAmount,
                    parts,
                    FLAG_DISABLE_BALANCER_POOL_TOKEN
                );

                for (uint i = 0; i < poolTokenToDistribution.length; i++) {
                    poolTokenFromDistribution[i] |= poolTokenToDistribution[i] << 128;
                }

                return (returnPoolTokenToAmount, poolTokenFromDistribution);
            }

            if (isPoolTokenFrom) {
                return _getExpectedReturnFromBalancerPoolToken(
                    fromToken,
                    toToken,
                    amount,
                    parts,
                    FLAG_DISABLE_BALANCER_POOL_TOKEN
                );
            }

            if (isPoolTokenTo) {
                return _getExpectedReturnToBalancerPoolToken(
                    fromToken,
                    toToken,
                    amount,
                    parts,
                    FLAG_DISABLE_BALANCER_POOL_TOKEN
                );
            }
        }

        return super.getExpectedReturn(
            fromToken,
            toToken,
            amount,
            parts,
            flags
        );
    }

    function _getExpectedReturnFromBalancerPoolToken(
        IERC20 poolToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
    private
    view
    returns (
        uint256 returnAmount,
        uint256[] memory distribution
    )
    {
        distribution = new uint256[](DEXES_COUNT);

        IBPool bToken = IBPool(address(poolToken));
        address[] memory currentTokens = bToken.getCurrentTokens();

        uint256 pAiAfterExitFee = amount.sub(
            amount.mul(bToken.EXIT_FEE())
        );
        uint256 ratio = pAiAfterExitFee.mul(1e18).div(poolToken.totalSupply());
        for (uint i = 0; i < currentTokens.length; i++) {
            uint256 tokenAmountOut = bToken.getBalance(currentTokens[i]).mul(ratio).div(1e18);

            if (currentTokens[i] == address(toToken)) {
                returnAmount = returnAmount.add(tokenAmountOut);
                continue;
            }

            (uint256 ret, uint256[] memory dist) = getExpectedReturn(
                IERC20(currentTokens[i]),
                toToken,
                tokenAmountOut,
                parts,
                flags
            );

            returnAmount = returnAmount.add(ret);

            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] |= dist[j] << (i * 8);
            }
        }

        return (returnAmount, distribution);
    }

    function _getExpectedReturnToBalancerPoolToken(
        IERC20 fromToken,
        IERC20 poolToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
    private
    view
    returns (
        uint256 minFundAmount,
        uint256[] memory distribution
    )
    {
        distribution = new uint256[](DEXES_COUNT);
        minFundAmount = uint256(-1);

        PoolTokenDetails memory details = _getPoolDetails(IBPool(address(poolToken)));

        uint256[] memory tokenAmounts = new uint256[](details.tokens.length);
        uint256[] memory dist;
        uint256[] memory fundAmounts = new uint256[](details.tokens.length);

        for (uint i = 0; i < details.tokens.length; i++) {
            uint256 exchangeAmount = amount.mul(
                details.tokens[i].denormalizedWeight
            ).div(details.totalWeight);

            if (details.tokens[i].token != fromToken) {
                (tokenAmounts[i], dist) = getExpectedReturn(
                    fromToken,
                    details.tokens[i].token,
                    exchangeAmount,
                    parts,
                    flags
                );

                for (uint j = 0; j < distribution.length; j++) {
                    distribution[j] |= dist[j] << (i * 8);
                }
            } else {
                tokenAmounts[i] = exchangeAmount;
            }

            fundAmounts[i] = tokenAmounts[i]
            .mul(details.totalSupply)
            .div(details.tokens[i].reserveBalance);

            if (fundAmounts[i] < minFundAmount) {
                minFundAmount = fundAmounts[i];
            }
        }

        //        uint256 _minFundAmount = minFundAmount;
        //        uint256 swapFee = IBPool(address(poolToken)).getSwapFee();
        // Swap leftovers for PoolToken
        //        for (uint i = 0; i < details.tokens.length; i++) {
        //            if (_minFundAmount == fundAmounts[i]) {
        //                continue;
        //            }
        //
        //            uint256 leftover = tokenAmounts[i].sub(
        //                fundAmounts[i].mul(details.tokens[i].reserveBalance).div(details.totalSupply)
        //            );
        //
        //            uint256 tokenRet = IBPool(address(poolToken)).calcPoolOutGivenSingleIn(
        //                details.tokens[i].reserveBalance,
        //                details.tokens[i].denormalizedWeight,
        //                details.totalSupply,
        //                details.totalWeight,
        //                leftover,
        //                swapFee
        //            );
        //
        //            minFundAmount = minFundAmount.add(tokenRet);
        //        }

        return (minFundAmount, distribution);
    }

}


contract OneSplitBalancerPoolToken is OneSplitBaseWrap, OneSplitBalancerPoolTokenBase {
    function _swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        if (fromToken == toToken) {
            return;
        }

        if (!flags.check(FLAG_DISABLE_BALANCER_POOL_TOKEN)) {
            bool isPoolTokenFrom = bFactory.isBPool(address(fromToken));
            bool isPoolTokenTo = bFactory.isBPool(address(toToken));

            if (isPoolTokenFrom && isPoolTokenTo) {
                uint256[] memory dist = new uint256[](distribution.length);
                for (uint i = 0; i < distribution.length; i++) {
                    dist[i] = distribution[i] & ((1 << 128) - 1);
                }

                uint256 ethBalanceBefore = address(this).balance;

                _swapFromBalancerPoolToken(
                    fromToken,
                    ETH_ADDRESS,
                    amount,
                    dist,
                    FLAG_DISABLE_BALANCER_POOL_TOKEN
                );

                for (uint i = 0; i < distribution.length; i++) {
                    dist[i] = distribution[i] >> 128;
                }

                uint256 ethBalanceAfter = address(this).balance;

                return _swapToBalancerPoolToken(
                    ETH_ADDRESS,
                    toToken,
                    ethBalanceAfter.sub(ethBalanceBefore),
                    dist,
                    FLAG_DISABLE_BALANCER_POOL_TOKEN
                );
            }

            if (isPoolTokenFrom) {
                return _swapFromBalancerPoolToken(
                    fromToken,
                    toToken,
                    amount,
                    distribution,
                    FLAG_DISABLE_BALANCER_POOL_TOKEN
                );
            }

            if (isPoolTokenTo) {
                return _swapToBalancerPoolToken(
                    fromToken,
                    toToken,
                    amount,
                    distribution,
                    FLAG_DISABLE_BALANCER_POOL_TOKEN
                );
            }
        }

        return super._swap(
            fromToken,
            toToken,
            amount,
            distribution,
            flags
        );
    }

    function _swapFromBalancerPoolToken(
        IERC20 poolToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {

        IBPool bToken = IBPool(address(poolToken));

        address[] memory currentTokens = bToken.getCurrentTokens();

        uint256 ratio = amount.sub(
            amount.mul(bToken.EXIT_FEE())
        ).mul(1e18).div(poolToken.totalSupply());

        uint256[] memory minAmountsOut = new uint256[](currentTokens.length);
        for (uint i = 0; i < currentTokens.length; i++) {
            minAmountsOut[i] = bToken.getBalance(currentTokens[i]).mul(ratio).div(1e18).mul(995).div(1000); // 0.5% slippage;
        }

        bToken.exitPool(amount, minAmountsOut);

        uint256[] memory dist = new uint256[](distribution.length);
        for (uint i = 0; i < currentTokens.length; i++) {

            if (currentTokens[i] == address(toToken)) {
                continue;
            }

            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j] >> (i * 8)) & 0xFF;
            }

            uint256 exchangeTokenAmount = IERC20(currentTokens[i]).balanceOf(address(this));

            this.swap(
                IERC20(currentTokens[i]),
                toToken,
                exchangeTokenAmount,
                0,
                dist,
                flags
            );
        }

    }

    function _swapToBalancerPoolToken(
        IERC20 fromToken,
        IERC20 poolToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {
        uint256[] memory dist = new uint256[](distribution.length);
        uint256 minFundAmount = uint256(-1);

        PoolTokenDetails memory details = _getPoolDetails(IBPool(address(poolToken)));

        uint256[] memory maxAmountsIn = new uint256[](details.tokens.length);
        uint256 curFundAmount;
        for (uint i = 0; i < details.tokens.length; i++) {
            uint256 exchangeAmount = amount
            .mul(details.tokens[i].denormalizedWeight)
            .div(details.totalWeight);

            if (details.tokens[i].token != fromToken) {
                uint256 tokenBalanceBefore = details.tokens[i].token.balanceOf(address(this));

                for (uint j = 0; j < distribution.length; j++) {
                    dist[j] = (distribution[j] >> (i * 8)) & 0xFF;
                }

                this.swap(
                    fromToken,
                    details.tokens[i].token,
                    exchangeAmount,
                    0,
                    dist,
                    flags
                );

                uint256 tokenBalanceAfter = details.tokens[i].token.balanceOf(address(this));

                curFundAmount = (
                tokenBalanceAfter.sub(tokenBalanceBefore)
                ).mul(details.totalSupply).div(details.tokens[i].reserveBalance);
            } else {
                curFundAmount = (
                exchangeAmount
                ).mul(details.totalSupply).div(details.tokens[i].reserveBalance);
            }

            if (curFundAmount < minFundAmount) {
                minFundAmount = curFundAmount;
            }

            maxAmountsIn[i] = uint256(-1);
            details.tokens[i].token.universalApprove(address(poolToken), uint256(-1));
        }

        // todo: check for vulnerability
        IBPool(address(poolToken)).joinPool(minFundAmount, maxAmountsIn);

        // Return leftovers
        for (uint i = 0; i < details.tokens.length; i++) {
            details.tokens[i].token.universalTransfer(msg.sender, details.tokens[i].token.balanceOf(address(this)));
        }
    }
}

// File: contracts/OneSplitUniswapPoolToken.sol

pragma solidity ^0.5.0;





contract OneSplitUniswapPoolTokenBase {
    using SafeMath for uint256;

    IUniswapFactory constant uniswapFactory = IUniswapFactory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);

    function isLiquidityPool(IERC20 token) internal view returns (bool) {
        return address(uniswapFactory.getToken(address(token))) != address(0);
    }

    function getMaxPossibleFund(
        IERC20 poolToken,
        IERC20 uniswapToken,
        uint256 tokenAmount,
        uint256 existEthAmount
    )
        internal
        view
        returns (
            uint256,
            uint256
        )
    {
        uint256 ethReserve = address(poolToken).balance;
        uint256 totalLiquidity = poolToken.totalSupply();
        uint256 tokenReserve = uniswapToken.balanceOf(address(poolToken));

        uint256 possibleEthAmount = ethReserve.mul(
            tokenAmount.sub(1)
        ).div(tokenReserve);

        if (existEthAmount > possibleEthAmount) {
            return (
                possibleEthAmount,
                possibleEthAmount.mul(totalLiquidity).div(ethReserve)
            );
        }

        return (
            existEthAmount,
            existEthAmount.mul(totalLiquidity).div(ethReserve)
        );
    }

}


contract OneSplitUniswapPoolTokenView is OneSplitViewWrapBase, OneSplitUniswapPoolTokenBase {

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == toToken) {
            return (amount, new uint256[](DEXES_COUNT));
        }


        if (!flags.check(FLAG_DISABLE_UNISWAP_POOL_TOKEN)) {
            bool isPoolTokenFrom = isLiquidityPool(fromToken);
            bool isPoolTokenTo = isLiquidityPool(toToken);

            if (isPoolTokenFrom && isPoolTokenTo) {
                (
                    uint256 returnETHAmount,
                    uint256[] memory poolTokenFromDistribution
                ) = _getExpectedReturnFromPoolToken(
                    fromToken,
                    ETH_ADDRESS,
                    amount,
                    parts,
                    FLAG_DISABLE_UNISWAP_POOL_TOKEN
                );

                (
                    uint256 returnPoolTokenToAmount,
                    uint256[] memory poolTokenToDistribution
                ) = _getExpectedReturnToPoolToken(
                    ETH_ADDRESS,
                    toToken,
                    returnETHAmount,
                    parts,
                    FLAG_DISABLE_UNISWAP_POOL_TOKEN
                );

                for (uint i = 0; i < poolTokenToDistribution.length; i++) {
                    poolTokenFromDistribution[i] |= poolTokenToDistribution[i] << 128;
                }

                return (returnPoolTokenToAmount, poolTokenFromDistribution);
            }

            if (isPoolTokenFrom) {
                return _getExpectedReturnFromPoolToken(
                    fromToken,
                    toToken,
                    amount,
                    parts,
                    FLAG_DISABLE_UNISWAP_POOL_TOKEN
                );
            }

            if (isPoolTokenTo) {
                return _getExpectedReturnToPoolToken(
                    fromToken,
                    toToken,
                    amount,
                    parts,
                    FLAG_DISABLE_UNISWAP_POOL_TOKEN
                );
            }
        }

        return super.getExpectedReturn(
            fromToken,
            toToken,
            amount,
            parts,
            flags
        );
    }

    function _getExpectedReturnFromPoolToken(
        IERC20 poolToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        private
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {

        distribution = new uint256[](DEXES_COUNT);

        IERC20 uniswapToken = uniswapFactory.getToken(address(poolToken));

        uint256 totalSupply = poolToken.totalSupply();

        uint256 ethReserve = address(poolToken).balance;
        uint256 ethAmount = amount.mul(ethReserve).div(totalSupply);

        if (!toToken.isETH()) {
            (uint256 ret, uint256[] memory dist) = getExpectedReturn(
                ETH_ADDRESS,
                toToken,
                ethAmount,
                parts,
                flags
            );

            returnAmount = returnAmount.add(ret);
            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] |= dist[j];
            }
        } else {
            returnAmount = returnAmount.add(ethAmount);
        }

        uint256 tokenReserve = uniswapToken.balanceOf(address(poolToken));
        uint256 exchangeTokenAmount = amount.mul(tokenReserve).div(totalSupply);

        if (toToken != uniswapToken) {
            (uint256 ret, uint256[] memory dist) = getExpectedReturn(
                uniswapToken,
                toToken,
                exchangeTokenAmount,
                parts,
                flags
            );

            returnAmount = returnAmount.add(ret);
            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] |= dist[j] << 8;
            }
        } else {
            returnAmount = returnAmount.add(exchangeTokenAmount);
        }

        return (returnAmount, distribution);
    }

    function _getExpectedReturnToPoolToken(
        IERC20 fromToken,
        IERC20 poolToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        private
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {

        distribution = new uint256[](DEXES_COUNT);

        uint256[] memory dist = new uint256[](DEXES_COUNT);

        uint256 ethAmount;
        uint256 partAmountForEth = amount.div(2);
        if (!fromToken.isETH()) {
            (ethAmount, dist) = super.getExpectedReturn(
                fromToken,
                ETH_ADDRESS,
                partAmountForEth,
                parts,
                flags
            );

            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] |= dist[j];
            }
        } else {
            ethAmount = partAmountForEth;
        }

        IERC20 uniswapToken = uniswapFactory.getToken(address(poolToken));

        uint256 tokenAmount;
        uint256 partAmountForToken = amount.sub(partAmountForEth);
        if (fromToken != uniswapToken) {
            (tokenAmount, dist) = super.getExpectedReturn(
                fromToken,
                uniswapToken,
                partAmountForToken,
                parts,
                flags
            );

            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] |= dist[j] << 8;
            }
        } else {
            tokenAmount = partAmountForToken;
        }

        (, returnAmount) = getMaxPossibleFund(
            poolToken,
            uniswapToken,
            tokenAmount,
            ethAmount
        );

        return (
            returnAmount,
            distribution
        );
    }

}


contract OneSplitUniswapPoolToken is OneSplitBaseWrap, OneSplitUniswapPoolTokenBase {
    function _swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        if (fromToken == toToken) {
            return;
        }

        if (!flags.check(FLAG_DISABLE_UNISWAP_POOL_TOKEN)) {
            bool isPoolTokenFrom = isLiquidityPool(fromToken);
            bool isPoolTokenTo = isLiquidityPool(toToken);

            if (isPoolTokenFrom && isPoolTokenTo) {
                uint256[] memory dist = new uint256[](distribution.length);
                for (uint i = 0; i < distribution.length; i++) {
                    dist[i] = distribution[i] & ((1 << 128) - 1);
                }

                uint256 ethBalanceBefore = address(this).balance;

                _swapFromPoolToken(
                    fromToken,
                    ETH_ADDRESS,
                    amount,
                    dist,
                    FLAG_DISABLE_UNISWAP_POOL_TOKEN
                );

                for (uint i = 0; i < distribution.length; i++) {
                    dist[i] = distribution[i] >> 128;
                }

                uint256 ethBalanceAfter = address(this).balance;

                return _swapToPoolToken(
                    ETH_ADDRESS,
                    toToken,
                    ethBalanceAfter.sub(ethBalanceBefore),
                    dist,
                    FLAG_DISABLE_UNISWAP_POOL_TOKEN
                );
            }

            if (isPoolTokenFrom) {
                return _swapFromPoolToken(
                    fromToken,
                    toToken,
                    amount,
                    distribution,
                    FLAG_DISABLE_UNISWAP_POOL_TOKEN
                );
            }

            if (isPoolTokenTo) {
                return _swapToPoolToken(
                    fromToken,
                    toToken,
                    amount,
                    distribution,
                    FLAG_DISABLE_UNISWAP_POOL_TOKEN
                );
            }
        }

        return super._swap(
            fromToken,
            toToken,
            amount,
            distribution,
            flags
        );
    }

    function _swapFromPoolToken(
        IERC20 poolToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {

        uint256[] memory dist = new uint256[](distribution.length);

        (
            uint256 ethAmount,
            uint256 exchangeTokenAmount
        ) = IUniswapExchange(address(poolToken)).removeLiquidity(
            amount,
            1,
            1,
            now.add(1800)
        );

        if (!toToken.isETH()) {
            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j]) & 0xFF;
            }

            super._swap(
                ETH_ADDRESS,
                toToken,
                ethAmount,
                dist,
                flags
            );
        }

        IERC20 uniswapToken = uniswapFactory.getToken(address(poolToken));

        if (toToken != uniswapToken) {
            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j] >> 8) & 0xFF;
            }

            super._swap(
                uniswapToken,
                toToken,
                exchangeTokenAmount,
                dist,
                flags
            );
        }
    }

    function _swapToPoolToken(
        IERC20 fromToken,
        IERC20 poolToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {
        uint256[] memory dist = new uint256[](distribution.length);

        uint256 partAmountForEth = amount.div(2);
        if (!fromToken.isETH()) {
            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j]) & 0xFF;
            }

            super._swap(
                fromToken,
                ETH_ADDRESS,
                partAmountForEth,
                dist,
                flags
            );
        }

        IERC20 uniswapToken = uniswapFactory.getToken(address(poolToken));

        uint256 partAmountForToken = amount.sub(partAmountForEth);
        if (fromToken != uniswapToken) {
            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j] >> 8) & 0xFF;
            }

            super._swap(
                fromToken,
                uniswapToken,
                partAmountForToken,
                dist,
                flags
            );

            uniswapToken.universalApprove(address(poolToken), uint256(-1));
        }

        uint256 ethBalance = address(this).balance;
        uint256 tokenBalance = uniswapToken.balanceOf(address(this));

        (uint256 ethAmount, uint256 returnAmount) = getMaxPossibleFund(
            poolToken,
            uniswapToken,
            tokenBalance,
            ethBalance
        );

        IUniswapExchange(address(poolToken)).addLiquidity.value(ethAmount)(
            returnAmount.mul(995).div(1000), // 0.5% slippage
            uint256(-1),                     // todo: think about another value
            now.add(1800)
        );

        // todo: do we need to check difference between balance before and balance after?
        uniswapToken.universalTransfer(msg.sender, uniswapToken.balanceOf(address(this)));
        ETH_ADDRESS.universalTransfer(msg.sender, address(this).balance);
    }
}

// File: contracts/OneSplitCurvePoolToken.sol

pragma solidity ^0.5.0;




contract OneSplitCurvePoolTokenBase {
    using SafeMath for uint256;
    using UniversalERC20 for IERC20;

    IERC20 constant curveSusdToken = IERC20(0xC25a3A3b969415c80451098fa907EC722572917F);
    IERC20 constant curveIearnToken = IERC20(0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8);
    IERC20 constant curveCompoundToken = IERC20(0x845838DF265Dcd2c412A1Dc9e959c7d08537f8a2);
    IERC20 constant curveUsdtToken = IERC20(0x9fC689CCaDa600B6DF723D9E47D84d76664a1F23);
    IERC20 constant curveBinanceToken = IERC20(0x3B3Ac5386837Dc563660FB6a0937DFAa5924333B);
    IERC20 constant curvePaxToken = IERC20(0xD905e2eaeBe188fc92179b6350807D8bd91Db0D8);
    IERC20 constant curveRenBtcToken = IERC20(0x7771F704490F9C0C3B06aFe8960dBB6c58CBC812);
    IERC20 constant curveTBtcToken = IERC20(0x1f2a662FB513441f06b8dB91ebD9a1466462b275);

    ICurve constant curveSusd = ICurve(0xA5407eAE9Ba41422680e2e00537571bcC53efBfD);
    ICurve constant curveIearn = ICurve(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51);
    ICurve constant curveCompound = ICurve(0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56);
    ICurve constant curveUsdt = ICurve(0x52EA46506B9CC5Ef470C5bf89f17Dc28bB35D85C);
    ICurve constant curveBinance = ICurve(0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27);
    ICurve constant curvePax = ICurve(0x06364f10B501e868329afBc005b3492902d6C763);
    ICurve constant curveRenBtc = ICurve(0x8474c1236F0Bc23830A23a41aBB81B2764bA9f4F);
    ICurve constant curveTBtc = ICurve(0x9726e9314eF1b96E45f40056bEd61A088897313E);

    struct CurveTokenInfo {
        IERC20 token;
        uint256 weightedReserveBalance;
    }

    struct CurveInfo {
        ICurve curve;
        uint256 tokenCount;
    }

    struct CurvePoolTokenDetails {
        CurveTokenInfo[] tokens;
        uint256 totalWeightedBalance;
    }

    function _isPoolToken(IERC20 token)
        internal
        pure
        returns (bool)
    {
        if (
            token == curveSusdToken ||
            token == curveIearnToken ||
            token == curveCompoundToken ||
            token == curveUsdtToken ||
            token == curveBinanceToken ||
            token == curvePaxToken ||
            token == curveRenBtcToken ||
            token == curveTBtcToken
        ) {
            return true;
        }
        return false;
    }

    function _getCurve(IERC20 poolToken)
        internal
        pure
        returns (CurveInfo memory curveInfo)
    {
        if (poolToken == curveSusdToken) {
            curveInfo.curve = curveSusd;
            curveInfo.tokenCount = 4;
            return curveInfo;
        }

        if (poolToken == curveIearnToken) {
            curveInfo.curve = curveIearn;
            curveInfo.tokenCount = 4;
            return curveInfo;
        }

        if (poolToken == curveCompoundToken) {
            curveInfo.curve = curveCompound;
            curveInfo.tokenCount = 2;
            return curveInfo;
        }

        if (poolToken == curveUsdtToken) {
            curveInfo.curve = curveUsdt;
            curveInfo.tokenCount = 3;
            return curveInfo;
        }

        if (poolToken == curveBinanceToken) {
            curveInfo.curve = curveBinance;
            curveInfo.tokenCount = 4;
            return curveInfo;
        }

        if (poolToken == curvePaxToken) {
            curveInfo.curve = curvePax;
            curveInfo.tokenCount = 4;
            return curveInfo;
        }

        if (poolToken == curveRenBtcToken) {
            curveInfo.curve = curveRenBtc;
            curveInfo.tokenCount = 2;
            return curveInfo;
        }

        if (poolToken == curveTBtcToken) {
            curveInfo.curve = curveTBtc;
            curveInfo.tokenCount = 3;
            return curveInfo;
        }

        revert();
    }

    function _getCurveCalcTokenAmountSelector(uint256 tokenCount)
        internal
        pure
        returns (bytes4)
    {
        return bytes4(keccak256(abi.encodePacked(
            "calc_token_amount(uint256[", uint8(48 + tokenCount) ,"],bool)"
        )));
    }

    function _getCurveRemoveLiquiditySelector(uint256 tokenCount)
        internal
        pure
        returns (bytes4)
    {
        return bytes4(keccak256(abi.encodePacked(
            "remove_liquidity(uint256,uint256[", uint8(48 + tokenCount) ,"])"
        )));
    }

    function _getCurveAddLiquiditySelector(uint256 tokenCount)
        internal
        pure
        returns (bytes4)
    {
        return bytes4(keccak256(abi.encodePacked(
            "add_liquidity(uint256[", uint8(48 + tokenCount) ,"],uint256)"
        )));
    }

    function _getPoolDetails(ICurve curve, uint256 tokenCount)
        internal
        view
        returns(CurvePoolTokenDetails memory details)
    {
        details.tokens = new CurveTokenInfo[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            details.tokens[i].token = IERC20(curve.coins(int128(i)));
            details.tokens[i].weightedReserveBalance = curve.balances(int128(i))
                .mul(1e18).div(10 ** details.tokens[i].token.universalDecimals());
            details.totalWeightedBalance = details.totalWeightedBalance.add(
                details.tokens[i].weightedReserveBalance
            );
        }
    }
}


contract OneSplitCurvePoolTokenView is OneSplitViewWrapBase, OneSplitCurvePoolTokenBase {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        public
        view
        returns (
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == toToken) {
            return (amount, new uint256[](DEXES_COUNT));
        }


        if (!flags.check(FLAG_DISABLE_CURVE_ZAP)) {
            if (_isPoolToken(fromToken)) {
                return _getExpectedReturnFromCurvePoolToken(
                    fromToken,
                    toToken,
                    amount,
                    parts,
                    FLAG_DISABLE_CURVE_ZAP
                );
            }

            if (_isPoolToken(toToken)) {
                return _getExpectedReturnToCurvePoolToken(
                    fromToken,
                    toToken,
                    amount,
                    parts,
                    FLAG_DISABLE_CURVE_ZAP
                );
            }
        }

        return super.getExpectedReturn(
            fromToken,
            toToken,
            amount,
            parts,
            flags
        );
    }

    function _getExpectedReturnFromCurvePoolToken(
        IERC20 poolToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        private
        view
        returns (
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        distribution = new uint256[](DEXES_COUNT);

        CurveInfo memory curveInfo = _getCurve(poolToken);
        uint256 totalSupply = poolToken.totalSupply();
        for (uint i = 0; i < curveInfo.tokenCount; i++) {
            IERC20 coin = IERC20(curveInfo.curve.coins(int128(i)));

            uint256 tokenAmountOut = curveInfo.curve.balances(int128(i))
                .mul(amount)
                .div(totalSupply);

            if (coin == toToken) {
                returnAmount = returnAmount.add(tokenAmountOut);
                continue;
            }

            (uint256 ret, uint256[] memory dist) = this.getExpectedReturn(
                coin,
                toToken,
                tokenAmountOut,
                parts,
                flags
            );

            returnAmount = returnAmount.add(ret);

            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] |= dist[j] << (i * 8);
            }
        }

        return (returnAmount, distribution);
    }

    function _getExpectedReturnToCurvePoolToken(
        IERC20 fromToken,
        IERC20 poolToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        private
        view
        returns (
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        distribution = new uint256[](DEXES_COUNT);

        CurveInfo memory curveInfo = _getCurve(poolToken);
        CurvePoolTokenDetails memory details = _getPoolDetails(
            curveInfo.curve,
            curveInfo.tokenCount
        );

        bytes memory tokenAmounts;
        for (uint i = 0; i < curveInfo.tokenCount; i++) {
            uint256 exchangeAmount = amount
                .mul(details.tokens[i].weightedReserveBalance)
                .div(details.totalWeightedBalance);

            if (details.tokens[i].token == fromToken) {
                tokenAmounts = abi.encodePacked(tokenAmounts, exchangeAmount);
                continue;
            }

            (uint256 tokenAmount, uint256[] memory dist) = this.getExpectedReturn(
                fromToken,
                details.tokens[i].token,
                exchangeAmount,
                parts,
                flags
            );

            tokenAmounts = abi.encodePacked(tokenAmounts, tokenAmount);

            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] |= dist[j] << (i * 8);
            }
        }

        (bool success, bytes memory data) = address(curveInfo.curve).staticcall(
            abi.encodePacked(
                _getCurveCalcTokenAmountSelector(curveInfo.tokenCount),
                tokenAmounts,
                uint256(1)
            )
        );

        require(success, "calc_token_amount failed");

        return (abi.decode(data, (uint256)), distribution);
    }
}


contract OneSplitCurvePoolToken is OneSplitBaseWrap, OneSplitCurvePoolTokenBase {
    function _swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        if (fromToken == toToken) {
            return;
        }

        if (!flags.check(FLAG_DISABLE_CURVE_ZAP)) {
            if (_isPoolToken(fromToken)) {
                return _swapFromCurvePoolToken(
                    fromToken,
                    toToken,
                    amount,
                    distribution,
                    FLAG_DISABLE_CURVE_ZAP
                );
            }

            if (_isPoolToken(toToken)) {
                return _swapToCurvePoolToken(
                    fromToken,
                    toToken,
                    amount,
                    distribution,
                    FLAG_DISABLE_CURVE_ZAP
                );
            }
        }

        return super._swap(
            fromToken,
            toToken,
            amount,
            distribution,
            flags
        );
    }

    function _swapFromCurvePoolToken(
        IERC20 poolToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {
        CurveInfo memory curveInfo = _getCurve(poolToken);

        bytes memory minAmountsOut;
        for (uint i = 0; i < curveInfo.tokenCount; i++) {
            minAmountsOut = abi.encodePacked(minAmountsOut, uint256(1));
        }

        (bool success,) = address(curveInfo.curve).call(
            abi.encodePacked(
                _getCurveRemoveLiquiditySelector(curveInfo.tokenCount),
                amount,
                minAmountsOut
            )
        );

        require(success, "remove_liquidity failed");

        uint256[] memory dist = new uint256[](distribution.length);
        for (uint i = 0; i < curveInfo.tokenCount; i++) {
            IERC20 coin = IERC20(curveInfo.curve.coins(int128(i)));

            if (coin == toToken) {
                continue;
            }

            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j] >> (i * 8)) & 0xFF;
            }

            uint256 exchangeTokenAmount = coin.universalBalanceOf(address(this));

            this.swap(
                coin,
                toToken,
                exchangeTokenAmount,
                0,
                dist,
                flags
            );
        }
    }

    function _swapToCurvePoolToken(
        IERC20 fromToken,
        IERC20 poolToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {
        uint256[] memory dist = new uint256[](distribution.length);

        CurveInfo memory curveInfo = _getCurve(poolToken);
        CurvePoolTokenDetails memory details = _getPoolDetails(
            curveInfo.curve,
            curveInfo.tokenCount
        );

        bytes memory tokenAmounts;
        for (uint i = 0; i < curveInfo.tokenCount; i++) {
            uint256 exchangeAmount = amount
                .mul(details.tokens[i].weightedReserveBalance)
                .div(details.totalWeightedBalance);

            details.tokens[i].token.universalApprove(address(curveInfo.curve), uint256(-1));

            if (details.tokens[i].token == fromToken) {
                tokenAmounts = abi.encodePacked(tokenAmounts, exchangeAmount);
                continue;
            }

            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j] >> (i * 8)) & 0xFF;
            }

            this.swap(
                fromToken,
                details.tokens[i].token,
                exchangeAmount,
                0,
                dist,
                flags
            );

            tokenAmounts = abi.encodePacked(
                tokenAmounts,
                details.tokens[i].token.universalBalanceOf(address(this))
            );
        }

        (bool success,) = address(curveInfo.curve).call(
            abi.encodePacked(
                _getCurveAddLiquiditySelector(curveInfo.tokenCount),
                tokenAmounts,
                uint256(0)
            )
        );

        require(success, "add_liquidity failed");
    }
}

// File: contracts/interface/ISmartTokenConverter.sol

pragma solidity ^0.5.0;


interface ISmartTokenConverter {

    function version() external view returns (uint16);

    function connectors(address) external view returns (uint256, uint32, bool, bool, bool);

    function getReserveRatio(IERC20 token) external view returns (uint256);

    function connectorTokenCount() external view returns (uint256);

    function connectorTokens(uint256 i) external view returns (IERC20);

    function liquidate(uint256 _amount) external;

    function fund(uint256 _amount) payable external;

    function convert2(IERC20 _fromToken, IERC20 _toToken, uint256 _amount, uint256 _minReturn, address _affiliateAccount, uint256 _affiliateFee) external returns (uint256);

    function convert(IERC20 _fromToken, IERC20 _toToken, uint256 _amount, uint256 _minReturn) external returns (uint256);

}

// File: contracts/interface/ISmartToken.sol

pragma solidity ^0.5.0;




interface ISmartToken {
    function owner() external view returns (ISmartTokenConverter);
}

// File: contracts/interface/ISmartTokenRegistry.sol

pragma solidity ^0.5.0;



interface ISmartTokenRegistry {
    function isSmartToken(IERC20 token) external view returns (bool);
}

// File: contracts/interface/ISmartTokenFormula.sol

pragma solidity ^0.5.0;



interface ISmartTokenFormula {
    function calculateLiquidateReturn(
        uint256 supply,
        uint256 reserveBalance,
        uint32 totalRatio,
        uint256 amount
    ) external view returns (uint256);

    function calculatePurchaseReturn(
        uint256 supply,
        uint256 reserveBalance,
        uint32 totalRatio,
        uint256 amount
    ) external view returns (uint256);
}

// File: contracts/OneSplitSmartToken.sol

pragma solidity ^0.5.0;







contract OneSplitSmartTokenBase {
    using SafeMath for uint256;

    ISmartTokenRegistry constant smartTokenRegistry = ISmartTokenRegistry(0x06915Fb082D34fF4fE5105e5Ff2829Dc5e7c3c6D);
    ISmartTokenFormula constant smartTokenFormula = ISmartTokenFormula(0x55F09AB2f8C6ad171f086abdB14e1eD8544f7398);
    IERC20 constant bntToken = IERC20(0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C);

    IERC20 constant susd = IERC20(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
    IERC20 constant acientSUSD = IERC20(0x57Ab1E02fEE23774580C119740129eAC7081e9D3);

    struct TokenWithRatio {
        IERC20 token;
        uint256 ratio;
    }

    struct SmartTokenDetails {
        TokenWithRatio[] tokens;
        address converter;
        uint256 totalRatio;
    }

    function _getSmartTokenDetails(ISmartToken smartToken)
        internal
        view
        returns(SmartTokenDetails memory details)
    {
        ISmartTokenConverter converter = smartToken.owner();
        details.converter = address(converter);
        details.tokens = new TokenWithRatio[](converter.connectorTokenCount());

        for (uint256 i = 0; i < details.tokens.length; i++) {
            details.tokens[i].token = converter.connectorTokens(i);
            details.tokens[i].ratio = _getReserveRatio(converter, details.tokens[i].token);
            details.totalRatio = details.totalRatio.add(details.tokens[i].ratio);
        }
    }

    function _getReserveRatio(
        ISmartTokenConverter converter,
        IERC20 token
    )
        internal
        view
        returns (uint256)
    {
        (bool success, bytes memory data) = address(converter).staticcall.gas(10000)(
            abi.encodeWithSelector(
                converter.getReserveRatio.selector,
                token
            )
        );

        if (!success || data.length == 0) {
            (, uint32 ratio, , ,) = converter.connectors(address(token));

            return uint256(ratio);
        }

        return abi.decode(data, (uint256));
    }

    function _canonicalSUSD(IERC20 token) internal pure returns(IERC20) {
        return token == acientSUSD ? susd : token;
    }
}


contract OneSplitSmartTokenView is OneSplitViewWrapBase, OneSplitSmartTokenBase {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        public
        view
        returns(
            uint256,
            uint256[] memory
        )
    {
        if (fromToken == toToken) {
            return (amount, new uint256[](DEXES_COUNT));
        }

        if (!flags.check(FLAG_DISABLE_SMART_TOKEN)) {
            bool isSmartTokenFrom = smartTokenRegistry.isSmartToken(fromToken);
            bool isSmartTokenTo = smartTokenRegistry.isSmartToken(toToken);

            if (isSmartTokenFrom && isSmartTokenTo) {
                (
                    uint256 returnBntAmount,
                    uint256[] memory smartTokenFromDistribution
                ) = _getExpectedReturnFromSmartToken(
                    fromToken,
                    bntToken,
                    amount,
                    parts,
                    FLAG_DISABLE_SMART_TOKEN
                );

                (
                    uint256 returnSmartTokenToAmount,
                    uint256[] memory smartTokenToDistribution
                ) = _getExpectedReturnToSmartToken(
                    bntToken,
                    toToken,
                    returnBntAmount,
                    parts,
                    FLAG_DISABLE_SMART_TOKEN
                );

                for (uint i = 0; i < smartTokenToDistribution.length; i++) {
                    smartTokenFromDistribution[i] |= smartTokenToDistribution[i] << 128;
                }

                return (returnSmartTokenToAmount, smartTokenFromDistribution);
            }

            if (isSmartTokenFrom) {
                return _getExpectedReturnFromSmartToken(
                    fromToken,
                    toToken,
                    amount,
                    parts,
                    FLAG_DISABLE_SMART_TOKEN
                );
            }

            if (isSmartTokenTo) {
                return _getExpectedReturnToSmartToken(
                    fromToken,
                    toToken,
                    amount,
                    parts,
                    FLAG_DISABLE_SMART_TOKEN
                );
            }
        }

        return super.getExpectedReturn(
            fromToken,
            toToken,
            amount,
            parts,
            flags
        );
    }

    function _getExpectedReturnFromSmartToken(
        IERC20 smartToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        private
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        distribution = new uint256[](DEXES_COUNT);

        SmartTokenDetails memory details = _getSmartTokenDetails(ISmartToken(address(smartToken)));

        for (uint i = 0; i < details.tokens.length; i++) {
            uint256 srcAmount = smartTokenFormula.calculateLiquidateReturn(
                smartToken.totalSupply(),
                _canonicalSUSD(details.tokens[i].token).universalBalanceOf(details.converter),
                uint32(details.totalRatio),
                amount
            );

            if (details.tokens[i].token == toToken) {
                returnAmount = returnAmount.add(srcAmount);
                continue;
            }

            (uint256 ret, uint256[] memory dist) = this.getExpectedReturn(
                _canonicalSUSD(details.tokens[i].token),
                toToken,
                srcAmount,
                parts,
                flags
            );

            returnAmount = returnAmount.add(ret);
            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] |= dist[j] << (i * 8);
            }
        }

        return (returnAmount, distribution);
    }

    function _getExpectedReturnToSmartToken(
        IERC20 fromToken,
        IERC20 smartToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        private
        view
        returns(
            uint256 minFundAmount,
            uint256[] memory distribution
        )
    {
        distribution = new uint256[](DEXES_COUNT);
        minFundAmount = uint256(-1);

        SmartTokenDetails memory details = _getSmartTokenDetails(ISmartToken(address(smartToken)));

        uint256 reserveTokenAmount;
        uint256[] memory dist;
        uint256[] memory fundAmounts = new uint256[](details.tokens.length);

        for (uint i = 0; i < details.tokens.length; i++) {
            uint256 exchangeAmount = amount
                .mul(details.tokens[i].ratio)
                .div(details.totalRatio);

            if (details.tokens[i].token != fromToken) {
                (reserveTokenAmount, dist) = this.getExpectedReturn(
                    fromToken,
                    _canonicalSUSD(details.tokens[i].token),
                    exchangeAmount,
                    parts,
                    flags
                );

                for (uint j = 0; j < distribution.length; j++) {
                    distribution[j] |= dist[j] << (i * 8);
                }
            } else {
                reserveTokenAmount = exchangeAmount;
            }

            fundAmounts[i] = smartTokenFormula.calculatePurchaseReturn(
                smartToken.totalSupply(),
                _canonicalSUSD(details.tokens[i].token).universalBalanceOf(details.converter),
                uint32(details.totalRatio),
                reserveTokenAmount
            );

            if (fundAmounts[i] < minFundAmount) {
                minFundAmount = fundAmounts[i];
            }
        }

        return (minFundAmount, distribution);
    }
}


contract OneSplitSmartToken is OneSplitBaseWrap, OneSplitSmartTokenBase {
    function _swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        if (fromToken == toToken) {
            return;
        }

        if (!flags.check(FLAG_DISABLE_SMART_TOKEN)) {

            bool isSmartTokenFrom = smartTokenRegistry.isSmartToken(fromToken);
            bool isSmartTokenTo = smartTokenRegistry.isSmartToken(toToken);

            if (isSmartTokenFrom && isSmartTokenTo) {
                uint256[] memory dist = new uint256[](distribution.length);
                for (uint i = 0; i < distribution.length; i++) {
                    dist[i] = distribution[i] & ((1 << 128) - 1);
                }

                uint256 bntBalanceBefore = bntToken.balanceOf(address(this));

                _swapFromSmartToken(
                    fromToken,
                    bntToken,
                    amount,
                    dist,
                    FLAG_DISABLE_SMART_TOKEN
                );

                for (uint i = 0; i < distribution.length; i++) {
                    dist[i] = distribution[i] >> 128;
                }

                uint256 bntBalanceAfter = bntToken.balanceOf(address(this));

                return _swapToSmartToken(
                    bntToken,
                    toToken,
                    bntBalanceAfter.sub(bntBalanceBefore),
                    dist,
                    FLAG_DISABLE_SMART_TOKEN
                );
            }

            if (isSmartTokenFrom) {
                return _swapFromSmartToken(
                    fromToken,
                    toToken,
                    amount,
                    distribution,
                    FLAG_DISABLE_SMART_TOKEN
                );
            }

            if (isSmartTokenTo) {
                return _swapToSmartToken(
                    fromToken,
                    toToken,
                    amount,
                    distribution,
                    FLAG_DISABLE_SMART_TOKEN
                );
            }
        }

        return super._swap(
            fromToken,
            toToken,
            amount,
            distribution,
            flags
        );
    }

    function _swapFromSmartToken(
        IERC20 smartToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {
        SmartTokenDetails memory details = _getSmartTokenDetails(ISmartToken(address(smartToken)));

        ISmartTokenConverter(details.converter).liquidate(amount);

        uint256[] memory dist = new uint256[](distribution.length);

        for (uint i = 0; i < details.tokens.length; i++) {
            if (details.tokens[i].token == toToken) {
                continue;
            }

            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j] >> (i * 8)) & 0xFF;
            }

            this.swap(
                _canonicalSUSD(details.tokens[i].token),
                toToken,
                _canonicalSUSD(details.tokens[i].token).universalBalanceOf(address(this)),
                0,
                dist,
                flags
            );
        }
    }

    function _swapToSmartToken(
        IERC20 fromToken,
        IERC20 smartToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {

        uint256[] memory dist = new uint256[](distribution.length);
        uint256 minFundAmount = uint256(-1);

        SmartTokenDetails memory details = _getSmartTokenDetails(ISmartToken(address(smartToken)));

        uint256 curFundAmount;
        uint256 ethAmount;
        for (uint i = 0; i < details.tokens.length; i++) {
            uint256 exchangeAmount = amount
                .mul(details.tokens[i].ratio)
                .div(details.totalRatio);

            if (details.tokens[i].token != fromToken) {

                uint256 tokenBalanceBefore = _canonicalSUSD(details.tokens[i].token).universalBalanceOf(address(this));

                for (uint j = 0; j < distribution.length; j++) {
                    dist[j] = (distribution[j] >> (i * 8)) & 0xFF;
                }

                this.swap(
                    fromToken,
                    _canonicalSUSD(details.tokens[i].token),
                    exchangeAmount,
                    0,
                    dist,
                    flags
                );

                uint256 tokenBalanceAfter = _canonicalSUSD(details.tokens[i].token).universalBalanceOf(address(this));
                uint256 returnedAmount = tokenBalanceAfter.sub(tokenBalanceBefore);
                curFundAmount = smartTokenFormula.calculatePurchaseReturn(
                    smartToken.totalSupply(),
                    _canonicalSUSD(details.tokens[i].token).universalBalanceOf(details.converter),
                    uint32(details.totalRatio),
                    returnedAmount
                );

                if (details.tokens[i].token.isETH()) {
                    ethAmount = returnedAmount;
                }
            } else {
                curFundAmount = smartTokenFormula.calculatePurchaseReturn(
                    smartToken.totalSupply(),
                    _canonicalSUSD(details.tokens[i].token).universalBalanceOf(details.converter),
                    uint32(details.totalRatio),
                    exchangeAmount
                );

                if (details.tokens[i].token.isETH()) {
                    ethAmount = exchangeAmount;
                }
            }

            if (curFundAmount < minFundAmount) {
                minFundAmount = curFundAmount;
            }

            _canonicalSUSD(details.tokens[i].token).universalApprove(details.converter, uint256(-1));
        }

        ISmartTokenConverter(details.converter).fund.value(ethAmount)(minFundAmount);

        for (uint i = 0; i < details.tokens.length; i++) {
            IERC20 reserveToken = _canonicalSUSD(details.tokens[i].token);
            reserveToken.universalTransfer(
                msg.sender,
                reserveToken.universalBalanceOf(address(this))
            );
        }
    }
}

// File: contracts/interface/IUniswapV2Router.sol

pragma solidity ^0.5.0;


interface IUniswapV2Router {
    function addLiquidity(
        IERC20 tokenA,
        IERC20 tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint256[2] memory amounts, uint liquidity);

    function removeLiquidity(
        IERC20 tokenA,
        IERC20 tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint256[2] memory);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        IERC20[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, IERC20[] calldata path) external view returns (uint[] memory amounts);
}

// File: contracts/interface/IUniswapV2Pair.sol

pragma solidity ^0.5.0;


interface IUniswapV2Pair {
    function factory() external view returns (address);

    function token0() external view returns (IERC20);
    function token1() external view returns (IERC20);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
}

// File: contracts/OneSplitUniswapV2PoolToken.sol

pragma solidity ^0.5.0;





library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
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
}


contract OneSplitUniswapV2PoolTokenBase {
    using SafeMath for uint256;

    IUniswapV2Router constant uniswapRouter = IUniswapV2Router(0xf164fC0Ec4E93095b804a4795bBe1e041497b92a);

    function isLiquidityPool(IERC20 token) internal view returns (bool) {
        (bool success, bytes memory data) = address(token).staticcall.gas(2000)(
            abi.encode(IUniswapV2Pair(address(token)).factory.selector)
        );
        if (!success || data.length == 0) {
            return false;
        }
        return abi.decode(data, (address)) == 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    }

    struct TokenInfo {
        IERC20 token;
        uint256 reserve;
    }

    struct PoolDetails {
        TokenInfo[2] tokens;
        uint256 totalSupply;
    }

    function _getPoolDetails(IUniswapV2Pair pair) internal view returns (PoolDetails memory details) {
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();

        details.tokens[0] = TokenInfo({
            token: pair.token0(),
            reserve: reserve0
            });
        details.tokens[1] = TokenInfo({
            token: pair.token1(),
            reserve: reserve1
            });

        details.totalSupply = IERC20(address(pair)).totalSupply();
    }

    function _calcRebalanceAmount(
        uint256 leftover,
        uint256 balanceOfLeftoverAsset,
        uint256 secondAssetBalance
    ) internal pure returns (uint256) {

        return Math.sqrt(
            3988000 * leftover * balanceOfLeftoverAsset +
            3988009 * balanceOfLeftoverAsset * balanceOfLeftoverAsset -
            9 * balanceOfLeftoverAsset * balanceOfLeftoverAsset / (secondAssetBalance - 1)
        ) / 1994 - balanceOfLeftoverAsset * 1997 / 1994;
    }

}


contract OneSplitUniswapV2PoolTokenView is OneSplitViewWrapBase, OneSplitUniswapV2PoolTokenBase {

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == toToken) {
            return (amount, new uint256[](DEXES_COUNT));
        }


        if (!flags.check(FLAG_DISABLE_UNISWAP_V2_POOL_TOKEN)) {
            bool isPoolTokenFrom = isLiquidityPool(fromToken);
            bool isPoolTokenTo = isLiquidityPool(toToken);

            if (isPoolTokenFrom && isPoolTokenTo) {
                (
                    uint256 returnWETHAmount,
                    uint256[] memory poolTokenFromDistribution
                ) = _getExpectedReturnFromUniswapV2PoolToken(
                    fromToken,
                    weth,
                    amount,
                    parts,
                    FLAG_DISABLE_UNISWAP_V2_POOL_TOKEN
                );

                (
                    uint256 returnPoolTokenToAmount,
                    uint256[] memory poolTokenToDistribution
                ) = _getExpectedReturnToUniswapV2PoolToken(
                    weth,
                    toToken,
                    returnWETHAmount,
                    parts,
                    FLAG_DISABLE_UNISWAP_V2_POOL_TOKEN
                );

                for (uint i = 0; i < poolTokenToDistribution.length; i++) {
                    poolTokenFromDistribution[i] |= poolTokenToDistribution[i] << 128;
                }

                return (returnPoolTokenToAmount, poolTokenFromDistribution);
            }

            if (isPoolTokenFrom) {
                return _getExpectedReturnFromUniswapV2PoolToken(
                    fromToken,
                    toToken,
                    amount,
                    parts,
                    FLAG_DISABLE_UNISWAP_V2_POOL_TOKEN
                );
            }

            if (isPoolTokenTo) {
                return _getExpectedReturnToUniswapV2PoolToken(
                    fromToken,
                    toToken,
                    amount,
                    parts,
                    FLAG_DISABLE_UNISWAP_V2_POOL_TOKEN
                );
            }
        }

        return super.getExpectedReturn(
            fromToken,
            toToken,
            amount,
            parts,
            flags
        );
    }

    function _getExpectedReturnFromUniswapV2PoolToken(
        IERC20 poolToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        private
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        distribution = new uint256[](DEXES_COUNT);

        PoolDetails memory details = _getPoolDetails(IUniswapV2Pair(address(poolToken)));

        for (uint i = 0; i < 2; i++) {

            uint256 exchangeAmount = amount
                .mul(details.tokens[i].reserve)
                .div(details.totalSupply);

            if (toToken == details.tokens[i].token) {
                returnAmount = returnAmount.add(exchangeAmount);
                continue;
            }

            (uint256 ret, uint256[] memory dist) = this.getExpectedReturn(
                details.tokens[i].token,
                toToken,
                exchangeAmount,
                parts,
                flags
            );

            returnAmount = returnAmount.add(ret);
            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] |= dist[j] << (i * 8);
            }
        }

        return (returnAmount, distribution);
    }

    function _getExpectedReturnToUniswapV2PoolToken(
        IERC20 fromToken,
        IERC20 poolToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        private
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        distribution = new uint256[](DEXES_COUNT);

        PoolDetails memory details = _getPoolDetails(IUniswapV2Pair(address(poolToken)));

        // will overwritten to liquidity amounts
        uint256[2] memory amounts;
        amounts[0] = amount.div(2);
        amounts[1] = amount.sub(amounts[0]);
        uint256[] memory dist = new uint256[](distribution.length);
        for (uint i = 0; i < 2; i++) {

            if (fromToken == details.tokens[i].token) {
                continue;
            }

            (amounts[i], dist) = this.getExpectedReturn(
                fromToken,
                details.tokens[i].token,
                amounts[i],
                parts,
                flags
            );

            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] |= dist[j] << (i * 8);
            }
        }

        uint256 possibleLiquidity0 = amounts[0].mul(details.totalSupply).div(details.tokens[0].reserve);
        returnAmount = Math.min(
            possibleLiquidity0,
            amounts[1].mul(details.totalSupply).div(details.tokens[1].reserve)
        );

        uint256 leftoverIndex = possibleLiquidity0 > returnAmount ? 0 : 1;
        IERC20[] memory path = new IERC20[](2);
        path[0] = details.tokens[leftoverIndex].token;
        path[1] = details.tokens[1 - leftoverIndex].token;

        uint256 optimalAmount = amounts[1 - leftoverIndex].mul(
            details.tokens[leftoverIndex].reserve
        ).div(details.tokens[1 - leftoverIndex].reserve);

        IERC20 _poolToken = poolToken; // stack too deep
        uint256 exchangeAmount = _calcRebalanceAmount(
            amounts[leftoverIndex].sub(optimalAmount),
            path[0].balanceOf(address(_poolToken)).add(optimalAmount),
            path[1].balanceOf(address(_poolToken)).add(amounts[1 - leftoverIndex])
        );

        (bool success, bytes memory data) = address(uniswapRouter).staticcall.gas(200000)(
            abi.encodeWithSelector(
                uniswapRouter.getAmountsOut.selector,
                exchangeAmount,
                path
            )
        );

        if (!success) {
            return (
                returnAmount,
                distribution
            );
        }

        uint256[] memory amountsOutAfterSwap = abi.decode(data, (uint256[]));

        uint256 _addedLiquidity = returnAmount; // stack too deep
        PoolDetails memory _details = details; // stack too deep
        returnAmount = _addedLiquidity.add(
            amountsOutAfterSwap[1] // amountOut after swap
                .mul(_details.totalSupply.add(_addedLiquidity))
                .div(_details.tokens[1 - leftoverIndex].reserve.sub(amountsOutAfterSwap[1]))
        );

        return (
            returnAmount,
            distribution
        );
    }

}


contract OneSplitUniswapV2PoolToken is OneSplitBaseWrap, OneSplitUniswapV2PoolTokenBase {
    function _swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        if (fromToken == toToken) {
            return;
        }

        if (!flags.check(FLAG_DISABLE_UNISWAP_V2_POOL_TOKEN)) {
            bool isPoolTokenFrom = isLiquidityPool(fromToken);
            bool isPoolTokenTo = isLiquidityPool(toToken);

            if (isPoolTokenFrom && isPoolTokenTo) {
                uint256[] memory dist = new uint256[](distribution.length);
                for (uint i = 0; i < distribution.length; i++) {
                    dist[i] = distribution[i] & ((1 << 128) - 1);
                }

                uint256 wEthBalanceBefore = weth.balanceOf(address(this));

                _swapFromUniswapV2PoolToken(
                    fromToken,
                    weth,
                    amount,
                    dist,
                    FLAG_DISABLE_UNISWAP_V2_POOL_TOKEN
                );

                for (uint i = 0; i < distribution.length; i++) {
                    dist[i] = distribution[i] >> 128;
                }

                uint256 wEthBalanceAfter = weth.balanceOf(address(this));

                return _swapToUniswapV2PoolToken(
                    weth,
                    toToken,
                    wEthBalanceAfter.sub(wEthBalanceBefore),
                    dist,
                    FLAG_DISABLE_UNISWAP_V2_POOL_TOKEN
                );
            }

            if (isPoolTokenFrom) {
                return _swapFromUniswapV2PoolToken(
                    fromToken,
                    toToken,
                    amount,
                    distribution,
                    FLAG_DISABLE_UNISWAP_V2_POOL_TOKEN
                );
            }

            if (isPoolTokenTo) {
                return _swapToUniswapV2PoolToken(
                    fromToken,
                    toToken,
                    amount,
                    distribution,
                    FLAG_DISABLE_UNISWAP_V2_POOL_TOKEN
                );
            }
        }

        return super._swap(
            fromToken,
            toToken,
            amount,
            distribution,
            flags
        );
    }

    function _swapFromUniswapV2PoolToken(
        IERC20 poolToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {
        poolToken.universalApprove(address(uniswapRouter), uint256(-1));

        IERC20 [2] memory tokens = [
            IUniswapV2Pair(address(poolToken)).token0(),
            IUniswapV2Pair(address(poolToken)).token1()
        ];

        uint256[2] memory amounts = uniswapRouter.removeLiquidity(
            tokens[0],
            tokens[1],
            amount,
            uint256(0),
            uint256(0),
            address(this),
            now.add(1800)
        );

        uint256[] memory dist = new uint256[](distribution.length);
        for (uint i = 0; i < 2; i++) {

            if (toToken == tokens[i]) {
                continue;
            }

            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j] >> (i * 8)) & 0xFF;
            }

            this.swap(
                tokens[i],
                toToken,
                amounts[i],
                0,
                dist,
                flags
            );
        }
    }

    function _swapToUniswapV2PoolToken(
        IERC20 fromToken,
        IERC20 poolToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {
        IERC20 [2] memory tokens = [
            IUniswapV2Pair(address(poolToken)).token0(),
            IUniswapV2Pair(address(poolToken)).token1()
        ];

        // will overwritten to liquidity amounts
        uint256[2] memory amounts;
        amounts[0] = amount.div(2);
        amounts[1] = amount.sub(amounts[0]);
        uint256[] memory dist = new uint256[](distribution.length);
        for (uint i = 0; i < 2; i++) {

            tokens[i].universalApprove(address(uniswapRouter), uint256(-1));

            if (fromToken == tokens[i]) {
                continue;
            }

            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j] >> (i * 8)) & 0xFF;
            }

            this.swap(
                fromToken,
                tokens[i],
                amounts[i],
                0,
                dist,
                flags
            );

            amounts[i] = tokens[i].universalBalanceOf(address(this));
        }

        (uint256[2] memory redeemAmounts, ) = uniswapRouter.addLiquidity(
            tokens[0],
            tokens[1],
            amounts[0],
            amounts[1],
            uint256(0),
            uint256(0),
            address(this),
            now.add(1800)
        );

        if (
            redeemAmounts[0] == amounts[0] &&
            redeemAmounts[1] == amounts[1]
        ) {
            return;
        }

        uint256 leftoverIndex = amounts[0] != redeemAmounts[0] ? 0 : 1;
        IERC20[] memory path = new IERC20[](2);
        path[0] = tokens[leftoverIndex];
        path[1] = tokens[1 - leftoverIndex];

        address _poolToken = address(poolToken); // stack too deep
        uint256 leftover = amounts[leftoverIndex].sub(redeemAmounts[leftoverIndex]);
        uint256 exchangeAmount = _calcRebalanceAmount(
            leftover,
            path[0].balanceOf(_poolToken),
            path[1].balanceOf(_poolToken)
        );

        (bool success, bytes memory data) = address(uniswapRouter).call.gas(1000000)(
            abi.encodeWithSelector(
                uniswapRouter.swapExactTokensForTokens.selector,
                exchangeAmount,
                uint256(0),
                path,
                address(this),
                now.add(1800)
            )
        );

        if (!success) {
            return;
        }

        uint256[] memory amountsOut = abi.decode(data, (uint256[]));

        address(uniswapRouter).call.gas(1000000)(
            abi.encodeWithSelector(
                uniswapRouter.addLiquidity.selector,
                tokens[0],
                tokens[1],
                leftoverIndex == 0
                    ? leftover.sub(amountsOut[0])
                    : amountsOut[1],
                leftoverIndex == 1
                    ? leftover.sub(amountsOut[0])
                    : amountsOut[1],
                uint256(0),
                uint256(0),
                address(this),
                now.add(1800)
            )
        );
    }
}

// File: contracts/OneSplitMStable.sol

pragma solidity ^0.5.0;




contract OneSplitMStableView is OneSplitViewWrapBase {
    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == destToken) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_MSTABLE_MUSD)) {
            if (fromToken == IERC20(musd) && ((destToken == usdc || destToken == dai || destToken == usdt || destToken == tusd))) {
                (,, uint256 result) = musd_helper.getRedeemValidity(fromToken, amount, destToken);
                return (result, 300_000, new uint256[](DEXES_COUNT));
            }

            if (destToken == IERC20(musd) && ((fromToken == usdc || fromToken == dai || fromToken == usdt || fromToken == tusd))) {
                (,, uint256 result) = musd.getSwapOutput(fromToken, destToken, amount);
                return (result, 300_000, new uint256[](DEXES_COUNT));
            }
        }

        return super.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }
}


contract OneSplitMStable is OneSplitBaseWrap {
    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        if (fromToken == destToken) {
            return;
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_MSTABLE_MUSD)) {
            if (fromToken == IERC20(musd) && ((destToken == usdc || destToken == dai || destToken == usdt || destToken == tusd))) {
                (,, uint256 result) = musd_helper.getRedeemValidity(fromToken, amount, destToken);
                musd.redeem(
                    destToken,
                    result
                );
                return;
            }

            if (destToken == IERC20(musd) && ((fromToken == usdc || fromToken == dai || fromToken == usdt || fromToken == tusd))) {
                musd.swap(
                    fromToken,
                    destToken,
                    amount,
                    address(this)
                );
                return;
            }
        }

        return super._swap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }
}

// File: contracts/OneSplit.sol

pragma solidity ^0.5.0;

















//import "./OneSplitSmartToken.sol";


contract OneSplitViewWrap is
    OneSplitViewWrapBase,
    OneSplitMultiPathView,
    OneSplitMStableView,
    OneSplitChaiView,
    OneSplitBdaiView,
    OneSplitAaveView,
    OneSplitFulcrumView,
    OneSplitCompoundView,
    OneSplitIearnView,
    OneSplitIdleView,
    OneSplitWethView,
    //OneSplitBalancerPoolTokenView,
    //OneSplitUniswapPoolTokenView,
    //OneSplitCurvePoolTokenView
    OneSplitSmartTokenView
//    OneSplitUniswapV2PoolTokenView
{
    IOneSplitView public oneSplitView;

    constructor(IOneSplitView _oneSplit) public {
        oneSplitView = _oneSplit;
    }

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        (returnAmount, , distribution) = getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            0
        );
    }

    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags, // See constants in IOneSplit.sol
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == destToken) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }

        return super.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function _getExpectedReturnRespectingGasFloor(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        internal
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        return oneSplitView.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }
}


contract OneSplitWrap is
    OneSplitBaseWrap,
    OneSplitMultiPath,
    OneSplitMStable,
    OneSplitChai,
    OneSplitBdai,
    OneSplitAave,
    OneSplitFulcrum,
    OneSplitCompound,
    OneSplitIearn,
    OneSplitIdle,
    OneSplitWeth,
    //OneSplitBalancerPoolToken,
    //OneSplitUniswapPoolToken,
    //OneSplitCurvePoolToken
    OneSplitSmartToken
//    OneSplitUniswapV2PoolToken
{
    IOneSplitView public oneSplitView;
    IOneSplit public oneSplit;

    constructor(IOneSplitView _oneSplitView, IOneSplit _oneSplit) public {
        oneSplitView = _oneSplitView;
        oneSplit = _oneSplit;
    }

    function() external payable {
        // solium-disable-next-line security/no-tx-origin
        require(msg.sender != tx.origin);
    }

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        (returnAmount, , distribution) = getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            0
        );
    }

    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        return oneSplitView.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution, // [Uniswap, Kyber, Bancor, Oasis]
        uint256 flags // 16 - Compound, 32 - Fulcrum, 64 - Chai, 128 - Aave, 256 - SmartToken, 1024 - bDAI
    ) public payable returns(uint256 returnAmount) {
        if (msg.sender != address(this)) {
            fromToken.universalTransferFrom(msg.sender, address(this), amount);
        }
        uint256 confirmed = fromToken.universalBalanceOf(address(this));
        _swap(fromToken, destToken, confirmed, distribution, flags);

        returnAmount = destToken.universalBalanceOf(address(this));
        require(returnAmount >= minReturn, "OneSplit: actual return amount is less than minReturn");

        if (msg.sender != address(this)) {
            destToken.universalTransfer(msg.sender, returnAmount);
            fromToken.universalTransfer(msg.sender, fromToken.universalBalanceOf(address(this)));
        }
}

    function _swapFloor(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        (bool success, bytes memory data) = address(oneSplit).delegatecall(
            abi.encodeWithSelector(
                this.swap.selector,
                fromToken,
                destToken,
                amount,
                0,
                distribution,
                flags
            )
        );

        assembly {
            switch success
                // delegatecall returns 0 on error.
                case 0 { revert(add(data, 32), returndatasize) }
        }
    }
}
