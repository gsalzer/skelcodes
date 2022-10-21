pragma solidity 0.5.12;

import "./IERC20.sol";
import "./SafeMath.sol";


contract LPTokenWrapper {
    using SafeMath for uint256;
    IERC20 public token;

    constructor(IERC20 _erc20Address) public {
        token = IERC20(_erc20Address);
    }

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        token.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        token.transfer(msg.sender, amount);
    }
}

