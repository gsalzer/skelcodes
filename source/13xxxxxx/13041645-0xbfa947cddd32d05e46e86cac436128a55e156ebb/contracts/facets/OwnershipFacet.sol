// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "diamond-libraries/contracts/libraries/LibOwnership.sol";
import "diamond-libraries/contracts/interfaces/IERC173.sol";

contract OwnershipFacet is IERC173 {
    function transferOwnership(address _newOwner) external override {
        LibOwnership.enforceIsContractOwner();
        LibOwnership.setContractOwner(_newOwner);
    }

    function owner() external view override returns (address owner_) {
        owner_ = LibOwnership.contractOwner();
    }
}

