// SPDX-License-Identifier: WHO GIVES A FUCK ANYWAY??

pragma solidity ^0.6.6;

import "./IDO20_base.sol";

contract STVKE_IDO {

    using SafeMath for uint256;
    
    UniswapV2Router02 internal constant uniswap = UniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    ISTVKE internal constant stvke = ISTVKE(0x226e390751A2e22449D611bAC83bD267F2A2CAfF);
    
    event SaleGenerated(address account, uint256 hardcap, uint256 startTime, uint256 duration, uint256 tokensPerEth, uint256 percentToUniswap);
    event SendForBuyBack(uint ethAmount);

    
    constructor() public
    {

    }
    
    
    function createIDO(IERC20 _token,
    uint256 _startTime, uint256 _duration,
    uint256 _hardcap, uint256 _softcap,
    uint256 _tokensPerEth, uint256 _percentToUniswap,
    uint256 _minContribution, uint256 _maxContribution,
    bool _burnLeftover, bool _whitelisting, uint256 _fcfs, address __owner) public payable {
         require(stvke.balanceOf(msg.sender) >= stvke.viewSTVrequirement());
         require(stvke.balanceOf(msg.sender) >= stvke.viewBypassPrice() || msg.value >= stvke.viewPrice());
        
        
        address saleAddress = address(new IDO20_base(_token,
                _startTime, _duration,
                _hardcap, _softcap,
                _tokensPerEth, _percentToUniswap,
                _minContribution, _maxContribution,
                _burnLeftover, _whitelisting, _fcfs, __owner));
                
                
        emit SaleGenerated(saleAddress, _hardcap, _startTime, _duration, _tokensPerEth, _percentToUniswap);
                
    sendForBuyBack();
                
    }
    
    function sendForBuyBack() internal {
        if (address(this).balance > 0.5 ether) {
            uint amountIn = address(this).balance.sub(0.2 ether);
            emit SendForBuyBack(amountIn);
            payable(0x226e390751A2e22449D611bAC83bD267F2A2CAfF).transfer(amountIn);
        }   
    }
}


