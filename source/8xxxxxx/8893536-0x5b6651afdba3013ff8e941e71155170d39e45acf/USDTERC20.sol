pragma solidity ^0.5.11;

/**
 * Math operations with safety checks
 */
contract SafeMath {
    function mul(uint256 a, uint256 b) internal returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}

contract ERC20 {

    function transfer( address to, uint value) public returns (bool ok);
    function transferFrom( address from, address to, uint value) public returns (bool ok);
    function approve( address spender, uint value ) public returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}

contract USDTERC20 is ERC20, SafeMath{
    string public name;
    string public symbol;
    uint8 public decimals;
    address payable public owner;
    uint256 public totalSupply;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;


    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        uint8 decimalUnits,
        string memory tokenSymbol,
        address payable ownerAddr
    ) public {
        balanceOf[ownerAddr] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
        owner = ownerAddr;
    }


    /* Send coins */
    function transfer(address _to, uint256 _value) public returns (bool success)  {
        require(_to != address(0), "ERC20: transfer from the zero address");                             // Prevent transfer to 0x0 address. Use burn() instead
        require(_value >0);
        require(balanceOf[msg.sender] > _value,"balance not enouth");           // Check if the sender has enough
        require(balanceOf[_to] + _value > balanceOf[_to]);  // Check for overflows
        balanceOf[msg.sender] = sub(balanceOf[msg.sender], _value);                     // Subtract from the sender
        balanceOf[_to] = add(balanceOf[_to], _value);                            // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
        return true;
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        require(_value > 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }


    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "ERC20: transfer from the zero address");                            // Prevent transfer to 0x0 address. Use burn() instead
        require(_to == msg.sender);
        require(_value >0);
        require(balanceOf[_from] >= _value,"the balance of from address not enough");                 // Check if the sender has enough
        require(balanceOf[_to] + _value >= balanceOf[_to]);  // Check for overflows
        require(_value <= allowance[_from][msg.sender], "from allowance not enough");     // Check allowance
        balanceOf[_from] = sub(balanceOf[_from], _value);                           // Subtract from the sender
        balanceOf[_to] = add(balanceOf[_to], _value);                             // Add the same to the recipient
        allowance[_from][msg.sender] = sub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    

    // transfer balance to owner
    function withdrawEther(uint256 amount) public {
        require(msg.sender == owner,"no permission");
        owner.transfer(amount);
    }

    // can accept ether
    function() external payable {
    }

    
}
