pragma solidity ^0.4.17;

import "./ETHToken.sol";
import "./Ownable.sol";

contract ICO is Ownable {

    //allows to use the SafeMath functions on the uint256 data type.
    using SafeMath for uint256;

    //EEE will be used to create a new instance of the token contract. 
    ETHToken public EEE;    

    //rate is for how many tokens 1 ETH equates to.
    uint256 public rate;  

    //this will can be written as startTime = now, or now.add(x amount of seconds/minutes/hours/days/weeks/years).   
    uint256 public startTime; 

    //this can be written as endTime = startTime.add(y amount of seconds/minutes/hours/days/weeks/years).
    uint256 public endTime;

    //tokensSold will be updated everytime new tokens are minted.
    uint256 public tokensSold;

    //a maximum amount of tokens to be sold during the preICO. 
    uint256 public tokensForPreIco;

    //the maximum amount of tokens to be sold in total, this number should include the tokens for pre ICO and 
    //should be >= tokensForPreIco.
    uint256 public totalTokensForSale;

    //preIcoStages is an array with 4 indexes. In each index, a timestamp will be stored. For example:
    //week 1: preIcoStages[0] = now.add(7 days)  
    //week 2: preIcoStages[1] = now.add(14 days)
    //week 3: preIcoStages[2] = now.add(21 days)
    //week 4: preIcoStages[3] = now.add(28 days)
    uint256[4] public preIcoStages;

    //IcoStages is also an array with 4 indexes. In each index, a timestamp that is greater than preIcoStages[3]
    //will be stored. For example:
    //week 1: icoStages[0] = now.add(35 days) and so on.
    uint256[4] public icoStages;
    
    event TokensPurchased(address indexed by, uint256 messageValue, uint256 tokens);
    event SoldOut();

    /**
     * Constructor deploys new instance of the ETHToken contract, sets the
     * start time to 72 days from the moment of deployment, initializes the 
     * end time to be 30 days after the start time, assigns a rate of 100
     * NCO per ETH and sets a soft and hard cap to 21686 - 27108 ETH.
     */
    function ICO() public {

        //deploys the ETHToken contract and stores it in EEE.
        EEE = new ETHToken();

        //mints 1,000,000 tokens to the owner.
        EEE.mintTokens(owner, 1000000e18); 

        //the pre ICO will begin as soon as the contract is deployed.
        startTime = now;

        //total duration of the presale and ICO.
        endTime = startTime.add(60 days);

        //1 ETH = 100 EEE tokens
        rate = 100;

        //1,000,000 for pre ICO. Please note, e18 covers the decimals and is a nicer way 
        //of writing 1000000* 10**18.
        tokensForPreIco = 1000000e18;

        //3,000,000 tokens in total. This includes the tokensForPreIco. If not all
        //1,000,000 tokens are sold during the pre ICO, then they will still be available
        //for sale when the pre ICO duration has ended. 
        totalTokensForSale = 3000000e18;

        tokensSold = 0;

        //sets the first stage of the pre sale to be 7 days long.
        preIcoStages[0] = startTime.add(7 days);

        //sets every other pre ICO stage to be 7 days longer than the previous stage.
        for (uint i = 1; i < preIcoStages.length; i++) {
            preIcoStages[i] = preIcoStages[i - 1].add(7 days);
        }

        //sets the ICOs first stage to be 7 days longer than the pre ICO's last stage.
        icoStages[0] = preIcoStages[3].add(7 days);

        //sets every other stage of the ICO to be 7 days longer than the previous stage.
        for (uint y = 1; y < icoStages.length; y++) {
            icoStages[y] = icoStages[y - 1].add(7 days);
        }
    }

    /**
     * Fallback function calls the buy tokens function when ETH is sent to 
     * the ICO address.
     */
    function() public payable {
        buyTokens(msg.sender);
    }

    /**
     * Sends an appropriate amount of NCO tokens to a specified ETH address 
     * by multiplying the rate by the amount of ETH that was sent to the 
     * contract.
     *
     * This function will not continue to execute once the hard cap of 27108
     * ETH has been raised. It will also fail to execute if the ICO period 
     * has not started yet, or if the 30 day duration is over. If anyone 
     * attempts to send ETH during any of these circumstances, they will be
     * automatically refunded. 
     *
     * @param _addr The address of the recipient. 
     */
    function buyTokens(address _addr) public payable {
        //requirement ensures that the total tokens sold cannot exceed the totalTokensForSale
        require(tokensSold.add(msg.value.mul(getRateWithBonus())) <= totalTokensForSale);
        //requirement checks if the purchase is valid and that the address is not null
        require(validPurchase() && _addr != 0x0);
        //calculates the tokens to mint based on the msg.value * with the rate and current bonus.
        uint256 toMint = msg.value.mul(getRateWithBonus());
        //ensures that the total token sales during the presale does not exceed tokensForPreIco.
        if (now <= preIcoStages[3] && tokensSold.add(toMint) > tokensForPreIco) {
            //revert() is the same as throw, however throw is depricated in favour of revert() and assert()
            revert();
        }
        //invokes the mint function of ETHToken in the Mintable contract.
        EEE.mintTokens(_addr, toMint);
        //updates the total amount of tokens sold.
        tokensSold = tokensSold.add(toMint);
        //TokensPurchased event is triggered. 
        TokensPurchased(_addr, msg.value, toMint);
        //the investment made is sent to the owner of the contract with forwardFunds().
        forwardFunds();
        //if all tokens have sold out, trigger the event SoldOut.
        if (tokensSold == totalTokensForSale) {
            SoldOut();
        }
    }

    /**
     * Calculates the rate with the current bonus. In this example of the contract
     * the rate has been sent to 1 ETH = 100 tokens, so the prices for the 60 day
     * duration are as follows:
     *
     * ----------- PRE ICO ------------------
     * day 1  - 7  / week 1: 145 tokens / 45%
     * day 7  - 14 / week 2: 140 tokens / 40%
     * day 14 - 21 / week 3: 135 tokens / 35%
     * day 21 - 28 / week 4: 130 tokens / 30%
     * --------------------------------------
     *
     * -------------- ICO -------------------
     * day 28 - 35 / week 5: 120 tokens / 20%
     * day 35 - 42 / week 6: 115 tokens / 15%
     * day 42 - 49 / week 7: 110 tokens / 10%
     * day 49 - 56 / week 8: 105 tokens / 5%
     * day 56 - 60 / week 9: 100 tokens / 0%
     * --------------------------------------
     *
     * Please note that you can change the bonus percentages in the getPreIcoPercentage()
     * function and the getIcoPercentage() function.
     */
    function getRateWithBonus() internal returns (uint256) {
        //if the preIco has not ended and the token sales are less than tokensForPreIco.
        if (now <= preIcoStages[3] && tokensSold < tokensForPreIco) {
            //compute the current rate with bonus in the presale bonus stages.
            return rate.mul(getPreIcoBonusPercentage()).div(100).add(rate);
        }
        //if the preIco has ended and the token sales are less than the totalTokensForSale.
        if (now > preIcoStages[3] && tokensSold < totalTokensForSale) {
            //compute the current rate with bonus in the ICO bonus stages.
            return rate.mul(getIcoBonusPercentage()).div(100).add(rate);
        }
        //if none of the statements above are true, just return the rate without the bonus.
        return rate;
    }

    /**
     * Function is called when the buy function is invoked  during pre sale and returns 
     * the current bonus in percentage. In this example, the bonus starts at 45% and reduces by
     * 5% for every bonus period that has passed. 
     *
     * day 1  - 7  / week 1: 45%
     * day 7  - 14 / week 2: 40%
     * day 14 - 21 / week 3: 35%
     * day 21 - 28 / week 4: 30%
     */
    function getPreIcoBonusPercentage() internal returns (uint256 _percent) {
        //first bonus is set to 45%
        _percent = 45;
        for (uint i = 0; i < preIcoStages.length; i++) {
            //if the current timestamp is less than preIcoStages[i] then break out of the loop 
            if (now <= preIcoStages[i]) {
                break;
            } else {
                //subtract _percent by 5 with each iteration of the loop.
                _percent = _percent.sub(5);
            }
        }
        return _percent;
    }

    /**
     * Function is called when the buy function is invoked  only after the pre sale duration and returns 
     * the current bonus in percentage. In this example, the bonus starts at 20% and reduces by 5% for 
     * every bonus period that has passed. After the 8th week, the bonus percentage will be set to 0.
     *
     * day 28 - 35   / week 5: 20%
     * day 35 - 42   / week 6: 15%
     * day 42 - 49   / week 7: 10%
     * day 49 - 56   / week 8:  5%
     * day 56 - 60   / week 9:  0%
     */
    function getIcoBonusPercentage() internal returns (uint256 _percent) {
        //if all bonus stages have passed, i.e more than 8 weeks, then _percent will be assigned 0.
        if (now > icoStages[3]) {
            _percent = 0;
        } else {
            //the percentage starts from 20.
            _percent = 20;
            for (uint i = 0; i < icoStages.length; i++) {
                //if the current timestamp is less than icoStages[i] then break out of the loop 
                if (now <= icoStages[i]) {
                    break;
                } else {
                    //reduce _percent by 5 with each iteration of the loop.
                    _percent = _percent.sub(5);
                }
            }
        }
        return _percent;
    }

    /**
     * Transfers the funds received to the owner of the contract in real time.
     */
    function forwardFunds() internal {
        owner.transfer(msg.value);
    }

    /**
     * Invoked by the buyTokens() function to ensure that investments can only be made
     * during the pre sale and ICO period and that the total investment is greater than 0.
     */
    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

    /**
     * This function has been added incase you would like to mint new tokens. The reason for
     * adding this here is because only the owner of the token contract can mint new tokens,
     * and the owner of the token contract is the ICO contract because the ICO contract is the 
     * ETH address which deployed the token contract. You will also notice that the onlyOwner
     * modifier has been added in the method signature, this means that only the owner of the 
     * ICO contract will be allowed to mint new tokens. When this function is invoked, the ICO 
     * contract will then call the mintTokens function of the token contract and since the 
     * ICO contract is the owner of the token contract, the function will execute successfully.
     *
     * @param _addr The address of the recipient.
     * @param _value The amount of tokens to be minted.
     */
    function mintTokens(address _addr, uint256 _value) public onlyOwner {
        require(_addr != 0x0 && _value > 0);
        //you could also include the commented lines of code to ensure the maximum supply is 
        //never exceded when invoking this function: 
        
        //require(tokensSold.add(_value) <= totalTokensForSale)
        //tokensSold = tokensSold.add(_value) 
        // if (tokensSold == totalTokensForSale) {
        //     SoldOut();
        // }
        EEE.mintTokens(_addr, _value);
    }

    /**
     * Terminates the minting period permanently. This function is restricted and can
     * only be executed by the owner of the contract given that the ICO duration has ended. 
     */
    function finishMintingPeriod() public onlyOwner {
        require(now > endTime);
        EEE.finishMinting();
    }

    /**
     * Returns the amount of tokens sold at any given time.
     */
    function tokensSold() public constant returns(uint256) {
        return tokensSold;
    }
}

