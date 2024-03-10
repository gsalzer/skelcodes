pragma solidity ^0.5.0;

import "./erc20.sol";


contract TokenSale is Ownable {
    using SafeMath for uint256;
    Token public token;
    address payable public wallet;
    uint256 public _weiRaised;
    uint256 private _openingTime;
    uint256 private _closingTime;

    //_openingTime = 1572566400;
    //_closingTime = 1575158400;
    
    uint256 public tokenPrice = 5714200000000;
    uint256 private decimals = 1000000000000000000;
    
    constructor (address payable _wallet, Token _token, uint256 openingTime, uint256 closingTime) public {
        require(_wallet != address(0), "Crowdsale: wallet is the zero address");
        require(address(_token) != address(0), "Crowdsale: token is the zero address");
        // require(openingTime >= block.timestamp);
        require(closingTime > openingTime);
        
        wallet = _wallet;
        token = _token;

        _openingTime = openingTime;
        _closingTime = closingTime;
    }
    

    function setTokenPrice (uint256 price) public onlyOwner{
        tokenPrice = price;
    }

    function getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.div(tokenPrice);
     }

  
    function buyToken() public payable {
        if(isOpen()){
        uint256 weiAmount = msg.value;
        uint256 tokenToTransfer = getTokenAmount(weiAmount);
        
        require((weiAmount * tokenPrice) <= token.balanceOf(address(this)));
         _deliverTokens(msg.sender, tokenToTransfer * decimals);
         wallet.transfer(weiAmount);
        _weiRaised = _weiRaised.add(weiAmount);
        }
    }
    
    function setWallet(address payable _wallet) public onlyOwner {
        wallet = _wallet;
    }
    
    function withdrawFunds() external onlyOwner {
        wallet.transfer(address(this).balance);
    }
    
    function _preValidatePurchase(uint256 weiAmount) internal  {
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
    }
    
    function _deliverTokens(address beneficiary, uint256 _amount) internal {
        token.transfer(beneficiary, _amount);
    }
    
     function openingTime() public view returns (uint256) {
        return _openingTime;
    }
    /**
  * @return the crowdsale closing time.
  */
    function closingTime() public view returns (uint256) {
        return _closingTime;
    }

    /**
     * @return true if the crowdsale is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed.
     * @return Whether crowdsale period has elapsed
     */
    function hasClosed() public view returns (bool) {
        return block.timestamp > _closingTime;
    }
    
    function getMyBalance() public view returns (uint) {
        return token.balanceOf(msg.sender);
    }

    function getICOBalance() public view returns (uint) {
        return token.balanceOf(address(this));
    }

}



