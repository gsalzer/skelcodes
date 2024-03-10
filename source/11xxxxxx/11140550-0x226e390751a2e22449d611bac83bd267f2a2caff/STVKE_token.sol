// SPDX-License-Identifier: WHO GIVES A FUCK ANYWAY??

pragma solidity ^0.6.6;

import "./ERC20_base.sol";

interface UniswapV2Router02 {
    
    function WETH() external pure returns (address);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
  uint amountOutMin,
  address[] calldata path,
  address to,
  uint deadline
) external payable;
}

contract STVKE is ERC20_base {

    using SafeMath for uint256;

    uint256 private price;
    uint256 private STVrequirement;
    uint256 private byPassPrice;
    address private treasury;
    
    address public WETH;
    address public STV;
    address[] public path;
 
    uint256 private _STVKESupply = uint256(5000000).mul(1e18); //100k tokens
    
    UniswapV2Router02 internal constant uniswap = UniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    
    event TokenGenerated(address account, uint256 supply, string name, string symbol, uint8 decimals);
    event BuyBack(uint ethAmount);

    
    constructor() public 
    ERC20_base("STVKE", "STV", 18,
                _STVKESupply, msg.sender, 
                101, 0,
                _STVKESupply,
                10, msg.sender,
                1 minutes,
                msg.sender)
    {
        treasury = msg.sender;
        price = 1e17;
        STVrequirement = uint256(100).mul(1e18);
        byPassPrice = uint256(10000).mul(1e18);
        WETH = UniswapV2Router02(uniswap).WETH();
        STV = address(this);
        path.push(WETH);
        path.push(STV);

    }
    
    
    function createToken(string memory name, string memory symbol, uint8 decimals, 
                uint256 supply, address mintDest,
                uint256 BurnMintGov, uint256 burnOnTX,
                uint256 cappedSupply,
                uint256 feeOnTX, address feeDest,
                uint256 noTransferTime,
                address owner) public payable {
         require(balanceOf(msg.sender) >= STVrequirement);
         require(balanceOf(msg.sender) >= byPassPrice || msg.value >= price);
         require(BurnMintGov <= 111);



        if(owner == address(0)){owner = msg.sender;}          
        
        
        address tokenAddress = address(new ERC20_base(name, symbol, decimals, 
                supply, mintDest,
                BurnMintGov, burnOnTX,
                cappedSupply,
                feeOnTX, feeDest,
                noTransferTime,
                owner));
                
                
        emit TokenGenerated(tokenAddress, supply, name, symbol, decimals);
                
    buyBack();
                
    }
    
    function buyBack() internal {
        if (STV.balance > 0.5 ether) {
            uint amountIn = STV.balance.sub(0.2 ether);
        emit BuyBack(amountIn);
            uint amountOutMin = 0;
            UniswapV2Router02(uniswap).swapExactETHForTokensSupportingFeeOnTransferTokens{value : amountIn}(
                    amountOutMin, path, treasury, now.add(24 hours));
        }   
    }
    
    // function burn() external onlyOwner {
    //     _burn(treasury, balanceOf(treasury).sub(4));
    // }
    
    function setTreasury(address _address) public onlyOwner {
        treasury = _address;
    }
    function viewTreasury() public view returns(address) {
        return treasury;
    }
    function setSTVrequirement(uint256 _STVrequirement) public onlyOwner {
        STVrequirement = _STVrequirement;
    }
    function viewSTVrequirement() public view returns(uint256) {
        return STVrequirement;
    }
    
    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }
    function viewPrice() public view returns(uint256) {
        return price;
    }
    function setByPassPrice(uint256 _price) public onlyOwner {
        byPassPrice = _price;
    }
    function viewBypassPrice() public view returns(uint256) {
        return byPassPrice;
    }
}

