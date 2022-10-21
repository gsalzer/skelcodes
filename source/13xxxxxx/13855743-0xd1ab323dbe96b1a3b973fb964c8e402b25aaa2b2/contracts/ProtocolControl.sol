// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Access Control
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

// Registry
import { Registry } from "./Registry.sol";
import { Royalty } from "./Royalty.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ProtocolControl is AccessControlEnumerable {
    /// @dev MAX_BPS for the contract: 10_000 == 100%
    uint128 public constant MAX_BPS = 10000;

    /// @dev Module ID => Module address.
    mapping(bytes32 => address) public modules;

    /// @dev Module type => Num of modules of that type.
    mapping(uint256 => uint256) public numOfModuleType;

    /// @dev module address => royalty address
    mapping(address => address) private moduleRoyalty;

    /// @dev The top level app registry.
    address public registry;

    /// @dev Deployer's treasury
    address public royaltyTreasury;

    /// @dev The Forwarder for this app's modules.
    address private _forwarder;

    /// @dev Contract level metadata.
    string private _contractURI;

    /// @dev Events.
    event ModuleUpdated(bytes32 indexed moduleId, address indexed module);
    event TreasuryUpdated(address _newTreasury);
    event ForwarderUpdated(address _newForwarder);
    event FundsWithdrawn(address indexed to, address indexed currency, uint256 amount, uint256 fee);
    event EtherReceived(address from, uint256 amount);
    event RoyaltyTreasuryUpdated(
        address indexed protocolControlAddress,
        address indexed moduleAddress,
        address treasury
    );

    /// @dev Check whether the caller is a protocol admin
    modifier onlyProtocolAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ProtocolControl: Only protocol admins can call this function."
        );
        _;
    }

    constructor(
        address _registry,
        address _admin,
        string memory _uri
    ) {
        // Set contract URI
        _contractURI = _uri;
        // Set top level ap registry
        registry = _registry;
        // Set default royalty treasury address
        royaltyTreasury = address(this);
        // Set access control roles
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /// @dev Lets the contract receive ether.
    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }

    /// @dev Initialize treasury payment royalty splitting pool
    function setRoyaltyTreasury(address payable _treasury) external onlyProtocolAdmin {
        require(_isRoyaltyTreasuryValid(_treasury), "ProtocolControl: provider shares too low.");
        royaltyTreasury = _treasury;
        emit RoyaltyTreasuryUpdated(address(this), address(0), _treasury);
    }

    /// @dev _treasury must be PaymentSplitter compatible interface.
    function setModuleRoyaltyTreasury(address moduleAddress, address payable _treasury) external onlyProtocolAdmin {
        require(_isRoyaltyTreasuryValid(_treasury), "ProtocolControl: provider shares too low.");
        moduleRoyalty[moduleAddress] = _treasury;
        emit RoyaltyTreasuryUpdated(address(this), moduleAddress, _treasury);
    }

    /// @dev validate to make sure protocol provider (the registry) gets enough fees.
    function _isRoyaltyTreasuryValid(address payable _treasury) private view returns (bool) {
        // Get `Royalty` and `Registry` instances
        Royalty royalty = Royalty(_treasury);
        Registry _registry = Registry(registry);

        // Calculate the protocol provider's shares.
        uint256 royaltyRegistryShares = royalty.shares(_registry.treasury());
        uint256 royaltyTotalShares = royalty.totalShares();
        uint256 registryCutBps = (royaltyRegistryShares * MAX_BPS) / royaltyTotalShares;

        // 10 bps (0.10%) tolerance in case of precision loss
        // making sure registry treasury gets at least the fee's worth of shares.
        uint256 feeBpsTolerance = 10;
        return registryCutBps >= (_registry.getFeeBps(address(this)) - feeBpsTolerance);
    }

    /// @dev Returns the Royalty payment splitter for a particular module.
    function getRoyaltyTreasury(address moduleAddress) external view returns (address) {
        address moduleRoyaltyTreasury = moduleRoyalty[moduleAddress];
        if (moduleRoyaltyTreasury == address(0)) {
            return royaltyTreasury;
        }
        return moduleRoyaltyTreasury;
    }

    /// @dev Lets a protocol admin add a module to the protocol.
    function addModule(address _newModuleAddress, uint256 _moduleType)
        external
        onlyProtocolAdmin
        returns (bytes32 moduleId)
    {
        // `moduleId` is collision resitant -- unique `_moduleType` and incrementing `numOfModuleType`
        moduleId = keccak256(abi.encodePacked(numOfModuleType[_moduleType], _moduleType));
        numOfModuleType[_moduleType] += 1;

        modules[moduleId] = _newModuleAddress;

        emit ModuleUpdated(moduleId, _newModuleAddress);
    }

    /// @dev Lets a protocol admin change the address of a module of the protocol.
    function updateModule(bytes32 _moduleId, address _newModuleAddress) external onlyProtocolAdmin {
        require(modules[_moduleId] != address(0), "ProtocolControl: a module with this ID does not exist.");

        modules[_moduleId] = _newModuleAddress;

        emit ModuleUpdated(_moduleId, _newModuleAddress);
    }

    /// @dev Sets contract URI for the contract-level metadata of the contract.
    function setContractURI(string calldata _URI) external onlyProtocolAdmin {
        _contractURI = _URI;
    }

    /// @dev Lets the admin set a new Forwarder address [NOTE: for off-chain convenience only.]
    function setForwarder(address forwarder) external onlyProtocolAdmin {
        _forwarder = forwarder;
        emit ForwarderUpdated(forwarder);
    }

    /// @dev Returns the URI for the contract-level metadata of the contract.
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @dev Returns all addresses for a module type
    function getAllModulesOfType(uint256 _moduleType) external view returns (address[] memory allModules) {
        uint256 numOfModules = numOfModuleType[_moduleType];
        allModules = new address[](numOfModules);

        for (uint256 i = 0; i < numOfModules; i += 1) {
            bytes32 moduleId = keccak256(abi.encodePacked(i, _moduleType));
            allModules[i] = modules[moduleId];
        }
    }

    /// @dev Returns the forwarder address stored on the contract.
    function getForwarder() public view returns (address) {
        if (_forwarder == address(0)) {
            return Registry(registry).forwarder();
        }
        return _forwarder;
    }

    function withdrawFunds(address to, address currency) external onlyProtocolAdmin {
        Registry _registry = Registry(registry);
        IERC20 _currency = IERC20(currency);
        address registryTreasury = _registry.treasury();
        uint256 registryTreasuryFee = 0;
        uint256 amount = 0;

        if (currency == address(0)) {
            amount = address(this).balance;
        } else {
            amount = _currency.balanceOf(address(this));
        }

        registryTreasuryFee = (amount * _registry.getFeeBps(address(this))) / MAX_BPS;
        amount = amount - registryTreasuryFee;

        if (currency == address(0)) {
            (bool sent, ) = payable(to).call{ value: amount }("");
            require(sent, "failed to withdraw funds");

            (bool sentRegistry, ) = payable(registryTreasury).call{ value: registryTreasuryFee }("");
            require(sentRegistry, "failed to withdraw funds to registry");

            emit FundsWithdrawn(to, currency, amount, registryTreasuryFee);
        } else {
            require(_currency.transferFrom(_msgSender(), to, amount), "failed to transfer payment");

            require(
                _currency.transferFrom(_msgSender(), registryTreasury, registryTreasuryFee),
                "failed to transfer payment to registry"
            );

            emit FundsWithdrawn(to, currency, amount, registryTreasuryFee);
        }
    }
}

