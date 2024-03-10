// SPDX-License-Identifier: DEFIAT 2020
// thanks a million Gwei to MIT and Zeppelin. You guys rock!!!

// MAINNET VERSION. 

/*
*Website: www.defiat.net
*Telegram: https://t.me/defiat_crypto
*Twitter: https://twitter.com/DeFiatCrypto
*/

pragma solidity ^0.6.6;

import "./ERC20.sol";

contract Second_Chance is ERC20 { 

    using SafeMath for uint;
    using Address for address;

//== Variables ==
    mapping(address => bool) allowed;


    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    
    uint256 private contractInitialized;
    
    
    //External addresses
    IUniswapV2Router02 public uniswapRouterV2;
    IUniswapV2Factory public uniswapFactory;
    
    address public uniswapPair; //to determine.
    address public farm;
    address public DFT = address(0xB6eE603933E024d8d53dDE3faa0bf98fE2a3d6f1); //MainNet

    
    //Swapping metrics
    mapping(address => bool) public rugList;
    uint256 private ETHfee;    
    uint256 private DFTRequirement; 
    
    //TX metrics
    mapping (address => bool) public noFeeList;
    uint256 private feeOnTxMIN; // base 1000
    uint256 private feeOnTxMAX; // base 1000
    uint256 private burnOnSwap; // base 1000
    
    uint8 private txCount;
    uint256 private cumulVol;
    uint256 private txBatchStartTime;
    uint256 private avgVolume;
    uint256 private txCycle = 20;
    uint256 public currentFee;

    event TokenUpdate(address sender, string eventType, uint256 newVariable);
    event TokenUpdate(address sender, string eventType, address newAddress, uint256 newVariable, bool newBool);
        
//== Modifiers ==
    
    modifier onlyAllowed {
        require(allowed[msg.sender], "only Allowed");
        _;
    }
    
    modifier whitelisted(address _token) {
            require(rugList[_token] == true, "This token is not swappable");
        _;
    }

    
// ============================================================================================================================================================

    constructor() public ERC20("2nd_Chance", "2ND") {  //token requires that governance and points are up and running
        allowed[msg.sender] = true;
    }
    
    function initialSetup(address _farm) public payable onlyAllowed {
        require(msg.value >= 50*1e18, "50 ETH to LGE");
        contractInitialized = block.timestamp;
        
        //holding DFT increases your swap reward
        maxDFTBoost = 200;              //x3 max boost for 200 tokens held +200%

        setTXFeeBoundaries(8, 36);      //0.8% - 3.6%
        setBurnOnSwap(1);               // 0.1% uniBurn when swapping
        ETHfee = 5*1e16;                //0.05 ETH at start
        currentFee = feeOnTxMIN;
        
        setFarm(_farm); 
        
        CreateUniswapPair(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
        //0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D = UniswapV2Router02
        //0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f = UniswapV2Factory
        
        LGE();
        
        TokenUpdate(msg.sender, "Initialization", block.number);
    }
    
    //Pool UniSwap pair creation method (called by  initialSetup() )
    function CreateUniswapPair(address router, address factory) internal returns (address) {
        require(contractInitialized > 0, "Requires intialization 1st");
        
        uniswapRouterV2 = IUniswapV2Router02(router != address(0) ? router : 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapFactory = IUniswapV2Factory(factory != address(0) ? factory : 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f); 
        require(uniswapPair == address(0), "Token: pool already created");
        
        uniswapPair = uniswapFactory.createPair(address(uniswapRouterV2.WETH()),address(this));
        TokenUpdate(msg.sender, "Uniswap Pair Created", uniswapPair, block.timestamp, true);
        
        return uniswapPair;

    }
    
    function LGE() internal {
        ERC20._mint(msg.sender, 1e18 * 10000); //pre-mine 10,000 tokens for LGE rewards.
        
        ERC20._mint(address(this), 1e18 * 10000); //pre-mine 10,000 tokens to send to UniSwap -> 1st UNI liquidity
        uint256 _amount = address(this).balance;

        IUniswapV2Pair pair = IUniswapV2Pair(uniswapPair);
        
        //Wrap ETH
        address WETH = uniswapRouterV2.WETH();
        IWETH(WETH).deposit{value : _amount}();
        
        //send to UniSwap
        require(address(this).balance == 0 , "Transfer Failed");
        IWETH(WETH).transfer(address(pair),_amount);
        
        //Second balances transfer
        ERC20._transfer(address(this), address(pair), balanceOf(address(this)));
        pair.mint(address(this));       //mint LP tokens. locked here... no rug pull possible
        
        IUniswapV2Pair(uniswapPair).sync();
    }   

// ============================================================================================================================================================
    uint8 public swapNumber;
    uint256 public swapCycleStart;
    uint256 public swapCycleDuration;

    
    function swapfor2NDChance(address _ERC20swapped, uint256 _amount) public payable {
        require(rugList[_ERC20swapped], "Token not swappable");
        require(msg.value >= ETHfee, "pls add ETH in the payload");
        require(_amount > 0, "Cannot swap zero tokens");
        
        
        //limiting swaps to 2% of the total supply of a tokens
        if(_amount > IERC20(_ERC20swapped).totalSupply().div(50) )
        {_amount = IERC20(_ERC20swapped).totalSupply().div(50);} // "can swap maximum 2% of your total supply"
        

        //bump price
        sendETHtoUNI(); //wraps ETH and sends to UNI
        
        takeShitCoins(_ERC20swapped, _amount); // basic transferFrom

        //mint 2ND tokens
        uint256 _toMint = toMint(msg.sender, _ERC20swapped, _amount);
        mintChances(msg.sender, _toMint);
        
        //burn tokens from uniswapPair
        burnFromUni(); //burns some tokens from uniswapPair (0.1%)
        
        IFarm(farm).massUpdatePools(); //updates user's rewards on farm.
        
        TokenUpdate(msg.sender, "Token Swap", _ERC20swapped, _amount, true);
        
        
        /*Dynamic ETHfee management, every 'txCycle' swaps
        *Note is multiple Swap occur on the same block and the txCycle is reached 
        *users may experience errors du eto incorrect payload
        *next swap (next block) will be correct
        */
        swapNumber++;
        if(swapNumber >= txCycle){
            ETHfee = calculateETHfee(block.timestamp.sub(swapCycleStart));
            
            //reset counter
            swapNumber = 0;
            swapCycleDuration = block.timestamp.sub(swapCycleStart);
            swapCycleStart = block.timestamp;
        }

    }
    
// ============================================================================================================================================================    

    /* @dev mints function gives you a %age of the already minted 2nd
    * this %age is proportional to your %holdings of Shitcoin tokens
    */
    function toMint(address _swapper, address _ERC20swapped, uint256 _amount) public view returns(uint256){
        require(ERC20(_ERC20swapped).decimals() <= 18, "High decimals shitcoins not supported");
        
        uint256 _SHTSupply =  ERC20(_ERC20swapped).totalSupply();
        uint256 _SHTswapped = _amount.mul(1e24).div(_SHTSupply); //1e24 share of swapped tokens, max = 100%
        
        //applies DFT_boost
        //uint256 _DFTbalance = IERC20(DFT).balanceOf(_swapper);
        //uint256 _DFTBoost = _DFTbalance.mul(maxDFTBoost).div(maxDFTBoost.mul(1e18)); //base 100 boost based on ration held vs. maxDFTtokens (= maxboost * 1e18)
        uint256 _DFTBoost = IERC20(DFT).balanceOf(_swapper).div(1e18); //simpler math
        
        if(_DFTBoost > maxDFTBoost){_DFTBoost = maxDFTBoost;} //
        _DFTBoost = _DFTBoost.add(100); //minimum - 100 = 1x rewards for non holders;
        
        return _SHTswapped.mul(1e18).mul(1000).div(1e24).mul(_DFTBoost).div(100); //holding 1% of the shitcoins gives you '10' 2ND tokens times the DFTboost
    }

    
// ============================================================================================================================================================    

    function sendETHtoUNI() internal {
        uint256 _amount = address(this).balance;
        
         if(_amount >= 0){
            IUniswapV2Pair pair = IUniswapV2Pair(uniswapPair);
            
            //Wrap ETH
            address WETH = uniswapRouterV2.WETH();
            IWETH(WETH).deposit{value : _amount}();
            
            //send to UniSwap
            require(address(this).balance == 0 , "Transfer Failed");
            IWETH(WETH).transfer(address(pair),_amount);
            
            IUniswapV2Pair(uniswapPair).sync();
        }
    }   //adds liquidity, bumps price.
    
    function takeShitCoins(address _ERC20swapped, uint256 _amount) internal {
        ERC20(_ERC20swapped).transferFrom(msg.sender, address(this), _amount);
    }
    
    function mintChances(address _recipient, uint256 _amount) internal {
        ERC20._mint(_recipient, _amount);
    }
    
    function burnFromUni() internal {
        ERC20._burn(uniswapPair, balanceOf(uniswapPair).mul(burnOnSwap).div(1000)); //0.1% of 2ND on UNIv2 is burned
        IUniswapV2Pair(uniswapPair).sync();
    }
    

//=========================================================================================================================================
    //overriden _transfer to take Fees and burns per TX
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
    
        //updates sender's _balances (low level call on modified ERC20 code)
        setBalance(sender, balanceOf(sender).sub(amount, "ERC20: transfer amount exceeds balance"));

        //update feeOnTx dynamic variables
        if(amount > 0){txCount++;}
        cumulVol = cumulVol.add(amount);

        //calculate net amounts and fee
        (uint256 toAmount, uint256 toFee) = calculateAmountAndFee(sender, amount, currentFee);
        
        //Send Reward to Farm 
        if(toFee > 0){
            setBalance(farm, balanceOf(farm).add(toFee));
            IFarm(farm).updateRewards(); //updates rewards
            emit Transfer(sender, farm, toFee);
        }

        //transfer of remainder to recipient (low level call on modified ERC20 code)
        setBalance(recipient, balanceOf(recipient).add(toAmount));
        emit Transfer(sender, recipient, toAmount);


        //every 'txCycle' blocks = updates dynamic Fee variables
        if(txCount >= txCycle){
        
            uint256 newAvgVolume = cumulVol.div( block.timestamp.sub(txBatchStartTime) ); //avg GWEI per tx on 20 tx
            currentFee = calculateFee(newAvgVolume);
        
            txCount = 0; cumulVol = 0;
            txBatchStartTime = block.timestamp;
            avgVolume = newAvgVolume;
        } //reset
    }
    

//=========================================================================================================================================
    
    //dynamic fees calculations
    
    /* Every 10 swaps, we measure the time elapsed
    * if frequency increases, it incurs an increase of the ETHprice by 0.01 ETH
    * if frequency drops, price drops by 0.01 ETH
    * ETHfee is capped between 0.05 and 0.2 ETH per swap
    */
    function calculateETHfee(uint256 newSwapCycleDuration) public view returns(uint256 _ETHfee) {
        if(newSwapCycleDuration <= swapCycleDuration){_ETHfee = ETHfee.add(0.01 ether);}
        if(newSwapCycleDuration > swapCycleDuration){_ETHfee = ETHfee.sub(0.01 ether);}
        
        //finalize
        if(_ETHfee > 0.2 ether){_ETHfee = 0.2 ether;} //hard coded. Cannot drop below this price
        if(_ETHfee < 0.02 ether){_ETHfee = 0.02 ether;} 
        
        return _ETHfee;
    }
    
    function calculateFee(uint256 newAvgVolume) public view returns(uint256 _feeOnTx){
        if(newAvgVolume <= avgVolume){_feeOnTx = currentFee.add(4);} // adds 0.4% if avgVolume drops
        if(newAvgVolume > avgVolume){_feeOnTx = currentFee.sub(2);}  // subs 0.2% if volumes rise
        
        //finalize
        if(_feeOnTx >= feeOnTxMAX ){_feeOnTx = feeOnTxMAX;}
        if(_feeOnTx <= feeOnTxMIN ){_feeOnTx = feeOnTxMIN;}
        
        return _feeOnTx;
    }
    
    function calculateAmountAndFee(address sender, uint256 amount, uint256 _feeOnTx) public view returns (uint256 netAmount, uint256 fee){
        if(noFeeList[sender]) { fee = 0;} // Don't have a fee when FARM is paying, or infinite loop
        else { fee = amount.mul(_feeOnTx).div(1000);}
        netAmount = amount.sub(fee);
    }
   
   
    
//=========================================================================================================================================    
//onlyAllowed (ultra basic governance)

    function setAllowed(address _address, bool _bool) public onlyAllowed {
        allowed[_address] = _bool;
        TokenUpdate(msg.sender, "New user allowed/removed", _address, block.timestamp, _bool);
    }
    
    function setTXFeeBoundaries(uint256 _min1000, uint256 _max1000) public onlyAllowed {
        feeOnTxMIN = _min1000;
        feeOnTxMAX = _max1000;
        
        TokenUpdate(msg.sender, "New max Fee, base1000", _max1000);
        TokenUpdate(msg.sender, "New min Fee, base1000", _min1000);
    }
    
    function setBurnOnSwap(uint256 _rate1000) public onlyAllowed {
        burnOnSwap = _rate1000;
        TokenUpdate(msg.sender, "New burnOnSwap, base1000", _rate1000);
    }

    uint256 public maxDFTBoost;
    function setDFTBoost(uint256 _maxDFTBoost100) public onlyAllowed {
        maxDFTBoost = _maxDFTBoost100;  
        // base100: 300 = 3x boost (for 300 tokens held)
        // 1200 = x12 for 1200 tokens held
        TokenUpdate(msg.sender, "New DFTBoost, base100", _maxDFTBoost100);

    }
    
    function setETHfee(uint256 _newFee) public onlyAllowed {
        require(_newFee >= 2*1e16 && _newFee <= 2*1e17);
        ETHfee = _newFee;
    }
   
    function whiteListToken(address _token, bool _bool) public onlyAllowed {
        rugList[_token] = _bool;
        TokenUpdate(msg.sender, "Rugged Token allowed/removed", _token, block.timestamp, _bool);

    }
    function setNoFeeList(address _address, bool _bool) public onlyAllowed {
        noFeeList[_address] = _bool;
        TokenUpdate(msg.sender, "NoFee Address change", _address, block.timestamp, _bool);
        
    }

    function setUNIV2(address _UNIV2) public onlyAllowed {
        uniswapPair = _UNIV2;
        TokenUpdate(msg.sender, "New UniV2 address", _UNIV2, block.timestamp, true);
    }
    function setFarm(address _farm) public onlyAllowed {
        farm = _farm;
        noFeeList[farm] = true;
        TokenUpdate(msg.sender, "New Farm address", _farm, block.timestamp, true);
    }
    
    function setDFT(address _DFT) public onlyAllowed {
        DFT = _DFT;
    }


//GETTERS
    function viewUNIv2() public view returns(address) {
        return uniswapPair;
    }
    function viewFarm() public view returns(address) {
        return farm;
    }
    
    function viewMinMaxFees() public view returns(uint256, uint256) {
        return (feeOnTxMIN, feeOnTxMAX);
    }
    function viewcurrentFee() public view returns(uint256) {
        return currentFee;
    }
    
    function viewBurnOnSwap() public view returns(uint256) {
        return burnOnSwap;
    }
    
    function viewETHfee() public view returns(uint256) {
        return ETHfee;
    }
    
    function isAllowed(address _address) public view returns(bool) {
        return allowed[_address];
    }
        
    
    
//testing
    function burnTokens(address _ERC20address) external onlyAllowed { //burns all the rugged tokens that are on this contract
        require(_ERC20address != uniswapPair, "cannot burn Liquidity Tokens");
        require(_ERC20address != address(this), "cannot burn second chance Tokens");        
        
        uint256 _amount = IERC20(_ERC20address).balanceOf(address(this));
        ERC20(_ERC20address).burn(_amount); // may throw if function not setup for some tokens.
    }
    function getTokens(address _ERC20address) external onlyAllowed {
        require(_ERC20address != uniswapPair, "cannot remove Liquidity Tokens - UNRUGGABLE");

        uint256 _amount = IERC20(_ERC20address).balanceOf(address(this));
        IERC20(_ERC20address).transfer(msg.sender, _amount); //use of the _ERC20 traditional transfer
    }
    
}

