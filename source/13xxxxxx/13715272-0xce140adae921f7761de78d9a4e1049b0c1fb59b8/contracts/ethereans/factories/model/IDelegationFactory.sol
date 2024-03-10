// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./IOrganizationFactory.sol";
import { IDelegationRulesChanger } from "../../../ext/delegation/impl/DelegationProposals.sol";

interface IDelegationFactory is IOrganizationFactory, IDelegationRulesChanger {

    function initializeProposalModels(
        address delegationAddress,
        address host,
        uint256 quorum,
        uint256 validationBomb,
        uint256 blockLength,
        uint256 hardCap) external;
}
