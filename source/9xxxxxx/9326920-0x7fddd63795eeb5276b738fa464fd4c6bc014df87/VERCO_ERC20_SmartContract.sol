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
    function transfer(address recipient, uint256 amount) public returns (bool);
    function approve(address spender, uint256 amount) public returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool);
    event Transfer(address indexed _from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

}

contract ERC20 is ERC20Basic{
    using SafeMath for uint256;
    
    // Tokens total supply
    uint256 public totalSupply;
	
	// Company's name
	string public name;
	
	// Number of decimals
	uint8 public decimals;
	
	// Token symbol
	string public symbol;
	
	// treasury address
	address treasuryAddress;
	
	// Token version
	string public version;
	
	//Token buyer
	address payable saleAgent;
	
	// Project owner address
	address project_owner;
	
	// Token owner address
	address payable token_owner;
	
	// Balances global values
	mapping (address => uint256) balances;
	
	// Balances with address global values
	mapping (address => mapping (address => uint)) allowed;
	
	// Holder struct
	 struct Holder {
        uint256 payment_id;
        uint256 dateCangeBalance;
    }
        
    // Holder global values
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

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(recipient, amount);
        return true;
    }
    
     /**
     * @dev Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
     
	function _transfer(address recipient, uint256 amount) internal  onlyPayloadSize(2*32) {
	    require(recipient != address(0));
	    require(balances[msg.sender] >= amount && amount > 0);
	    balances[msg.sender] = balances[msg.sender].sub(amount);
	    balances[recipient] = balances[recipient].add(amount);
	    holders[recipient].dateCangeBalance = block.timestamp;
	    emit Transfer(msg.sender, recipient, amount);        
    }

    /**
     * @dev Moves `tokens` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    
     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transferFrom(sender, recipient, amount);
            return true;
    }

     /**
     * @dev Emits an {Transfer} event indicating the updated allowance. 
     * 
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */

    function _transferFrom (address sender, address recipient, uint256 amount) internal {
        require(recipient != address(0) || sender != address (0), "APPROVE TO THE ZERO ADDRESS");
	    require(balances[sender] >= amount && allowed[sender][msg.sender] >= amount && amount > 0);
            balances[recipient] = balances[recipient].add(amount);
            balances[sender] = balances[sender].sub(amount);
            allowed[sender][msg.sender] = allowed[sender][msg.sender].sub(amount);
            holders[recipient].dateCangeBalance = block.timestamp;
            emit Transfer(sender, recipient, amount);
    }

     /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value.
     *
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(spender, amount);
        return true;
    }
    /** @dev Sets `tokens` as the allowance of `spender` over the caller's tokens.
     *
     *  boolean value indicating whether the operation succeeded.
     * Emits an {Approval} event.
     */

	function  _approve(address spender, uint256 amount) internal {
        require(spender != address(0), "APPROVE TO THE ZERO ADDRESS");
		allowed[msg.sender][spender] = amount;
		emit Approval(msg.sender, spender, amount);
	}

    /**@dev allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     * @return remaining number of tokens that `spender` will be
     * This value changes when {approve} or {transferFrom} are called.
     */

	function allowance(address _token_owner, address spender) public view returns (uint256 remaining) {
		return allowed[_token_owner][spender];
	}
	
}

contract ERC25Interface is ERC20 {
    
     function acceptOwnership() external;
     function getOwnersList() public view returns (address[] memory Owners_List);
     function getNumOfOwners() public view returns (uint256);
     function projectOwner() external view returns (address);
     function checkOwner (address address_owner) public view returns (bool);
     function newOwnerInvite(address _to) public;
     function createVote() public returns (uint256);
     function currentVoting () public view returns (uint256 _votes_num, uint256 _quorum, uint256 _start_vote, uint256 _end_vote);
     function vote(uint256 _vote_status_value) public;
     function getVotingDataBase (uint256 _voting_num) public;
     function getVoteResult() public returns (uint256[] memory);
     function previousVoteResult() public view returns (uint256 vote_ID, uint256 Result, uint256 Quorum, uint256 Start, uint256 End);
     function reward (address token_holder) public view returns (uint256 Reward);
     function dividendPaymentsTime (uint256 _start) public returns (uint256 Start_reward, uint256 End_reward);
     function treasuryRest () public view returns (uint256);
     function withdrawDividend() external;
     function depositEther() external payable;
}


