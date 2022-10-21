pragma solidity 0.5.10;


library SafeMath {

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
  
}


contract Ownable {
    
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract Token is Ownable {
  
    using SafeMath for uint256;

    string  public name;
    string  public symbol;
    uint8   public decimals;
    uint256 public totalSupply;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping(address => uint256)) public allowance;
    mapping (address => bool) public isFrozen;

    event Transfer (address indexed from, address indexed to, uint256 value);
    event Approval (address indexed owner, address indexed spender, uint256 value);
    event Freeze   (address indexed account);
    event Unfreeze (address indexed account);
    event Mint     (address indexed minter, uint256 value);
    event Burn     (address indexed account, uint256 value);


    /**
    * @dev Transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        
        require(_to != address(0), "Transfer: to address is the zero address");
        require(_value <= balanceOf[msg.sender], "Transfer: transfer value is more than your balance");
        require(!isFrozen[msg.sender], "Transfer: your address is forozen");

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public returns (bool) {

        require(!isFrozen[msg.sender], "Approve: your address is forozen");
        allowance[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        
        require(_to != address(0), "TransferFrom: to address is the zero address");
        require(_value <= balanceOf[_from], "TransferFrom: transfer value is more than the balance of the from address");
        require(_value <= allowance[_from][msg.sender], "TransferFrom: transfer value is more than your allowance");
        require(!isFrozen[msg.sender] && !isFrozen[_from], "TransferFrom: your address or the from address is forozen");

        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev Increase the amount of tokens that an owner allowed to a spender.
    * @param _spender The address which will spend the funds.
    * @param _addedValue The amount of tokens to increase the allowance by.
    */
    function increaseApproval( address _spender, uint256 _addedValue) public returns (bool) {   
        
        require(!isFrozen[msg.sender], "IncreaseApproval: your address is forozen");

        allowance[msg.sender][_spender] = allowance[msg.sender][_spender].add(_addedValue);
        
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

    /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender.
    * @param _spender The address which will spend the funds.
    * @param _subtractedValue The amount of tokens to decrease the allowance by.
    */
    function decreaseApproval( address _spender, uint256 _subtractedValue ) public returns (bool) {

        require(!isFrozen[msg.sender], "DecreaseApproval: your address is forozen");
        
        uint256 oldValue = allowance[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
        allowance[msg.sender][_spender] = 0;
        } else {
        allowance[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }

        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

    /**
    * @dev Freeze an account, and only the owner can do so.
    * @param _account The address which will be frozen.
    */
    function freeze( address _account ) onlyOwner public {
        
        isFrozen[_account] = true;
        
        emit Freeze(_account);
    }

    /**
    * @dev Unfreeze an account, and only the owner can do so.
    * @param _account The address which will be unfrozen.
    */
    function unfreeze(address _account) onlyOwner public {
        
        isFrozen[_account] = false;

        emit Unfreeze(_account);
    }

    /**
    * @dev Issue a specified amount token for a specified account, and only the owner can do so. 
    * @param _minter the address which will receive the minted token.
    * @param _mintedValue The amount of tokens to minted by the owner.
    */
    function mint(address _minter, uint256 _mintedValue) onlyOwner public {
        
        balanceOf[_minter] = balanceOf[_minter].add(_mintedValue);
        totalSupply = totalSupply.add(_mintedValue);
        
        emit Mint(_minter, _mintedValue);
    }

    /**
    * @dev Destroy token of the executor
    * @param _value The amount of tokens to destory.
    */
    function burn(uint256 _value) public returns (bool) {

        require(!isFrozen[msg.sender], "Burn: your address is forozen");
        require(_value <= balanceOf[msg.sender], "Burn: burn value is more than your balance");
        
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);           
        totalSupply = totalSupply.sub(_value);                      
        
        emit Burn(msg.sender, _value);
        return true;
    }
        
    /**
    * @dev Destroy token of a specified address
    * @param _from The address which the owner of the token.
    * @param _value The amount of tokens to destory.
    */ 
    function burnFrom(address _from, uint256 _value) public returns (bool) {
        
        require(!isFrozen[msg.sender], "BurnFrom: your address is forozen");
        require(_value <= balanceOf[_from], "BurnFrom: burn value is more than the balance of the from address");                
        require(_value <= allowance[_from][msg.sender], "BurnFrom: burn value is more than your allowance");    
        
        balanceOf[_from] = balanceOf[_from].sub(_value);                         
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);             
        totalSupply = totalSupply.sub(_value);                                
        
        emit Burn(_from, _value);
        return true;
    }
}


contract SpotChainToken is Token {

    uint256 internal constant INIT_TOTALSUPLLY = 600000000; // Total amount of tokens

    constructor() public {

        name        = "SpotChain Token";
        symbol      = "GSB";
        decimals    = uint8(18);
        totalSupply = INIT_TOTALSUPLLY * uint256(10) ** uint256(decimals);
        
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
}
