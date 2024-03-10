pragma solidity ^0.4.24;

contract AuthModule {

    address primaryAdmin;
    address primaryIssuer;
    address primaryExchange;

    event JobshipTransferred(
        string  strType,
        address indexed previousOwner,
        address indexed newOwner,
        address indexed caller
      );

    constructor(
        address _admin, 
        address _issuer, 
        address _exchange
    ) 
        public 
    {
        primaryAdmin = _admin;
        primaryIssuer = _issuer;
        primaryExchange = _exchange;
    }

    function isAdmin(address _admin) public view returns (bool) {
        return primaryAdmin == _admin;
    }

    function isIssuer(address _issuer) public view returns (bool) {
        return primaryIssuer == _issuer;
    }

    function isExchange(address _exchange) public view returns (bool) {
        return primaryExchange == _exchange;
    }

    function transferIssuer(address _addr) public returns (bool) {
        require (_addr != address(0) && _addr != primaryIssuer, "_addr invalid");
        require (isIssuer(msg.sender) || isAdmin(msg.sender), "only issuer or admin");

        emit JobshipTransferred("issuer", primaryIssuer, _addr, msg.sender);
        primaryIssuer = _addr;
        return true;
    }

    function transferExchange(address _addr) public returns(bool) {
        require (_addr != address(0) && _addr != primaryExchange, "_addr invalid");
        require (isExchange(msg.sender) || isAdmin(msg.sender), "only exchange or admin");

        emit JobshipTransferred("exchange", primaryExchange, _addr, msg.sender);
        primaryExchange = _addr;
        return true;
    }
}
