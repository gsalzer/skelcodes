pragma solidity 0.4.25;

import "./RefundableCrowdsale.sol";
import "./IERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Detailed.sol";
import "./Ownable.sol";

contract BitbookCrowdsale is Ownable, RefundableCrowdsale {
    
    // amount of tokens sold
    uint256 private _totalTokensSold;
    
    ////////////////////////////////////
    //        DATES AND LIMITS
    ////////////////////////////////////
    
    mapping (uint8 => uint256) private _hardcaps;
    mapping (uint8 => uint256) private _minInvestments;
    mapping (uint8 => uint8) private _bonuses;
    mapping (uint8 => uint256) private _tokensSold;
    
    // private sale timestamps
    // uint256 private _privateSaleStartTime; ->  openingTime()
    uint256 private _privateSaleEndTime = 1548979200;
    
    // pre-sale timestamps
    // uint256 private _preSaleStartTime = 1543336832; -> _privateSaleEndTime
    uint256 private _preSaleEndTime = 1550275200;
    
    // main-sale timestamps
    // uint256 private _mainSaleStartTime = 1543337132; not used
    // uint256 private _mainSaleEndTime; ->  closingTime()

    //       END OF DATES AND LIMITS
    
    
    constructor (uint256 rate, address wallet, IERC20 tokenAddress) public 
    Crowdsale(rate, wallet, tokenAddress)
    TimedCrowdsale(1547553600, 1554076800)
    RefundableCrowdsale(60 * 10 ** 6 * (10 ** 18))
    {
        
        _hardcaps[0] = 120 * 10 ** 6 * (10 ** uint256(ERC20Detailed(token()).decimals()));
        _hardcaps[1] = 80 * 10 ** 6 * (10 ** uint256(ERC20Detailed(token()).decimals()));
        _hardcaps[2] = 220 * 10 ** 6 * (10 ** uint256(ERC20Detailed(token()).decimals()));
        
        _minInvestments[0] = 1 * 10 ** 6 * (10 ** uint256(ERC20Detailed(token()).decimals()));
        _minInvestments[1] = 2 * 10 ** 4 * (10 ** uint256(ERC20Detailed(token()).decimals()));
        //_minInvestments[0] = 10000;
        //_minInvestments[1] = 20000;
        // _minInvestments[2] = 0;
        
        _bonuses[0] = 0;
        _bonuses[1] = 0;
        _bonuses[2] = 0;
    }
    
    /**
     * @return current stag.
    */
    function getStage() public view onlyWhileOpen returns (uint8) {
        uint256 currentTime = block.timestamp;
        if (currentTime >= openingTime() && currentTime <= _privateSaleEndTime) {
            // private sale
            return 0;
        }
        else if (currentTime > _privateSaleEndTime && currentTime < _preSaleEndTime) {
            // pre-sale
            return 1;
        }
        else {
            // no condition needed because end of crowdsale checks in onlyWhileOpen modifier
            // main sale
            return 2;
        }
    }
    
    /**
     * @return the amount of tokens sold.
     */
    function totalTokensSold() public view returns (uint256) {
        return _totalTokensSold;
    }
    
    /**
     * @return the amount of tokens sold on current stage.
    */
    function tokensSoldOnCurrentStage() public view returns (uint256) {
        return _tokensSold[getStage()];
    }
    
    /**
     * @return hardcap on current stage.
    */
    function hardcapOnCurrentStage() public view returns (uint256) {
        return _hardcaps[getStage()];
    }
    
    /**
     * @return minimum amount of tokens to be sold
     */
    function goal() public view returns (uint256) {
        return 60 * 10 ** 6 * (10 ** uint256(ERC20Detailed(token()).decimals()));
    }
    
    /**
     * @dev Checks whether tokens sold goal was reached.
     * @return Whether tokens sold goal was reached
     */
    function goalReached() public view returns (bool) {
        return totalTokensSold() >= goal();
    }
    
    /**
     * @dev Set new rate.
    */
    function setRate(uint256 rate) external onlyOwner {
        require(rate != 0);
        _rate = rate;
    }
    
    /**
     * @dev escrow finalization task, called when finalize() is called
     */
    function _finalization() internal {
        super._finalization();
        ERC20Burnable(token()).burn(token().balanceOf(address(this)));
    }
    
    /**
     * @dev Increase amount of tokens sold by value, which beneficiary will get. 
     * Also increase amount of tokens sold in current stage
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        super._deliverTokens(beneficiary, tokenAmount);
        _totalTokensSold = _totalTokensSold.add(tokenAmount);
        uint8 stage = getStage();
        _tokensSold[stage] = _tokensSold[stage].add(tokenAmount);
    }
    
    /**
     * @dev Revert if purchased tokens amount is less then minimum investment.
    */
    function _validateMinInvestment(uint256 tokenAmount, uint8 stage) internal view {
        require(tokenAmount >= _minInvestments[stage]);
    }
    
    /**
     * @dev Revert if hardcap is reached.
    */
    function _validateCap(uint256 tokenAmount, uint8 stage) internal view {
        require(_tokensSold[stage] + tokenAmount <= _hardcaps[stage]);
    }
    
    /**
     * @dev Calculate bonus and validate purchased and received tokens amount.
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        uint256 tokenAmount = super._getTokenAmount(weiAmount);
        uint8 stage = getStage();
        
        _validateMinInvestment(tokenAmount, stage);
        
        uint256 purchaseBonus = 0;
        if (_bonuses[stage] != 0) {
            purchaseBonus = tokenAmount.mul(_bonuses[stage]).div(100);
        }
        tokenAmount = tokenAmount.add(purchaseBonus);
        
        _validateCap(tokenAmount, stage);
        
        return tokenAmount;
    }
    
    /**
     * @dev Externally token purchase (for beneficiaries who will pay through PayPal or BTC)
     * @param beneficiary Recipient of the token purchase
     * @param tokenAmount Number of tokens to be emitted
    */
    function buyTokensExternally(address beneficiary, uint256 tokenAmount) external onlyOwner onlyWhileOpen {
        require(! finalized());
        uint8 stage = getStage();
        _validateMinInvestment(tokenAmount, stage);
        _validateCap(tokenAmount, stage);
        _deliverTokens(beneficiary, tokenAmount);
        emit TokensPurchased(beneficiary, beneficiary, 0, tokenAmount);
    }
}

