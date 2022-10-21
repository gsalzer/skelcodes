// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { IERC20, SafeMath, Ownable } from './interfaces/CommonImports.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

contract RefundContract is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public ETHperTokens = 0.0023733873 ether;
    uint256 public totalETHRefunded = 0;

    address burnAddr = 0x000000000000000000000000000000000000dEaD;
    IERC20 public token = IERC20(0xA6D84dce85c457d28A971f858967002BFDe74c1c);

    receive() external payable {}

    event Refunded(uint256 indexed tokensGotten,uint256 indexed ethSent);
    event RateChanged(uint256 indexed newRate);
    event ETHRetrived();

    function refund(uint256 tokenAmount) public nonReentrant {
        uint256 startETHBal = address(this).balance;
        //Get tokens from user
        token.safeTransferFrom(msg.sender,address(this),tokenAmount);
        //send eth
        (bool refundT,) = payable(msg.sender).call{ value: tokenAmount.mul(ETHperTokens).div(1e18) }("");
        require(refundT,"Eth refund failed");
        //send gotten tokens to burn address
        token.safeTransfer(burnAddr,tokenAmount);
        //Update total eth refund stat and emit event
        uint256 ethDiff = address(this).balance.sub(startETHBal);
        totalETHRefunded = totalETHRefunded.add(ethDiff);
        emit Refunded(tokenAmount,ethDiff);
    }

    function setExchangeRate(uint256 newRate) public onlyOwner {
        ETHperTokens = newRate;
        emit RateChanged(newRate);
    }

    function setToken(address tokenAddr) public onlyOwner {
        token = IERC20(tokenAddr);
    }

    //Use this only in emergency cases to retreive eth from contract
    function retriveETH() public onlyOwner {
        (bool success,) = payable(owner()).call{value : address(this).balance }("");
        require(success);
        emit ETHRetrived();
    }

}
