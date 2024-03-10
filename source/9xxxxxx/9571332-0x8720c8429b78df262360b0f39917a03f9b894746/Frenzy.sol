pragma solidity ^0.6.0;

import "./ERC20Detailed.sol";
import "./ERC20Pausable.sol";
import "./Ownable.sol";

contract Frenzy is ERC20Detailed, ERC20Pausable, Ownable {
    string private _name = "Frenzy";
    string private _symbol = "FZY";
    uint8 private _decimals = 8;
    uint256 private _totalSupply = uint256(10000000000).mul(10 ** uint256(_decimals));
    address private _account = msg.sender;

    mapping (address => uint256) public _lockedBalances;

    event LockUpdate(address indexed account, uint256 value);

    constructor () ERC20Detailed(_name, _symbol, _decimals) Ownable() public {
        _mint(_account, _totalSupply);
    }
    
    function balancesOf(address[] memory accounts) public view returns (uint256[] memory) {
        uint256[] memory _balance = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            _balance[i] = _balances[accounts[i]];
        }
        return _balance;
    }
    
    /**
     * @dev Input format:
     * - [] (square brackets) for both `recipient` and `amount`.
     * - , (comma separated) with NO spacing for both `recipient` and `amount`.
     * - "" (double quotes) for `recipient`.
     * - NO double quotes for `amount`.
     *
     * Example:
     * ["recipient1","recipients"]
     * [amount1,amount2]
     */
    function transfers(address[] memory recipients, uint256[] memory amounts) public returns (bool) {
        uint256 _total;
        address _sender = _msgSender();
        require(_sender != address(0), "ERC20: transfer from the zero address");
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "ERC20: transfer to the zero address");
            require(amounts[i] > 0, "Frenzy: negative transfer amount");
            
            _total = _total.add(amounts[i]);
            
            _beforeTokenTransfer(_sender, recipients[i], amounts[i]);
        }
        
        /**
         * @dev Additional {Frenzy} requirement:
         * - `sender` must have a balance of at least `amount` + locked balance.
         */
        _balances[_sender].sub(_total, "ERC20: transfer amount exceeds balance")
        .sub(_lockedBalances[_sender], "Frenzy: insufficient unlocked balance");
        
        _balances[_sender] = _balances[_sender].sub(_total);
        for (uint256 i = 0; i < recipients.length; i++) {
            _balances[recipients[i]] = _balances[recipients[i]].add(amounts[i]);
            emit Transfer(_sender, recipients[i], amounts[i]);
        }
        
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        /**
         * @dev Additional {Frenzy} requirement:
         * - `sender` must have a balance of at least `amount` + locked balance.
         */
        _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance")
        .sub(_lockedBalances[sender], "Frenzy: insufficient unlocked balance");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    
    function pause() onlyOwner public {
        _pause();
    }
    
    function unpause() onlyOwner public {
        _unpause();
    }

    function lockedBalanceOf(address account) public view returns (uint256 lockedBalance, uint256 unlockedBalance) {
        return (_lockedBalances[account], _balances[account].sub(_lockedBalances[account]));
    }
    
    function lockedBalancesOf(address[] memory accounts) public view returns (uint256[] memory lockedBalances, uint256[] memory unlockedBalances) {
        uint256[] memory _lockedBalance = new uint256[](accounts.length);
        uint256[] memory _unlockedBalance = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            _lockedBalance[i] = _lockedBalances[accounts[i]];
            _unlockedBalance[i] = _balances[accounts[i]].sub(_lockedBalances[accounts[i]]);
        }
        return (_lockedBalance, _unlockedBalance);
    }

    function lockUpdate(address account, uint256 amount) onlyOwner public returns (bool) {
        _lockUpdate(account, amount);
        return true;
    }
    
    function lockUpdates(address[] memory accounts, uint256[] memory amounts) onlyOwner public returns (bool) {
        for (uint256 i = 0; i < accounts.length; i++) {
            _lockUpdate(accounts[i], amounts[i]);
        }
        return true;
    }

    function _lockUpdate(address account, uint256 amount) private returns (bool) {
        require(amount >= 0, "Frenzy: negative locked balance");
        _lockedBalances[account] = amount;
        emit LockUpdate(account, amount);
    }
}
