pragma solidity ^0.4.25;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract.
    */
    constructor(address _owner) public {
        owner = _owner == address(0) ? msg.sender : _owner;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    /**
    * @dev confirm ownership by a new owner
    */
    function confirmOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

/**
 * @title IERC20Token - ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract IERC20Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value)  public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value)  public returns (bool success);
    function approve(address _spender, uint256 _value)  public returns (bool success);
    function allowance(address _owner, address _spender)  public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
contract SafeMath {
    /**
    * @dev constructor
    */
    constructor() public {
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(a >= b);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title ERC20Token - ERC20 base implementation
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Token is IERC20Token, SafeMath {
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(balances[msg.sender] >= _value);

        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);

        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowed[_owner][_spender];
    }
}

/**
 * @title ITokenEventListener
 * @dev Interface which should be implemented by token listener
 */
interface ITokenEventListener {
    /**
     * @dev Function is called after token transfer/transferFrom
     * @param _from Sender address
     * @param _to Receiver address
     * @param _value Amount of tokens
     */
    function onTokenTransfer(address _from, address _to, uint256 _value) external;
}

/**
 * @title ManagedToken
 * @dev ERC20 compatible token with issue
 * @dev All transfers can be monitored by token event listener
 */
contract ManagedToken is ERC20Token, Ownable {
    uint256 public totalIssue;                                                  //Total token issue
    bool public allowTransfers = true;                                          //Default enable transfer

    ITokenEventListener public eventListener;                                   //Listen events

    event AllowTransfersChanged(bool _newState);                                //Event:
    event Issue(address indexed _to, uint256 _value);                           //Event: Issue
    event Destroy(address indexed _from, uint256 _value);                       //Event:
    event IssuanceFinished(bool _issuanceFinished);                             //Event: Finished issuance

    //Modifier: Allow all transfer if not any condition
    modifier transfersAllowed() {
        require(allowTransfers, "Require enable transfer");
        _;
    }

    /**
     * @dev ManagedToken constructor
     * @param _listener Token listener(address can be 0x0)
     * @param _owner Owner of contract(address can be 0x0)
     */
    constructor(address _listener, address _owner) public Ownable(_owner) {
        if(_listener != address(0)) {
            eventListener = ITokenEventListener(_listener);
        }
    }

    /**
     * @dev Enable/disable token transfers. Can be called only by owners
     * @param _allowTransfers True - allow False - disable
     */
    function setAllowTransfers(bool _allowTransfers) external onlyOwner {
        allowTransfers = _allowTransfers;

        //Call event
        emit AllowTransfersChanged(_allowTransfers);
    }

    /**
     * @dev Set/remove token event listener
     * @param _listener Listener address (Contract must implement ITokenEventListener interface)
     */
    function setListener(address _listener) public onlyOwner {
        if(_listener != address(0)) {
            eventListener = ITokenEventListener(_listener);
        } else {
            delete eventListener;
        }
    }

    function transfer(address _to, uint256 _value) public transfersAllowed returns (bool) {
        bool success = super.transfer(_to, _value);
        /* if(hasListener() && success) {
            eventListener.onTokenTransfer(msg.sender, _to, _value);
        } */
        return success;
    }

    function transferFrom(address _from, address _to, uint256 _value) public transfersAllowed returns (bool) {
        bool success = super.transferFrom(_from, _to, _value);

        //If has Listenser and transfer success
        /* if(hasListener() && success) {
            //Call event listener
            eventListener.onTokenTransfer(_from, _to, _value);
        } */
        return success;
    }

    function hasListener() internal view returns(bool) {
        if(eventListener == address(0)) {
            return false;
        }
        return true;
    }

    /**
     * @dev Issue tokens to specified wallet
     * @param _to Wallet address
     * @param _value Amount of tokens
     */
    function issue(address _to, uint256 _value) external onlyOwner {
        totalIssue = safeAdd(totalIssue, _value);
        require(totalSupply >= totalIssue, "Total issue is not greater total of supply");
        balances[_to] = safeAdd(balances[_to], _value);
        //Call event
        emit Issue(_to, _value);
        emit Transfer(address(0), _to, _value);
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From OpenZeppelin StandardToken.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = safeAdd(allowed[msg.sender][_spender], _addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From OpenZeppelin StandardToken.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = safeSub(oldValue, _subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

/**
 * LEX Token Contract
 * @title LEX
 */
contract LEX is ManagedToken {

    /*
    *  Token with ability to limit transfers of owner
    *  for certain period of time and certain amount
    */
    struct OwnerLock {
        string name;                                                            //Name of lock
        uint256 lockEndTime;                                                    //Time end of lock
        uint256 amount;                                                         //Total token is lock
        bool isLock;                                                            //Total token is lock
    }

    /*
    *  Token with ability to limit transfers of client
    *  for certain period of time and certain amount
    */
    struct ClientLock {
        uint256 lockEndTime;                                                    //Time end of lock
        uint256 amount;                                                         //Total token is lock
        bool isLock;                                                            //Total token is lock
    }

    uint256 public TotalLocked = 0;                                             //Total token is lock

    /* This creates an array with all balances of freeze */
    mapping (address => uint256) public freezeOf;
    /* This creates an array with all locks of owner*/
    mapping(uint256 => OwnerLock) public ownerLocks;
    /* This creates an array with all locks of client*/
    mapping(address => ClientLock) public clientLocks;
    /* This creates an array with all ids of locks */
    uint256[] public LockIds;

    /* This notifies about owner lock the amount of token for certain period of time */
    event LockOwner(string name, uint256 lockEndTime, uint256 amount, uint256 id);

    /* This notifies about owner unlock the amount of token for certain period of time */
    event UnLockOwner(string name, uint256 lockEndTime, uint256 amount, uint256 id);

    /* This notifies about owner burnt the amount of token */
    event Burn(address indexed from, uint256 value);

    /* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);

    event UnLockClient(address _addressLock, uint256 lockEndTime, uint256 amount);
    event LockClient(address _addressLock, uint256 lockEndTime, uint256 amount);

    /**
     * @dev Liq constructor
     */
    constructor() public ManagedToken(msg.sender, msg.sender) {
        name = "Liquiditex";
        symbol = "LEX";
        decimals = 18;
        totalIssue = 0;
        //The maximum number of tokens is unchanged and totals will decrease after issue
        totalSupply = 100000000 ether;
    }

    function issue(address _to, uint256 _value) external onlyOwner {
        totalIssue = safeAdd(totalIssue, _value);
        require(totalSupply >= totalIssue, "Total issue is not greater total of supply");

        balances[_to] = safeAdd(balances[_to], _value);
        //Call event
        emit Issue(_to, _value);
        emit Transfer(address(0), _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        if(clientLocks[msg.sender].isLock){
            require(_value <= safeSub(balances[msg.sender], clientLocks[msg.sender].amount), "Not enough token to transfer");
        }
        bool success = super.transfer(_to, _value);
        return success;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if(clientLocks[_from].isLock){
            require(_value <= safeSub(balances[_from], clientLocks[_from].amount), "Not enough token to transfer");
        }
        bool success = super.transferFrom(_from, _to, _value);
        return success;
    }

    /**
    * @dev Owner burn token with certain of amount
    * @param _value number of token will be burn of owner
    */
    function burn(uint256 _value) external onlyOwner returns (bool success) {
        require(balances[msg.sender] >= _value, "Not enough token to burn");                // Check if the sender has enough
		require(_value > 0, "Require burn token greater than 0");
        balances[msg.sender] = safeSub(balances[msg.sender], _value);                       // Subtract from the sender
        totalSupply = safeSub(totalSupply,_value);                                          // Updates totalSupply
        totalIssue = safeSub(totalIssue,_value);                                            // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
    * @dev Client freeze token with certain of amount and not allow unfreeze
    * @param _value number of token will be freeze of client
    */
    function freeze(uint256 _value) external returns (bool success) {
        require(balances[msg.sender] >= _value, "Not enough token to freeze");             // Check if the sender has enough
		require(_value > 0, "Require burn token greater than 0");
        balances[msg.sender] = safeSub(balances[msg.sender], _value);                      // Subtract from the sender
        freezeOf[msg.sender] = safeAdd(freezeOf[msg.sender], _value);                      // Updates totalSupply
        emit Freeze(msg.sender, _value);
        return true;
    }

    /**
    * @dev Owner lock token with for certain period of time and certain of amount
    * @param _lockTotal number of token lock
    * @param _totalDayLock number of day lock
    * @param name name of lock
    * @param id id of lock
    */
    function setLockInOwner(uint256 _lockTotal, uint256 _totalDayLock, string name, uint256 id) external onlyOwner {
        require(_totalDayLock >= 1, "Lock for at least one day");
        require(balances[msg.sender] >= _lockTotal, "Total lock is not greater total of owner");
        require(ownerLocks[id].amount == 0, "Lock with id is not existed");

        //set truct lock
        ownerLocks[id].amount = _lockTotal;
        ownerLocks[id].lockEndTime = _totalDayLock * 86400 + now;
        ownerLocks[id].name = name;
        ownerLocks[id].isLock = true;

        //set lock token of owner
        TotalLocked = safeAdd(TotalLocked, _lockTotal);
        balances[msg.sender] = safeSub(balances[msg.sender], _lockTotal);

        //Add id of lock in list LockIds
        LockIds.push(id);

        //Call event lock
        emit LockOwner(name, ownerLocks[id].lockEndTime, _lockTotal, id);
    }

    /**
    * @dev Owner unlock token with id of lock if lock is end
    * @param id id of lock
    */
    function unLockInOwner(uint256 id) external onlyOwner {
        //Lock with id is not unlock
        require(ownerLocks[id].isLock == true, "Lock with id is locking");
        require(now > ownerLocks[id].lockEndTime, "Please wait to until the end of lock previous");
        //unlock
        ownerLocks[id].isLock = false;

        //release token
        TotalLocked = safeSub(TotalLocked, ownerLocks[id].amount);
        balances[msg.sender] = safeAdd(balances[msg.sender], ownerLocks[id].amount);

        //Call event unlock
        emit UnLockOwner(name, ownerLocks[id].lockEndTime, ownerLocks[id].amount, id);
    }

    /**
    * @dev Owner transfer token to client and this token is lock in period of time
    * @param _value number of token transfer and is lock
    * @param _totalDayLock number of day lock
    * @param _to address received token
    */
    function transferLockFromOwner(address _to, uint256 _value, uint256 _totalDayLock) external onlyOwner returns (bool) {
        require(_totalDayLock >= 1, "Lock for at least one day");
        require(clientLocks[_to].isLock == false, "Account client has not lock token");
        bool success = super.transfer(_to, _value);
        if(success){
            clientLocks[_to].isLock = true;
            clientLocks[_to].amount = _value;
            clientLocks[_to].lockEndTime = _totalDayLock * 86400 + now;

            //Call event
            emit LockClient(_to, clientLocks[_to].lockEndTime, clientLocks[_to].amount);
        }

        return success;
    }

    /**
    * @dev Any address can confirm to unlock token of address if lock is expired
    * @param _addressLock address will be unlock token
    */
    function unLockTransferClient(address _addressLock) external {
        require(clientLocks[_addressLock].isLock == true, "Account client has lock token");
        require(now > clientLocks[_addressLock].lockEndTime, "Please wait to until the end of lock previous");

        //unlock
        clientLocks[_addressLock].isLock = false;

        //Call event
        emit UnLockClient(_addressLock, clientLocks[_addressLock].lockEndTime, clientLocks[_addressLock].amount);
    }

}
