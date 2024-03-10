
// File: node_modules\zos-lib\contracts\Initializable.sol

pragma solidity >=0.4.24 <0.6.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool wasInitializing = initializing;
    initializing = true;
    initialized = true;

    _;

    initializing = wasInitializing;
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: contracts\MDZA.sol

pragma solidity ^0.5.0;
// produced by the Solididy File Flattener (c) David Appleton 2018
// contact : dave@akomba.com
// released under Apache 2.0 licence
// input  D:\MDZA-TESTNET1\solidity-flattener\SolidityFlatteryGo\contract\MDZAToken.sol
// flattened :  Sunday, 30-Dec-18 09:30:12 UTC

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}
contract ERCInterface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Burn(address indexed from, uint256 value);
    event FrozenFunds(address target, bool frozen);
}


library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
contract MDZA is Initializable, Owned, ERCInterface {
    using SafeMath for uint;

    uint public lastIssuance;
    uint public issuanceAmount;
    uint public adminSpendAllowance;

    string public symbol;
    string public  name;
    uint public decimals;
    uint public _totalSupply;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => uint256) adminAllowed;
    mapping (address => bool) public frozenAccount;

    bool public transactionLock;

    //Initialize settings for the storage contract
    function initialize() public{
        symbol = "MDZA";
        name = "MEDOOZA Ecosystem v2.0";
        decimals = 18;
        owner = msg.sender;
        _totalSupply = 1200000000 * 10**uint(decimals);
        adminSpendAllowance = 300000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    function() payable external{
        revert();
    }
    function changeName(string memory n) public onlyOwner{
    name = n;
    }
        // Get total supply
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }

    // Get the token balance for specific account
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    // Transfer the balance from token owner account to receiver account
    function transfer(address to, uint tokens) public returns (bool success) {
        require(!transactionLock);  // Check for transaction lock
        require(!frozenAccount[to]);// Check if recipient is frozen
        require(!frozenAccount[msg.sender]);     // Check if sender is frozen
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // Token owner can approve for spender to transferFrom(...) tokens from the token owner's account
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    // Transfer token from spender account to receiver account
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(!transactionLock);         // Check for transaction lock
        require(!frozenAccount[from]);     // Check if sender is frozen
        require(!frozenAccount[to]);       // Check if recipient is frozen
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    // Get tokens that are approved by the owner
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // Token owner can approve for spender to transferFrom(...) tokens
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

        // Burn specific amount token
        function burn(uint256 tokens) public returns (bool success) {
            balances[msg.sender] = balances[msg.sender].sub(tokens);
            _totalSupply = _totalSupply.sub(tokens);
            emit Burn(msg.sender, tokens);
            return true;
        }

        // Burn token from specific account and with specific value
        function burnFrom(address from, uint256 tokens) public  returns (bool success) {
            balances[from] = balances[from].sub(tokens);
            allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
            _totalSupply = _totalSupply.sub(tokens);
            emit Burn(from, tokens);
            return true;
        }

        // Freeze and unFreeze account from sending and receiving tokens
        function freezeAccount(address target, bool freeze) onlyOwner public {
            frozenAccount[target] = freeze;
            emit FrozenFunds(target, freeze);
        }

        // Get status of a locked account
        function freezeAccountStatus(address target) onlyOwner public view returns (bool response){
            return frozenAccount[target];
        }

        // Lock and unLock all transactions
        function lockTransactions(bool lock) public onlyOwner returns (bool response){
            transactionLock = lock;
            return lock;
        }

        // Get status of global transaction lock
        function transactionLockStatus() public onlyOwner view returns (bool response){
            return transactionLock;
        }

        //Send funds from the admin account with the ability to revoke
        function adminIssueFunds(uint tokens, address to) public onlyOwner returns (bool response){
            require(!transactionLock); // Check for transaction lock
            require(!frozenAccount[to]);// Check if recipient is frozen
            require(!frozenAccount[msg.sender]); // Check if sender is frozen
          require(tokens <= adminSpendAllowance);
          if(now / 1 days  == lastIssuance){
              require(issuanceAmount + tokens <= adminSpendAllowance);
              balances[owner] = balances[owner].sub(tokens);
              adminAllowed[to] = adminAllowed[to].add(tokens);
              balances[to] = balances[to].add(tokens);
              issuanceAmount = issuanceAmount.add(tokens);
              emit Transfer(owner, to, tokens);
              return true;

          }
          else{
              lastIssuance = now / 1 days;
              issuanceAmount = tokens;
              balances[owner] = balances[owner].sub(tokens);
              adminAllowed[to] = adminAllowed[to].add(tokens);
              balances[to] = balances[to].add(tokens);
              emit Transfer(owner, to, tokens);
              return true;
          }


        }

        //Revoke funds issued from adminIssueFunds()
        function adminRevokeFunds(address from, uint tokens) public onlyOwner returns (bool success) {
            balances[from] = balances[from].sub(tokens);
            adminAllowed[from] = adminAllowed[from].sub(tokens);
            balances[owner] = balances[owner].add(tokens);
            emit Transfer(from, owner, tokens);
            return true;
        }

        //Change the daily limit for adminIssueFunds()
        function changeSpendAllowance(uint amount) public onlyOwner returns (bool success){
            adminSpendAllowance = amount;
            return true;
        }


}

