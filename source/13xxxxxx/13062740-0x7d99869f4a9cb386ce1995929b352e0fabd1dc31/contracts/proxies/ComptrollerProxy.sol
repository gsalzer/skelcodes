pragma solidity 0.7.3;

import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";

contract ComptrollerProxy is TransparentUpgradeableProxy {
    constructor(address _logic, address _proxyAdmin) public TransparentUpgradeableProxy(_logic, _proxyAdmin, "") {}
}

