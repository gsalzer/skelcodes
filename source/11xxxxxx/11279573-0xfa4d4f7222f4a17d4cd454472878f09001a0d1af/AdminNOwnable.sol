pragma solidity 0.5.0;

import "./Ownable.sol";

contract AdminNOwnable is Ownable {
    address private _admin;
    address private _operator;

    modifier onlyOwnerOrAdmin() {
        require(msg.sender != address(0) && (msg.sender == owner() || msg.sender == admin()),"onlyOwnerOrAdmin:");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender != address(0) && (msg.sender == operator()),"onlyOperator:");
        _;
    } 

    function setAdmin(address newAdmin)  public onlyOwner {
        require(newAdmin != address(0), "setAdmin: newAdmin is the zero address");
        require(admin() != newAdmin,"setAdmin: newAdmin is same admin");
        require(owner() != newAdmin,"setAdmin: newAdmin is same owner");
        _admin = newAdmin;
    }

    function admin() public view returns (address) {
        return _admin;
    }

    function setOperator(address newOperator)  public onlyOwnerOrAdmin {
        require(newOperator != address(0) && _operator != newOperator , "newOperator: newOperator is the zero address or _operator ");
        require(_admin != newOperator,"newOperator: newOperator is same admin");
        require(owner() != newOperator,"newOperator: newOperator is same owner");
        _operator = newOperator;
    }

    function operator() public view returns (address) {
        return _operator;
    }

}
