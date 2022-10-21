pragma solidity >=0.4.22 <0.6.0;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}





/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) public _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply =  0;
    
    
    

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer token to a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }
 
 
    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));
        require(value <= _balances[account]);
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }


    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    

}




/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}



contract OlaCoin is ERC20, Ownable, ERC20Detailed {
    
	address teamWallet = 0x86bD0BF7dfbc76289e5ffA54cC2510C98010227B;
    address serviceWallet = 0x30e6C204a8851fa6588Baa6563C5293A9c47d735;
    address partnerWallet = 0x693d5b141F6a4dc06e85F36dde4f7bdf6Cb83D0B;
    address bountyWallet = 0x1807505942C9fA6A628367E309472A1Abc021634;
        
    struct LockItem {
        uint256  releaseDate;
        uint256  amount;
    }
    
    mapping (address => LockItem[]) public lockList;
    mapping (uint => uint) public quarterMap;
    
	constructor() public ERC20Detailed("Ola Coin", "OLA", 6) {  
	        
        quarterMap[1]=1609459200;//=Fri, 01 Jan 2021 00:00:00 GMT
        quarterMap[2]=1617235200;//=Thu, 01 Apr 2021 00:00:00 GMT
        quarterMap[3]=1625097600;//=Thu, 01 Jul 2021 00:00:00 GMT
        quarterMap[4]=1633046400;//=Fri, 01 Oct 2021 00:00:00 GMT
        quarterMap[5]=1640995200;//=Sat, 01 Jan 2022 00:00:00 GMT
        quarterMap[6]=1648771200;//=Fri, 01 Apr 2022 00:00:00 GMT
        quarterMap[7]=1656633600;//=Fri, 01 Jul 2022 00:00:00 GMT
        quarterMap[8]=1664582400;//=Sat, 01 Oct 2022 00:00:00 GMT
        quarterMap[9]=1672531200;//=Sun, 01 Jan 2023 00:00:00 GMT
        quarterMap[10]=1680307200;//=Sat, 01 Apr 2023 00:00:00 GMT
        quarterMap[11]=1688169600;//=Sat, 01 Jul 2023 00:00:00 GMT
        quarterMap[12]=1696118400;//=Sun, 01 Oct 2023 00:00:00 GMT
        quarterMap[13]=1704067200;//=Mon, 01 Jan 2024 00:00:00 GMT
        quarterMap[14]=1711929600;//=Mon, 01 Apr 2024 00:00:00 GMT
        quarterMap[15]=1719792000;//=Mon, 01 Jul 2024 00:00:00 GMT
        quarterMap[16]=1727740800;//=Tue, 01 Oct 2024 00:00:00 GMT
        quarterMap[17]=1735689600;//=Wed, 01 Jan 2025 00:00:00 GMT
        quarterMap[18]=1743465600;//=Tue, 01 Apr 2025 00:00:00 GMT
        quarterMap[19]=1751328000;//=Tue, 01 Jul 2025 00:00:00 GMT
        quarterMap[20]=1759276800;//=Wed, 01 Oct 2025 00:00:00 GMT
        quarterMap[21]=1767225600;//=Thu, 01 Jan 2026 00:00:00 GMT
        quarterMap[22]=1775001600;//=Wed, 01 Apr 2026 00:00:00 GMT
        quarterMap[23]=1782864000;//=Wed, 01 Jul 2026 00:00:00 GMT
        quarterMap[24]=1790812800;//=Thu, 01 Oct 2026 00:00:00 GMT
        quarterMap[25]=1798761600;//=Fri, 01 Jan 2027 00:00:00 GMT
        quarterMap[26]=1806537600;//=Thu, 01 Apr 2027 00:00:00 GMT
        quarterMap[27]=1814400000;//=Thu, 01 Jul 2027 00:00:00 GMT
        quarterMap[28]=1822348800;//=Fri, 01 Oct 2027 00:00:00 GMT
        quarterMap[29]=1830297600;//=Sat, 01 Jan 2028 00:00:00 GMT
        quarterMap[30]=1838160000;//=Sat, 01 Apr 2028 00:00:00 GMT
        quarterMap[31]=1846022400;//=Sat, 01 Jul 2028 00:00:00 GMT
        quarterMap[32]=1853971200;//=Sun, 01 Oct 2028 00:00:00 GMT
        quarterMap[33]=1861920000;//=Mon, 01 Jan 2029 00:00:00 GMT
        quarterMap[34]=1869696000;//=Sun, 01 Apr 2029 00:00:00 GMT
        quarterMap[35]=1877558400;//=Sun, 01 Jul 2029 00:00:00 GMT
        quarterMap[36]=1885507200;//=Mon, 01 Oct 2029 00:00:00 GMT
        quarterMap[37]=1893456000;//=Tue, 01 Jan 2030 00:00:00 GMT
        quarterMap[38]=1901232000;//=Mon, 01 Apr 2030 00:00:00 GMT
        quarterMap[39]=1909094400;//=Mon, 01 Jul 2030 00:00:00 GMT
        
        _mint(owner(), 100000000000000000); // total supply fixed at 100 billion coins
        
        ERC20.transfer(teamWallet, 9000000000000000);
        ERC20.transfer(partnerWallet, 9000000000000000);
        ERC20.transfer(serviceWallet, 2000000000000000);
        ERC20.transfer(bountyWallet, 2000000000000000);

        for(uint i = 1; i<= 39;i++) {
            transferAndLock(serviceWallet,   2000000000000000 , quarterMap[i]);
        }
        
    }
	
	
     /**
     * @dev transfer of token to another address.
     * always require the sender has enough balance
     * @return the bool true if success. 
     * @param _receiver The address to transfer to.
     * @param _amount The amount to be transferred.
     */
     
	function transfer(address _receiver, uint256 _amount) public returns (bool success) {
	    require(_receiver != address(0)); 
	    require(_amount <= getAvailableBalance(msg.sender));
        return ERC20.transfer(_receiver, _amount);
	}
	
	/**
     * @dev transfer of token on behalf of the owner to another address. 
     * always require the owner has enough balance and the sender is allowed to transfer the given amount
     * @return the bool true if success. 
     * @param _from The address to transfer from.
     * @param _receiver The address to transfer to.
     * @param _amount The amount to be transferred.
     */
    function transferFrom(address _from, address _receiver, uint256 _amount) public returns (bool) {
        require(_from != address(0));
        require(_receiver != address(0));
        require(_amount <= allowance(_from, msg.sender));
        require(_amount <= getAvailableBalance(_from));
        return ERC20.transferFrom(_from, _receiver, _amount);
    }

    /**
     * @dev transfer to a given address a given amount and lock this fund until a given time
     * used for sending fund to team members, partners, or for owner to lock service fund over time
     * @return the bool true if success.
     * @param _receiver The address to transfer to.
     * @param _amount The amount to transfer.
     * @param _releaseDate The date to release token.
     */
	
	function transferAndLock(address _receiver, uint256 _amount, uint256 _releaseDate) public returns (bool success) {
	    require(msg.sender == teamWallet || msg.sender == partnerWallet || msg.sender == owner());
        ERC20._transfer(msg.sender,_receiver,_amount);
    	LockItem memory item = LockItem({amount:_amount, releaseDate:_releaseDate});
		lockList[_receiver].push(item);
        return true;
	}
	
	
    /**
     * @return the total amount of locked funds of a given address.
     * @param lockedAddress The address to check.
     */
	function getLockedAmount(address lockedAddress) public view returns(uint256 _amount) {
	    uint256 lockedAmount =0;
	    for(uint256 j = 0; j<lockList[lockedAddress].length; j++) {
	        if(now < lockList[lockedAddress][j].releaseDate) {
	            uint256 temp = lockList[lockedAddress][j].amount;
	            lockedAmount += temp;
	        }
	    }
	    return lockedAmount;
	}
	
	/**
     * @return the total amount of locked funds of a given address.
     * @param lockedAddress The address to check.
     */
	function getAvailableBalance(address lockedAddress) public view returns(uint256 _amount) {
	    uint256 bal = balanceOf(lockedAddress);
	    uint256 locked = getLockedAmount(lockedAddress);
	    return bal.sub(locked);
	}
    
    /**
     * @dev function that burns an amount of the token of a given account.
     * @param _amount The amount that will be burnt.
     */
    function burn(uint256 _amount) public {
        _burn(msg.sender, _amount);
    }
    
    function () payable external {   
        revert();
    }
}
