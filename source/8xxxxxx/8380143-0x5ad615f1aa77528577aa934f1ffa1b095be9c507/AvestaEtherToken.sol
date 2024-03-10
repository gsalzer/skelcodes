pragma solidity ^0.4.25;

/* 
 * @@ Title Avesta token @@
 */


contract Logging {
    // @@ Any events 
    //  Logged when new tokens are issued
    event Issue(uint amount,string note);
    // Logged when tokens are redeemed
    event Redeem(uint amount,string note);
    // Logged when fee new changed
    event Params(uint feeBasisPoints, uint maxFee); 

}

/**
 * @title ERC20Basic
 * Simpler version of ERC20 interface
 * https://github.com/ethereum/EIPs/issues/20
 */

contract ERC20Basic {
    uint public _totalSupply;
    function totalSupply() public constant returns (uint);
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
    event Approval(address indexed owner, address indexed spender, uint value);
}


/**
 * @title Ownable
 */
contract Ownable {
    address public owner;

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows current owner to transfer newOwner.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is Ownable, ERC20Basic {
    using SafeMath for uint;

    mapping(address => uint) public balances;

    // additional variables for use if transaction fees ever became necessary
    uint public basisPointsRate = 0;
    uint public maximumFee = 0;

    /**
    * @dev Fix for the ERC20 short address attack.
    */
    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }

    /**
    * @dev transfer token 
    * @param _to The address to transfer to 
    * @param _value The amount to be transferred
    */
    function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) {
        uint fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        uint sendAmount = _value.sub(fee);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee);
         emit   Transfer(msg.sender, owner, fee);
        }
        emit Transfer(msg.sender, _to, sendAmount);
    }

    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }

}

/**
 * @title Library for assert basic Math
 */

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Internal solidity throws when dividing by 0
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
}

contract StandardToken is BasicToken, ERC20 {

    mapping (address => mapping (address => uint)) public allowed;
    uint public constant MAX_UINT = 2**256 - 1;

    /**
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) {
        uint _allowance = allowed[_from][msg.sender];
        uint fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        if (_allowance < MAX_UINT) {
            allowed[_from][msg.sender] = _allowance.sub(_value);
        }
        uint sendAmount = _value.sub(fee);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee);
         emit   Transfer(_from, owner, fee);
        }
        emit Transfer(_from, _to, sendAmount);
    }

    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32) {
        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));
        allowed[msg.sender][_spender] = _value;
    emit    Approval(msg.sender, _spender, _value);
    }
    /*
     * @dev to allow a person to transfer tokens with limit amount    
     * 
    */
    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }
}

/**
 * @title Pausable 
 * @dev to pause next transfer  
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();
  bool public paused;
  constructor () public {
       paused = false;
  }

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
  emit  Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
   emit Unpause();
  }
}


contract BlackList is  Ownable, BasicToken   {
    
    uint public totalBlacklist  ; 
    constructor () public {
        totalBlacklist = 0 ;
    }

    /*
    * BlackList logging
    *
    */
    event DestroyEvilFunds(address _blackListedUser, uint _balance);
    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);
    
    function showBlackListStatus(address _maker) external constant returns (bool Result) {
        Result = isBlackListed[_maker] ;
    }

    function getOwner() external constant returns (address) {
        return owner;
    }

    mapping (address => bool) public isBlackListed;

    /*
     * EvilUser'all tokens  going to be ZERO !!
    */
    function destroyEvilFunds (address _blackListedUser) public onlyOwner {
        // to owner current owner's tokens use function redeem instead 
        require ( _blackListedUser != owner , "REJECT:B001 Not Allow  owner destroy self tokens"  ) ;
        require(isBlackListed[_blackListedUser]);
        uint dirtyFunds = balanceOf(_blackListedUser);
        balances[_blackListedUser] = 0;
        _totalSupply -= dirtyFunds;
    emit    DestroyEvilFunds(_blackListedUser, dirtyFunds);
    }
    
    function addBlackList (address _evilUserAddress) public onlyOwner {
        require (!isBlackListed[_evilUserAddress]  , "REJECT:B002 This address already is in Blacklist " ) ; 
        isBlackListed[_evilUserAddress] = true;
        totalBlacklist += 1 ; 
      emit  AddedBlackList(_evilUserAddress);
    }

    function removeBlackList (address _clearedUserAddress) public onlyOwner {
        require( isBlackListed[_clearedUserAddress] , "REJECT:B003 This address isn't Blacklist " );
        isBlackListed[_clearedUserAddress] = false;
         totalBlacklist -=  1 ; 
    emit    RemovedBlackList(_clearedUserAddress);
    }

}


contract AvestaEtherToken is Pausable, StandardToken, BlackList , Logging {
    string public name;
    string public symbol;
    uint public decimals;
    constructor (uint _initialSupply, string _name, string _symbol, uint _decimals) public {
        _totalSupply = _initialSupply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        balances[owner] = _initialSupply;
    }
    
    function transfer(address _to, uint _value) public whenNotPaused {
        require(!isBlackListed[msg.sender]);
            return super.transfer(_to, _value);
    }
    function transferFrom(address _from, address _to, uint _value) public whenNotPaused {
        require(!isBlackListed[_from]);
            return super.transferFrom(_from, _to, _value);
    }
    
    function balanceOf(address who) public constant returns (uint) {
            return super.balanceOf(who);
    }

    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32) {
 
            return super.approve(_spender, _value);
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
            return super.allowance(_owner, _spender);
    }

    // deprecate current contract if favour of a new one
    function totalSupply() public constant returns (uint) {
            return _totalSupply;
    }
    
    // @param _amount  issued additional to supply tokens  
    function issue(uint amount , string note ) public onlyOwner {
        require(_totalSupply + amount > _totalSupply);
        require(balances[owner] + amount > balances[owner]);
        assert( amount > 0 ) ;
        balances[owner] += amount;
        _totalSupply += amount;
     emit   Issue(amount,note );
    }

    // Redeem tokens to remove owner tokens out the system

    function redeem(uint amount,string note) public onlyOwner {
        require(_totalSupply >= amount);
        require(balances[owner] >= amount);
        _totalSupply -= amount;
        balances[owner] -= amount;
     emit   Redeem(amount,note);
    }

    function setParams(uint newBasisPoints, uint newMaxFee) public onlyOwner {
        // Fee of transfer chrage initial with zero 
        require(newBasisPoints < 30);
        require(newMaxFee < 60);
        basisPointsRate = newBasisPoints;
        maximumFee = newMaxFee.mul(10**decimals);
        emit   Params(basisPointsRate, maximumFee);
    }
    
    function showTokenInfo () public view returns ( string Name , string Symbol , address ContractAddress ,  uint TotalSupply , uint FeeRate , uint TotalBlacklist , bool PauseStatus ){
        //@dev get current Infomation
        Name = name ;
        Symbol = symbol ;
        ContractAddress = address(this) ;
        TotalSupply =  totalSupply();
        TotalBlacklist = totalBlacklist ;
        // Show pause status
         PauseStatus = paused ;
        // Show total supply 
        FeeRate = basisPointsRate ;
  
    }
 
}
