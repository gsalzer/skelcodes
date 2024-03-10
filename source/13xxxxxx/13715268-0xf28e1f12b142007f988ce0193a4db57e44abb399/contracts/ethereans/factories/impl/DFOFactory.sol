// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../model/IDFOFactory.sol";
import "./EthereansFactory.sol";
import { Grimoire as BaseGrimoire, Getters } from "../../../base/lib/KnowledgeBase.sol";
import { Grimoire as ExternalGrimoire } from "../../../ext/lib/KnowledgeBase.sol";
import "../../../base/model/IProposalsManager.sol";
import "../../../core/model/IOrganization.sol";
import { Getters as ExternalGetters } from  "../../../ext/lib/KnowledgeBase.sol";
import { State } from  "../../../base/lib/KnowledgeBase.sol";
import "../../../base/model/IStateManager.sol";

contract DFOFactory is IDFOFactory, EthereansFactory {
    using ReflectionUtilities for address;
    using Getters for IOrganization;
    using ExternalGetters for IOrganization;
    using State for IStateManager;

    uint256 private constant MANDATORY_COMPONENTS = 1;
    //ProposalsManager true

    uint256 public constant PROPOSALS_MANAGER_POSITION = 0;
    uint256 public constant TREASURY_MANAGER_POSITION = 1;
    uint256 public constant TREASURY_SPLITTER_MANAGER_POSITION = 4;
    uint256 public constant SUBDAOS_MANAGER_POSITION = 5;
    uint256 public constant DELEGATIONS_MANAGER_POSITION = 6;

    address[] private _utilityModels;
    bytes32[] private _utilityModelKeys;
    bool[] private _utilityModelsActive;
    string private _proposalUri;

    uint256 public delegationsMaxSize;

    constructor(bytes memory lazyInitData) EthereansFactory(lazyInitData) {
    }

    function _ethosFactoryLazyInit(bytes memory lazyInitData) internal override returns(bytes memory lazyInitResponse) {
        (_utilityModels, _utilityModelKeys, _utilityModelsActive, _proposalUri, delegationsMaxSize) = abi.decode(lazyInitData, (address[], bytes32[], bool[], string, uint256));
        return "";
    }

    function data() external override view returns(address[] memory utilityModels, bytes32[] memory utilitiyModelKeys, bool[] memory utilitiyModelActive, string memory proposalUri) {
        return (_utilityModels, _utilityModelKeys, _utilityModelsActive, _proposalUri);
    }

    function deploy(bytes memory deployData) external virtual override(IFactory, Factory) payable returns(address productAddress, bytes memory productInitResponse) {

       (OrganizationDeployData memory organizationDeployData) = abi.decode(deployData, (OrganizationDeployData));

        deployer[productAddress = modelAddress.clone()] = msg.sender;

        uint256 componentsLength = MANDATORY_COMPONENTS + organizationDeployData.specialComponentsData.length;
        for(uint256 i = 0; i < organizationDeployData.additionalComponents.length; i++) {
            uint256 additionalComponentIndex = organizationDeployData.additionalComponents[i];
            require(i == 0 || additionalComponentIndex > organizationDeployData.additionalComponents[i - 1], "DESC");
            require(additionalComponentIndex >= MANDATORY_COMPONENTS && additionalComponentIndex < _utilityModels.length, "index");
            componentsLength++;
        }

        IOrganization.Component[] memory components = new IOrganization.Component[](componentsLength);

        for(uint256 i = 0; i < MANDATORY_COMPONENTS; i++) {
            components[i] = _createOrganizationComponent(i, productAddress, i == PROPOSALS_MANAGER_POSITION ? abi.encode(false, organizationDeployData.mandatoryComponentsDeployData[i]) : organizationDeployData.mandatoryComponentsDeployData[i]);
        }

        uint256 nextIndex = MANDATORY_COMPONENTS;
        if(organizationDeployData.additionalComponents.length > 0) {
            for(uint256 i = 0; i < organizationDeployData.additionalComponents.length; i++) {
                uint256 additionalComponentIndex = organizationDeployData.additionalComponents[i];
                components[nextIndex++] = additionalComponentIndex == DELEGATIONS_MANAGER_POSITION ? _deployDelegationsManager(productAddress, organizationDeployData.additionalComponentsDeployData[i]) : _createOrganizationComponent(additionalComponentIndex, productAddress, organizationDeployData.additionalComponentsDeployData[i]);
            }
        }

        if(organizationDeployData.specialComponentsData.length > 0) {
            for(uint256 i = 0; i < organizationDeployData.specialComponentsData.length; i++) {
                components[nextIndex++] = _deploySpecialComponent(productAddress, organizationDeployData.specialComponentsData[i]);
            }
        }

        productInitResponse = ILazyInitCapableElement(productAddress).lazyInit(abi.encode(address(0), abi.encode(organizationDeployData.uri, dynamicUriResolver, abi.encode(components))));

        emit Deployed(modelAddress, productAddress, msg.sender, productInitResponse);

        require(ILazyInitCapableElement(productAddress).initializer() == address(this));
    }

    function _deployDelegationsManager(address organizationAddress, bytes memory deployData) private returns(IOrganization.Component memory) {
        return _createOrganizationComponent(DELEGATIONS_MANAGER_POSITION, organizationAddress, abi.encode(delegationsMaxSize, _utilityModels[TREASURY_MANAGER_POSITION], deployData));
    }

    function _createOrganizationComponent(uint256 index, address productAddress, bytes memory lazyInitData) private returns(IOrganization.Component memory organizationComponent) {
        ILazyInitCapableElement((organizationComponent = IOrganization.Component(_utilityModelKeys[index], _utilityModels[index].clone(), _utilityModelsActive[index], true)).location).lazyInit(abi.encode(productAddress, lazyInitData));
        deployer[organizationComponent.location] = msg.sender;
    }

    function _deploySpecialComponent(address productAddress, bytes memory specialComponentData) private returns(IOrganization.Component memory organizationComponent) {
        (bytes32 key, address modelOrLocation, bool active, bytes memory deployData) = abi.decode(specialComponentData, (bytes32, address, bool, bytes));
        if(deployData.length > 0) {
            bool clone;
            (clone, deployData) = abi.decode(deployData, (bool, bytes));
            if(clone) {
                deployer[modelOrLocation = modelOrLocation.clone()] = msg.sender;
            }
            ILazyInitCapableElement(modelOrLocation).lazyInit(abi.encode(productAddress, deployData));
        }
        organizationComponent = IOrganization.Component(key, modelOrLocation, active, true);
    }
}
