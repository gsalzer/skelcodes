// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "./ICertification.sol";
import "./IElections.sol";
import "./ManagedContract.sol";

contract Certification is ICertification, ManagedContract {
    mapping(address => bool) guardianCertification;

    constructor(IContractRegistry _contractRegistry, address _registryAdmin) ManagedContract(_contractRegistry, _registryAdmin) public {}

    /*
     * External functions
     */

    function isGuardianCertified(address guardian) external override view returns (bool isCertified) {
        return guardianCertification[guardian];
    }

    function setGuardianCertification(address guardian, bool isCertified) external override onlyFunctionalManager onlyWhenActive {
        guardianCertification[guardian] = isCertified;
        emit GuardianCertificationUpdate(guardian, isCertified);
        electionsContract.guardianCertificationChanged(guardian, isCertified);
    }

    /*
     * Contracts topology / registry interface
     */

    IElections electionsContract;
    function refreshContracts() external override {
        electionsContract = IElections(getElectionsContract());
    }
}

