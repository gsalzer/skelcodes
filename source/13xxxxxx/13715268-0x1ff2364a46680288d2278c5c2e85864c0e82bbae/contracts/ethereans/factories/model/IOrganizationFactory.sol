// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./IEthereansFactory.sol";

interface IOrganizationFactory is IEthereansFactory {

    struct OrganizationDeployData {
        string uri;
        bytes[] mandatoryComponentsDeployData;
        uint256[] additionalComponents;
        bytes[] additionalComponentsDeployData;
        bytes[] specialComponentsData;
        bytes specificOrganizationData;
    }

    function data() external view returns(address[] memory utilityModels, bytes32[] memory utilitiyModelKeys, bool[] memory utilitiyModelActive, string memory proposalUri);
}
