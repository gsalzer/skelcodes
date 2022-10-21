pragma solidity ^0.4.24;


import "./SafeMath.sol";
import "./KaikenInuToken.sol";
import "./Pausable.sol";
import "./PullPayment.sol";
import "./Whitelist.sol";
import "./TokenBonus.sol";

contract Crowdsale is Pausable, PullPayment, Whitelist, TokenBonus {
    using SafeMath for uint256;

    address private wallet = 0x47C8bbEAD537e7d013034B3d83AF6f0ee84e14a2;
    address private team = 0x092406Df82C3631bC0F0D77937379c3CbaABcA8F;

    KaikenInuToken public token;

    // Presale period
    uint256 public presaleRate;                                         
    uint256 public totalTokensForPresale;                                
    bool public ICO;                                                
    bool public presale;                                                

    uint256 public rate;                                                 
    uint256 public totalTokensForSale = 20000000000000000000000000000000000000;      // 200 000 000 000 000 KaikenInu tokens will be sold
    uint256 public totalTokensForPreSale = 20000000000000000000000000000000000000;      // 200 000 000 000 000 KaikenInu tokens will be sold
    uint256 public  maxFundingGoal;                                      
    uint256 public  minFundingGoal;                                      
    bool public crowdsale;                                          

    uint256 public  REFUNDSTART;                                        
    uint256 public  REFUNDEADLINE;                                      
    uint256 public savedBalance;                                        
    uint256 public savedTokenBalance;                                   
    uint256 public savedPresaleTokenBalance;                            
    mapping (address => uint256) balances;                              

    event Contribution(address indexed _contributor, uint256 indexed _value, uint256 indexed _tokens);    
    event PayEther(address indexed _receiver, uint256 indexed _value, uint256 indexed _timestamp);         
    event BurnTokens(uint256 indexed _value, uint256 indexed _timestamp);                                 

    constructor(address _token) public {
        token = KaikenInuToken(_token);
    }

    function () public payable whenNotPaused {
        uint256 _tokensAmount;
        if (msg.sender != wallet) {
          require(ICO || presale || crowdsale);
          if (ICO || presale) {
              buyPresaleTokens(msg.sender,_tokensAmount);
          }else{
              buyTokens(msg.sender);
          }
        }
    }

    // Function to set Rate & tokens to sell for ICO
    function startPresale(uint256 _rate, uint256 _totalTokensForPresale, uint256 _maxCap, uint256 _minCap) public onlyOwner {
        presaleRate = _rate;
        totalTokensForPresale = _totalTokensForPresale;
        maxFundingGoal = _maxCap;
        minFundingGoal = _minCap;
        ICO = true;
    }

    // Function to move to the second period for presale
    function updatePresale() public onlyOwner {
        require(ICO);
        ICO = false;
        presale = true;
    }

    // Function to close the presale
    function closePresale() public onlyOwner {
        require(presale || ICO);
        ICO = false;
        presale = false;
    }

    function startCrowdsale(uint256 _rate, uint256 _maxCap, uint256 _minCap) public onlyOwner {
        require(!presale || !ICO);
        rate = _rate;
        maxFundingGoal = _maxCap;
        minFundingGoal = _minCap;
        crowdsale = true;
    }

    function closeCrowdsale() public onlyOwner{
      require(crowdsale);
	    crowdsale = false;
        REFUNDSTART = now;
	    REFUNDEADLINE = REFUNDSTART + 30 days;
    }

    function isComplete() public view returns (bool) {
        return (savedBalance >= maxFundingGoal) || (savedTokenBalance >= totalTokensForSale) || (crowdsale == false);
    }

    function isSuccessful() public view returns (bool) {
        return (savedBalance >= minFundingGoal);
    }

    function refundPeriodOver() public view returns (bool) {
        return (now > REFUNDEADLINE);
    }

    function refundPeriodStart() public view returns (bool) {
        return (now > REFUNDSTART);
    }

    function finalize() public onlyOwner {
        require(crowdsale);
        crowdsale = false;
        REFUNDSTART = now;
        REFUNDEADLINE = REFUNDSTART+ 30 days;
    }

    function payout(address _newOwner) public onlyOwner {
        require((isSuccessful() && isComplete()) || refundPeriodOver());
        if (isSuccessful() && isComplete()) {
            uint256 tokensToBurn =  token.balanceOf(address(this)).sub(savedBonusToken);
            require(token.burn(tokensToBurn));
            transferTokenOwnership(_newOwner);
            crowdsale = false;
        }else {
            if (refundPeriodOver()) {
                wallet.transfer(address(this).balance);
                emit PayEther(wallet, address(this).balance, now);
                require(token.burn(token.balanceOf(address(this))));
                transferTokenOwnership(_newOwner);
            }
        }
    }

    // Function to transferOwnership of the KaikenInu token
    function transferTokenOwnership(address _newOwner) public onlyOwner {
        token.transferOwnership(_newOwner);
    }
    
    /* When MIN_CAP is not reach the smart contract will be credited to make refund possible by backers
     * 1) backer call the "refund" function of the Crowdsale contract
     * 2) backer call the "withdraw" function of the Crowdsale contract to get a refund in ETH
     */
    function refund() public {
        require(!isSuccessful());
        require(refundPeriodStart());
        require(!refundPeriodOver());
        require(balances[msg.sender] > 0);
        uint256 amountToRefund = balances[msg.sender].mul(95).div(100);
        asyncSend(msg.sender, amountToRefund);
        balances[msg.sender] = 0;
    }

    function withdraw() public {
        withdrawPayments();
        savedBalance = address(this).balance;
    }

    function buyTokens(address buyer) public payable {
        // require(!isComplete());
        address _beneficiary;
        if (isWhitelisted(_beneficiary)) {
            uint256 tokensAmount;
            if (msg.value >= 10 ether) {
                savedBalance = savedBalance.add(msg.value);
                tokensAmount = msg.value.mul(presaleRate);
                uint256 bonus = tokensAmount.mul(30).div(100);
                savedTokenBalance = savedTokenBalance.add(tokensAmount.add(bonus));
                token.transfer(_beneficiary, tokensAmount);
                savedBonusToken = savedBonusToken.add(bonus);
                bonusBalances[_beneficiary] = bonusBalances[_beneficiary].add(bonus);
                bonusList.push(_beneficiary);
                wallet.transfer(msg.value);
                emit PayEther(wallet, msg.value, now);
            }else {
                savedBalance = savedBalance.add(msg.value);
                tokensAmount = msg.value.mul(presaleRate);
                uint256 tokensToTransfer = tokensAmount.mul(130).div(100);
                savedTokenBalance = savedTokenBalance.add(tokensToTransfer);
                token.transfer(_beneficiary, tokensToTransfer);
                wallet.transfer(msg.value);
                emit PayEther(wallet, msg.value, now);
            }
        }else {
            balances[buyer] = balances[buyer].add(msg.value);
            savedBalance = savedBalance.add(msg.value);
            savedTokenBalance = savedTokenBalance.add(msg.value.mul(rate));
            token.transfer(_beneficiary, msg.value.mul(rate));
            wallet.transfer(msg.value);
            emit PayEther(wallet, msg.value, now);
        }
    }

    function buyPresaleTokens(address buyer, uint256 _tokensAmount) public payable {
        // require(isPresaleWhitelisted(_beneficiary));
        require((savedBalance.add(msg.value)) <= maxFundingGoal);
        require((savedPresaleTokenBalance.add(msg.value.mul(presaleRate))) <= totalTokensForPresale);
        uint256 tokensAmount = _tokensAmount;

        if (msg.value >= 10 ether) {
            savedBalance = savedBalance.add(msg.value);
            tokensAmount = msg.value.mul(presaleRate);
            uint256 bonus = tokensAmount.mul(checkPresaleBonus()).div(100);
            savedTokenBalance = savedTokenBalance.add(tokensAmount.add(bonus));
            token.transfer(buyer, tokensAmount);
            savedBonusToken = savedBonusToken.add(bonus);
            bonusBalances[buyer] = bonusBalances[buyer].add(bonus);
            bonusList.push(buyer);
            wallet.transfer(msg.value);
            emit PayEther(wallet, msg.value, now);
        }else {
            savedBalance = savedBalance.add(msg.value);
            tokensAmount = msg.value.mul(presaleRate);
            uint256 tokensToTransfer = tokensAmount.add((tokensAmount.mul(checkPresaleBonus())).div(100));
            savedTokenBalance = savedTokenBalance.add(tokensToTransfer);
            token.transfer(buyer, tokensToTransfer);
            wallet.transfer(msg.value);
            emit PayEther(wallet, msg.value, now);
        }
    }

    function checkPresaleBonus() internal view returns (uint256){
        if(ICO && msg.value >= 1 ether){
          return 40000;
        }else if(presale && msg.value >= 1 ether){
          return 30000;
        }else{
          return 0;
        }
    }
}

