// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

import "./PusdPool.sol";

contract Pool_USDC is PusdPool {
    address public USDC_address;
    constructor(
        address _pusd_contract_address,
        address _pegs_contract_address,
        address _collateral_address,
        address _creator_address,
        address _timelock_address,
        uint256 _pool_ceiling
    ) 
    PusdPool(_pusd_contract_address, _pegs_contract_address, _collateral_address, _creator_address, _timelock_address, _pool_ceiling)
    public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        USDC_address = _collateral_address;
    }
}

