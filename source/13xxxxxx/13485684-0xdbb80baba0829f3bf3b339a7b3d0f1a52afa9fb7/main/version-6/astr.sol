// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./common/Address.sol";
import "./common/SafeMath.sol";
import "./common/Initializable.sol";
import "./upgrade/ERC20BurnableUpgradeSafe.sol";
import "./interface/ITransferHandler.sol";

contract Token is ERC20BurnableUpgradeSafe {
    
    address public allocationContract;

    function initialize(address _allocationContract) external initializer {
        Ownable.init(_allocationContract);
        __ERC20_init("Astra", "ASTRA");
        
        allocationContract = _allocationContract;
        
        _mint(allocationContract, 1000000000 * uint256(10)**decimals());
    }
}

