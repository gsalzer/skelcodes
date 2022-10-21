pragma solidity ^0.5.17;

/**
 * @title CashBackMoney Investing Contract Interface
 */
interface CashBackMoneyI {
    /**
    * Buy subscription
    * 0x0000000000000000000000000000000000000000
    */
    function Subscribe(uint256 refererID) external payable;
}

