pragma solidity ^0.5.13;

contract ERC20Interface {
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    event Mint(address indexed to, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    function approve(address _spender, uint256 _amount) public returns (bool success);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _amount) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success);

    function decimals() public view returns (uint8);
    function name() public view returns (string memory);
    function symbol() public view returns (string memory);
    function totalSupply() public view returns (uint256);
}

