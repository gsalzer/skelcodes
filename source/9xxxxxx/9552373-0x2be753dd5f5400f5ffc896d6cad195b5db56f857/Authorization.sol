pragma solidity ^0.4.24;
import "ContractBase.sol";
import "Pausable.sol";
import "AuthModule.sol";

contract Authorization is ContractBase, Pausable{
    
    constructor(address _proxy) public ContractBase(_proxy) {

    }

    modifier onlyInside(address _sender) {
        require(proxy.isInsideContract(_sender), "Can only be called inside");
        _;
    }

    modifier onlyIssuer(address _sender) {
        AuthModule auth = AuthModule(proxy.getModule("AuthModule"));
        require(auth.isIssuer(_sender), "Need to be issuer");
        _;
    }

    modifier onlyAdmin(address _sender) {
        AuthModule auth = AuthModule(proxy.getModule("AuthModule"));
        require(auth.isAdmin(_sender), "Need to be admin");
        _;
    }

    modifier onlyExchange(address _sender) {
        AuthModule auth = AuthModule(proxy.getModule("AuthModule"));
        require(auth.isExchange(_sender), "Need to be exchange");
        _;
    }

    modifier onlyIssuerOrExchange(address _sender) {
        AuthModule auth = AuthModule(proxy.getModule("AuthModule"));
        require(auth.isIssuer(_sender) || auth.isExchange(_sender), "Need to be issuer or exchange");
        _;
    }

    modifier onlyTokenModule(address _sender) {
        require(_sender == proxy.getModule("TokenModule"), "Need to be tokenModule");
        _;
    }

    function unpause() public onlyAdmin(msg.sender)  {
        _unpause();
    }

    function pause() public onlyAdmin(msg.sender) {
        _pause();
    }

}
