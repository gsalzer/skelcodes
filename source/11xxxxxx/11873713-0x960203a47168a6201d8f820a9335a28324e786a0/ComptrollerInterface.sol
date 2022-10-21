pragma solidity ^0.5.16;

contract ComptrollerInterface {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    bool public constant isComptroller = true;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata gTokens) external returns (uint[] memory);
    function exitMarket(address gToken) external returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address gToken, address minter, uint mintAmount) external returns (uint);
    function mintVerify(address gToken, address minter, uint mintAmount, uint mintTokens) external;

    function redeemAllowed(address gToken, address redeemer, uint redeemTokens) external returns (uint);
    function redeemVerify(address gToken, address redeemer, uint redeemAmount, uint redeemTokens) external;

    function borrowAllowed(address gToken, address borrower, uint borrowAmount) external returns (uint);
    function borrowVerify(address gToken, address borrower, uint borrowAmount) external;

    function repayBorrowAllowed(
        address gToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (uint);
    function repayBorrowVerify(
        address gToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex) external;

    function liquidateBorrowAllowed(
        address gTokenBorrowed,
        address gTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (uint);
    function liquidateBorrowVerify(
        address gTokenBorrowed,
        address gTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) external;

    function seizeAllowed(
        address gTokenCollateral,
        address gTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (uint);
    function seizeVerify(
        address gTokenCollateral,
        address gTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external;

    function transferAllowed(address gToken, address src, address dst, uint transferTokens) external returns (uint);
    function transferVerify(address gToken, address src, address dst, uint transferTokens) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address gTokenBorrowed,
        address gTokenCollateral,
        uint repayAmount) external view returns (uint, uint);
}

