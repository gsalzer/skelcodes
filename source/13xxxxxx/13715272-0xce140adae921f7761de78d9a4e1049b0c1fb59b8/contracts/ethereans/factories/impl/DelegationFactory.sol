// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
pragma abicoder v2;

import "../model/IDelegationFactory.sol";
import "./EthereansFactory.sol";
import "../../../base/model/IProposalsManager.sol";
import { ReflectionUtilities, BehaviorUtilities, Uint256Utilities, AddressUtilities } from "@ethereansos/swissknife/contracts/lib/GeneralUtilities.sol";
import { Grimoire as BaseGrimoire, Getters } from "../../../base/lib/KnowledgeBase.sol";
import { Getters as ExternalGetters } from "../../../ext/lib/KnowledgeBase.sol";
import "../../../ext/subDAO/model/ISubDAO.sol";
import "../../../base/model/IProposalsManager.sol";
import "../../../core/model/IOrganization.sol";
import "../../../base/model/IStateManager.sol";
import { State } from "../../../base/lib/KnowledgeBase.sol";
import "@ethereansos/items-v2/contracts/projection/IItemProjection.sol";
import "@ethereansos/items-v2/contracts/projection/factory/model/IItemProjectionFactory.sol";
import "../model/IProposalModelsFactory.sol";

