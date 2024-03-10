pragma solidity 0.7.2;

// SPDX-License-Identifier: JPLv1.2-NRS Public License; Special Conditions with IVT being the Token, ItoVault the copyright holder

import "./SafeMath.sol";
import "./GeneralToken.sol";

contract DriverVaultSystemSpaceX {
    
    using SafeMath for uint256;
    
    GeneralToken public ivtToken;
    
    constructor() { 
        ivtToken = new GeneralToken(10 ** 30, msg.sender, "ItoVault Token V_1_0_0", "IVT V1_0");
    }
    
}
