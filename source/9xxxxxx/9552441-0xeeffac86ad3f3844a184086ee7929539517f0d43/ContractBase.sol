pragma solidity ^0.4.24;
import "./Proxy.sol";

contract ContractBase {
    
    Proxy proxy;

    constructor(address _proxy) public {
        proxy = Proxy(_proxy);
    }
    
}
