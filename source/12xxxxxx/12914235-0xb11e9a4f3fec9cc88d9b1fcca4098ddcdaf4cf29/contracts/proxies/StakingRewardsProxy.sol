pragma solidity 0.5.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/upgrades/contracts/upgradeability/AdminUpgradeabilityProxy.sol";

contract StakingRewardsProxy is AdminUpgradeabilityProxy {
    constructor(address _logic, address _proxyAdmin)
        public
        AdminUpgradeabilityProxy(
            _logic,
            _proxyAdmin,
            ""
        )
    {}
}
