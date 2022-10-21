// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "SafeMath.sol";
import "IERC20.sol";
import "SwapPriceCalculatorInterface.sol";

interface IUSDT
{
    function balanceOf(address who) external view returns (uint);
    function transfer(address to, uint value) external;
    function allowance(address owner, address spender) external view returns (uint);
    function transferFrom(address from, address to, uint value) external;
}

contract SwapperUsdtToToken
{
    using SafeMath for uint256;
    
    address public admin;
    IUSDT public usdtToken;
    IERC20 public sellToken;
    ISwapPriceCalculator public priceCalculator;
    
    uint256 public usdtReserve;
    uint256 public usdtFee;
    uint256 public tokensSold;
    
    string private constant ERR_MSG_SENDER = "ERR_MSG_SENDER";
    string private constant ERR_AMOUNT = "ERR_AMOUNT";
    string private constant ERR_ZERO_PAYMENT = "ERR_ZERO_PAYMENT";
    
    event Swap(uint256 fromAmount,
               uint256 expectedToAmount,
               uint16 slippage,
               uint256 fromFeeAdd,
               uint256 actualToAmount,
               uint256 tokensSold);
    
    constructor(address _admin, address _usdtToken, address _sellToken, address _priceCalculator) public
    {
        admin = _admin;
        usdtToken = IUSDT(_usdtToken);
        sellToken = IERC20(_sellToken);
        priceCalculator = ISwapPriceCalculator(_priceCalculator);
    }
    
    function sendUsdt(address _to) external returns (uint256 usdtReserveTaken_, uint256 usdtFeeTaken_)
    {
        require(msg.sender == admin, ERR_MSG_SENDER);
        
        usdtToken.transfer(_to, usdtToken.balanceOf(address(this)));
        
        usdtReserveTaken_ = usdtReserve;
        usdtFeeTaken_ = usdtFee;
        
        usdtReserve = 0;
        usdtFee = 0;
    }
    
    function sendSellTokens(address _to, uint256 _amount) external
    {
        require(msg.sender == admin, ERR_MSG_SENDER);
        
        if(_amount == 0)
        {
            sellToken.transfer(_to, sellToken.balanceOf(address(this)));
        }
        else
        {
            sellToken.transfer(_to, _amount);
        }
    }
    
    function setPriceCalculator(address _priceCalculator) external
    {
        require(msg.sender == admin, ERR_MSG_SENDER);
        
        priceCalculator = ISwapPriceCalculator(_priceCalculator);
    }
    
    function calcPrice(uint256 _fromAmount, bool _excludeFee) external view returns (uint256 _actualToAmount,
                                                                                     uint256 _fromFeeAdd,
                                                                                     uint256 _actualFromAmount)
    {
        require(_fromAmount > 0, ERR_ZERO_PAYMENT);
        
        return priceCalculator.calc(_fromAmount, 0, 0, usdtReserve, tokensSold, _excludeFee);
    }
    
    function swap(uint256 _expectedToAmount, uint16 _slippage, bool _excludeFee) external
    {
        require(_expectedToAmount > 0, "ERR_ZERO_EXP_AMOUNT");
        require(_slippage <= 500, "ERR_SLIPPAGE_TOO_BIG");
        
        uint256 usdtAmount = usdtToken.allowance(msg.sender, address(this));
        require(usdtAmount > 0, ERR_ZERO_PAYMENT);
        
        (uint256 actualToAmount, uint256 usdtFeeAdd, uint256 actualUsdtAmount)
            = priceCalculator.calc(usdtAmount, _expectedToAmount, _slippage, usdtReserve, tokensSold, _excludeFee);
            
        require(actualToAmount > 0, "ERR_ZERO_ACTUAL_TO_AMOUNT");
        require(actualUsdtAmount == usdtAmount, "ERR_WRONG_PAYMENT_AMOUNT");
        
        usdtToken.transferFrom(msg.sender, address(this), usdtAmount);
        
        usdtFee = usdtFee.add(usdtFeeAdd);
        usdtReserve = usdtReserve.add(usdtAmount.sub(usdtFeeAdd));
        tokensSold = tokensSold.add(actualToAmount);
        
        sellToken.transfer(msg.sender, actualToAmount);
     
        emit Swap(usdtAmount, _expectedToAmount, _slippage, usdtFeeAdd, actualToAmount, tokensSold);
    }
}
