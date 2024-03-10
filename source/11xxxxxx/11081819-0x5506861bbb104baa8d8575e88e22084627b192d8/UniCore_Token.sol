// SPDX-License-Identifier: WHO GIVES A FUCK ANYWAY??
// but thanks a million Gwei to MIT and Zeppelin. You guys rock!!!

// MAINNET VERSION.

pragma solidity >=0.6.0;

import "./UniCore_ERC20.sol";

contract UniCore_Token is ERC20 {
    using SafeMath for uint256;
    using Address for address;

    event LiquidityAddition(address indexed dst, uint value);
    event LPTokenClaimed(address dst, uint value);

    //ERC20
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 public constant initialSupply = 1000*1e18; // 1k
    
    //timeStamps
    uint256 public contractInitialized;
    uint256 public contractStart_Timestamp;
    uint256 public LGECompleted_Timestamp;
    uint256 public constant contributionPhase =  3 days;
    uint256 public constant stackingPhase = 1 hours;
    uint256 public constant emergencyPeriod = 4 days;
    
    //Tokenomics
    uint256 public totalLPTokensMinted;
    uint256 public totalETHContributed;
    uint256 public LPperETHUnit;
    mapping (address => uint)  public ethContributed;
    uint256 public constant individualCap = 25*1e18;
    uint256 public constant totalCap = 500*1e18;
    
    
    //Ecosystem
    address public UniswapPair;
    address public wUNIv2;
    address public Vault;
    IUniswapV2Router02 public uniswapRouterV2;
    IUniswapV2Factory public uniswapFactory;
    
//=========================================================================================================================================

    constructor() ERC20("Unicore", "UNICORE") public {
        _mint(address(this), initialSupply);
        governanceLevels[msg.sender] = 2;
    }
    
    function initialSetup() public governanceLevel(2) {
        contractInitialized = block.timestamp;
        setBuySellFees(10, 10); //1% on buy, 1% on sell.
        
        POOL_CreateUniswapPair(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
        //0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D = UniswapV2Router02
        //0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f = UniswapV2Factory
    }
    
    //Pool UniSwap pair creation method (called by  initialSetup() )
    function POOL_CreateUniswapPair(address router, address factory) internal returns (address) {
        require(contractInitialized > 0, "Requires intialization 1st");
        
        uniswapRouterV2 = IUniswapV2Router02(router != address(0) ? router : 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapFactory = IUniswapV2Factory(factory != address(0) ? factory : 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f); 
        require(UniswapPair == address(0), "Token: pool already created");
        
        UniswapPair = uniswapFactory.createPair(address(uniswapRouterV2.WETH()),address(this));
        
        return UniswapPair;
    }
    
    /* Once initialSetup has been invoked
    * Team will create the Vault and the LP wrapper token
    *  
    * Only AFTER these 2 addresses have been created the users
    * can start contributing in ETH
    */
    function secondarySetup(address _Vault, address _wUNIv2) public governanceLevel(2) {
        require(contractInitialized > 0 && contractStart_Timestamp == 0, "Requires Initialization and Start");
        setVault(_Vault); //also adds the Vault to noFeeList
        wUNIv2 = _wUNIv2;
        
        require(Vault != address(0) && wUNIv2 != address(0), "Wrapper Token and Vault not Setup");
        contractStart_Timestamp = block.timestamp;
    }
    

//=========================================================================================================================================
    /* Liquidity generation logic
    * Steps - All tokens that will ever exist go to this contract
    *  
    * This contract accepts ETH as payable
    * ETH is mapped to people
    *    
    * When liquidity generation event is over 
    * everyone can call the mint LP function.
    *    
    * which will put all the ETH and tokens inside the uniswap contract
    * without any involvement
    *    
    * This LP will go into this contract
    * And will be able to proportionally be withdrawn based on ETH put in
    *
    * emergency drain function allows the contract owner to drain all ETH and tokens from this contract
    * After the liquidity generation event happened. In case something goes wrong, to send ETH back
    */

    string public liquidityGenerationParticipationAgreement = "I agree that the developers and affiliated parties of the UniCore team are not responsible for my funds";

    
    /* @dev List of modifiers used to differentiate the project phases
     *      ETH_ContributionPhase lets users send ETH to the token contract
     *      LGP_possible triggers after the contributionPhase duration
     *      Trading_Possible: this modifiers prevent Unicore _transfer right
     *      after the LGE. It gives time for contributors to stake their 
     *      tokens before fees are generated.
     */
    
    modifier ETH_ContributionPhase() {
        require(contractStart_Timestamp > 0, "Requires contractTimestamp > 0");
        require(block.timestamp <= contractStart_Timestamp.add(contributionPhase), "Requires contributionPhase ongoing");
        _;
    }
    
    /* if totalETHContributed is bigger than 99% of the cap
     * the LGE can happen (allows the LGE to happen sooner if needed)
     * otherwise (ETHcontributed < 99% totalCap), time contraint applies
     */
    modifier LGE_Possible() {
         
        if(totalETHContributed < totalCap.mul(99).div(100)){ 
        require(contractStart_Timestamp > 0 , "Requires contractTimestamp > 0");
        require(block.timestamp > contractStart_Timestamp.add(contributionPhase), "Requies contributionPhase ended");
        }
       _; 
    }
    
    modifier LGE_happened() {
        require(LGECompleted_Timestamp > 0, "Requires LGE initialized");
        require(block.timestamp > LGECompleted_Timestamp, "Requires LGE ongoing");
        _;
    }
    
    //UniSwap Cuck Machine: Blocks Uniswap Trades for a certain period, allowing users to claim and stake REACTOR
    modifier Trading_Possible() {
         require(LGECompleted_Timestamp > 0, "Requires LGE initialized");
         require(block.timestamp > LGECompleted_Timestamp.add(stackingPhase), "Requires StackingPhase ended");
        _;
    }
    

//=========================================================================================================================================
  
    // Emergency drain in case of a bug
    function emergencyDrain24hAfterLiquidityGenerationEventIsDone() public governanceLevel(2) {
        require(contractStart_Timestamp > 0, "Requires contractTimestamp > 0");
        require(contractStart_Timestamp.add(emergencyPeriod) < block.timestamp, "Liquidity generation grace period still ongoing"); // About 24h after liquidity generation happens
        
        (bool success, ) = msg.sender.call{value:(address(this).balance)}("");
        require(success, "ETH Transfer failed... we are cucked");
       
        ERC20._transfer(address(this), msg.sender, balanceOf(address(this)));
    }

//During ETH_ContributionPhase: Users deposit funds

    //funds sent to TOKEN contract.
    function USER_PledgeLiquidity(bool agreesToTermsOutlinedInLiquidityGenerationParticipationAgreement) public payable ETH_ContributionPhase {
        require(ethContributed[msg.sender].add(msg.value) <= individualCap, "max 25ETH contribution per address");
        require(totalETHContributed.add(msg.value) <= totalCap, "500 ETH Hard cap"); 
        
        require(agreesToTermsOutlinedInLiquidityGenerationParticipationAgreement, "No agreement provided");
        
        ethContributed[msg.sender] = ethContributed[msg.sender].add(msg.value);
        totalETHContributed = totalETHContributed.add(msg.value); // for front end display during LGE
        emit LiquidityAddition(msg.sender, msg.value);
    }
    
    function USER_UNPledgeLiquidity() public ETH_ContributionPhase {
        uint256 _amount = ethContributed[msg.sender];
        ethContributed[msg.sender] = 0;
        msg.sender.transfer(_amount); //MUST CALL THE ETHERUM TRANSFER, not the TOKEN one!!!
        totalETHContributed = totalETHContributed.sub(_amount);
    }


// After ETH_ContributionPhase: Pool can create liquidity.
// Vault and wrapped UNIv2 contracts need to be setup in advance.

    function POOL_CreateLiquidity() public LGE_Possible {

        totalETHContributed = address(this).balance;
        IUniswapV2Pair pair = IUniswapV2Pair(UniswapPair);
        
        //Wrap eth
        address WETH = uniswapRouterV2.WETH();
        
        //Send to UniSwap
        IWETH(WETH).deposit{value : totalETHContributed}();
        require(address(this).balance == 0 , "Transfer Failed");
        IWETH(WETH).transfer(address(pair),totalETHContributed);
        
        emit Transfer(address(this), address(pair), balanceOf(address(this)));
        
        //UniCore balances transfer
        ERC20._transfer(address(this), address(pair), balanceOf(address(this)));
        pair.mint(address(this));       //mint LP tokens. lock method in UniSwapPairV2 PREVENTS FROM DOING IT TWICE
        
        totalLPTokensMinted = pair.balanceOf(address(this));
        
        require(totalLPTokensMinted != 0 , "LP creation failed");
        LPperETHUnit = totalLPTokensMinted.mul(1e18).div(totalETHContributed); // 1e18x for  change
        require(LPperETHUnit != 0 , "LP creation failed");
        
        LGECompleted_Timestamp = block.timestamp;
    }
    
 
//After ETH_ContributionPhase: Pool can create liquidity.
    function USER_ClaimWrappedLiquidity() public LGE_happened {
        require(ethContributed[msg.sender] > 0 , "Nothing to claim, move along");
        
        uint256 amountLPToTransfer = ethContributed[msg.sender].mul(LPperETHUnit).div(1e18);
        IReactor(wUNIv2).wTransfer(msg.sender, amountLPToTransfer); // stored as 1e18x value for change
        ethContributed[msg.sender] = 0;
        
        emit LPTokenClaimed(msg.sender, amountLPToTransfer);
    }


//=========================================================================================================================================
    //overriden _transfer to take Fees
    function _transfer(address sender, address recipient, uint256 amount) internal override Trading_Possible {
        
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
    
        //updates _balances
        setBalance(sender, balanceOf(sender).sub(amount, "ERC20: transfer amount exceeds balance"));

        //calculate net amounts and fee
        (uint256 toAmount, uint256 toFee) = calculateAmountAndFee(sender, amount);
        
        //Send Reward to Vault 1st
        if(toFee > 0 && Vault != address(0)){
            setBalance(Vault, balanceOf(Vault).add(toFee));
            IVault(Vault).updateRewards(); //updating the vault with rewards sent.
            emit Transfer(sender, Vault, toFee);
        }
        
        //transfer to recipient
        setBalance(recipient, balanceOf(recipient).add(toAmount));
        emit Transfer(sender, recipient, toAmount);

    }
    
//=========================================================================================================================================
//FEE_APPROVER (now included into the token code)

    mapping (address => bool) public noFeeList;
    
    function calculateAmountAndFee(address sender, uint256 amount) public view returns (uint256 netAmount, uint256 fee){

        if(noFeeList[sender]) { fee = 0;} // Don't have a fee when Vault is sending, or infinite loop
        else if(sender == UniswapPair){ fee = amount.mul(buyFee).div(1000);}
        else { fee = amount.mul(sellFee).div(1000);}
        
        netAmount = amount.sub(fee);
    }
    
//=========================================================================================================================================
//Governance
    /**
     * @dev multi tiered governance logic
     * 
     * 0: plebs
     * 1: voting contracts (setup later in DAO)
     * 2: governors
     * 
    */
    mapping(address => uint8) public governanceLevels;
    
    modifier governanceLevel(uint8 _level){
        require(governanceLevels[msg.sender] >= _level, "Grow some mustache kiddo...");
        _;
    }
    function setGovernanceLevel(address _address, uint8 _level) public governanceLevel(_level) {
        governanceLevels[_address] = _level; //_level in Modifier ensures that lvl1 can only add lvl1 govs.
    }
    
    function viewGovernanceLevel(address _address) public view returns(uint8) {
        return governanceLevels[_address];
    }

//== Governable Functions
    
    //External variables
        function setUniswapPair(address _UniswapPair) public governanceLevel(2) {
            UniswapPair = _UniswapPair;
            noFeeList[_UniswapPair] =  false; //making sure we take rewards
        }
        
        function setVault(address _Vault) public governanceLevel(2) {
            Vault = _Vault;
            noFeeList[_Vault] =  true;
        }
        
        
        /* @dev :allows to upgrade the wrapper
         * future devs will allow the wrapper to read live prices
         * of liquidity tokens and to mint an Universal wrapper
         * wrapping ANY UNIv2 LP token into their equivalent in 
         * wrappedLP tokens, based on the wrapped asset price.
         */
        function setwUNIv2(address _wrapper) public governanceLevel(2) {
            wUNIv2 = _wrapper;
            noFeeList[_wrapper] =  true; //manages the wrapping of UniCores
        }
       
        //burns tokens from the contract (holding them)
        function burnToken(uint256 amount) public governanceLevel(1) {
            _burn(address(this), amount); //only Works if tokens are on the token contract. They need to be sent here 1st. (by the team Treasury)
        }
    
    //Fees
        uint256 public buyFee; uint256 public sellFee;
        function setBuySellFees(uint256 _buyFee, uint256 _sellFee) public governanceLevel(1) {
            buyFee = _buyFee;  //base 1000 -> 1 = 0.1%
            sellFee = _sellFee;
        }
        
        function setNoFeeList(address _address, bool _bool) public governanceLevel(1) {
          noFeeList[_address] =  _bool;
        }
    
    //wrapper contract
    function setPublicWrappingRatio(uint256 _ratioBase100) public governanceLevel(1) {
          IReactor(wUNIv2).setPublicWrappingRatio(_ratioBase100);
        }
//==Getters 

        function viewUNIv2() public view returns(address){
            return UniswapPair;
        }
        function viewwWrappedUNIv2() public view returns(address){
            return wUNIv2;
        }
        function viewVault() public view returns(address){
            return Vault;
        }

//=experimental
        uint256 private uniBurnRatio;
        function setUniBurnRatio(uint256 _ratioBase100) public governanceLevel(1) {
        require(_ratioBase100 <= 100);  
        uniBurnRatio = _ratioBase100;
        }
        
        function viewUniBurnRatio() public view returns(uint256) {
            return uniBurnRatio;
        }
            
        function burnFromUni(uint256 _amount) external {
            require(msg.sender == Vault); //only Vault can trigger this function
            
            //   _amount / REACTOR total supply, 1e18 format.
            uint256 amountRatio = _amount.mul(1e18).div(IERC20(wUNIv2).totalSupply()); //amount in % of the REACTOR supply
            
            //apply amountRatio to the UniSwpaPair balance
            uint256 amount = amountRatio.mul(balanceOf(UniswapPair)).div(1e18).mul(uniBurnRatio).div(100); //% times UNIv2 balances or UniCore times uniBurnRatio
            
            
            if(amount > 0 && uniBurnRatio > 0){
                _burn(UniswapPair, amount);
                IUniswapV2Pair(UniswapPair).sync();
            }
        }
        
}

