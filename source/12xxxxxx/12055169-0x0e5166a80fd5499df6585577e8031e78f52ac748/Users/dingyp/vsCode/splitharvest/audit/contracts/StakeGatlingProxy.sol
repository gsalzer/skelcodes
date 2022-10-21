pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/MasterCaller.sol";
import "./utils/ERC1967Proxy.sol";
import "./storage/GatlingStorage.sol";



contract StakeGatlingProxy is GatlingStorage, Ownable, MasterCaller, ERC1967Proxy {

    constructor (address _pair, address _delegate) ERC1967Proxy(_delegate, '')  public {
        stakeLpPair = _pair;
        createAt = now;
    }
}
