pragma solidity 0.5.14;

/**
 * @title SafeMath 
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath {
    /**
     * @dev Multiplie two unsigned integers, revert on overflow.
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
     * @dev Integer division of two unsigned integers truncating the quotient, revert on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtract two unsigned integers, revert on underflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Add two unsigned integers, revert on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}

/**
 * @title ERC20 interface
 * @dev See https://eips.ethereum.org/EIPS/eip-20
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
 * @title Standard ERC20 token
 * @dev Implementation of the basic standard token.
 */
contract StandardToken is IERC20, Context {
    using SafeMath for uint256; 
    
    mapping (address => uint256) internal _balances; 
    mapping (address => mapping (address => uint256)) internal _allowed; 
    
    uint256 internal _totalSupply; 
    
    /**
     * @dev Total number of tokens in existence.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply; 
    }

    /**
     * @dev Get the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view  returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(_msgSender(), to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(_msgSender(), spender, value); 
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value); 
        _approve(from, _msgSender(), _allowed[from][_msgSender()].sub(value)); 
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowed[_msgSender()][spender].add(addedValue)); 
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowed[_msgSender()][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Transfer tokens for a specified address.
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), "Cannot transfer to the zero address"); 
        _balances[from] = _balances[from].sub(value); 
        _balances[to] = _balances[to].add(value); 
        emit Transfer(from, to, value); 
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0), "Cannot approve to the zero address"); 
        require(owner != address(0), "Setter cannot be the zero address"); 
	    _allowed[owner][spender] = value;
        emit Approval(owner, spender, value); 
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowed[account][_msgSender()].sub(amount));
    }

}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        return _msgSender() == _owner;
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

contract WTIToken is StandardToken, Ownable {
    string public constant name = "West Texas Intermediate";
    string public constant symbol = "WTI";
    uint8 public constant decimals = 18;

    uint256 internal constant INITIAL_SUPPLY = 16170000 * (10 ** uint256(decimals));
    uint256 internal constant MAX_POSREWARDS = 4830000 * (10 ** uint256(decimals));
    uint256 public rewarded;
    address private constant tokenWallet = 0xAE39690565914cD295405f12Da02b31701246362;
    address private constant banWallet = 0x6cC5F688a315f3dC28A7781717a9A798a59fDA7b;
    struct coinInfo{
        uint256 amount;
        uint256 time;
    }
    
    mapping(address => coinInfo[]) internal coinInfos;
    mapping(address => uint256) internal userIndex;
    mapping(address => bool) public ban;
    event Reward(address receipt, uint256 _value);
    /**
     * @dev Constructor, initialize the basic information of contract.
     */
    constructor() public {
        _totalSupply = INITIAL_SUPPLY;
        _balances[tokenWallet] = _totalSupply;
        emit Transfer(address(0), tokenWallet, INITIAL_SUPPLY);
        _owner = tokenWallet;
        ban[_owner] = true;
        ban[banWallet] = true;
        emit OwnershipTransferred(address(0), tokenWallet);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        if( _msgSender() == _to) {
            _checkAndRewarding(_msgSender());
            return true;
        }
        super.transfer(_to, _value);
        _updateCoinage(_msgSender(), _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_from != _to);
        super.transferFrom(_from, _to, _value);
        _updateCoinage(_from, _to, _value);
        return true;
    }

    function burn(uint256 amount) public onlyOwner {
        _burn(_msgSender(), amount);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != _owner);
        require(queryReward(newOwner) == 0, "Please claim rewarding of newOnwer before transferOwnership!");
        super.transferOwnership(newOwner);
        ban[_msgSender()] = false;
        ban[newOwner] = true;
        transfer(newOwner, _balances[_msgSender()]);
    }

    function _updateCoinage(address _from, address _to, uint256 _value) internal {
        if (rewarded < MAX_POSREWARDS) {
            if (ban[_from] == false) {
                if (coinInfos[_from].length > 0) {
                    delete coinInfos[_from];
                }
                if( _balances[_from] != 0){
                    coinInfos[_from].push(coinInfo(_balances[_from], now));
                }
            }
            if (ban[_to] == false && _value != 0) {
                coinInfos[_to].push(coinInfo(_value, now));
            }
            if (ban[_to] == true && coinInfos[_to].length > 0) {
                delete coinInfos[_to];
            }
        }
    }

    function _checkAndRewarding(address _from) internal {
        if (rewarded >= MAX_POSREWARDS || ban[_from] == true) {
            return;
        }
        uint256 reward = 0;
        uint256 settled = 0;
        uint256 index = userIndex[_from];
        uint256 _length = coinInfos[_from].length.sub(index);
        if  (_length > 250) {
            (settled, reward) = segmentCliamReward(_from, 250);
        } else {
            (settled, reward) = segmentCliamReward(_from, _length);
            if (coinInfos[_from].length > 0) {
                delete coinInfos[_from];
                userIndex[_from] = 0;
            }
            settled = _balances[_from];
        }
        if (settled > 0 && reward > 0) {
            rewarded = rewarded.add(reward);
            _totalSupply = _totalSupply.add(reward);
            _balances[_from] = _balances[_from].add(reward);
            coinInfos[_from].push(coinInfo(settled.add(reward), now));
            emit Transfer(address(0), _from, reward);
            emit Reward(_from, reward);
        }
    }
    
    function getCoinInfo(address _user, uint256 _index) public view returns (uint256 _amount, uint256 _coinAge) {
        _amount = coinInfos[_user][_index].amount;
        _coinAge = now.sub(coinInfos[_user][_index].time).div(86400);
    }

    function queryReward(address receipt) view public returns (uint256 totalReward) {
        if (rewarded >= MAX_POSREWARDS) {
            return 0;
        }
        if (ban[receipt] == true) {
            return 0;
        }
        uint256 _length = coinInfos[receipt].length;
        for (uint256 i = userIndex[receipt]; i < _length; i++) {
            (uint256 amount, uint256 coinAge) = getCoinInfo(receipt, i);
            uint256 cycle = coinAge.div(30);
            if (cycle > 0) {
                uint256 reward = amount.div(100).mul(cycle);
                if (rewarded.add(totalReward).add(reward) > MAX_POSREWARDS) {
                    uint256 remain = MAX_POSREWARDS.sub(rewarded.add(totalReward));
                    totalReward = totalReward.add(remain);
                    break;
                } else {
                    totalReward = totalReward.add(reward);
                }
             } else{
                 break;
             }
        }
    }

    function segmentCliamReward(address _user, uint256 _length) internal returns (uint256 settledAmount, uint256 totalReward) {
        uint256 index = userIndex[_user];
        for (uint256 i = index; i < index.add(_length); i++) {
            (uint256 amount, uint256 coinAge) = getCoinInfo(_user, i);
            if (amount == 0) {
                continue;
            }
            uint256 cycle = coinAge.div(30);
            if (cycle > 0) {
                uint256 reward = amount.div(100).mul(cycle);
                if (rewarded.add(totalReward).add(reward) > MAX_POSREWARDS) {
                    uint256 remain = MAX_POSREWARDS.sub(rewarded.add(totalReward));
                    totalReward = totalReward.add(remain);
                    delete coinInfos[_user];
                    userIndex[_user] = 0;
                    settledAmount = _balances[_user];
                    return (settledAmount, totalReward);
                } else {
                    delete coinInfos[_user][i];
                    totalReward = totalReward.add(reward);
                    settledAmount = settledAmount.add(amount);
                }
             } else{
                 delete coinInfos[_user];
                 userIndex[_user] = 0;
                 settledAmount = _balances[_user];
                 return (settledAmount, totalReward);
             }
        }
        userIndex[_user] = userIndex[_user].add(_length);
    }

}
