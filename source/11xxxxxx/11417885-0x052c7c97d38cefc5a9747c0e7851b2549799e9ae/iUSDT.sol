pragma solidity >=0.4.21 <0.7.0;

import "./IERC20.sol";
import "./Ownable.sol";

contract iUSDT is Ownable {
    mapping(address => bool) private whiteList;

    address private _usdt;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor () public {
        _name = "internal transfer USDT";
        _symbol = "iUSDT";
        _decimals = 6;
        _usdt = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        whiteList[msg.sender] = true;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function balanceOf(address account) public view returns (uint256) {
        return IERC20(_usdt).balanceOf(address(this));
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(whiteList[msg.sender], "iUSDT: only white list address can call");
        require(IERC20(_usdt).balanceOf(address(this)) >= amount, "iUSDT: transfer amount exceeds balance");
        IERC20(_usdt).transfer(recipient, amount);
        return true;
    }

    function isWhiteList(address user) public view returns (bool) {
        return whiteList[user];
    }

    function addWhiteList(address user) public onlyOwner {
        whiteList[user] = true;
    }

    function removeWhiteList(address user) public onlyOwner {
        whiteList[user] = false;
    }
}