contract DelegationFactory is EthereansFactory, IDelegationFactory {
    using ReflectionUtilities for address;
    using Getters for IOrganization;
    using ExternalGetters for IOrganization;
    using State for IStateManager;
    using Uint256Utilities for uint256;
    using AddressUtilities for address;

    uint256 public constant MANDATORY_COMPONENTS = 3;
    //ProposalsManager true
    //TreasuryManager false
    //DelegationTokensManager true

    uint256 public constant PROPOSALS_MANAGER_POSITION = 0;

    address[] private _utilityModels;
    bytes32[] private _utilityModelKeys;
    bool[] private _utilityModelsActive;

    uint256 public presetArrayMaxSize;

    address public itemProjectionFactoryAddress;
    address public mainInterface;
    address public projectionAddress;
    bytes32 public collectionId;
    ISubDAO.SubDAOProposalModel[] private _proposalModels;

    address public proposalModelsFactory;

    uint256 private constant BY_SPECIFIC_ADDRESS_POSITION = 0;
    uint256 private constant BLOCK_LENGTH_POSITION = 2;
    uint256 private constant HARD_CAP_POSITION = 3;
    uint256 private constant VALIDATION_BOMB_POSITION = 4;
    uint256 private constant QUORUM_POSITION = 5;

    constructor(bytes memory lazyInitData) EthereansFactory(lazyInitData) {
    }

    function _ethosFactoryLazyInit(bytes memory lazyInitData) internal override returns(bytes memory lazyInitResponse) {
        (proposalModelsFactory, _utilityModels, _utilityModelKeys, _utilityModelsActive, lazyInitResponse) = abi.decode(lazyInitData, (address, address[], bytes32[], bool[], bytes));
        ISubDAO.SubDAOProposalModel[] memory proposalModels;
        Header memory collectionHeader;
        (itemProjectionFactoryAddress, collectionHeader, presetArrayMaxSize, proposalModels) = abi.decode(lazyInitResponse, (address, Header, uint256, ISubDAO.SubDAOProposalModel[]));
        for(uint256 i = 0; i < proposalModels.length; i++) {
            _proposalModels.push(proposalModels[i]);
        }
        _deployCollection(collectionHeader);
        lazyInitResponse = "";
    }

    function mintItems(CreateItem[] memory items) external returns(uint256[] memory itemIds) {
        require(deployer[msg.sender] != address(0), "unauthorized");
        for(uint256 i = 0; i < items.length; i++) {
            items[i].collectionId = collectionId;
        }
        return IItemProjection(projectionAddress).mintItems(items);
    }

    function data() external override view returns(address[] memory utilityModels, bytes32[] memory utilitiyModelKeys, bool[] memory utilitiyModelActive, string memory proposalUri) {
        return (_utilityModels, _utilityModelKeys, _utilityModelsActive, "");
    }

    function deploy(bytes calldata deployData) external payable override(Factory, IFactory) virtual returns(address productAddress, bytes memory productInitResponse) {
        (OrganizationDeployData memory organizationDeployData) = abi.decode(deployData, (OrganizationDeployData));

        deployer[productAddress = modelAddress.clone()] = msg.sender;

        uint256 componentsLength = MANDATORY_COMPONENTS;
        IOrganization.Component[] memory components = new IOrganization.Component[](componentsLength);

        for(uint256 i = 0; i < MANDATORY_COMPONENTS; i++) {
            components[i] = _createOrganizationComponent(i, productAddress, i == PROPOSALS_MANAGER_POSITION ? abi.encode(true, organizationDeployData.mandatoryComponentsDeployData[i]) : organizationDeployData.mandatoryComponentsDeployData[i]);
        }

        productInitResponse = _emitDeploy(productAddress, organizationDeployData.uri, components);

        require(ILazyInitCapableElement(productAddress).initializer() == address(this));
    }

    address[] private _validationAddresses;
    address[] private _canTerminateAddresses;

    function createNewRules(
        address delegationAddress,
        uint256 quorumPercentage,
        uint256 validationBomb,
        uint256 blockLength,
        uint256 hardCapPercentage
    ) public override returns (address[] memory validationAddresses, address[] memory canTerminateAddresses) {
        require(deployer[delegationAddress] != address(0), "unknown delegation");

        _addTo(QUORUM_POSITION, quorumPercentage, true, true);
        if(validationBomb > 0) {
            _addTo(VALIDATION_BOMB_POSITION, validationBomb, false, true);
        }

        if(blockLength > 0) {
            _addTo(BLOCK_LENGTH_POSITION, blockLength, false, false);
        }

        if(hardCapPercentage > 0) {
            _addTo(HARD_CAP_POSITION, hardCapPercentage, true, false);
        }

        validationAddresses = _validationAddresses;
        canTerminateAddresses = _canTerminateAddresses;

        require(validationAddresses.length > 0, "No validators");
        require(canTerminateAddresses.length > 0, "No canTerminates");

        delete _validationAddresses;
        delete _canTerminateAddresses;
    }

    function initializeProposalModels(
        address delegationAddress,
        address host,
        uint256 quorumPercentage,
        uint256 validationBomb,
        uint256 blockLength,
        uint256 hardCapPercentage
        ) external override {

        require(deployer[delegationAddress] == msg.sender, "unauthorized");
        (address creationRules,) = IProposalModelsFactory(proposalModelsFactory).deploy(abi.encode(BY_SPECIFIC_ADDRESS_POSITION, abi.encode(host, true)));

        (address[] memory validationAddresses, address[] memory canTerminateAddresses) = createNewRules(
            delegationAddress,
            quorumPercentage,
            validationBomb,
            blockLength,
            hardCapPercentage
        );

        ISubDAO.SubDAOProposalModel[] memory proposalModels = _proposalModels;
        proposalModels[0].creationRules = creationRules;//Attach-Detach

        proposalModels[1].creationRules = creationRules;//Change URI

        proposalModels[2].creationRules = creationRules;//Change Rules

        proposalModels[3].creationRules = creationRules;//Transfer
        proposalModels[3].validatorsAddresses[0] = validationAddresses;
        proposalModels[3].canTerminateAddresses[0] = canTerminateAddresses;

        proposalModels[4].creationRules = creationRules;//Vote
        proposalModels[4].validatorsAddresses[0] = validationAddresses;
        proposalModels[4].canTerminateAddresses[0] = canTerminateAddresses;

        ISubDAO(delegationAddress).setInitialProposalModels(proposalModels);
    }

    function _addTo(uint256 position, uint256 value, bool valueIsPercentage, bool validators) private {
        bytes memory init = valueIsPercentage ? abi.encode(value, true) : abi.encode(value);
        (address model,) = IProposalModelsFactory(proposalModelsFactory).deploy(abi.encode(position, init));
        if(validators) {
            _validationAddresses.push(model);
        } else {
            _canTerminateAddresses.push(model);
        }
    }

    function _emitDeploy(address productAddress, string memory uri, IOrganization.Component[] memory components) private returns(bytes memory productInitResponse) {
        emit Deployed(modelAddress, productAddress, msg.sender, productInitResponse = ILazyInitCapableElement(productAddress).lazyInit(abi.encode(address(0), abi.encode(uri, dynamicUriResolver, abi.encode(false, presetArrayMaxSize, abi.encode(new ISubDAO.SubDAOProposalModel[](0), abi.encode(components)))))));
    }

    function proposeToAttachOrDetach(address delegationAddress, address delegationsManagerAddress, bool attach) public returns(bytes32 proposalId) {
        require(deployer[delegationAddress] != address(0), "Unrecognized");

        IProposalsManager.ProposalCode[] memory proposalCodes = new IProposalsManager.ProposalCode[](1);
        proposalCodes[0] = IProposalsManager.ProposalCode(address(0), abi.encode(delegationsManagerAddress, attach));

        IProposalsManager.ProposalCodes[] memory proposalCodesArray = new IProposalsManager.ProposalCodes[](1);
        proposalCodesArray[0] = IProposalsManager.ProposalCodes(proposalCodes, true);

        return IOrganization(delegationAddress).proposalsManager().batchCreate(proposalCodesArray)[0];
    }

    function _createOrganizationComponent(uint256 index, address productAddress, bytes memory lazyInitData) private returns(IOrganization.Component memory organizationComponent) {
        ILazyInitCapableElement((organizationComponent = IOrganization.Component(_utilityModelKeys[index], _utilityModels[index].clone(), _utilityModelsActive[index], true)).location).lazyInit(abi.encode(productAddress, lazyInitData));
        deployer[organizationComponent.location] = msg.sender;
    }

    function _deployCollection(Header memory collectionHeader) private {
        mainInterface = IItemProjectionFactory(itemProjectionFactoryAddress).mainInterface();

        collectionHeader.host = address(0);

        bytes memory deployData = abi.encode((uint256(1)).asSingletonArray(), address(this).asSingletonArray());
        deployData = abi.encode(bytes32(0), collectionHeader, new CreateItem[](0), deployData);
        deployData = abi.encode(address(0), deployData);
        deployData = abi.encode(0, deployData);
        (projectionAddress,) = IItemProjectionFactory(itemProjectionFactoryAddress).deploy(deployData);
        collectionId = IItemProjection(projectionAddress).collectionId();
    }
}
