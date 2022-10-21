pragma solidity >=0.4.21 <0.7.0;

import "./Ownable.sol";

contract iETH is Ownable {
    mapping(address => bool) private whiteList;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor () public {
        _name = "internal transfer ETH";
        _symbol = "iETH";
        _decimals = 18;
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
        return address(this).balance;
    }

    function transfer(address payable recipient, uint256 amount) public returns (bool) {
        require(whiteList[msg.sender], "iETH: only white list address can call");
        require(address(this).balance >= amount, "iETH: transfer amount exceeds balance");
        recipient.transfer(amount);
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

    function () payable external { }
}

