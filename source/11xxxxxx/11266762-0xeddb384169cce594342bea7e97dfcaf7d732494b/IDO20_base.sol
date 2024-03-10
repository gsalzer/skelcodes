// SPDX-License-Identifier: WHO GIVES A FUCK ANYWAY??

pragma solidity ^0.6.0;

import "./STVKE_lib.sol";

interface UniswapV2Router02 {
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) 
    external 
    payable 
    returns (uint amountToken, uint amountETH, uint liquidity);
    
    function WETH() external pure returns (address);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
  uint amountOutMin,
  address[] calldata path,
  address to,
  uint deadline
) external payable;
}

contract IDO20_base is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public HARDCAP;
    
    uint256 public SOFTCAP;

    uint256 public TOKENS_PER_ETH;

    uint256 public startTime;

    uint256 public duration;

    uint256 public endTime;

    uint256 public percentToUniswap;
    
    bool public finalized = false;

    mapping(address => bool) public whitelists;

    mapping(address => uint256) public contributions;


    uint256 public minContribution;

    uint256 public maxContribution;

    uint256 public weiRaised;

    bool public burnLeftover;

    bool public whitelisting;

    uint256 public fcfs;

    IERC20 public token;

    UniswapV2Router02 internal constant uniswap = UniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    constructor(IERC20 _token,
    uint256 _startTime, uint256 _duration,
    uint256 _hardcap, uint256 _softcap,
    uint256 _tokensPerEth, uint256 _percentToUniswap,
    uint256 _minContribution, uint256 _maxContribution,
    bool _burnLeftover, bool _whitelisting, uint256 _fcfs, address __owner)
    public
    Ownable()
    {
        require(_percentToUniswap <= 100 && _percentToUniswap >= 0);
        token = _token;
        startTime = _startTime;
        duration = _duration;
        HARDCAP = _hardcap.mul(1e18);
        SOFTCAP = _softcap.mul(1e18);
        endTime = startTime + duration;
        TOKENS_PER_ETH = _tokensPerEth;
        percentToUniswap = _percentToUniswap;
        minContribution = _minContribution;
        maxContribution = _maxContribution;
        burnLeftover = _burnLeftover;
        whitelisting = _whitelisting;
        if (_fcfs == 0) { 
            fcfs = startTime.add(duration);
        } else {
        fcfs = startTime.add(_fcfs);
        }
        transferOwnership(__owner);
    }

    receive() payable external {
        _buyTokens(msg.sender);
    }

    function _buyTokens(address _beneficiary) internal {
        uint256 weiToHardcap = HARDCAP.sub(weiRaised);
        uint256 weiAmount = weiToHardcap < msg.value ? weiToHardcap : msg.value;

        _buyTokens(_beneficiary, weiAmount);

        uint256 refund = msg.value.sub(weiAmount);
        if (refund > 0) {
            payable(_beneficiary).transfer(refund);
        }
    }

    function _buyTokens(address _beneficiary, uint256 _amount) internal {
        require(isOpen(), "Sale is not open.");
        require(!hasEnded(), "Sale has ended.");
        require(contributions[_beneficiary].add(_amount) <= maxContribution || maxContribution == 0, "You have sent more than the max contribution.");
        require(_amount >= minContribution || weiRaised.add(_amount) == HARDCAP || minContribution == 0, "You have sent less than the min contribution.");
        require(now >= fcfs || !whitelisting || whitelists[_beneficiary], "The sale requires you to be whitelisted, or FCFS has not yet started.");

        weiRaised = weiRaised.add(_amount);
        contributions[_beneficiary] = contributions[_beneficiary].add(_amount);
    }
    
    function claim() public {
        require(hasEnded(), "Sale has not ended.");
        require(finalized, "Sale not finalized.");
        if (weiRaised >= SOFTCAP) { 
            uint256 tokenAmount = contributions[_msgSender()].mul(TOKENS_PER_ETH);
            contributions[_msgSender()] = 0;
            token.safeTransfer(_msgSender(), tokenAmount);
        } else {
            uint256 contribution = contributions[_msgSender()];
            contributions[_msgSender()] = 0;
            payable(_msgSender()).transfer(contribution);
        }
    }

    function isOpen() public view returns (bool) {
        return block.timestamp >= startTime;
    }

    function hasEnded() public view returns (bool) {
        return block.timestamp >= endTime || weiRaised >= HARDCAP;
    }

    function addWhitelists(address[] calldata _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelists[_addresses[i]] = true;
        }
    }

    function finalize() external virtual onlyOwner {
        require(hasEnded(), "Sale has not ended.");
        if (weiRaised > SOFTCAP) {

        uint256 liquidityETH = weiRaised.mul(percentToUniswap).div(100);
        uint256 remainingETH = weiRaised.sub(liquidityETH);
        uint256 liquidityTokens = token.balanceOf(address(this));

        uint256 tokensPerEth = TOKENS_PER_ETH;

        uint256 tokensToBurn = HARDCAP.sub(weiRaised).mul(tokensPerEth);
            if (tokensToBurn > 0 && burnLeftover == true) {
                liquidityTokens = liquidityETH.mul(tokensPerEth);
                tokensToBurn = tokensToBurn.add(HARDCAP.mul(percentToUniswap).div(100).mul(tokensPerEth).sub(liquidityTokens));

                token.approve(0x000000000000000000000000000000000000dEaD, tokensToBurn);
                token.safeTransfer(0x000000000000000000000000000000000000dEaD, tokensToBurn);
            } else if (tokensToBurn > 0 && burnLeftover == false) {
                liquidityTokens = liquidityETH.mul(tokensPerEth);
                tokensToBurn = tokensToBurn.add(HARDCAP.mul(percentToUniswap).div(100).mul(tokensPerEth).sub(liquidityTokens));
                token.approve(owner(), tokensToBurn);
                token.safeTransfer(owner(), tokensToBurn);
            }

            token.approve(address(uniswap), liquidityTokens);
            uniswap.addLiquidityETH
            { value: liquidityETH }
            (
                address(token),
                liquidityTokens,
                liquidityTokens,
                liquidityETH,
                address(0),
                block.timestamp
            );
            payable(owner()).transfer(remainingETH);
        } else {
            token.approve(address(owner()), token.balanceOf(address(this)));
            token.safeTransfer(address(owner()), token.balanceOf(address(this)));
        }
        finalized = true;
    }    

}
