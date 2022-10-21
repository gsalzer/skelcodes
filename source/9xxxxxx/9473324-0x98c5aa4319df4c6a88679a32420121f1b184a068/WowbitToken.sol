pragma solidity >= 0.5.3 < 0.6.0;

import "./SafeMath.sol";
import "./ERC20Interface.sol";
import "./ERC223Interface.sol";
import "./ERC223ReceivingContract.sol";

//  Ownership contract
//  - token contract ownership for owner & lockup addresses

contract Ownership {
    address private _owner;
    address private _lockup;
    
    event OwnerOwnershipTransferred(address indexed prevOwner, address indexed newOwner);
    event LockupOwnershipTransferred(address indexed prevLockup, address indexed newLockup);
    
    // Returns contract owner address
    function owner() public view returns (address){
        return _owner;
    }
    
    // Returns contract lockup address
    function lockup() public view returns (address){
        return _lockup;
    }
    
    // Check if caller is owner account
    function isOwner() public view returns (bool){
        return (msg.sender == _owner);
    }
    
    // Check if caller is lockup account
    function isLockup() public view returns (bool){
        return (msg.sender == _lockup);
    }
    
    // Modifier for function restricted to owner only
    modifier onlyOwner() {
        require(isOwner(), "Ownership: the caller is not the owner address");
        _;
    }
    
    // Modifier for function restricted to lockup only
    modifier onlyLockup() {
        require(isLockup(), "Ownership: the caller is not the lockup address");
        _;
    }
    
    // Modifier for function restricted to owner & lockup only
    modifier onlyOwnerLockup() {
        require(isOwner() || isLockup(), "Ownership: the caller is not either owner or lockup address");
        _;
    }
    
    // Transfer owner's ownership to new address
    // # param newOwner: address of new owner to be transferred
    function transferOwnerOwnership(address newOwner) public onlyOwner {
        _transferOwnerOwnership(newOwner);
    }
    
    // Transfer lockup's ownership to new address
    // # param newLockup: address of new lockup to be transferred
    function transferLockupOwnership(address newLockup) public onlyOwner {
        _transferLockupOwnership(newLockup);
    }
    
    // ==== internal functions ====

    function _transferOwnerOwnership(address newOwner) internal {
        require (newOwner != address(0), "Ownable: new owner is zero address");
        emit OwnerOwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    function _transferLockupOwnership(address newLockup) internal {
        require (newLockup != address(0), "Ownable: new lockup is zero address");
        emit LockupOwnershipTransferred(_lockup, newLockup);
        _lockup = newLockup;
    }
    
    function _setupOwnerships(address own, address lock) internal {
        require (own != address(0), "Ownable: owner is zero address");
        require (lock != address(0), "Ownable: lockup is zero address");
        
        _owner = own;
        _lockup = lock;
        
        emit OwnerOwnershipTransferred(address(0), own);
        emit LockupOwnershipTransferred(address(0), lock);
    }
    
}

//  ERC20 Base Token contract
//  - token functions for ERC20
contract ERC20CompatibleToken {
    using SafeMath for uint256;
    
    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
  	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  	
    // Moves the `_value` tokens from sender `_from` to recipient `_to` using the allowance mechanism.
    // `_value` is then deducted from the caller's allowance.
    // # params _from:   sender's address for token to be taken
    // # params _to:     recepient's address for token to be sent
    // # params _value:  amount of tokens (in wei)
    // * returns (bool): status of transaction if its succeed or not
  	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        
        return true;
    }
    
    // Sets `_value` of token as the allowance of `_spender` over the caller's tokens.
    // # params _spender: recepient's address who will spends the token
    // # params _value:   amount of tokens (in wei) to be sent
    // * returns (bool):  status of transaction if its succeed or not
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }
    
    // Returns the remaining number of tokens that `_spender` will be allowed to spend on behalf
    // of `_owner` through transferFrom(). This is zero by default.
    // # params _owner:    address of the owner approved for spender to spend tokens
    // # params _spender:  address of spender
    // * returns (uint256):amount of token (in wei) that can be spent
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    // Adds `_addValue` of token to the allowance of `_spender`.
    // # params _spender:  address of the spender to add its allowance
    // # params _addValue: amount of token (in wei) to be added
    // * returns (bool):  status of transaction if its succeed or not
    function increaseApproval(address _spender, uint256 _addValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        
        return true;
    }
    
    // Subtracts `_subValue` of token from the allowance of `_spender`.
    // # params _spender:  address of the spender to add its allowance
    // # params _subValue: amount of token (in wei) to be subtracted
    // * returns (bool):   status of transaction if its succeed or not
    function decreaseApproval(address _spender, uint256 _subValue) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        
        return true;
    }
}

