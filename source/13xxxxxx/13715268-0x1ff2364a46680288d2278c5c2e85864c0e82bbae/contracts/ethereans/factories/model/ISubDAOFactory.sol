// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./IOrganizationFactory.sol";
import "../../../ext/subDAO/model/ISubDAO.sol";

interface ISubDAOFactory is IOrganizationFactory {
    function setInitialProposalModels(address subDAO, ISubDAO.SubDAOProposalModel[] calldata newValue) external;
}