contract ERC25BasicContract is ERC25Interface {
    using SafeMath for uint256;
    
    //Board Of Directors composition
    uint256 internal Fas_number;
    
    // Board of Directors acception Id
    uint256 internal acception_Id; 

    // Difference time for new member acception
    uint256 internal difference_time;
    
    // Temporary address for new member
    address internal temporary_address;

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
    
    // Quorum who voted
    uint256 internal quorum;
    
    // vote Result
    uint256 internal voteResult;
    
    // Vote start time
    uint256 internal vote_start;
    
    // Voting period
    uint256 internal voting_period;
   
    // Result of last voting 
    uint256[] internal lastVoteResult;
    
    // Voting data base
    uint256 internal VotingResult;
    
    // Vote end time
    uint256 internal voteEndTime;
    
    // Array to get voting data by votes_num
    uint256[] internal voteData;
    
    // Ids of owners struct
    struct OwnerId {
       
       // Owners Ids
        address ID;
        
        // Voted time
        uint256 voted_time;
     }
     
    // Owners Ids global values
    mapping(address => OwnerId) internal owners;
    
    // Voing data base struct 
    struct VotingDataBase {
        
        // Number of participants in the voting
        uint256 quorum_summ;
        
        // Voting result
        uint256 voting_result;
        
        // Voting start time
        uint256 voting_starts;
        
        // Voting end time
        uint256 voting_ends;
    }
    
    // Voting global values
    mapping (uint256 => VotingDataBase) internal voteNum;
 
 	// Start of dividend payments
	uint256 public dividend_start;
	
	// end of dividend payments
	uint256 public dividend_end;
    
    // Amount of ether to pay dividents
    uint256 public treasuryBalance;
    
    // Time when token holder has received dividends
    uint256 internal LastWithdrawTime;
    
    // ID of dividend payments
    uint256 internal dividend_payment_Id;

 
    constructor () public{
       project_owner = msg.sender;
       FASList.push(project_owner);
       votes_num = 0;
       voting_period = 86400; 
       owners[project_owner].ID = project_owner;
       Fas_number = 1;
       dividend_payment_Id = 0;
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
   
    function acceptOwnership() external {
        require(this.checkOwner(msg.sender) == true, "ACCESS DENIED");
        require(msg.sender != project_owner, "ACCESS DENIED");
        uint256 time_accept = block.timestamp;
        difference_time = time_accept - acception_Id;
        if (difference_time < 86400){    
            FASList.push(msg.sender);
            Fas_number++;
            }
        else{
            delete owners[msg.sender];
        }
    }
    
    /**@dev Checking the owner in the list of owners
     * @return true or false
    */
    
    function checkOwner (address address_owner) public view returns (bool) {
        if(owners[address_owner].ID == address_owner || address_owner == temporary_address)
            return true;
        else {
            return false;
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
        delete owners[address_owner];
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
     * Conditions in White Paper 
    */
   
    function newOwnerInvite(address _new_owner) public {
        require(_new_owner != address(0));
        require(msg.sender == project_owner, "ACCESS DENIED");
        require(balances[_new_owner]>0, "ZERO BALANCE");
        require(owners[_new_owner].ID != _new_owner, "ALREADY EXIST");
        owners[_new_owner].ID = _new_owner;
        acception_Id = block.timestamp;
        temporary_address = _new_owner;
    }

    /** @dev Function to start the voting process. Call access only project_owner. 
     * Clears the previous result of the vote. Sets a time stamp for the 
     * start of voting.
     * @return votes_num
     */

   function createVote() public returns (uint256){
        require (msg.sender == project_owner, "ACCESS DENIED");
        uint256 current_time = block.timestamp;
        require(current_time > voteEndTime, "CURRENT VOTING IS'N OVER YET");
        votes_num = votes_num.add(1);
        vote_start = current_time;
        voteEndTime = vote_start.add(voting_period);
        voteResult_Agree = 0;
        voteResult_Dissagree = 0;
        quorum = 0;
        voteNum[votes_num].voting_starts = vote_start;
        voteNum[votes_num].voting_ends = voteEndTime;
        return votes_num;
    }

    /**
    * vote for a given votes_num
    * param _vote_status_value uint256 the vote of status, 1 Agree, 0 Disagree
    * Only a member of the company's Board of Directors has the right to vote.
    * You can only vote once during the voting period.
    * Votes are counted in proportion to the number of tokens.
    * If you did not participate in the voting your vote will be abstained.
    */
    
    function vote(uint256 _vote_status_value) public{
        require(_vote_status_value >= 0, "INPUT: 1 = AGREE, 0 = DISAGREE");
        require(_vote_status_value <= 1, "INPUT: 1 = AGREE, 0 = DISAGREE");
        uint256 voting_time = block.timestamp;
        require(owners[msg.sender].ID == msg.sender, "ACCESS DENIED");
        uint256 lastVotingOwnerCheck = voting_time.sub(owners[msg.sender].voted_time);
        require(voting_time < voteEndTime, "THE VOTE IS ALREADY OVER");
        require(voting_period < lastVotingOwnerCheck, "YOU HAVE ALREADY VOTED");

        if(_vote_status_value == 0)
        {
            disagree = balances[msg.sender];
            voteResult_Dissagree = voteResult_Dissagree.add(disagree); 
            owners[msg.sender].voted_time = voting_time;
        }
        if (_vote_status_value == 1)
        {
            agree = balances[msg.sender];
            voteResult_Agree = voteResult_Agree.add(agree); 
            owners[msg.sender].voted_time = voting_time;
        }

        quorum = voteResult_Agree.add(voteResult_Dissagree);
        voteNum[votes_num].quorum_summ = quorum;
    }
	/**
     * @dev Sows current voting process.
     * @return _votes_num
    */
    function currentVoting () public view returns (uint256 _votes_num, uint256 _quorum, uint256 _start_vote, uint256 _end_vote){
        return (votes_num, quorum, vote_start, voteEndTime);
    }

    /**
    * @dev Called only after the end of the voting time.
    * @return the voting restult: vote_num, voteResult, quorum_summ, vote_start, vote_end
    */
   function getVoteResult() public returns (uint256 [] memory){
       uint256 current_time = block.timestamp;
       require (current_time > voteEndTime, "THE VOTE ISN'T OVER YET");
            if(voteResult_Agree >= voteResult_Dissagree)
            {
                voteResult = 1;
            }

            if(voteResult_Agree < voteResult_Dissagree)
            {
                voteResult = 0;
            }

        lastVoteResult = [votes_num, voteResult, quorum, vote_start, voteEndTime];
        voteNum[votes_num].voting_result = voteResult;
            return lastVoteResult;
   }
    
      /**
     * @dev Shows previous voting data
    * @return Ballot of all completed votes by '_voting_num'
    * output format 'voting_result', 'quorum', 'voting_starts', 'voting_ends'.
    */
    
    function previousVoteResult() public view returns (uint256 vote_ID, uint256 Result, uint256 Quorum, uint256 Start, uint256 End){ 
        vote_ID = lastVoteResult[0];
        Result = lastVoteResult[1];
        Quorum = lastVoteResult[2];
        Start = lastVoteResult[3];
        End = lastVoteResult[4];
        return (vote_ID, Result, Quorum, Start, End);
     }

    /**
    * @dev Create array for previous voting data
    * @return Ballot of all completed votes by '_voting_num'
    * output format 'voting_result', 'quorum', 'voting_starts', 'voting_ends'.
    */

    function getVotingDataBase (uint256 _voting_num) public { 
        voteData = [0, 0, 0, 0, 0];
        uint256 result = voteNum[_voting_num].voting_result;
        uint256 quorum_vote = voteNum[_voting_num].quorum_summ;
        uint256 start_vote = voteNum[_voting_num].voting_starts;
        uint256 end_vote = voteNum[_voting_num].voting_ends;
        voteData = [_voting_num, result, quorum_vote, start_vote, end_vote];
     }
     
     /**
    * @dev Shows result of previous voting data
    * @return Ballot of all completed votes by '_voting_num'
    * output format 'vote_ID', 'Result', 'Quorum', 'Start', 'End'.
    */
    
    function showVotingDataBase () public view returns (uint256 vote_ID, uint256 Result, uint256 Quorum, uint256 Start, uint256 End){
        vote_ID = voteData[0];
        Result = voteData[1];
        Quorum = voteData[2];
        Start = voteData[3];
        End = voteData[4];
        return (vote_ID, Result, Quorum, Start, End);
    } 
     
   	/**
	 * @dev Set time of dividend Payments.
	 * @return Start reward, End reward. The period for receiving 
	 * the reward is 30 days. Approved Fund of the Treasury for the payment of dividends. 
	*/
	function dividendPaymentsTime (uint256 _start) public onlyOwner returns (uint256 Start_reward, uint256 End_reward)  {
	    uint256 check_time = block.timestamp;
	    require(check_time > dividend_end, "CURRENT DIVIDEND PAYMENT IS'T OVER YET"); 
	    treasuryBalance = address(this).balance;
	    require(treasuryBalance > 0, "BALANCE IS EMPTY");
	    dividend_payment_Id = dividend_payment_Id.add(1);
	    require (check_time < _start, "INCORRECT TIME, LESS CURRENT TIME");
	    require (check_time < _start.add(2629743), "ONE MONTH BEFORE THE START OF PAYMENTS"); 
	    dividend_start = _start;
        dividend_end = dividend_start.add(2629743);
        return (dividend_start, dividend_end);
	}  
	
    /**@dev Shows rest of treasuryBalance of ether on contract address
    * @return address(this).balance
    */
    function treasuryRest () public view returns (uint256){
        return address(this).balance; 
 }
    
    /*@dev call _token_owner address 
	* @return Reward _dividend. The function can only be called 
	* during the dividend payment period. 
	* During the rest of the time, the function returns an error if 
	* the Fund has a zero balance for paying dividends.
	* The minimum amount of tokens for receiving dividends is 30 tokens. 
	* This allows you to get 0.001% of the treasury Fund.
	*/
	function reward (address token_holder) public view returns (uint256 Reward) {
        require(msg.sender != address(0));
        uint256 current_time = block.timestamp;
	    uint256 rest_treasury = treasuryRest();
        require(rest_treasury > 0, "BALANCE IS EMPTY");
        require(balances[token_holder] != 0, "ZERO BALANCE");
        require(holders[token_holder].payment_id < dividend_payment_Id, "DIVIDENDS RECEIVED ALREADY");
        require(holders[token_holder].dateCangeBalance < dividend_start, "IT'S TO EARLY FOR RECEIVING DIVIDENDS");
        require(current_time > dividend_start, "TO EARLY");
        require(current_time < dividend_end, "TO LATE");
        uint256 percentage_count = balances[token_holder];
        uint256 _percentage = percentage_count.mul(1000000).div(totalSupply);
        uint256 _dividend = treasuryBalance.mul(_percentage).div(1000000);
        return _dividend;
  }
	
	 /** 
    * Distribution of dividends.
    * IMPORTANT:
    * The time stamp of receipt of dividends in struct 'Holder' to 'holders' to 
    * exclude multiple receipt of dividends, valid for 30 days.
    * Change balance of token owner it is not allowed during dividend payments 
    * period for receiveng  dividends. Before changing token balance holder have
    * to receive dividends, else the execution of function will revert.
    * Dividends are received once during payment period. 
    * Dividends are debited from the contract address by token owners PERSONALLY. 
    * The contract balance is replenished with  ether depending on the results of the company's work.
    */
    
    function withdrawDividend() external {
        uint256 dividend = this.reward(msg.sender);
        address pay_dividends = address(this);
        address payable token_holder = address (msg.sender);
        holders[msg.sender].payment_id = dividend_payment_Id;
            if (pay_dividends.balance >= dividend)
            token_holder.transfer(dividend);
  }  
    /**@dev accept Ether for dividend payments 
     * onlly project_owner can deposit Ether on the contract balance
    */
    function depositEther() external payable{
        require(msg.sender == this.projectOwner(), "ACCESS DENIED");
        require(msg.sender.balance > msg.value);
     }  
         
    /* accept Ether
    *
    */
    function() external payable{
        this.depositEther();
        msg.sender.transfer(msg.value);
    }
    
}
