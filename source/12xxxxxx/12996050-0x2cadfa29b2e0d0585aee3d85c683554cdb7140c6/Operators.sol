pragma solidity ^0.5.0;

contract Operators {

    mapping(address => bool) ownerAddress;
    mapping(address => bool) operatorAddress;

    constructor() public {
        ownerAddress[msg.sender] = true;
    }

    modifier onlyOwner() {
        require(ownerAddress[msg.sender], "Access denied");
        _;
    }

    function isOwner(address _addr) public view returns (bool) {
        return ownerAddress[_addr];
    }

    function addOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Owner cannot be zero");

        ownerAddress[_newOwner] = true;
    }

    function removeOwner(address _oldOwner) external onlyOwner {
        delete(ownerAddress[_oldOwner]);
    }

    modifier onlyOperator() {
        require(isOperator(msg.sender), "Access denied");
        _;
    }

    function isOperator(address _addr) public view returns (bool) {
        return operatorAddress[_addr] || ownerAddress[_addr];
    }

    function addOperator(address _newOperator) external onlyOwner {
        require(_newOperator != address(0), "Operator cannot be zero");

        operatorAddress[_newOperator] = true;
    }

    function removeOperator(address _oldOperator) external onlyOwner {
        delete(operatorAddress[_oldOperator]);
    }
}

