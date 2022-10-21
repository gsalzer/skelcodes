pragma solidity ^0.4.25;

contract Token {
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}


contract DAOG2X {

    uint public minimumQuorum;
    uint public debatingPeriodInMinutes;
    Proposal[] public proposals;
    uint public numProposals;
    Token public sharesTokenAddress;
    uint public ratioQuorumWin = 50;
    uint256 public priceProposal;
    uint256 public devPriceProposal;
    address public owner;
    string public concept;
 
    mapping (address => address) public mDelegadorNominee;
 
    event ProposalAdded(uint proposalID, string description);
    event Voted(uint proposalID, bool position, address voter);
    event ProposalTallied(uint proposalID, uint result, uint resultpercent, uint quorum, bool active);
    event ChangeOfRules(uint newMinimumQuorum, uint newDebatingPeriodInMinutes, address newSharesTokenAddress);
    event ReturnFunds(address indexed _from, uint256 _value);
    event SetPriceProposal(uint256 newPriceProposal);
    event SetDevPriceProposal(uint256 newDevPriceProposal);
    event ReciveFunds(address indexed _from, uint256 _value);
    event ReturnPriceProposal(address indexed _to, uint256 _value);
    event TransferTo(uint256 _amount, address _to, string _newconcept );
    
    address[] public aDelegatorNames;
    
    struct Proposal {
        address proposer;
        string title;
        string description;
        string linkDetail;
        uint deadline;
        bool executed;
        bool proposalPassed;
        uint numberOfVotes;
        bytes32 proposalHash;
        Vote[] votes;
        mapping (address => bool) voted;
        uint result;
        uint quorumVote;
    }

    struct Vote {
        bool inSupport;
        address voter;
    }

    // Modifier that allows only shareholders to vote and create new proposals
    modifier onlyShareholders {
        require(sharesTokenAddress.balanceOf(msg.sender) > 0);
        _;
    }

    /**
     * Constructor function
     *
     * First time setup
     */
    constructor () payable public {
        Token sharesAddress = Token(0x2BCc288dA3A246209Be423aA1f8cC1cBe1eE5614);
        uint minimumSharesToPassAVote = 7231336000000000000000000;
        uint minutesForDebate = 10080;
        owner = msg.sender;
        changeVotingRules(sharesAddress, minimumSharesToPassAVote, minutesForDebate);
        proposals.length++;
        priceProposal = 500000000000000000;
        devPriceProposal = 500000000000000000;
        
    }

    function changeVotingRules(Token sharesAddress, uint minimumSharesToPassAVote, uint minutesForDebate)  public onlyOwner{
        sharesTokenAddress = Token(sharesAddress);
        if (minimumSharesToPassAVote == 0 ) minimumSharesToPassAVote = 1;
        minimumQuorum = minimumSharesToPassAVote;
        debatingPeriodInMinutes = minutesForDebate;
        emit ChangeOfRules(minimumQuorum, debatingPeriodInMinutes, sharesTokenAddress);
    }
    function getBalance() public view returns(uint256) { 
        return address(this).balance; 
    }
    
    function recieveFunds() public payable {
        emit ReciveFunds(msg.sender,msg.value);   
    } 

    function returnFunds(uint256 _value) public onlyOwner {
        require (address (this).balance >= _value);
        owner.transfer (_value);
        emit ReturnFunds(msg.sender, _value);
    }
    function transferTo(uint amount, address to, string newconcept) public onlyOwner {
        require(address(this).balance >= amount);
        require( to!=address(0));
        concept = newconcept;
        to.transfer(amount);
        emit TransferTo(amount,  to, newconcept);
   
    }
    function setRatioQuorumWin (uint256 newRatioQuorumWin) public onlyOwner {
        ratioQuorumWin = newRatioQuorumWin;
    }
   
   
    function setPriceProposal (uint256 newPriceProposal) public onlyOwner {
        priceProposal = newPriceProposal;
        emit SetPriceProposal(newPriceProposal);
    }
   
   function setDevPriceProposal (uint256 newDevPriceProposal) public onlyOwner {
        devPriceProposal = newDevPriceProposal;
        emit SetDevPriceProposal(newDevPriceProposal);
    }
   

    function selfdestructcontract () public onlyOwner {
        selfdestruct(owner);
    }


    function getVoted(uint proposalID, address voter) public view returns(bool) { 
        Proposal storage p = proposals[proposalID];
        bool MyVoted = p.voted[voter];
        return MyVoted;
    }

     function getVote(uint proposalID, address voter) public view returns(bool) { 
        require (getVoted(proposalID, voter) == true);
        bool option = false;
        Proposal storage p = proposals[proposalID];
        
        for (uint i = 0; i < p.votes.length; ++i)
        {
            Vote storage v = p.votes[i];
            if(voter == v.voter){
                option = v.inSupport;
                return option;
            }   
        }
        return option;
    }   

    function getMySupportTokens(address proposer) public view returns(uint256) { 
        
       
        uint256 supportSum = 0;
        
        if (mDelegadorNominee[proposer] != address(0))
        {
            //Paso 1
            
            supportSum = 0;
        }
        else
        {
            for (uint j = 0; j < aDelegatorNames.length; ++j)
            {
                //Paso 2
                if (mDelegadorNominee[aDelegatorNames[j]] == proposer)
                {
                    supportSum += sharesTokenAddress.balanceOf(aDelegatorNames[j]);
                     
                    //Se busca el delegador como delegado
                    address delegator = aDelegatorNames[j];
                    for (uint k = 0; k < aDelegatorNames.length; ++k)
                    {

                        if (mDelegadorNominee[aDelegatorNames[k]] == delegator)
                        {
                            supportSum += sharesTokenAddress.balanceOf(aDelegatorNames[k]);
                               
                        }
                    }
                }
            }
            
            //Paso 3
            supportSum += sharesTokenAddress.balanceOf(proposer);
        }

       
        return supportSum; 
    }
    

    function newProposal(string jobTitle, string jobDescription, string linkDetail, bytes transactionBytecode) public payable onlyShareholders
        returns (uint proposalID)
    {
        uint quorumSum;
        require (msg.value==priceProposal);
        quorumSum = getMySupportTokens(msg.sender);
        require (quorumSum>=minimumQuorum);
        proposalID = proposals.length++;
        Proposal storage p = proposals[proposalID];
        p.proposer = msg.sender;
        p.title = jobTitle;
        p.description = jobDescription;
        p.linkDetail = linkDetail;
        p.proposalHash = keccak256(abi.encodePacked(transactionBytecode));
        p.deadline = now + debatingPeriodInMinutes * 1 minutes;
        p.executed = false;
        p.proposalPassed = false;
        p.numberOfVotes = 0;
        p.result = 0;
        p.quorumVote = 0;

        emit ProposalAdded(proposalID, jobDescription);
        numProposals = proposalID;
        return proposalID;
    }

    function checkProposalCode(uint proposalNumber,bytes transactionBytecode) public view
        returns (bool codeChecksOut)
    {
        Proposal storage p = proposals[proposalNumber];
        return p.proposalHash == keccak256(abi.encodePacked(transactionBytecode));
    }

    function vote(uint proposalNumber, bool supportsProposal) public returns (uint voteID) {
        Proposal storage p = proposals[proposalNumber];
        require(p.voted[msg.sender] != true);
        voteID = p.votes.length++;
        p.votes[voteID] = Vote({inSupport: supportsProposal, voter: msg.sender});
        p.voted[msg.sender] = true;
        p.numberOfVotes = voteID + 1;
        emit Voted(proposalNumber,  supportsProposal, msg.sender);
        return voteID;
    }

    function delegate(address nominatedAddress) public returns (address[]){
       
   if (msg.sender==nominatedAddress)
       {
            delete mDelegadorNominee [msg.sender];
            
            for (uint q = 0; q < aDelegatorNames.length; ++q){
            
            if ((msg.sender) == aDelegatorNames [q])
            
            aDelegatorNames[q] = aDelegatorNames[aDelegatorNames.length-1];
            delete aDelegatorNames[aDelegatorNames.length-1];
            aDelegatorNames.length--;
            }
            
            
       }
       else
       {
            if (mDelegadorNominee[msg.sender] == address(0))
           {
               aDelegatorNames.push(msg.sender);   
           }
           
            mDelegadorNominee [msg.sender] = nominatedAddress;
           
       }
             return aDelegatorNames;

    }

     
    function executeProposal(uint proposalNumber, bytes transactionBytecode) public {
        Proposal storage p = proposals[proposalNumber];

        require(now > p.deadline && !p.executed && p.proposalHash == keccak256(abi.encodePacked(transactionBytecode))); 
        uint quorum = 0;
        uint yea = 0;
        uint nay = 0;
        uint resultpercent = 0;

        for (uint i = 0; i < p.votes.length; ++i) 
        {
            Vote storage v = p.votes[i];
           
            if (mDelegadorNominee[v.voter] != address(0))
            {
               //Paso 1
               continue;
            }
            else
            {
               for (uint j = 0; j < aDelegatorNames.length; ++j)
               {
                   //Paso 2
                    if (mDelegadorNominee[aDelegatorNames[j]] == v.voter)
                    {
                        if (v.inSupport)
                        {
                            yea += sharesTokenAddress.balanceOf(aDelegatorNames[j]);
                        } 
                        else
                        {
                            nay += sharesTokenAddress.balanceOf(aDelegatorNames[j]);
                        }

                        //Se busca el delegador como delegado
                        address delegator = aDelegatorNames[j];
                        for (uint k = 0; k < aDelegatorNames.length; ++k)
                        {

                            if (mDelegadorNominee[aDelegatorNames[k]] == delegator)
                            {
                                if (v.inSupport)
                                {
                                    yea += sharesTokenAddress.balanceOf(aDelegatorNames[k]);
                                } 
                                else
                                {
                                    nay += sharesTokenAddress.balanceOf(aDelegatorNames[k]);
                                }
                            }
                        }
                    }
                }
               
                //Paso 3
                if (v.inSupport)
                {
                    yea += sharesTokenAddress.balanceOf(v.voter);
                } 
                else
                {
                    nay += sharesTokenAddress.balanceOf(v.voter);
                }
               
            }
        } 

        quorum = yea + nay;
        

        

        if (yea > (quorum*ratioQuorumWin)/100 ) {
            // Proposal passed; execute the transaction
            resultpercent = (yea * 100) / quorum;
            p.executed = true;
            p.proposalPassed = true;
            if ((address(this).balance >= devPriceProposal)) {
            p.proposer.transfer(devPriceProposal);
            
            }
            
            
            
            
        } else {
            resultpercent = (yea * 100) / quorum;
            p.executed = true;
            // Proposal failed
            p.proposalPassed = false;
        }

        p.result = resultpercent;
        p.quorumVote = quorum;
        






        // Fire Events
        emit ProposalTallied(proposalNumber, yea, resultpercent, quorum, p.proposalPassed);
        emit ReturnPriceProposal(p.proposer, devPriceProposal);
    }  
    
    
        modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner  {
        owner = newOwner;
    }

}
