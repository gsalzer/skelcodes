pragma solidity ^0.5.0;

import "./Ownable.sol";
import "./Math.sol";
import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./LockAmount.sol";

contract BlaaToken is ERC20, ERC20Detailed, LockAmount {
    using Math for uint256;

    uint256 private _maxSupply;
    
    constructor(string memory name, string memory symbol, uint8 decimals, uint256 maximumSupply) public ERC20Detailed(name, symbol, decimals) {
        _maxSupply = maximumSupply * (10 ** uint256(decimals));
    }
    
    /**
     * @dev 최대 공급량
     */
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }
    
    /**
     * @dev 사용가능 잔액조회
     */
    function availableBalanceOf(address account) public view returns (uint256) {
        require(account != address(0), "BlaaToken: address is the zero address");

        uint256 lockedAmount = getLockedAmountOfLockTable(account);
        
        // 현재 잔액 락금액을 뺌, 락금액이 더 큰 경우 0
        if (_balances[account] < lockedAmount) return 0;
        
        return _balances[account].sub(lockedAmount);
    }
    
    /**
     * @dev ADMIN 발행
     */
    function mint(address account, uint256 amount) onlyOwner public returns (bool) { 
        require(_totalSupply.add(amount) <= _maxSupply, "BlaaToken: Issued exceeds maximum supply");
        
        _mint(account, amount);
        return true;
    }
    
    /**
     * @dev ADMIN 소각
     */
    function burn(uint256 amount) onlyOwner public returns (bool){
        require(_balances[_msgSender()] >= amount, "BlaaToken: destruction amount exceeds balance");
        
        _burn(_msgSender(), amount);
        return true;
    }

    /**
     * @dev ERC20 _transfer() 재정의
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BlaaToken: transfer from the zero address");
        require(recipient != address(0), "BlaaToken: transfer to the zero address");
        
        uint256 lockedAmount = getLockedAmountOfLockTable(sender);
        require(_balances[sender].sub(amount) >= lockedAmount, "BlaaToken: exceeded amount available");

        _balances[sender] = _balances[sender].sub(amount, "BlaaToken: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    
    /**
     * @dev 락금액조회
     */
    function getLockedAmount(address account) public view returns (uint256) {
        require(account != address(0), "BlaaToken: address is the zero address");

        uint256 lockedAmount = getLockedAmountOfLockTable(account);

        // 락금액과 현재 잔액을 비교하여 작은 값을 출력
        return Math.min(lockedAmount, _balances[account]);
    }
}

