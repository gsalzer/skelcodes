pragma solidity ^0.5.16;

import "./ATokenInterface.sol";

contract AErc20Common {
    address public underlying;
}

/**
 * @title AErc20Interface
 * @author Aegis
 */
contract AErc20Interface is AErc20Common {
    function mint(uint _mintAmount) external returns (uint);
    function redeem(uint _redeemTokens) external returns (uint);
    function redeemUnderlying(uint _redeemAmount) external returns (uint);
    function borrow(uint _borrowAmount) external returns (uint);
    function repayBorrow(uint _repayAmount) external returns (uint);
    function repayBorrowBehalf(address _borrower, uint _repayAmount) external returns (uint);

    function _addReserves(uint addAmount) external returns (uint);
}
