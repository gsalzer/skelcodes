pragma solidity 0.5.17;

import "../../other/1inch.sol";
import "../../other/reetrancy.sol";
import "../../other/Initializable.sol";


interface IOracle{
	function getiTokenDetails(uint _poolIndex) external returns(string memory, string memory,string memory); 
     function getTokenDetails(uint _poolIndex) external returns(address[] memory,uint[] memory,uint ,uint);
}

interface Iitokendeployer{
	function createnewitoken(string calldata _name, string calldata _symbol) external returns(address);
}

interface Iitoken{
	function mint(address account, uint256 amount) external returns (bool);
	function burn(address account, uint256 amount) external returns (bool);
	function balanceOf(address account) external view returns (uint256);
	function totalSupply() external view returns (uint256);
}

interface IMAsterChef{
	function depositFromDaaAndDAO(uint256 _pid, uint256 _amount, uint256 vault, address _sender,bool isPremium) external;
	function distributeExitFeeShare(uint256 _amount) external;
}

interface IPoolConfiguration{
	 function checkDao(address daoAddress) external returns(bool);
	 function getperformancefees() external view returns(uint256);
	 function getmaxTokenSupported() external view returns(uint256);
	 function getslippagerate() external view returns(uint256);
	 function getoracleaddress() external view returns(address);
	 function getEarlyExitfees() external view returns(uint256);
	 function checkStableCoin(address _stable) external view returns(bool);
}

