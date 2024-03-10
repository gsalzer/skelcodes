pragma solidity ^0.4.0;


contract Erc20TokenInterface {
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowances;
    uint256 internal totalSupply_;
    string public name;
    string public symbol;
    uint8 public decimals;

    modifier smallerOrLessThan(uint256 _value1, uint256 _value2, string errorMessage) {
        require(_value1 <= _value2, errorMessage);
        _;
    }

    modifier validAddress(address _address, string errorMessage) {
        require(_address != address(0), errorMessage);
        _;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }

    function transfer(address to, uint256 value) public returns (bool);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    function increaseApproval(address _spender, uint _addedValue) public returns (bool);

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);

}

