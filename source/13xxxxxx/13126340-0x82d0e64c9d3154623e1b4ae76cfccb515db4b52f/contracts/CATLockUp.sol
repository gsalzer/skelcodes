pragma solidity ^0.5.16;

import "openzeppelin-solidity/contracts/math/Math.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";

contract CATLockUp is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public lockToken;
    uint256 public periodFinish;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(address _lockToken, uint256 _lockDuration) public {
        lockToken = IERC20(_lockToken);
        periodFinish = block.timestamp.add(_lockDuration);
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lock(uint256 amount) external nonReentrant {
        require(amount > 0, "LOCK_AMOUNT_ZERO");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        lockToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Locked(msg.sender, amount);
    }

    function unlock(uint256 amount) public nonReentrant {
        require(periodFinish < block.timestamp, "LOCKUP_PERIOD_NOT_FINISH");
        require(amount > 0, "UNLOCK_AMOUNT_ZERO");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        lockToken.safeTransfer(msg.sender, amount);
        emit UnLocked(msg.sender, amount);
    }

    event Locked(address indexed user, uint256 amount);
    event UnLocked(address indexed user, uint256 amount);
}
