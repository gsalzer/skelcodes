pragma solidity ^0.5.16;
/**
* Version: 0.1.0
*  * Equity agreement standard used for Ethereum smart contracts
 blockchain for the apportionment of the capital project.
* The current standard version of the Agreement is 0.1.0, which includes the main 
* information about the project application, creation of equity, confirming the validity of equity,
* capital transfer, capital transfer accounting and other functions.
*  Payment of dividends. 
*  Decentralized management of the company through voting. 
*  Acceptance of a member to the Board of Directors. 
* * Exclusion of a participant from the Board of Directors.
*/

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}


contract ERC20Basic{

    function balanceOf(address tokenOwner) public view returns (uint256 amount);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public;
    function approve(address spender, uint tokens) public;
    function transferFrom(address _from, address to, uint tokens) public;
    function dividendToReward() internal;
    function rewardTreasury () public view returns (uint256);
    function dividendPaymentsTime (uint256 _start) public returns (uint256 Start_reward, uint256 End_reward);
    event Transfer(address indexed _from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

}

contract ERC20 is ERC20Basic{
    using SafeMath for uint256;
    
    // Tokens total supply
    uint public totalSupply;
	
	// Company's name
	string public name;
	
	// Number of decimals
	uint8 public decimals;
	
	// Token symbol
	string public symbol;
	
	// Start of dividend payments
	uint256 public dividend_start;
	
	// end of dividend payments
	uint256 public dividend_end;
	
	// Token version
	string public version;
	
	//Token buyer
	address payable saleAgent;
	
	// Project owner address
	address payable project_owner = msg.sender;
	
	// Dividend to receive
	uint256 dividend;
	
	// Token owner address
	address payable token_owner;
	
	// Balances blockchain
	mapping (address => uint256) balances;
	
	// Balances blockchain
	mapping (address => mapping (address => uint)) allowed;
	
	// Holder struct
	 struct Holder {
	    uint256 quantity;
        uint256 rewardWithdrawTime;
    }
    
    // Holder blockchain
    mapping(address => Holder) holders;
    
    
    
		//Fix for short address attack against ERC20
	modifier onlyPayloadSize(uint size) {
		assert(msg.data.length == size + 4);
		_;
	}
	
	// Owner modifier
	 modifier onlyOwner {
        require(msg.sender == project_owner, "ACCESS DENIED");
        _;
    }

    /** @dev Shows balances `_token_owner`.
     * @return amount of tokens owned by `_token_owner`.
     */

	function balanceOf(address _token_owner) public view returns (uint256 amount) {
		return balances[_token_owner];
    }

    /**
     * @dev Moves `tokens` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */

	function transfer(address to, uint tokens) public  onlyPayloadSize(2*32) {
	    require(balances[msg.sender] >= tokens && tokens > 0);
	    balances[msg.sender] = balances[msg.sender].sub(tokens);
	    balances[to] = balances[to].add(tokens);
	    emit Transfer(msg.sender, to, tokens);        
    }

    /**
     * @dev Moves `tokens` tokens from `_from` to `_to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */

    function transferFrom (address _from, address to, uint tokens) public {
	    require(balances[_from] >= tokens && allowed[_from][msg.sender] >= tokens && tokens > 0);
            balances[to] = balances[to].add(tokens);
            balances[_from] = balances[_from].sub(tokens);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(tokens);
            emit Transfer(_from, to, tokens);
    }

    /** @dev Sets `tokens` as the allowance of `spender` over the caller's tokens.
     *
     *  boolean value indicating whether the operation succeeded.
     * Emits an {Approval} event.
     */

	function  approve(address spender, uint tokens) public {
		allowed[msg.sender][spender] = tokens;
		emit Approval(msg.sender, spender, tokens);
	}

    /**@dev allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     * @return remaining number of tokens that `spender` will be
     * This value changes when {approve} or {transferFrom} are called.
     */

	function allowance(address _token_owner, address spender) public view returns (uint256 remaining) {
		return allowed[_token_owner][spender];
	}
	
	/**
	 * @dev Set time of dividend Payments.
	 * @return Start_reward
	*/
	
	function dividendPaymentsTime (uint256 _start) public onlyOwner returns (uint256 Start_reward, uint256 End_reward)  {
	    uint256 check_time = block.timestamp;
	   	require (check_time < _start, "WRONG TIME, LESS THEM CURRENT");
	   //	require (check_time < _start.add(2629743), "ONE MONTH BEFORE THE START OF PAYMENTS");
	    dividend_start = _start;
        dividend_end = dividend_start.add(2629743);
        return (dividend_start, dividend_end);
	}
	
	/**@dev Shows balance of ether on project_owner address
    * @return project_owner.balance
    */

    function rewardTreasury () public view returns (uint256){
     return    project_owner.balance;
    }
	
	/*@dev call _token_owner address 
	* @return Revard _dividend
	* private function dividend withdraw 
	*/
	function reward () public view returns (uint256 Reward) {
	uint256 temp_allowance = project_owner.balance;
    require(temp_allowance > 0, "BALANCE IS EMPTY");
    require(balances[msg.sender] != 0, "ZERO BALANCE");
    uint256 temp_Fas_count = balances[msg.sender];
    uint256 _percentage = temp_Fas_count.mul(100000).div(totalSupply);
    uint256 _dividend = temp_allowance.mul(_percentage).div(100000);
    return _dividend;
  }
	
	 /** 
    * Distribution of benefits
    * param _token_owner Divider's Token address
    * binds the time stamp of receipt of dividends in struct 'Holder' to
    * 'holders' to exclude multiple receipt of dividends, valid for 30 days. 
    * Dividends are received once a month. 
    * Dividends are debited from the Treasury address. 
    * The Treasury is replenished with ether depending on the results of the company's work.
    */
    function dividendToReward() internal {
           	uint256 temp_allowance = project_owner.balance;
            require(balances[msg.sender] != 0, "ZERO BALANCE");
            require(temp_allowance > 0, "BALANCE IS EMPTY");
            uint256 withdraw_time = block.timestamp;
            require (withdraw_time > dividend_start, "PAYMENTS HAVEN'T STARTED YET");
            require (withdraw_time < dividend_end, "PAYMENTS HAVE ALREADY ENDED");
            uint256 period = withdraw_time.sub(holders[msg.sender].rewardWithdrawTime);
            require (period > 2505600, "DIVIDENDS RECIEVED ALREADY");
            dividend = reward ();
            holders[msg.sender].rewardWithdrawTime = withdraw_time;
    }
    /**@dev withdraw dividends to holders
     * 
    */

    function withdrawDividend() external {
            dividendToReward();
            require(project_owner.balance > dividend, "BALANCE IS EMPTY");
            project_owner.transfer(dividend);  
    }
}

contract ERC1384Interface is ERC20 {
    
    function acceptOwnership() public;
    function idOf (address address_owner) public view returns (uint256);
    function exist(uint256 Owner_Id) public view returns (address);
    function getOwnersList() public view returns (address[] memory Owners_List);
    function getNumOfOwners() public view returns (uint256);
    function projectOwner() external view returns (address);
    function newOwnerInvite(address _to) public;
    function createVote() public returns (uint256);
    function currentVoting () public view returns (uint256 _votes_num, uint256 _start_vote, uint256 _end_vote);
    function vote(uint256 Owner_Id, uint256 _vote_status_value) public;
    function getVoteResult() public returns (uint256[] memory);
    function getVotingDataBase (uint256 _votes_num) public returns (uint256[] memory);
}


contract ERC1384BasicContract is ERC1384Interface {
    using SafeMath for uint256;

    // Project Create Time
    uint256 internal project_create_time;
    
    //Board Of Directors composition
    uint256 internal Fas_number;

    // Vote Number
    uint256 internal votes_num;
    
    // Board Of Directors addresses list 
    address[] internal FASList;
    
    //Number of voters Dissagree
    uint256 internal voteResult_Dissagree;
    
     //Number of voters Dissagree
    uint256 internal voteResult_Agree;
    
    // Agree vote
     uint256 agree;
    
    // Dissagree vote
    uint256 disagree;
    
    // vote Result
    uint256 internal voteResult;
    
    // Vote start time
    uint256 internal vote_start;
    
    // Voting period
    uint256 internal voting_period;
   
    // Result of last voting 
    uint256[] internal lastVoteResult;
    
    // Voting data base
    uint256[] internal votingData;

    // Board of Directors acception Id
    uint256 internal acception_Id; 
    
    // Difference time for new member acception
    uint256 internal difference_time;
    
    // Temporary address for new member
    address internal temporary_address;
    
    // Vote end time
    uint256 internal voteEndTime;
    
    // Ids of owners struct
    struct OwnerId {
       
       // Owners Ids
        uint256 ID;
     }
     
    // Owners Ids blockchain
    mapping(address => OwnerId) internal owners;
        
    // Owners addresses struct    
    struct OwnerAddress{
        
        // Owners addresses
        address owner_address;
        
        // Voted time
        uint256 voted_time;
    }
    
    // Owners addresses Ids
    mapping (uint256=> OwnerAddress) internal FasID;
    
    // Voing data base struct 
    struct VotingDataBase {
        
        // Number of participants in the voting
        uint256 quorum;
        
        // Voting result
        uint256 voting_result;
        
        // Voting start time
        uint256 voting_starts;
        
        // Voting end time
        uint256 voting_ends;
    }
    
    // Voting blockchain
    mapping (uint256 => VotingDataBase) internal voteNum;
 
    constructor () public{
       project_create_time = block.timestamp;
       project_owner = msg.sender;
       FASList.push(project_owner);
       votes_num = 0;
       voting_period = 86400; 
       FasID[project_create_time].owner_address = project_owner;
       owners[project_owner].ID = project_create_time;
       Fas_number = 1;
    }
    
    /** @dev Shows project_owner address
     * @return project owner address
    */
    
    function projectOwner() external view returns (address) { 
        return project_owner;
    }
    
    /**@dev New member accepts the invitation of the Board of Directors.
    * param Owner_Id used to confirm your consent to the invitation
    * to the Board of Directors of the company valid for 24 hours.
    * if the Owner_Id is not used during the day, the invitation is canceled
    * 'Owner_Id' is deleted.
    * only a new member of the company's Board of Directors has access to the function call
    */
   
    function acceptOwnership() public {
        address new_owner = temporary_address;
        require(msg.sender == new_owner, "ACCESS DENIED"); 
        uint256 time_accept = block.timestamp;
        difference_time = time_accept - acception_Id;
        if (difference_time < 86400){    
            FASList.push(new_owner);
            Fas_number++;
            }
        else{
            delete owners[new_owner];
            delete FasID[acception_Id].owner_address; 
        }
    }
    
    /**@dev Removes a member from the company's Board of Directors.
    * param address_owner this is the address of the Board member being 
    * removed. Only the project owner has access to call the function. 
    * The 'project_owner' cannot be deleted. 
    */
    
    function delOwner (address address_owner) public {
    require(msg.sender == project_owner, "ACCESS DENIED");
    require (address_owner != project_owner, "IT IS IMPOSSIBLE TO REMOVE PROJECT OWNER");
    uint256 Id_toDel = owners[address_owner].ID;
    delete owners[address_owner];
    delete FasID[Id_toDel].owner_address; 
    uint256 new_FASListLength = FASList.length;
    new_FASListLength--;
    uint256 index_array_del;
    address [] memory _FASList = new address[](new_FASListLength);
    for (uint256 j = 0; j< Fas_number; j++){
       if (FASList[j] == address_owner){
           index_array_del = j;
       }
     }
      for (uint256 i = 0; i< new_FASListLength; i++){
       if (i < index_array_del){
           _FASList[i] = FASList[i];
       }
      else
      {
         _FASList[i] = FASList[i+1]; 
      }
     }
     Fas_number--;
     FASList = _FASList;
    }
   
   /**@dev Only the 'Owner_Id' owner and 'project_owner' have access to the function call.
    * @return Owner_Id of a member of the company's Board of Directors
   */
    
   function idOf (address address_owner) public view returns (uint256 Owner_Id){
        uint256 _Owner_Id = owners[address_owner].ID;
        address_owner = FasID[_Owner_Id].owner_address;
        require (msg.sender == address_owner || msg.sender == project_owner, "ACCESS DENIED");
        return owners[address_owner].ID;
    }

   /** @dev  Only the 'address_owner' owner and 'project_owner' have access to the function call
    * @return address_owner of a member of the company's Board of Directors
   */
  
   function exist(uint256 Owner_Id) public view returns (address address_owner){
      address check_address = FasID[Owner_Id].owner_address;
      require (msg.sender == check_address || msg.sender == project_owner, "ACCESS DENIED");
      return FasID[Owner_Id].owner_address;
    }
    
    /**@dev Shows addresses of company's Owners
     * @return Owners_List a listing of addresses of the company's Board of Directors
     */
    
    function getOwnersList() public view returns (address[] memory Owners_List){
        address[] memory _FASList = new address[](FASList.length);
        _FASList = FASList;
        return _FASList;
    }

    /**@dev Shows number of Owners
     * @return number of members of the company's Board of Directors
     */

    function getNumOfOwners() public view returns (uint256 number){
        return Fas_number;
    }
 
    /**Invitation of a new member of the company's Board of Directors.
     * Only the project owner has access to the function call.
     * param _to address of the invited member of the company's Board of Directors
     * A new member of the company's Board of Directors receives 'Owner_Id'.
    */
   
    function newOwnerInvite(address _to) public {
            require (msg.sender == project_owner, "ACCESS DENIED");
            require (balances[_to]>0, "ZERO BALANCE");
            for (uint256 j = 0; j< Fas_number; j++){
            require (FASList[j] != _to);
            }
            beforeNewOwnerInvite(_to);
            acception_Id = block.timestamp;
            temporary_address = _to;
    }

    /**internal function generates a constructor for binding the address and ID
     * of a new member of the company's Board of Directors.
     */

    function beforeNewOwnerInvite(address _who) internal {
            uint256 time_accept = block.timestamp;
            owners[_who].ID = time_accept;
            FasID[time_accept].owner_address = _who;
    }
    /** @dev Function to start the voting process. Call access only project_owner. 
     * Clears the previous result of the vote. Sets a time stamp for the 
     * start of voting.
     * @return votes_num
     */

   function createVote() public returns (uint256){
        require (msg.sender == project_owner, "ACCESS DENIED");
        votes_num = votes_num.add(1);
        vote_start = block.timestamp;
        voteEndTime = vote_start.add(voting_period);
        voteResult_Agree = 0;
        voteResult_Dissagree = 0;
        lastVoteResult = [0, 0, 0, 0, 0];

        return votes_num;
    }

    /**
    * vote for a given votes_num
    * param Owner_Id the given rights to vote
    * param _vote_status_value uint256 the vote of status, 1 Agree, 0 Disagree
    * Only a member of the company's Board of Directors has the right to vote.
    * You can only vote once during the voting period
    */
    
    function vote(uint256 Owner_Id, uint256 _vote_status_value) public{
        require(_vote_status_value >= 0, "INPUT: 1 = AGREE, 0 = DISAGREE");
        require(_vote_status_value <= 1, "INPUT: 1 = AGREE, 0 = DISAGREE");
        uint256 voting_time = block.timestamp;
        address check_address = FasID[Owner_Id].owner_address;
        require (msg.sender == check_address, "ACCESS DENIED");
        uint256 lastVotingOwnerCheck = voting_time.sub(FasID[Owner_Id].voted_time);
        require(voting_time < voteEndTime, "THE VOTE IS ALREADY OVER");
        require(voting_period < lastVotingOwnerCheck, "YOU HAVE ALREADY VOTED");

        if(_vote_status_value == 0)
        {
            disagree = balances[check_address];
            voteResult_Dissagree = voteResult_Dissagree.add(disagree); 
            FasID[Owner_Id].voted_time = voting_time;
        }
        if (_vote_status_value == 1)
        {
            agree = balances[check_address];
            voteResult_Agree = voteResult_Agree.add(agree); 
            FasID[Owner_Id].voted_time = voting_time;
        }
    }
	/**
     * @dev Sows current voting process.
     * @return _votes_num
    */
    function currentVoting () public view returns (uint256 _votes_num, uint256 _start_vote, uint256 _end_vote){
        return (votes_num, vote_start, voteEndTime);
    }

    /**
    * @dev Called only after the end of the voting time.
    * @return the voting restult: vote_num, voteResult, quorum_summ, vote_start, vote_end
    */
   function getVoteResult() public returns (uint256[] memory){
        uint256 current_time = block.timestamp;
        require (vote_start < current_time, "VOTING HAS NOT STARTED");
        voteEndTime = vote_start.add(voting_period);
        require (current_time > voteEndTime, "THE VOTE ISN'T OVER YET");
        
    
        uint256 quorum_summ = voteResult_Agree.add(voteResult_Dissagree);

        if(voteResult_Agree >= voteResult_Dissagree)
        {
            voteResult = 1;
        }

        if(voteResult_Agree < voteResult_Dissagree)
        {
            voteResult = 0;
        }

        lastVoteResult = [votes_num, voteResult, quorum_summ, vote_start, voteEndTime];
        voteNum[votes_num].quorum = quorum_summ;
        voteNum[votes_num].voting_result = voteResult;
        voteNum[votes_num].voting_starts = vote_start;
        voteNum[votes_num].voting_ends = voteEndTime;
        vote_start = 0;
        return lastVoteResult;
       
    }
    
    
    
    /**
     * @dev Shows voting data
    * @return Ballot of all completed votes by '_voting_num'
    * output format 'voting_result', 'quorum', 'voting_starts', 'voting_ends'.
    */

   function getVotingDataBase (uint256 _voting_num) public returns (uint256[] memory Ballot){
       require (_voting_num != 0, "THE VOTING ID IS NOT FILLED IN");
       votingData = [voteNum[_voting_num].voting_result,
       voteNum[_voting_num].quorum, 
       voteNum[_voting_num].voting_starts, 
       voteNum[_voting_num].voting_ends];
       return votingData;
    }
}

