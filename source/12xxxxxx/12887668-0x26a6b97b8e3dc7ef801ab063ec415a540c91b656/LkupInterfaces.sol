// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.6;

// import { DataTypes } from "LkupLibraries.sol";


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  // underlying function is not available for Aave tokens
  function underlying (  ) external view returns ( address );

  function liquidateBorrow ( address borrower, uint256 repayAmount, address cTokenCollateral ) external returns ( uint256 );
  /************
   * The mint function transfers an asset into the CompFi protocol, which begins 
   * accumulating interest based on the current Supply Rate for the asset. 
   * The user receives a quantity of cTokens equal to the underlying 
   * tokens supplied, divided by the current Exchange Rate.
   * **********/
  function mint ( uint256 mintAmount ) external returns ( uint256 );
  /**********
   * redeem function converts a specified quantity of cTokens into the underlying asset, 
   * and returns them to the user.
   * redeemTokens - numberr of tokens to convert to the underlying token.
   * RETURN: 0 on success, otherwise an Error code.
   * ********/
  function redeem( uint redeemTokens ) external returns ( uint );
  
  /**
   * redeem underlying function converts cTokens into a specified quantity of the 
   * underlying asset, and returns them to the user.
   * redeemAmount - number of underlying tokens desired, depends on the exchange rate
   **/
    // available only for Compound tokens, like cUSDC or cETH
    function redeemUnderlying(uint redeemAmount) external returns (uint);

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

interface IComptroller {

    /**
     * @notice Returns whether the given account is entered in the given asset
     * @param account The address of the account to check
     * @param cToken The cToken to check
     * @return True if the account is in the asset, otherwise false.
     */
  function checkMembership ( address account, address cToken ) external view returns ( bool );
  
    /**
     * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
     */
  function closeFactorMantissa (  ) external view returns ( uint256 );

  function enterMarkets ( address[] memory cTokens ) external returns ( uint256[] memory );

  function exitMarket ( address cTokenAddress ) external returns ( uint256 );

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @return ( possible error code ( semi-opaque ),
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements )
     */
  function getAccountLiquidity ( address account ) external view returns ( uint256, uint256, uint256 );

  function getAllMarkets (  ) external view returns ( address[] memory );

    /**
     * @notice Returns the assets an account has entered
     * @param account The address of the account to pull assets for
     * @return A dynamic list with the assets the account has entered
     */
  function getAssetsIn ( address account ) external view returns ( address[] memory );

  function liquidateBorrowAllowed ( address cTokenBorrowed, address cTokenCollateral, address liquidator, address borrower, uint256 repayAmount ) external returns ( uint256 );

  function liquidateBorrowVerify ( address cTokenBorrowed, address cTokenCollateral, address liquidator, address borrower, uint256 actualRepayAmount, uint256 seizeTokens ) external;

    /**
     * @notice Multiplier representing the discount on collateral that a liquidator receives
     */
  function liquidationIncentiveMantissa (  ) external view returns ( uint256 );
}

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);
  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);
  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);
  function createPair(address tokenA, address tokenB) external returns (address pair);
}

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
}

