// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import '../interfaces/AdministrateeInterface.sol';
import '../../../../../@openzeppelin/contracts/access/Ownable.sol';

contract FinancialContractsAdmin is Ownable {
  function callEmergencyShutdown(address financialContract) external onlyOwner {
    AdministrateeInterface administratee =
      AdministrateeInterface(financialContract);
    administratee.emergencyShutdown();
  }

  function callRemargin(address financialContract) external onlyOwner {
    AdministrateeInterface administratee =
      AdministrateeInterface(financialContract);
    administratee.remargin();
  }
}

