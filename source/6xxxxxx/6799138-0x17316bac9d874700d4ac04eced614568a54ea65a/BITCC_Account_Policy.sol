pragma solidity ^0.5.0;

contract tokenInterface{
    uint256 public totalSupply;
    uint8 public decimals;
    string public symbol;
    string public name;
}

contract ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf( address who ) public view returns (uint value);
    function allowance( address owner, address spender ) public view returns (uint _allowance);

    function transfer( address to, uint value) public returns (bool ok);
    function transferFrom( address from, address to, uint value) public returns (bool ok);
    function approve( address spender, uint value ) public returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}

contract Owned{
    address public owner;
    address public newOwner;

    event OwnerUpdate(address _prevOwner, address _newOwner);

    /**
        @dev constructor
    */
    constructor() public {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    /**
        @dev allows transferring the contract ownership
        the new owner still need to accept the transfer
        can only be called by the contract owner

        @param _newOwner    new contract owner
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    /**
        @dev used by a new owner to accept an ownership transfer
    */
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0x0);
    }
}

contract BITCC_Account_Policy is Owned{
    tokenInterface private tokenLedger;
    string public clause;
    string private oldClause;
    struct Policy {
        uint256 since;
        uint256 policyNum;
        uint256 amount;
    }

    uint256 public policyActiveNum=0;
    
    mapping (uint256 => uint256) policyInternalID;
    // policies[policyInternalID[policyNum]]
    Policy[] public policies;
    
    event ClauseUpdate(string _prevClause, string _newClause);
    event WelcomePolicy(uint256 holder, uint256 month_num);
    
    constructor(address token, string memory clauseTx) public{
        tokenLedger=tokenInterface(token);
        clause=clauseTx;
        addPolicy(0,0);
    }
    
    function changeClause(string memory clauseTx) public onlyOwner returns(bool){
        oldClause=clause;
        clause=clauseTx;
        emit ClauseUpdate(oldClause,clause);
        return true;
    }
    
    function acceptPolicyNum(uint256[] memory policyNums, uint256[] memory amounts) public onlyOwner returns(bool){
        require(policyNums.length == amounts.length);
        uint i;
        for (i=0;i<policyNums.length;i++){
            uint256 id=policyInternalID[policyNums[i]];
            if (id == 0) {
                id = policies.length;
                policyInternalID[policyNums[i]] = id;
                if(!addPolicy(policyNums[i],amounts[i])){revert();}
                emit WelcomePolicy(policyNums[i],amounts[i]);
                policyActiveNum++;
            }
            
        }
        return true;
    }
    
    function addPolicy(uint256 policyNum,uint256 amount) internal returns(bool){
        policies.length++;
        policies[policies.length-1].since = now; // + 3 days
        policies[policies.length-1].policyNum = policyNum;
        policies[policies.length-1].amount = amount;
        return true;
    }
    
    function policyID(uint256 policyNum) public view returns (uint id){
        return policyInternalID[policyNum];
    }
    
    function tokenDecimals() public view returns(uint8){
        return tokenLedger.decimals();
    }
    
    function tokenTotalSupply() public view returns(uint256){
        return tokenLedger.totalSupply();
    }
    
    function tokenSymbol() public view returns(string memory){
        return tokenLedger.symbol();
    }
    
    function partyBName() public view returns(string memory){
        return tokenLedger.name();
    }
    
    function claimTokens(address _token) onlyOwner public {
        require(_token != address(0));

        ERC20 token = ERC20(_token);
        uint balance = token.balanceOf(address(this));
        token.transfer(owner, balance);
    }
}
