pragma solidity ^0.4.26;


// Defined Owned Contract
contract Owned {
    
    //Setting Contract Creator As Owner via Constructor
    constructor() public { owner = msg.sender; }
    address owner;

    //Changing Owner
    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }
}

// Defined SafeMath to Prevent from Arithmetic Exceptions

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

// Defined Generic ERC-20 Contract Functions

interface ERC20Interface {
    function totalSupply() external constant returns (uint);
    function balanceOf(address tokenOwner) external constant returns (uint balance);
    function allowance(address tokenOwner, address spender) external constant returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// Defined JOBTokenSelfDrop Contract

contract JOBTokenSelfDrop is Owned, SafeMath{

    address tokenContractAddress;
    address ethContributionAddress;
    uint iPricePerToken;
    
    // Set Token Contract Address
    function setContractAddress(address tokenAddress) public onlyOwner
    {
        tokenContractAddress = tokenAddress;
    }
    
    // Get Token Contract Address
    function getContractAddress() public view returns (address tokenAddress)
    {
        return tokenContractAddress;
    }
    
    // Set Ethereum Address To Receive SelfDrop Fund
    function setethContributionAddress(address accountAddress) public onlyOwner
    {
        ethContributionAddress = accountAddress;
    }
    
    // Get Ethereum Address Used To Receive SelfDrop Fund
    function getethContributionAddress() public view returns (address accountAddress)
    {
        return ethContributionAddress;
    }
    
    // Set Token Price in Wei(ETH Unit)
    function setPricePerToken(uint Price) public onlyOwner
    {
        iPricePerToken = Price;
    }
    
    // Get Token Price in Wei(ETH Unit)
    function getPricePerToken() public view returns (uint Price)
    {
        return iPricePerToken;
    }
    
    // Withdraw Tokens from SelfDrop Contract
    function withdrawTokens(uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenContractAddress).transfer(msg.sender, tokens);
    }
    
    // CallBack/Fallback Function To Receive Ethereum And Send Tokens
    function () public payable
    {
        if (msg.value > 0) 
        {
            uint tokenCount;
            
            tokenCount = safeDiv(msg.value,iPricePerToken);
            
            if (msg.value <= 1 ether)
            {
                tokenCount = tokenCount + 0;
            }
            else if(msg.value <= 2 ether)
            {
                tokenCount = tokenCount + safeDiv(tokenCount,10);
            }
            else if(msg.value <= 5 ether)
            {
                tokenCount = tokenCount + safeDiv(tokenCount,20);
            }
            else if(msg.value <= 10 ether)
            {
                tokenCount = tokenCount + safeDiv(tokenCount,30);
            }
            else if(msg.value <= 50 ether)
            {
                tokenCount = tokenCount + safeDiv(tokenCount,40);
            }
            else
            {
                tokenCount = tokenCount + safeDiv(tokenCount,50);
            }
            
            // Transfer Tokens To Sender Address
            ERC20Interface(tokenContractAddress).transfer(msg.sender, tokenCount);
            
            // Transfer ETH To Contribution Address
            ethContributionAddress.transfer(msg.value);
        }
        
    }

}
