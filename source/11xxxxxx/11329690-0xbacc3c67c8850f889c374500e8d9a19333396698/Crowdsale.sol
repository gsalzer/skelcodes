pragma solidity ^0.6.6;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface IERC20 {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Crowdsale is Ownable, ReentrancyGuard
{
    using SafeMath for uint256;
    
    IERC20 public _token;
    uint256 public _tokensPerEth = 125; // 125 tokens per 1 ETH (0.008 ETH per token)
    uint256 public _saleStartTime = 1606752000;
    uint256 public _saleEndTime = 1609430400;
    uint256 public _totalRaised = 0;
    
    event TokensPurchased(address purchaser, uint256 weiValue, uint256 purchasedAmount);
    
    constructor(IERC20 token) public
    {
        require(address(token) != address(0));
        
        _token = token;
        _tokensPerEth = _tokensPerEth.mul(10**uint256(_token.decimals()));
    }
    
    function withdrawEther() public onlyOwner
    { payable(owner()).transfer(address(this).balance); }
    
    function withdrawTokens() public onlyOwner
    {
        require(now > _saleEndTime, "Can't withdraw tokens before sale end");
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }
    
    receive() external payable nonReentrant
    {
        require(now >= _saleStartTime && now <= _saleEndTime, "Sale is currently not in progress");
        
        uint256 tokens = msg.value.mul(_tokensPerEth).div(1e18);
        _token.transfer(msg.sender, tokens);
        
        _totalRaised = _totalRaised.add(msg.value);
        emit TokensPurchased(msg.sender, msg.value, tokens);
    }
    
}