//  Base ERC223 Token contract
//  - Token with ERC223 standard functions including ERC20 token compability functions
contract BaseToken is ERC20Interface, ERC223Interface, ERC20CompatibleToken {
    using SafeMath for uint256;

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

    // Returns the name of the token
    // * returns (string): name of token
    function name() public view returns (string memory) {
        return _name;
    }

    // Returns the symbol of the token
    // * returns (string): symbol of token
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    // Returns the decimals of the token
    // * returns (uint8): decimal value of token
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    // Returns the total supply of the token
    // * returns (uint256): total supply of token
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    // Returns the amount of tokens owned by `_who`.
    // # params _who:       the address of the account
    // * returns balance:   the amount of token in the account
    function balanceOf(address _who) public view returns (uint256 balance) {
        return balances[_who];
    }
    
    // Function that is called when a user or another contract wants to transfer funds
    // (compatible with ERC20 standards).
    // # params _to:     address of recipient
    // # params _value:  amount of token (in wei) to be sent
    // * returns (bool): status of transaction if its succeed or not
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value > 0, "Token: value to send is zero value");
        require(balanceOf(msg.sender) >= _value, "Token: balance of token is not enough");

        uint codeLength;
        bytes memory empty;
        assembly {
            codeLength := extcodesize(_to)
        }
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        // Check to see if receiver is contract
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    // Function that is called when a user or another contract wants to transfer funds
    // (for ERC223 standards use)
    // # params _to:    address of recipient / contract
    // # params _value: amount of token (in wei) to be sent
    // # params _data:  additional data parameter in bytes
    // * returns (bool): status of transaction if its succeed or not
    function transfer(address _to, uint256 _value, bytes memory _data) public returns (bool) {
        require(_value > 0, "Token: value to send is zero value");
        require(balanceOf(msg.sender) >= _value, "Token: balance of token is not enough");

        // Standard function transfer similar to ERC20 transfer with no _data .
        // Added due to backwards compatibility reasons .
        if(isContract(_to)) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value, _data);
    }
    
    // ==== internal functions ====
    
    function isContract(address _addr) internal view returns (bool is_contract) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length>0);
    }
}

//  Wowbit Token contract
//  - main contract for Wowbit ERC20-ERC223 token
contract WowbitToken is Ownership, BaseToken{
    using SafeMath for uint256;
    uint256 internal reservedTotal = 0;

    event ReservedToken(address indexed caller, uint256 amount, uint256 newtotal, uint timestamp);
    event ReleaseReservedToken(address indexed caller, uint256 amount, uint256 newtotal, uint timestamp);

    // Constructor for Wowbit token initialization upon deployment
    // # params name:           string name of the token
    // # params symbol:         string symbol of the token
    // # params decimals:       decimal of token (0 - 18 decimals)
    // # params supply:         initial supply of the token
    // # params contractOwner:  address of the contract owner account
    // # params contractLockup: address of token lockup account
    constructor(string memory name, string memory symbol, uint8 decimals, uint256 supply, address contractOwner, address contractLockup) public {
        require(decimals <= 18, "Token: decimals must be less than 18");
        require(supply > 0, "Token: token supply must be greater than 0");
        _setupOwnerships(contractOwner, contractLockup);
        
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _totalSupply = supply * 10**uint(_decimals);
        balances[owner()] = _totalSupply;
        
        emit Transfer(address(0x0), owner(), _totalSupply);
    }
    
    // Mints the certain amount of token to owner
    // # params _value: the amount of token (in decimals) to mint
    function mint(uint256 _amount) public onlyOwner {
        _mint(owner(), _amount);
    }
    
    // Burns the certain amount of token
    // # params _value: the amount of token (in wei) to burn
    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }
    
    // Burns the certain amount of token using on behalf of other user
    // # params _account: the targer user's account
    // # params _value:   the amount of token (in wei) to burn
    function burnFrom(address _account, uint256 _value) public {
        _burnFrom(_account, _value);
    }
    
    // Reserves the amount of token to lockup account
    // # params _value: amount of token (in wei) to lock
    function reserveToken(uint256 _value) public onlyOwner {
        transfer(lockup(), _value);
        reservedTotal = reservedTotal.add(_value);

        emit ReservedToken(msg.sender, _value, reservedTotal, now);
    } 

    // Returns the total amount of tokens reserved in lockup account
    // * returns (uint256): amount of token reserved in lockup account
    function reserveTotal() public view returns (uint256) {
        return reservedTotal;
    }

    // Release amount of reserved token from lockup to owner address
    // # params _value: amount of token (in wei) to release
    function releaseReserveToken(uint256 _value) public onlyOwner returns (bool){
        _releaseReserveToken(_value);
    }

    // ==== internal functions ====
    
    // Process in mint some tokens
    function _mint(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _totalSupply = _totalSupply.add(value);
        balances[account] = balances[account].add(value);
        emit Transfer(address(0), account, value);
    }
    
    // Process in burn token
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _totalSupply = _totalSupply.sub(value);
        balances[account] = balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }
    
    // Process in burn from tokens
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        approve(account, allowed[account][msg.sender].sub(value));
    }
    
    // Process of releasing locked tokens from lockup account
    function _releaseReserveToken(uint256 _value) internal {
        require(_value > 0, "Token: release reserve token amount is zero");
        if(_value >= reservedTotal){
            _release(reservedTotal);
            reservedTotal = 0;
            emit ReleaseReservedToken(msg.sender, reservedTotal, reservedTotal, now);
        } else {
            _release(_value);
            reservedTotal = reservedTotal.sub(_value);
            emit ReleaseReservedToken(msg.sender, _value, reservedTotal, now);
        }
    }

    // Transfer process from lockup to owner accounts
    function _release(uint256 _val) internal {
        balances[lockup()] = balances[lockup()].sub(_val);
        balances[owner()] = balances[owner()].add(_val);
        emit Transfer(lockup(), owner(), _val);
    }
    
    // Transfer process from lockup to owner accounts
    function _lock(uint256 _val) internal {
        balances[owner()] = balances[owner()].sub(_val);
        balances[lockup()] = balances[lockup()].add(_val);
        emit Transfer(lockup(), owner(), _val);
    }
}
