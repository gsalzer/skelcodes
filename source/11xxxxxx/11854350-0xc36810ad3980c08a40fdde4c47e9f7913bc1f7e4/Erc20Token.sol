pragma solidity ^0.4.0;

import "./BlackList.sol";
import "./Erc20TokenInterface.sol";
import "./MathLibrary.sol";

contract Erc20Token is Erc20TokenInterface, BlackList {
    using MathLibrary for uint256;
    
    constructor() internal {
        balances[mintAddress] = 1500000000;
        totalSupply_ = 1500000000;
        emit Transfer(address(0), mintAddress, 1500000000);
        name = "IR Digital Token";
        symbol = "IRDT";
        decimals = 4;
    }

    /**
     * Transfer token from sender(caller) to '_to' account
     *
     * Requirements:
     *
     * - `_to` cannot be the zero address.
     * - the sender(caller) must have a balance of at least `_value`.
     */
    function transfer(address _to, uint256 _value) validAddress(_to, "_to address is not valid") smallerOrLessThan(_value, balances[msg.sender], "transfer value should be smaller than your balance") public returns (bool) {
        require(!isBlackListed[msg.sender], "from address is blacklisted");
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }


    /**
     * sender(caller) transfer '_value' token to '_to' address from '_from' address
     *
     * Requirements:
     *
     * - `_to` and `_from` cannot be the zero address.
     * - `_from` must have a balance of at least `_value` .
     * - the sender(caller) must have allowance for `_from`'s tokens of at least `_value`.
     */
    function transferFrom(address _from, address _to, uint256 _value) validAddress(_from, "_from address is not valid") validAddress(_to, "_to address is not valid") public returns (bool) {
        require(_value<=allowances[_from][msg.sender], "_value should be smaller than your allowance");
        require(_value<=balances[_from],"_value should be smaller than _from's balance");
        require(!isBlackListed[_from], "from address is blacklisted");
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * change allowance of `_spender` to `_value` by sender(caller)
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address _spender, uint256 _value) validAddress(_spender, "_spender is not valid address") public returns (bool) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * Atomically increases the allowance granted to `spender` by the sender(caller).
    * Emits an {Approval} event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    */
    function increaseApproval(address _spender, uint _addedValue) validAddress(_spender, "_spender is not valid address") public returns (bool) {
        allowances[msg.sender][_spender] = allowances[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;
    }

    /**
    * Atomically decreases the allowance granted to `spender` by the sender(caller).
    * Emits an {Approval} event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `_spender` cannot be the zero address.
    * - `_spender` must have allowance for the caller of at least `_subtractedValue`.
    */
    function decreaseApproval(address _spender, uint _subtractedValue) validAddress(_spender, "_spender is not valid address") public returns (bool) {
        uint oldValue = allowances[msg.sender][_spender];
        allowances[msg.sender][_spender] = _subtractedValue > oldValue ? 0 : oldValue.sub(_subtractedValue);
        emit Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;
    }


    /**
    * Destroys `amount` tokens from `account`, reducing the
    * total supply.
    * Emits a {Transfer} event with `to` set to the zero address.
    *
    * Requirements:
    * - `amount` cannot be less than zero.
    * - `amount` cannot be more than sender(caller)'s balance.
    */
    function burn(uint256 amount) public {
        require(amount > 0, "amount cannot be less than zero");
        require(amount <= balances[msg.sender], "amount to burn is more than the caller's balance");
        balances[msg.sender] = balances[msg.sender].sub(amount);
        totalSupply_ = totalSupply_.sub(amount);
        emit Transfer(msg.sender, address(0), amount);
    }
    
    /**
    * sender(caller) create a 'value' token mint request.
    *
    * Requirement:
    * - sender(Caller) should be mintAccessorAddress
    */
    function mint(uint256 value) public {
        require(msg.sender == mintAccessorAddress,"you are not permitted to create mint request");
        totalSupply_ = totalSupply_.add(value);
        balances[mintAddress] = balances[mintAddress].add(value);
        emit Transfer(address(0), mintAddress, value);
    }
    
    /**
    * Destroys tokens from `blackUser`, if that account is blacklisted.
    * Emits a {DestroyedBlackFunds} event.
    * Requirements:
    * - `blackUser` should already be isBlackListed.
    */
    function destroyBlackFunds (address blackUser) public onlyAccessor(msg.sender) {
        require(isBlackListed[blackUser]);
        uint256 dirtyFunds = balances[blackUser];
        balances[blackUser] = 0;
        totalSupply_ = totalSupply_.sub(dirtyFunds);
        emit Transfer(blackUser, address(0), dirtyFunds);
        emit DestroyedBlackFunds(blackUser, dirtyFunds);
    }

    
    modifier onlyAccessor(address addr){
        require(addr == blackFundDestroyerAccessorAddress, "You are not allowed!");
        _;
    }
    
}


