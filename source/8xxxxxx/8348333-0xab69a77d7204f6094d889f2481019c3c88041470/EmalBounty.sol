pragma solidity 0.4.24;

import "./SafeMath.sol";
import "./Ownable.sol";


contract EmalToken {
    // add function prototypes of only those used here
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool);
    
    function getBountyAmount() public view returns(uint256);
}


contract EmalBounty is Ownable {

    using SafeMath for uint256;

    // The token being sold
    EmalToken public token;

    // Bounty contract state Data structures
    enum State {
        Active,
        Closed
    }

    // contains current state of bounty contract
    State public state;

    // Bounty limit in EMAL tokens
    uint256 public bountyLimit;

    // Count of total number of EML tokens that have been currently allocated to bounty users
    uint256 public totalTokensAllocated = 0;

    // Count of allocated tokens (not issued only allocated) for each bounty user
    mapping(address => uint256) public allocatedTokens;

    // Count of allocated tokens issued to each bounty user.
    mapping(address => uint256) public amountOfAllocatedTokensGivenOut;


    /** @dev Event fired when tokens are allocated to a bounty user account
      * @param beneficiary Address that is allocated tokens
      * @param tokenCount The amount of tokens that were allocated
      */
    event TokensAllocated(address indexed beneficiary, uint256 tokenCount);
    event TokensDeallocated(address indexed beneficiary, uint256 tokenCount);

    /**
     * @dev Event fired when EML tokens are sent to a bounty user
     * @param beneficiary Address where the allocated tokens were sent
     * @param tokenCount The amount of tokens that were sent
     */
    event IssuedAllocatedTokens(address indexed beneficiary, uint256 tokenCount);



    /** @param _token Address of the token that will be rewarded for the investors
      */
    constructor(address _token) public {
        require(_token != address(0));
        owner = msg.sender;
        token = EmalToken(_token);
        state = State.Active;
        bountyLimit = token.getBountyAmount();
    }

    /* Do not accept ETH */
    function() external payable {
        revert();
    }

    function closeBounty() public onlyOwner returns(bool){
        require( state!=State.Closed );
        state = State.Closed;
        return true;
    }

    /** @dev Public function to check if bounty isActive or not
      * @return True if Bounty event has ended
      */
    function isBountyActive() public view returns(bool) {
        if (state==State.Active && totalTokensAllocated<bountyLimit){
            return true;
        } else {
            return false;
        }
    }

    /** @dev Allocates tokens to a bounty user
      * @param beneficiary The address of the bounty user
      * @param tokenCount The number of tokens to be allocated to this address
      */
    function allocateTokens(address beneficiary, uint256 tokenCount) public onlyOwner returns(bool success) {
        require(beneficiary != address(0));
        require(validAllocation(tokenCount));

        uint256 tokens = tokenCount;

        /* Allocate only the remaining tokens if final contribution exceeds hard cap */
        if (totalTokensAllocated.add(tokens) > bountyLimit) {
            tokens = bountyLimit.sub(totalTokensAllocated);
        }

        /* Update state and balances */
        allocatedTokens[beneficiary] = allocatedTokens[beneficiary].add(tokens);
        totalTokensAllocated = totalTokensAllocated.add(tokens);
        emit TokensAllocated(beneficiary, tokens);

        return true;
    }

    function validAllocation( uint256 tokenCount ) internal view returns(bool) {
        bool isActive = state==State.Active;
        bool positiveAllocation = tokenCount>0;
        bool bountyLimitNotReached = totalTokensAllocated<bountyLimit;
        return isActive && positiveAllocation && bountyLimitNotReached;
    }

    /** @dev Remove tokens from a bounty user's allocation.
      * @dev Used in game based bounty allocation, automatically called from the Sails app
      * @param beneficiary The address of the bounty user
      * @param tokenCount The number of tokens to be deallocated to this address
      */
    function deductAllocatedTokens(address beneficiary, uint256 tokenCount) public onlyOwner returns(bool success) {
        require(beneficiary != address(0));
        require(tokenCount>0 && tokenCount<=allocatedTokens[beneficiary]);

        allocatedTokens[beneficiary] = allocatedTokens[beneficiary].sub(tokenCount);
        totalTokensAllocated = totalTokensAllocated.sub(tokenCount);
        emit TokensDeallocated(beneficiary, tokenCount);

        return true;
    }

    /** @dev Getter function to check the amount of allocated tokens
      * @param beneficiary address of the investor or the bounty user
      */
    function getAllocatedTokens(address beneficiary) public view returns(uint256 tokenCount) {
        require(beneficiary != address(0));
        return allocatedTokens[beneficiary];
    }

    /** @dev Bounty users will be issued EML Tokens by the sails api,
      * @dev after the Bounty has ended to their address
      * @param beneficiary address of the bounty user
      */
    function issueTokensToAllocatedUsers(address beneficiary) public onlyOwner returns(bool success) {
        require(beneficiary!=address(0));
        require(allocatedTokens[beneficiary]>0);

        uint256 tokensToSend = allocatedTokens[beneficiary];
        allocatedTokens[beneficiary] = 0;
        amountOfAllocatedTokensGivenOut[beneficiary] = amountOfAllocatedTokensGivenOut[beneficiary].add(tokensToSend);
        assert(token.transferFrom(owner, beneficiary, tokensToSend));

        emit IssuedAllocatedTokens(beneficiary, tokensToSend);
        return true;
    }
}