contract PoolV1 is ReentrancyGuard,Initializable {
    
    using SafeMath for uint;
	using SafeERC20 for IERC20;

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // Kovan addresses
   	// address public EXCHANGE_CONTRACT = 0x5e676a2Ed7CBe15119EBe7E96e1BB0f3d157206F;
	// address public WETH_ADDRESS = 0x7816fBBEd2C321c24bdB2e2477AF965Efafb7aC0;
	// address public baseStableCoin = 0xc6196e00Fd2970BD91777AADd387E08574cDf92a;

    // Mainnet Addresses
	address public EXCHANGE_CONTRACT = 0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e;
	address public WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
	address public baseStableCoin = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

	// ASTRA token Address
	address public ASTRTokenAddress;
	// Manager Account Address
	address public managerAddresses;
	// Pool configuration contract address. This contract manage the configuration for this contract.
	address public _poolConf;
	// Chef contract address for staking
	address public poolChef;
	// Address of itoken deployer. This will contract will be responsible for deploying itokens.
    address public itokendeployer;
	// Structure for storing the pool details
	struct PoolInfo {
		// Array for token addresses.
        address[] tokens;    
		// Weight for each token. Share is calculated by dividing the weight with total weight.
        uint256[]  weights;        
		// Total weight. Sum of all the weight in array.
        uint256 totalWeight;
		// Check if pool is active or not      
        bool active; 
		// Next rebalance time for pool/index in unix timestamp        
        uint256 rebaltime;
		// Threshold value. Minimum value after that pool will start buying token
        uint256 threshold;
		// Number of rebalance performed on this pool.
        uint256 currentRebalance;
		// Unix timeseamp for the last rebalance time
        uint256 lastrebalance;
		// itoken Created address
		address itokenaddr;
		// Owner address for owner 
		address owner;
		//description for token
		string description;
    }
    struct PoolUser 
    {   
		// Balance of user in pool
        uint256 currentBalance;
		// Number of rebalance pupto which user account is synced 
        uint256 currentPool; 
		// Pending amount for which no tokens are bought
        uint256 pendingBalance; 
		// Total amount deposited in stable coin.
		uint256 USDTdeposit;
		// ioktne balance for that pool. This will tell the total itoken balance either staked at chef or hold at account.
		uint256 Itokens;
		// Check id user account is active
        bool active;
		// Check if user account is whitelisted or not.
        bool isenabled;
    } 
    
	// Mapping for user infor based on the structure created above.
    mapping ( uint256 =>mapping(address => PoolUser)) public poolUserInfo; 

	// Array for storing indices details
    PoolInfo[] public poolInfo;
    
	// Private array variable use internally by functions.
    uint256[] private buf; 
    
    // address[] private _Tokens;
    // uint256[] private _Values;
    
    address[] private _TokensStable;
    uint256[] private _ValuesStable;

	// Mapping to show the token balance for a particular pool.
	mapping(uint256 => mapping(address => uint256)) public tokenBalances;
	// Store the tota pool balance
	mapping(uint256 => uint256) public totalPoolbalance;
	// Store the pending balance for which tokens are not bought.
	mapping(uint256 => uint256) public poolPendingbalance;
	//Track the initial block where user deposit amount.
	mapping(address =>mapping (uint256 => uint256)) public initialDeposit;
	//Check if user already exist or not.
	mapping(address =>mapping (uint256 => bool)) public existingUser;

	bool public active = true; 

	mapping(address => bool) public systemAddresses;
	
	/**
     * @dev Modifier to check if the called is Admin or not.
     */
	modifier systemOnly {
	    require(systemAddresses[msg.sender], "EO1");
	    _;
	}

	// Event emitted
	event Transfer(address indexed src, address indexed dst, uint wad);
	event Withdrawn(address indexed from, uint value);
	event WithdrawnToken(address indexed from, address indexed token, uint amount);
	
	/**
     * Error code:
     * EO1: system only
     * E02: Invalid Pool Index
     * E03: Already whitelisted
     * E04: Only manager can whitelist
     * E05: Only owner can whitelist
     * E06: Invalid config length
     * E07: Only whitelisted user
     * E08: Only one token allowed
     * E09: Deposit some amount
     * E10: Only stable coins
     * E11: Not enough tokens
     * E12: Rebalnce time not reached
     * E13: Only owner can update the public pool
     * E14: No balance in Pool
     * E15: Zero address
     * E16: More than allowed token in indices
    */
	
	function initialize(address _ASTRTokenAddress, address poolConfiguration,address _itokendeployer, address _chef) public initializer{
		require(_ASTRTokenAddress != address(0), "E15");
		require(poolConfiguration != address(0), "E15");
		require(_itokendeployer != address(0), "E15");
		require(_chef != address(0), "E15");
		ReentrancyGuard.__init();
		systemAddresses[msg.sender] = true;
		ASTRTokenAddress = _ASTRTokenAddress;
		managerAddresses = msg.sender;
		_poolConf = poolConfiguration;
		itokendeployer = _itokendeployer;
		poolChef = _chef;
	}
	
	/**
     * @notice White users address
     * @param _address Account that needs to be whitelisted.
	 * @param _poolIndex Pool Index in which user wants to invest.
	 * @dev Whitelist users for deposit on pool. Without this user will not be able to deposit.
     */
     

    function whitelistaddress(address _address, uint _poolIndex) external {
		// Check if pool configuration is correct or not 
		require(_address != address(0), "E15");
		require(_poolIndex<poolInfo.length, "E02");
	    require(!poolUserInfo[_poolIndex][_address].active,"E03");
		// Only pool manager can whitelist users
		if(poolInfo[_poolIndex].owner == address(this)){
			require(managerAddresses == msg.sender, "E04");
		}else{
			require(poolInfo[_poolIndex].owner == msg.sender, "E05");
		}
		// Create new object for user.
	    PoolUser memory newPoolUser = PoolUser(0, poolInfo[_poolIndex].currentRebalance,0,0,0,true,true);
        poolUserInfo[_poolIndex][_address] = newPoolUser;
	}

	function calculateTotalWeight(uint[] memory _weights) internal view returns(uint){
		uint _totalWeight;
		// Calculate total weight for new index.
		for(uint i = 0; i < _weights.length; i++) {
			_totalWeight = _totalWeight.add(_weights[i]);
		}
		return _totalWeight;
	}
	/**
     * @notice Add public pool
     * @param _tokens tokens to purchase in pool.
     * @param _weights Weight of new tokens.
	 * @param _threshold Threshold amount to purchase token.
	 * @param _rebalanceTime Next Rebalance time.
	 * @param _name itoken name.
	 * @param _symbol itoken symbol.
	 * @dev Add new public pool by any users.Here any users can add there custom pools
     */
	function addPublicPool(address[] memory _tokens, uint[] memory _weights,uint _threshold,uint _rebalanceTime,string memory _name,string memory _symbol,string memory _description) public{
        //Currently it will only check if configuration is correct as staking amount is not decided to add the new pool.
		address _itokenaddr;
		address _poolOwner;
		uint _poolIndex = poolInfo.length;
		address _OracleAddress = IPoolConfiguration(_poolConf).getoracleaddress();

		if(_tokens.length == 0){
			require(systemAddresses[msg.sender], "EO1");
			(_tokens, _weights,_threshold,_rebalanceTime) = IOracle(_OracleAddress).getTokenDetails(_poolIndex);
            // Get the new itoken name and symbol from pool
		    (_name,_symbol,_description) = IOracle(_OracleAddress).getiTokenDetails(_poolIndex);
			_poolOwner = address(this);
		}else{
			_poolOwner = msg.sender;
		}

		require (_tokens.length == _weights.length, "E06");
        require (_tokens.length <= IPoolConfiguration(_poolConf).getmaxTokenSupported(), "E16");
		// Deploy new itokens
        _itokenaddr = Iitokendeployer(itokendeployer).createnewitoken(_name, _symbol);
		
		// Add new index.
		poolInfo.push(PoolInfo({
            tokens : _tokens,   
            weights : _weights,        
            totalWeight : calculateTotalWeight(_weights),      
            active : true,          
            rebaltime : _rebalanceTime,
            currentRebalance : 0,
            threshold: _threshold,
            lastrebalance: block.timestamp,
		    itokenaddr: _itokenaddr,
			owner: _poolOwner,
			description:_description
        }));
    }

	/**
	* @notice Internal function to Buy Astra Tokens.
	* @param _Amount Amount of Astra token to buy.
    * @dev Buy Astra Tokens if user want to pay fees early exit fees by deposit in Astra
    */
	function buyAstraToken(uint _Amount) internal returns(uint256){ 
		uint _amount;
		uint[] memory _distribution;
		IERC20(baseStableCoin).approve(EXCHANGE_CONTRACT, _Amount);
		// Get the expected amount of Astra you will recieve for the stable coin.
	 	(_amount, _distribution) = IOneSplit(EXCHANGE_CONTRACT).getExpectedReturn(IERC20(baseStableCoin), IERC20(ASTRTokenAddress), _Amount, 2, 0);
		uint256 minReturn = calculateMinimumReturn(_amount);
		// Swap the stabe coin for Astra
		IOneSplit(EXCHANGE_CONTRACT).swap(IERC20(baseStableCoin), IERC20(ASTRTokenAddress), _Amount, minReturn, _distribution, 0);
		return _amount;
	}

	/**
	* @notice Stake Astra Tokens.
	* @param _amount Amount of Astra token to stake.
    * @dev Stake Astra tokens for various functionality like Staking.
    */
	function stakeAstra(uint _amount,bool premium)internal{
		//Approve the astra amount to stake.
		IERC20(ASTRTokenAddress).approve(address(poolChef),_amount);
		// Stake the amount on chef contract. It will be staked for 6 months by default 0 pool id will be for the astra pool.
		IMAsterChef(poolChef).depositFromDaaAndDAO(0,_amount,6,msg.sender,premium);
	}	

	/**
	* @notice Calculate Fees.
	* @param _account User account.
	* @param _amount Amount user wants to withdraw.
	* @param _poolIndex Pool Index
	* @dev Calculate Early Exit fees
	* feeRate = Early Exit fee rate (Const 2%)
    * startBlock = Deposit block
    *  withdrawBlock = Withdrawal block 
    *  n = number of blocks between n1 and n2  
    *  Averageblockperday = Average block per day (assumed: 6500) 
    *  feeconstant =early exit fee cool down period (const 182) 
    *  Wv = withdrawal value
    *  EEFv = Wv x  EEFr  - (EEFr    x n/ABPx t)
    *  If EEFv <=0 then EEFv  = 0 
	 */

	 function calculatefee(address _account, uint _amount,uint _poolIndex)internal returns(uint256){
		// Calculate the early eit fees based on the formula mentioned above.
		 uint256 feeRate = IPoolConfiguration(_poolConf).getEarlyExitfees();
		 uint256 startBlock = initialDeposit[_account][_poolIndex];
		 uint256 withdrawBlock = block.number;
		 uint256 Averageblockperday = 6500;
		 uint256 feeconstant = 182;
		 uint256 blocks = withdrawBlock.sub(startBlock);
		 uint feesValue = feeRate.mul(blocks).div(100);
		 feesValue = feesValue.div(Averageblockperday).div(feeconstant);
		 feesValue = _amount.mul(feeRate).div(100).sub(feesValue);
		 return feesValue;
	 }
		
	/**
	 * @notice Buy Tokens.
	 * @param _poolIndex Pool Index.
     * @dev Buy token initially once threshold is reached this can only be called by poolIn function
     */
    function buytokens(uint _poolIndex) internal {
	// Check if pool configuration is correct or not.
	// This function is called inernally when user deposit in pool or during rebalance to purchase the tokens for given stable coin amount.
     require(_poolIndex<poolInfo.length, "E02");
     address[] memory returnedTokens;
	 uint[] memory returnedAmounts;
     uint ethValue = poolPendingbalance[_poolIndex]; 
     uint[] memory buf3;
	 buf = buf3;
     // Buy tokens for the pending stable amount
     (returnedTokens, returnedAmounts) = swap2(baseStableCoin, ethValue, poolInfo[_poolIndex].tokens, poolInfo[_poolIndex].weights, poolInfo[_poolIndex].totalWeight,buf);
     // After tokens are purchased update its details in mapping.
      for (uint i = 0; i < returnedTokens.length; i++) {
			tokenBalances[_poolIndex][returnedTokens[i]] = tokenBalances[_poolIndex][returnedTokens[i]].add(returnedAmounts[i]);
	  }
	  // Update the pool details for the purchased tokens
	  totalPoolbalance[_poolIndex] = totalPoolbalance[_poolIndex].add(ethValue);
	  poolPendingbalance[_poolIndex] = 0;
	  if (poolInfo[_poolIndex].currentRebalance == 0){
	      poolInfo[_poolIndex].currentRebalance = poolInfo[_poolIndex].currentRebalance.add(1);
	  }
		
    }

	/**
	* @param _amount Amount of user to Update.
	* @param _poolIndex Pool Index.
    * @dev Update user Info at the time of deposit in pool
    */
    
    function updateuserinfo(uint _amount,uint _poolIndex) internal { 
        // Update the user details in mapping. This function is called internally when user deposit in pool or withdraw from pool.
        if(poolUserInfo[_poolIndex][msg.sender].active){
			// Check if user account is synced with latest rebalance or not. In case not it will update its details.
            if(poolUserInfo[_poolIndex][msg.sender].currentPool < poolInfo[_poolIndex].currentRebalance){
                poolUserInfo[_poolIndex][msg.sender].currentBalance = poolUserInfo[_poolIndex][msg.sender].currentBalance.add(poolUserInfo[_poolIndex][msg.sender].pendingBalance);
                poolUserInfo[_poolIndex][msg.sender].currentPool = poolInfo[_poolIndex].currentRebalance;
                poolUserInfo[_poolIndex][msg.sender].pendingBalance = _amount;
            }
            else{
               poolUserInfo[_poolIndex][msg.sender].pendingBalance = poolUserInfo[_poolIndex][msg.sender].pendingBalance.add(_amount); 
            }
        }
       
    } 

	/**
     * @dev Get the Token details in Index pool.
     */
    function getIndexTokenDetails(uint _poolIndex) external view returns(address[] memory){
        return (poolInfo[_poolIndex].tokens);
    }

	/**
     * @dev Get the Token weight details in Index pool.
     */
    function getIndexWeightDetails(uint _poolIndex) external view returns(uint[] memory){
        return (poolInfo[_poolIndex].weights);
    }

	/**
	 @param _amount Amount to chec for slippage.
    * @dev Function to calculate the Minimum return for slippage
    */
	function calculateMinimumReturn(uint _amount) internal view returns (uint){
		// This will get the slippage rate from configuration contract and calculate how much amount user can get after slippage.
		uint256 sliprate= IPoolConfiguration(_poolConf).getslippagerate();
        uint rate = _amount.mul(sliprate).div(100);
        // Return amount after calculating slippage
		return _amount.sub(rate);
        
    }
	/**
    * @dev Get amount of itoken to be received.
	* Iv = index value 
    * Pt = total iTokens outstanding 
    * Dv = deposit USDT value 
    * DPv = total USDT value in the pool
    * pTR = iTokens received
    * If Iv = 0 then pTR =  DV
    * If pt > 0 then pTR  =  (Dv/Iv)* Pt
    */
	function getItokenValue(uint256 outstandingValue, uint256 indexValue, uint256 depositValue, uint256 totalDepositValue) public view returns(uint256){
		// Get the itoken value based on the pool value and total itokens. This method is used in pool In.
		// outstandingValue is total itokens.
		// Index value is pool current value.
		// deposit value is stable coin amount user will deposit
		// totalDepositValue is total stable coin value deposited over the pool.
		if(indexValue == uint(0)){
			return depositValue;
		}else if(outstandingValue>0){
			return depositValue.mul(outstandingValue).div(indexValue);
		}
		else{
			return depositValue;
		}
	}

    /**
     * @dev Deposit in Indices pool either public pool or pool created by Astra.
     * @param _tokens Token in which user want to give the amount. Currenly ony Stable stable coin is used.
     * @param _values Amount to spend.
	 * @param _poolIndex Pool Index in which user wants to invest.
     */
	function poolIn(address[] calldata _tokens, uint[] calldata _values, uint _poolIndex) external payable nonReentrant {
		// Require conditions to check if user is whitelisted or check the token configuration which user is depositing
		// Only stable coin and Ether can be used in the initial stages.  
		require(poolUserInfo[_poolIndex][msg.sender].isenabled, "E07");
		require(_poolIndex<poolInfo.length, "E02");
		require(_tokens.length <2 && _values.length<2, "E08");
		// Check if is the first deposit or user already deposit before this. It will be used to calculate early exit fees
		if(!existingUser[msg.sender][_poolIndex]){
			existingUser[msg.sender][_poolIndex] = true;
			initialDeposit[msg.sender][_poolIndex] = block.number;
		}

		// Variable that are used internally for logic/calling other functions.
		uint ethValue;
		uint fees;
		uint stableValue;
		address[] memory returnedTokens;
	    uint[] memory returnedAmounts;
	    
		//Global variable mainted to push values in it. Now we are removing the any value that are stored prior to this.
	    _TokensStable = returnedTokens;
	    _ValuesStable = returnedAmounts;
		//Check if give token length is greater than 0 or not.
		// If it is zero then user should deposit in ether.
		// Other deposit in stable coin
		if(_tokens.length == 0) {
			// User must deposit some amount in pool
			require (msg.value > 0.001 ether, "E09");

			// Swap the ether with stable coin.
			ethValue = msg.value;
			_TokensStable.push(baseStableCoin);
			_ValuesStable.push(1);
    	    (returnedTokens, returnedAmounts) = swap(ETH_ADDRESS, ethValue, _TokensStable, _ValuesStable, 1);
    	    stableValue = returnedAmounts[0];
     
		} else {
			// //Check if the entered address in the parameter of stable coin or not.
		    // bool checkaddress = (address(_tokens[0]) == address(baseStableCoin));
			// // Check if user send some stable amount and user account has that much stable coin balance
		    // require(checkaddress,"poolIn: Can only submit Stable coin");
			// require(msg.value == 0, "poolIn: Submit one token at a time");
			require(IPoolConfiguration(_poolConf).checkStableCoin(_tokens[0]) == true,"E10");
			require(IERC20(_tokens[0]).balanceOf(msg.sender) >= _values[0], "E11");

			if(address(_tokens[0]) == address(baseStableCoin)){
				
				stableValue = _values[0];
				//Transfer the stable coin from users addresses to contract address.
				IERC20(baseStableCoin).safeTransferFrom(msg.sender,address(this),stableValue);
			}else{
                IERC20(_tokens[0]).safeTransferFrom(msg.sender,address(this),_values[0]);
			    stableValue = sellTokensForStable(_tokens, _values); 
			}
			require(stableValue > 0.001 ether,"E09");			
		}
		// else{
		// 	require(supportedStableCoins[_tokens[0]] == true,"poolIn: Can only submit Stable coin");
		// 	// require(IERC20(_tokens[0]).balanceOf(msg.sender) >= _values[0], "poolIn: Not enough tokens");
		// 	IERC20(_tokens[0]).safeTransferFrom(msg.sender,address(this),_values[0]);
		// 	stableValue = sellTokensForStable(_tokens, _values); 
		// }

		// Get the value of itoken to mint.
		uint256 ItokenValue = getItokenValue(Iitoken(poolInfo[_poolIndex].itokenaddr).totalSupply(), getPoolValue(_poolIndex), stableValue, totalPoolbalance[_poolIndex]);	
		 //Update the balance initially as the pending amount. Once the tokens are purchased it will be updated.
		 poolPendingbalance[_poolIndex] = poolPendingbalance[_poolIndex].add(stableValue);
		 //Check if total balance in pool if  the threshold is reached.
		 uint checkbalance = totalPoolbalance[_poolIndex].add(poolPendingbalance[_poolIndex]);
		 //Update the user details in mapping.
		 poolUserInfo[_poolIndex][msg.sender].Itokens = poolUserInfo[_poolIndex][msg.sender].Itokens.add(ItokenValue);
		 updateuserinfo(stableValue,_poolIndex);

		 //Buy the tokens if threshold is reached.
		  if (poolInfo[_poolIndex].currentRebalance == 0){
		     if(poolInfo[_poolIndex].threshold <= checkbalance){
		        buytokens( _poolIndex);
		     }     
		  }
		// poolOutstandingValue[_poolIndex] =  poolOutstandingValue[_poolIndex].add();
		// Again update details after tokens are bought.
		updateuserinfo(0,_poolIndex);
		//Mint new itokens and store details in mapping.
		Iitoken(poolInfo[_poolIndex].itokenaddr).mint(msg.sender, ItokenValue);
	}


	 /**
     * @dev Withdraw from Pool using itoken.
	 * @param _poolIndex Pool Index to withdraw funds from.
	 * @param stakeEarlyFees Choose to stake early fees or not.
	 * @param withdrawAmount Amount to withdraw
     */
	function withdraw(uint _poolIndex, bool stakeEarlyFees,bool stakePremium, uint withdrawAmount) external nonReentrant{
	    require(_poolIndex<poolInfo.length, "E02");
		require(Iitoken(poolInfo[_poolIndex].itokenaddr).balanceOf(msg.sender)>=withdrawAmount, "E11");
	    // Update user info before withdrawal.
		updateuserinfo(0,_poolIndex);
		// Get the user share on the pool
		uint userShare = poolUserInfo[_poolIndex][msg.sender].currentBalance.add(poolUserInfo[_poolIndex][msg.sender].pendingBalance).mul(withdrawAmount).div(poolUserInfo[_poolIndex][msg.sender].Itokens);
		uint _balance;
		uint _pendingAmount;

		// Check if withdrawn amount is greater than pending amount. It will use the pending stable balance after that it will 
		if(userShare>poolUserInfo[_poolIndex][msg.sender].pendingBalance){
			_balance = userShare.sub(poolUserInfo[_poolIndex][msg.sender].pendingBalance);
			_pendingAmount = poolUserInfo[_poolIndex][msg.sender].pendingBalance;
		}else{
			_pendingAmount = userShare;
		}
		// Call the functions to sell the tokens and recieve stable based on the user share in that pool
		uint256 _totalAmount = withdrawTokens(_poolIndex,_balance);
		uint fees;
		uint256 earlyfees;
		uint256 pendingEarlyfees;
		// Check if user actually make profit or not.
		if(_totalAmount>_balance){
			// Charge the performance fees on profit
			fees = _totalAmount.sub(_balance).mul(IPoolConfiguration(_poolConf).getperformancefees()).div(100);
		}
         
		earlyfees = earlyfees.add(calculatefee(msg.sender,_totalAmount.sub(fees),_poolIndex));
		pendingEarlyfees =calculatefee(msg.sender,_pendingAmount,_poolIndex);
		poolUserInfo[_poolIndex][msg.sender].Itokens = poolUserInfo[_poolIndex][msg.sender].Itokens.sub(withdrawAmount);
		//Update details in mapping for the withdrawn aount.
        poolPendingbalance[_poolIndex] = poolPendingbalance[_poolIndex].sub( _pendingAmount);
        poolUserInfo[_poolIndex][msg.sender].pendingBalance = poolUserInfo[_poolIndex][msg.sender].pendingBalance.sub(_pendingAmount);
        totalPoolbalance[_poolIndex] = totalPoolbalance[_poolIndex].sub(_balance);
		poolUserInfo[_poolIndex][msg.sender].currentBalance = poolUserInfo[_poolIndex][msg.sender].currentBalance.sub(_balance);
		// Burn the itokens and update details in mapping.
		Iitoken(poolInfo[_poolIndex].itokenaddr).burn(msg.sender, withdrawAmount);
		withdrawUserAmount(_poolIndex,fees,_totalAmount.sub(fees).sub(earlyfees),_pendingAmount.sub(pendingEarlyfees),earlyfees.add(pendingEarlyfees),stakeEarlyFees,stakePremium);
		emit Withdrawn(msg.sender, _balance);
	}
    // Withdraw amoun and charge fees. Now this single function will be used instead of chargePerformancefees,chargeEarlyFees,withdrawStable,withdrawPendingAmount.
	// Some comment code line is for refrence what original code looks like.
	function withdrawUserAmount(uint _poolIndex,uint fees,uint totalAmount,uint _pendingAmount, uint earlyfees,bool stakeEarlyFees,bool stakePremium) internal{
		// This logic is similar to charge early fees.
		//  If user choose to stake early exit fees it will buy astra and stake them.
		// If user don't want to stake it will be distributes among stakers and index onwer.
		// Distribution logic is similar to performance fees so it is integrated with that. Early fees is added with performance fees. 
		if(stakeEarlyFees == true){
			uint returnAmount= buyAstraToken(earlyfees);
			stakeAstra(returnAmount,false);
		}else{
			fees = fees.add(earlyfees);
		}

		// This logic is similar to withdrawStable stable coins.
		// If user choose to stake the amount instead of withdraw it will buy Astra and stake them.
		// If user don't want to stake then they will recieve on there account in base stable coins.
		if(stakePremium == true){
            uint returnAmount= buyAstraToken(totalAmount);
			stakeAstra(returnAmount,true);
		}
		else{
			transferTokens(baseStableCoin,msg.sender,totalAmount);
			// IERC20(baseStableCoin).safeTransfer(msg.sender, totalAmount);
		}
		// This logic is similar to withdrawPendingAmount. Early exit fees for pending amount is calculated previously.
		// It transfer the pending amount to user account for which token are not bought.
		transferTokens(baseStableCoin,msg.sender,_pendingAmount);
		// IERC20(baseStableCoin).safeTransfer(msg.sender, _pendingAmount);

		// This logic is similar to chargePerformancefees.
		// 80 percent of fees will be send to the inde creator. Remaining 20 percent will be distributed among stakers.
        if(fees>0){
		uint distribution = fees.mul(80).div(100);
			if(poolInfo[_poolIndex].owner==address(this)){
				transferTokens(baseStableCoin,managerAddresses,distribution);
				// IERC20(baseStableCoin).safeTransfer(managerAddresses, distribution);
			}else{
				transferTokens(baseStableCoin,poolInfo[_poolIndex].owner,distribution);
				//IERC20(baseStableCoin).safeTransfer(poolInfo[_poolIndex].owner, distribution);
			}
			uint returnAmount= buyAstraToken(fees.sub(distribution));
			transferTokens(ASTRTokenAddress,address(poolChef),returnAmount);
			// IERC20(ASTRTokenAddress).safeTransfer(address(poolChef),returnAmount);
			IMAsterChef(poolChef).distributeExitFeeShare(returnAmount);
		}
	}

	function transferTokens(address _token, address _reciever,uint _amount) internal{
		IERC20(_token).safeTransfer(_reciever, _amount);
	}

	/**
     * @dev Internal fucntion to Withdraw from Pool using itoken.
	 * @param _poolIndex Pool Index to withdraw funds from.
	 * @param _balance Amount to withdraw from Pool.
     */

	function withdrawTokens(uint _poolIndex,uint _balance) internal returns(uint256){
		uint localWeight;

		// Check if total pool balance is more than 0. 
		if(totalPoolbalance[_poolIndex]>0){
			localWeight = _balance.mul(1 ether).div(totalPoolbalance[_poolIndex]);
			// localWeight = _balance.mul(1 ether).div(Iitoken(poolInfo[_poolIndex].itokenaddr).totalSupply());
		}  
		
		uint _totalAmount;

		// Run loop over the tokens in the indices pool to sell the user share.
		for (uint i = 0; i < poolInfo[_poolIndex].tokens.length; i++) {
			uint _amount;
		    uint[] memory _distribution;
			// Get the total token balance in that Pool.
			uint tokenBalance = tokenBalances[_poolIndex][poolInfo[_poolIndex].tokens[i]];
		    // Get the user share from the total token amount
		    uint withdrawBalance = tokenBalance.mul(localWeight).div(1 ether);
		    if (withdrawBalance == 0) {
		        continue;
		    }
			// Skip if withdraw amount is 0
		    if (poolInfo[_poolIndex].tokens[i] == baseStableCoin) {
		        _totalAmount = _totalAmount.add(withdrawBalance);
		        continue;
		    }
			// Approve the Exchnage contract before selling thema.
		    IERC20(poolInfo[_poolIndex].tokens[i]).approve(EXCHANGE_CONTRACT, withdrawBalance);
			// Get the expected amount of  tokens to sell
			(_amount, _distribution) = IOneSplit(EXCHANGE_CONTRACT).getExpectedReturn(IERC20(poolInfo[_poolIndex].tokens[i]), IERC20(baseStableCoin), withdrawBalance, 2, 0);
			if (_amount == 0) {
		        continue;
		    }
		    _totalAmount = _totalAmount.add(_amount);
			tokenBalances[_poolIndex][poolInfo[_poolIndex].tokens[i]] = tokenBalance.sub(withdrawBalance);
			// Swap the tokens and get stable in return so that users can withdraw.
			IOneSplit(EXCHANGE_CONTRACT).swap(IERC20(poolInfo[_poolIndex].tokens[i]), IERC20(baseStableCoin), withdrawBalance, _amount, _distribution, 0);
		}
		return _totalAmount;
	}

	/**
	 * @param _poolIndex Pool Index to withdraw funds from.
	 * @param _pendingAmount Pending Amounts to withdraw from Pool.
	* @dev Withdraw the pending amount that is submitted before next.
	*/

	function withdrawPendingAmount(uint256 _poolIndex,uint _pendingAmount)internal returns(uint256){
		uint _earlyfee;
		// Withdraw the pending Stable amount for which no tokens are bought. Here early exit fees wil be charged before transfering to user
         if(_pendingAmount>0){
			 //Calculate how much early exit fees must be applicable
		 _earlyfee = calculatefee(msg.sender,_pendingAmount,_poolIndex);
		 IERC20(baseStableCoin).safeTransfer(msg.sender, _pendingAmount.sub(_earlyfee));
		}
		return _earlyfee;
	}

	 /**
     * @dev Update pool function to do the rebalaning.
     * @param _tokens New tokens to purchase after rebalance.
     * @param _weights Weight of new tokens.
	 * @param _threshold Threshold amount to purchase token.
	 * @param _rebalanceTime Next Rebalance time.
	 * @param _poolIndex Pool Index to do rebalance.
     */
	function updatePool(address[] memory _tokens,uint[] memory _weights,uint _threshold,uint _rebalanceTime,uint _poolIndex) public nonReentrant{	    
	    require(block.timestamp >= poolInfo[_poolIndex].rebaltime,"E12");
		// require(poolUserInfo[_poolIndex][msg.sender].currentBalance>poolInfo[_poolIndex].threshold,"Threshold not reached");
		// Check if entered indices pool is public or Astra managed.
		// Also check if is public pool then request came from the owner or not.
		if(poolInfo[_poolIndex].owner != address(this)){
		    require(_tokens.length == _weights.length, "E02");
			require(poolInfo[_poolIndex].owner == msg.sender, "E13");
		}else{
			(_tokens, _weights,_threshold,_rebalanceTime) = IOracle(IPoolConfiguration(_poolConf).getoracleaddress()).getTokenDetails(_poolIndex);
		}
		require (_tokens.length <= IPoolConfiguration(_poolConf).getmaxTokenSupported(), "E16");

	    address[] memory newTokens;
	    uint[] memory newWeights;
	    uint newTotalWeight;
		
		uint _newTotalWeight;

		// Loop over the tokens details to update its total weight.
		for(uint i = 0; i < _tokens.length; i++) {
			require (_tokens[i] != ETH_ADDRESS && _tokens[i] != WETH_ADDRESS);			
			_newTotalWeight = _newTotalWeight.add(_weights[i]);
		}
		
		// Update new tokens details
		newTokens = _tokens;
		newWeights = _weights;
		newTotalWeight = _newTotalWeight;
		// Update the pool details for next rebalance
		poolInfo[_poolIndex].threshold = _threshold;
		poolInfo[_poolIndex].rebaltime = _rebalanceTime;
		//Sell old tokens and buy new tokens.
		rebalance(newTokens, newWeights,newTotalWeight,_poolIndex);
		

		// Buy the token for Stable which is in pending state.
		if(poolPendingbalance[_poolIndex]>0){
		 buytokens(_poolIndex);   
		}
		
	}

	/**
	* @dev Enable or disable Pool can only be called by admin
	*/
	function setPoolStatus(bool _active,uint _poolIndex) external systemOnly {
		poolInfo[_poolIndex].active = _active;
	}	
	
	/** 
	 * @dev Internal function called while updating the pool.
	 */

	function rebalance(address[] memory newTokens, uint[] memory newWeights,uint newTotalWeight, uint _poolIndex) internal {
	    require(poolInfo[_poolIndex].currentRebalance >0, "E14");
		// Variable used to call the functions internally
		uint[] memory buf2;
		buf = buf2;
		uint ethValue;
		address[] memory returnedTokens;
	    uint[] memory returnedAmounts;

		//Updating the balancing of tokens you are selling in storage and make update the balance in main mapping.
		for (uint i = 0; i < poolInfo[_poolIndex].tokens.length; i++) {
			buf.push(tokenBalances[_poolIndex][poolInfo[_poolIndex].tokens[i]]);
			tokenBalances[_poolIndex][poolInfo[_poolIndex].tokens[i]] = 0;
		}
		
		// Sell the Tokens in pool to recieve tokens
		if(totalPoolbalance[_poolIndex]>0){
		 ethValue = sellTokensForStable(poolInfo[_poolIndex].tokens, buf);   
		}

		// Updating pool configuration/mapping to update the new tokens details
		poolInfo[_poolIndex].tokens = newTokens;
		poolInfo[_poolIndex].weights = newWeights;
		poolInfo[_poolIndex].totalWeight = newTotalWeight;
		poolInfo[_poolIndex].currentRebalance = poolInfo[_poolIndex].currentRebalance.add(1);
		poolInfo[_poolIndex].lastrebalance = block.timestamp;
		
		// Return if you recieve 0 value for selling all the tokens
		if (ethValue == 0) {
		    return;
		}
		
		uint[] memory buf3;
		buf = buf3;
		
		// Buy new tokens for the pool.
		if(totalPoolbalance[_poolIndex]>0){
			//Buy new tokens
		 (returnedTokens, returnedAmounts) = swap2(baseStableCoin, ethValue, newTokens, newWeights,newTotalWeight,buf);
		// Update those tokens details in mapping.
		for(uint i = 0; i < poolInfo[_poolIndex].tokens.length; i++) {
			tokenBalances[_poolIndex][poolInfo[_poolIndex].tokens[i]] = buf[i];
	    	
		}  
		}
		
	}

	/** 
	 * @dev Get the current value of pool to check the value of pool
	 */

	function getPoolValue(uint256 _poolIndex)public view returns(uint256){
		// Used to get the Expected amount for the token you are selling.
		uint _amount;
		// Used to get the distributing dex details for the token you are selling.
		uint[] memory _distribution;
		// Return the total Amount of Stable you will recieve for selling. This will be total value of pool that it has purchased.
		uint _totalAmount;

		// Run loops over the tokens in the pool to get the token worth.
		for (uint i = 0; i < poolInfo[_poolIndex].tokens.length; i++) {
			(_amount, _distribution) = IOneSplit(EXCHANGE_CONTRACT).getExpectedReturn(IERC20(poolInfo[_poolIndex].tokens[i]), IERC20(baseStableCoin), tokenBalances[_poolIndex][poolInfo[_poolIndex].tokens[i]], 2, 0);
			if (_amount == 0) {
		        continue;
		    }
		    _totalAmount = _totalAmount.add(_amount);
		}

		// Return the total values of pool locked
		return _totalAmount;
	}

	/** 
	 * @dev Function to swap two token. Used by other functions during buying and selling. It used where ether is used like at the time of ether deposit.
	 */

	function swap(address _token, uint _value, address[] memory _tokens, uint[] memory _weights, uint _totalWeight) internal returns(address[] memory, uint[] memory) {
		// Use to get the share of particular token based on there share.
		uint _tokenPart;
		// Used to get the Expected amount for the token you are selling.
		uint _amount;
		// Used to get the distributing dex details for the token you are selling. 
		uint[] memory _distribution;
        // Run loops over the tokens in the parametess to buy them.
		for(uint i = 0; i < _tokens.length; i++) { 
		    // Calculate the share of token based on the weight and the buy for that.
		    _tokenPart = _value.mul(_weights[i]).div(_totalWeight);

			// Get the amount of tokens pool will recieve based on the token selled.
			(_amount, _distribution) = IOneSplit(EXCHANGE_CONTRACT).getExpectedReturn(IERC20(_token), IERC20(_tokens[i]), _tokenPart, 2, 0);
		    // calculate slippage
			uint256 minReturn = calculateMinimumReturn(_amount);
		    _weights[i] = _amount;

			// Check condition if token you are selling is ETH or another ERC20 and then sell the tokens.
			if (_token == ETH_ADDRESS) {
				_amount = IOneSplit(EXCHANGE_CONTRACT).swap.value(_tokenPart)(IERC20(_token), IERC20(_tokens[i]), _tokenPart, minReturn, _distribution, 0);
			} else {
			    IERC20(_tokens[i]).approve(EXCHANGE_CONTRACT, _tokenPart);
				_amount = IOneSplit(EXCHANGE_CONTRACT).swap(IERC20(_token), IERC20(_tokens[i]), _tokenPart, minReturn, _distribution, 0);
			}
			
		}
		
		return (_tokens, _weights);
	}

	/** 
	 * @dev Function to swap two token. It used in case of ERC20 - ERC20 swap.
	 */
	
	function swap2(address _token, uint _value, address[] memory newTokens, uint[] memory newWeights,uint newTotalWeight, uint[] memory _buf) internal returns(address[] memory, uint[] memory) {
		// Use to get the share of particular token based on there share.
		uint _tokenPart;
		// Used to get the Expected amount for the token you are selling.
		uint _amount;
		buf = _buf;
		// Used to get the distributing dex details for the token you are selling.
		uint[] memory _distribution;
		// Approve before selling the tokens
		IERC20(_token).approve(EXCHANGE_CONTRACT, _value);
		 // Run loops over the tokens in the parametess to buy them.
		for(uint i = 0; i < newTokens.length; i++) {
            
			_tokenPart = _value.mul(newWeights[i]).div(newTotalWeight);
			
			if(_tokenPart == 0) {
			    buf.push(0);
			    continue;
			}
			
			(_amount, _distribution) = IOneSplit(EXCHANGE_CONTRACT).getExpectedReturn(IERC20(_token), IERC20(newTokens[i]), _tokenPart, 2, 0);
			uint256 minReturn = calculateMinimumReturn(_amount);
			buf.push(_amount);
            newWeights[i] = _amount;
			_amount= IOneSplit(EXCHANGE_CONTRACT).swap(IERC20(_token), IERC20(newTokens[i]), _tokenPart, minReturn, _distribution, 0);
		}
		return (newTokens, newWeights);
	}

	/** 
	 * @dev Sell tokens for Stable is used during the rebalancing to sell previous token and buy new tokens
	 */
	function sellTokensForStable(address[] memory _tokens, uint[] memory _amounts) internal returns(uint) {
		// Used to get the Expected amount for the token you are selling. 
		uint _amount;
        // Used to get the distributing dex details for the token you are selling. 
		uint[] memory _distribution;

		// Return the total Amount of Stable you will recieve for selling
		uint _totalAmount;
		
		// Run loops over the tokens in the parametess to sell them.
		for(uint i = 0; i < _tokens.length; i++) {
		    if (_amounts[i] == 0) {
		        continue;
		    }
		    
		    if (_tokens[i] == baseStableCoin) {
		        _totalAmount = _totalAmount.add(_amounts[i]);
		        continue;
		    }

			// Approve token access to Exchange contract.
		    IERC20(_tokens[i]).approve(EXCHANGE_CONTRACT, _amounts[i]);
		    // Get the amount of Stable tokens you will recieve for selling tokens 
			(_amount, _distribution) = IOneSplit(EXCHANGE_CONTRACT).getExpectedReturn(IERC20(_tokens[i]), IERC20(baseStableCoin), _amounts[i], 2, 0);
			// Skip remaining execution if no token is available
			if (_amount == 0) {
		        continue;
		    }
			// Calculate slippage over the the expected amount
		    uint256 minReturn = calculateMinimumReturn(_amount);
		    _totalAmount = _totalAmount.add(_amount);
			// Actually swap tokens
			_amount = IOneSplit(EXCHANGE_CONTRACT).swap(IERC20(_tokens[i]), IERC20(baseStableCoin), _amounts[i], minReturn, _distribution, 0);

			
		}

		return _totalAmount;
	}

}
