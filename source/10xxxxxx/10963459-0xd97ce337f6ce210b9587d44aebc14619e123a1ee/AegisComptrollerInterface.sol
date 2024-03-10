pragma solidity ^0.5.16;

/**
 * @title Aegis Comptroller Interface
 * @author Aegis
 */
contract AegisComptrollerInterface {
    bool public constant aegisComptroller = true;

    function enterMarkets(address[] calldata _aTokens) external returns (uint[] memory);
    
    function exitMarket(address _aToken) external returns (uint);

    function mintAllowed() external returns (uint);

    function redeemAllowed(address _aToken, address _redeemer, uint _redeemTokens) external returns (uint);
    
    function redeemVerify(uint _redeemAmount, uint _redeemTokens) external;

    function borrowAllowed(address _aToken, address _borrower, uint _borrowAmount) external returns (uint);

    function repayBorrowAllowed() external returns (uint);

    function seizeAllowed(address _aTokenCollateral, address _aTokenBorrowed) external returns (uint);

    function transferAllowed(address _aToken, address _src, uint _transferTokens) external returns (uint);

    /**
     * @notice liquidation
     */
    function liquidateCalculateSeizeTokens(address _aTokenBorrowed, address _aTokenCollateral, uint _repayAmount) external view returns (uint, uint);
}
