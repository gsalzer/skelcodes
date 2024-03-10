pragma solidity ^0.4.26;

/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
contract SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
  
    function percent(uint value,uint numerator, uint denominator, uint precision) internal pure  returns(uint quotient) {
        uint _numerator  = numerator * 10 ** (precision+1);
        uint _quotient =  ((_numerator / denominator) + 5) / 10;
        return (value*_quotient/1000000000000000000);
    }
}

contract Canistoken is SafeMath {
    string public constant name     		            = "Canistoken";                     // Name of the token
    string public constant symbol   		            = "CNTK";                           // Symbol of token
    uint256 public constant decimals  		            = 18;                               // Decimal of token
    uint256 public constant _minbalance       		    = 10000 * 10 ** decimals;           // 10000 tokens min balance to minting
    uint256 public constant _mintransfer       		    = 1000 * 10 ** decimals;            // 1000 tokens min amount for transfer to consider in minting
    uint256 public constant _totalsupply        		= 500000000 * 10 ** decimals;       // 500 million total supply
    uint256 public constant _premined       		    = 400000000 * 10 ** decimals;       // 400 million premined tokens
    uint256 public constant _rewardperweek 		        = 162037 * 10 ** decimals;          // Tokens reward per week
    uint256 public _mined       		                = 0;                                // Mined tokens
    uint256 public _mintuserCount       		        = 0;                                // Count of user started minting
    uint256 public _totaltransactioncount       		= 0;                                // Total transaction count for session
    uint256 public _intdate       		                = now;                              // Time of contract deploy
    uint256 public _expdate       		                = now + 4380 days;                  // Time of closing minting function after 12 years
    address public owner                                = msg.sender;                       // Owner of smart contract
    address public admin                                = 0x00260EEA23db5a3dd06b164A62F26f60bA238B93;// Admin of smart contract 
    
    mapping (address => uint256) balances;
    mapping (bytes32 => uint256) transactioncount;
    mapping (bytes32 => uint256) mintingTime;
    mapping (bytes32 => address) mintingUsersList;
    uint32 mintingUsers;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // Only owner can access the function
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }
    
    // Only admin can access the function
    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert();
        }
        _;
    }
    
    constructor() public {
        balances[msg.sender]        = _premined;
        emit Transfer(0, msg.sender, _premined);
    }
    
    // Token minting function
    function mint() public returns (bool success) {
        address _customerAddress    = msg.sender;
        uint256 userBalance         = balances[_customerAddress];
        bytes32 userAdd             = keccak256(abi.encodePacked(mintingUsers, _customerAddress));
        require(userBalance >= _minbalance);                                                // Sender balance should be >= 10000 tokens
        require(_totalsupply > (add(_premined, _mined)));                                   // Total supply should be > premined token and mined token combined
        require(_expdate >= now);                                                           // Last date of minting should be >= current time
        require(mintingTime[userAdd] == 0);                                                 // User can minting only one time in 7 days
    // If all OK go ahed
        _mintuserCount              = add(_mintuserCount, 1);
        bytes32 userAddbyCount      = keccak256(abi.encodePacked(mintingUsers, _mintuserCount));
        mintingUsersList[userAddbyCount] = _customerAddress;
        mintingTime[userAdd]        = now;
        
        return true;
    }
    
    // Show token balance of address owner
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    // Transfer mined tokens to admin for distribution
    function transferMined() external onlyAdmin {
        balances[admin]             = add(balances[admin], _rewardperweek);
        emit Transfer(0, admin, _rewardperweek);
    }
    
    // Token transfer function
    // Token amount should be in 18 decimals (eg. 199 * 10 ** 18)
    function transfer(address _to, uint256 _amount ) public {
        require(balances[msg.sender] >= _amount && _amount >= 0);
        balances[msg.sender]            = sub(balances[msg.sender], _amount);
        balances[_to]                   = add(balances[_to], _amount);
        // If user started minting and amount is >= 1000 tokens
        bytes32 userAdd = keccak256(abi.encodePacked(mintingUsers, msg.sender));
        if(mintingTime[userAdd] > 0 && _amount >= _mintransfer) {
            transactioncount[userAdd]   = add(transactioncount[userAdd], 1);                // Transaction count for user
            _totaltransactioncount      = add(_totaltransactioncount, 1);                   // Total transaction count
        }
        emit Transfer(msg.sender, _to, _amount);
        
    }
    
    // Get minting users list 
    function getmintingUsersList(uint _index) external view returns(address) {
        bytes32 userAddbyCount      = keccak256(abi.encodePacked(mintingUsers, _index));
        return mintingUsersList[userAddbyCount];
    }
    
    // Get user transaction count
    function getUserTransactionCount(address _useraddress) external view returns(uint256) {
        bytes32 userAddbyCount      = keccak256(abi.encodePacked(mintingUsers, _useraddress));
        return transactioncount[userAddbyCount];
    }
    
    // Reset minting users
    function resetMintingUsers() external onlyAdmin {
        mintingUsers++;
        _mintuserCount              = 0;
        _totaltransactioncount      = 0;
        _mined                      = add(_mined, _rewardperweek);
    }
    
    // Transfer ETH to owners wallet address
    function drain() external onlyOwner {
        owner.transfer(address(this).balance);
    }
    
    // Total Supply of Canistoken
    function totalSupply() public pure returns (uint256 total_Supply) {
        total_Supply = _totalsupply;
    }
    
    // Change Admin of this contract
    function changeAdmin(address _newAdminAddress) external onlyOwner {
        admin = _newAdminAddress;
    }
    
}
