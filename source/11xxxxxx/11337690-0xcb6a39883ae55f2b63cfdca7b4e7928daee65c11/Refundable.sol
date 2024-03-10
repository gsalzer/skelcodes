pragma solidity ^0.6.12;
import "./Ownable.sol";
import "./IERC20.sol";

/**
 * @title Refundable
 * @dev Base contract that can refund funds(ETH and tokens) by owner.
 */
contract Refundable is Ownable {
    event RefundETH(address indexed payee, uint256 amount);
    event RefundERC20(address indexed payee, address indexed token, uint256 amount);

    function refundETH() public onlyOwner {
        uint256 amount = address(this).balance;
        msg.sender.transfer(amount);
        emit RefundETH(msg.sender, amount);
    }

    function refundERC20(address tokenContract) public onlyOwner {
        IERC20 token = IERC20(tokenContract);
        uint256 amount = token.balanceOf(address(this));
        token.transfer(msg.sender, amount);
        emit RefundERC20(msg.sender, tokenContract, amount);
    }
}
