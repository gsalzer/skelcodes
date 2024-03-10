// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IDetailedERC20, Ownable} from "contracts/common/Imports.sol";
import {MetaPoolToken} from "contracts/mapt/MetaPoolToken.sol";
import {AggregatorV3Interface} from "contracts/oracle/Imports.sol";
import {PoolTokenV2} from "contracts/pool/PoolTokenV2.sol";
import {LpAccount} from "contracts/lpaccount/LpAccount.sol";
import {IAddressRegistryV2} from "contracts/registry/Imports.sol";
import {AddressRegistryV2} from "contracts/registry/AddressRegistryV2.sol";
import {
    ProxyAdmin,
    TransparentUpgradeableProxy
} from "contracts/proxy/Imports.sol";
import {IAssetAllocationRegistry} from "contracts/tvl/Imports.sol";

import {DeploymentConstants} from "./constants.sol";
import {
    AddressRegistryV2Factory,
    Erc20AllocationFactory,
    LpAccountFactory,
    MetaPoolTokenFactory,
    OracleAdapterFactory,
    ProxyAdminFactory,
    PoolTokenV1Factory,
    PoolTokenV2Factory,
    TvlManagerFactory
} from "./factories.sol";
import {IGnosisModuleManager, Enum} from "./IGnosisModuleManager.sol";

/** @dev
# Alpha Deployment

## Deployment order of contracts

The address registry needs multiple addresses registered
to setup the roles for access control in the contract
constructors:

MetaPoolToken

- emergencySafe (emergency role, default admin role)
- lpSafe (LP role)

PoolTokenV2

- emergencySafe (emergency role, default admin role)
- adminSafe (admin role)
- mApt (contract role)

TvlManager

- emergencySafe (emergency role, default admin role)
- lpSafe (LP role)

LpAccount

- emergencySafe (emergency role, default admin role)
- adminSafe (admin role)
- lpSafe (LP role)

OracleAdapter

- emergencySafe (emergency role, default admin role)
- adminSafe (admin role)
- tvlManager (contract role)
- mApt (contract role)
- lpAccount (contract role)

Note the order of dependencies: a contract requires contracts
above it in the list to be deployed first. Thus we need
to deploy in the order given, starting with the Safes.

*/

/* solhint-disable max-states-count, func-name-mixedcase */
contract AlphaDeployment is Ownable, DeploymentConstants {
    // TODO: figure out a versioning scheme
    string public constant VERSION = "1.0.0";

    address private constant FAKE_AGG_ADDRESS =
        0xCAfEcAfeCAfECaFeCaFecaFecaFECafECafeCaFe;

    IAddressRegistryV2 public addressRegistry;

    address public immutable proxyAdminFactory;
    address public immutable proxyFactory;
    address public immutable addressRegistryV2Factory;
    address public immutable mAptFactory;
    address public immutable poolTokenV1Factory;
    address public immutable poolTokenV2Factory;
    address public immutable tvlManagerFactory;
    address public immutable erc20AllocationFactory;
    address public immutable oracleAdapterFactory;
    address public immutable lpAccountFactory;

    uint256 public step;

    address public immutable emergencySafe;
    address public immutable adminSafe;
    address public immutable lpSafe;

    // step 0
    address public addressRegistryV2;

    // step 1
    address public mApt;

    // step 2
    address public poolTokenV2;

    // step 3
    address public daiDemoPool;
    address public usdcDemoPool;
    address public usdtDemoPool;

    // step 4
    address public tvlManager;
    address public erc20Allocation;

    // step 5
    address public oracleAdapter;

    // step 6
    address public lpAccount;

    modifier updateStep(uint256 step_) {
        require(step == step_, "INVALID_STEP");
        _;
        step += 1;
    }

    /**
     * @dev Uses `getAddress` in case `AddressRegistry` has not been upgraded
     */
    modifier checkSafeRegistrations() {
        require(
            addressRegistry.getAddress("emergencySafe") == emergencySafe,
            "INVALID_EMERGENCY_SAFE"
        );

        require(
            addressRegistry.getAddress("adminSafe") == adminSafe,
            "INVALID_ADMIN_SAFE"
        );

        require(
            addressRegistry.getAddress("lpSafe") == lpSafe,
            "INVALID_LP_SAFE"
        );

        _;
    }

    constructor(
        address proxyAdminFactory_,
        address proxyFactory_,
        address addressRegistryV2Factory_,
        address mAptFactory_,
        address poolTokenV1Factory_,
        address poolTokenV2Factory_,
        address tvlManagerFactory_,
        address erc20AllocationFactory_,
        address oracleAdapterFactory_,
        address lpAccountFactory_
    ) public {
        addressRegistry = IAddressRegistryV2(ADDRESS_REGISTRY_PROXY);

        // Simplest to check now that Safes are deployed in order to
        // avoid repeated preconditions checks later.
        emergencySafe = addressRegistry.getAddress("emergencySafe");
        adminSafe = addressRegistry.getAddress("adminSafe");
        lpSafe = addressRegistry.getAddress("lpSafe");

        proxyAdminFactory = proxyAdminFactory_;
        proxyFactory = proxyFactory_;
        addressRegistryV2Factory = addressRegistryV2Factory_;
        mAptFactory = mAptFactory_;
        poolTokenV1Factory = poolTokenV1Factory_;
        poolTokenV2Factory = poolTokenV2Factory_;
        tvlManagerFactory = tvlManagerFactory_;
        erc20AllocationFactory = erc20AllocationFactory_;
        oracleAdapterFactory = oracleAdapterFactory_;
        lpAccountFactory = lpAccountFactory_;
    }

    /**
     * @dev
     *   Check a contract address from a previous step's deployment
     *   is registered with expected ID.
     *
     * @param registeredIds identifiers for the Address Registry
     * @param deployedAddresses addresses from previous steps' deploys
     */
    function checkRegisteredDependencies(
        bytes32[] memory registeredIds,
        address[] memory deployedAddresses
    ) public view virtual {
        require(
            registeredIds.length == deployedAddresses.length,
            "LENGTH_MISMATCH"
        );

        for (uint256 i = 0; i < registeredIds.length; i++) {
            require(
                addressRegistry.getAddress(registeredIds[i]) ==
                    deployedAddresses[i],
                "MISSING_DEPLOYED_ADDRESS"
            );
        }
    }

    /**
     * @dev
     *   Check the deployment contract has ownership of necessary
     *   contracts to perform actions, e.g. register an address or upgrade
     *   a proxy.
     *
     * @param ownedContracts addresses that should be owned by this contract
     */
    function checkOwnerships(address[] memory ownedContracts)
        public
        view
        virtual
    {
        for (uint256 i = 0; i < ownedContracts.length; i++) {
            require(
                Ownable(ownedContracts[i]).owner() == adminSafe,
                "MISSING_OWNERSHIP"
            );
        }
    }

    function deploy_0_AddressRegistryV2_upgrade()
        external
        onlyOwner
        updateStep(0)
        checkSafeRegistrations
    {
        address[] memory ownerships = new address[](2);
        ownerships[0] = ADDRESS_REGISTRY_PROXY;
        ownerships[1] = ADDRESS_REGISTRY_PROXY_ADMIN;
        checkOwnerships(ownerships);

        addressRegistryV2 = AddressRegistryV2Factory(addressRegistryV2Factory)
            .create();
        bytes memory data =
            abi.encodeWithSelector(
                ProxyAdmin.upgrade.selector,
                ADDRESS_REGISTRY_PROXY,
                addressRegistryV2
            );

        require(
            IGnosisModuleManager(adminSafe).execTransactionFromModule(
                ADDRESS_REGISTRY_PROXY_ADMIN,
                0, // value
                data,
                Enum.Operation.Call
            ),
            "SAFE_TX_FAILED"
        );

        // TODO: delete "poolManager" ID

        // Initialize logic storage to block possible attack vector:
        // attacker may control and selfdestruct the logic contract
        // if more powerful functionality is added later
        AddressRegistryV2(addressRegistryV2).initialize(
            ADDRESS_REGISTRY_PROXY_ADMIN
        );
    }

    /// @dev Deploy the mAPT proxy and its proxy admin.
    ///      Does not register any roles for contracts.
    function deploy_1_MetaPoolToken()
        external
        onlyOwner
        updateStep(1)
        checkSafeRegistrations
    {
        address[] memory ownerships = new address[](1);
        ownerships[0] = ADDRESS_REGISTRY_PROXY;
        checkOwnerships(ownerships);

        address proxyAdmin = ProxyAdminFactory(proxyAdminFactory).create();

        bytes memory initData =
            abi.encodeWithSelector(
                MetaPoolToken.initialize.selector,
                addressRegistry
            );

        mApt = MetaPoolTokenFactory(mAptFactory).create(
            proxyFactory,
            proxyAdmin,
            initData
        );

        _registerAddress("mApt", mApt);

        ProxyAdmin(proxyAdmin).transferOwnership(adminSafe);
    }

    function deploy_2_PoolTokenV2_logic() external onlyOwner updateStep(2) {
        poolTokenV2 = PoolTokenV2Factory(poolTokenV2Factory).create();

        // Initialize logic storage to block possible attack vector:
        // attacker may control and selfdestruct the logic contract
        // if more powerful functionality is added later
        PoolTokenV2(poolTokenV2).initialize(
            POOL_PROXY_ADMIN,
            IDetailedERC20(DAI_ADDRESS),
            AggregatorV3Interface(0xCAfEcAfeCAfECaFeCaFecaFecaFECafECafeCaFe)
        );
    }

    /// @dev complete proxy deploy for the demo pools
    ///      Registers mAPT for a contract role.
    function deploy_3_DemoPools()
        external
        onlyOwner
        updateStep(3)
        checkSafeRegistrations
    {
        bytes32[] memory registeredIds = new bytes32[](1);
        address[] memory deployedAddresses = new address[](1);
        (registeredIds[0], deployedAddresses[0]) = ("mApt", mApt);
        checkRegisteredDependencies(registeredIds, deployedAddresses);

        address[] memory ownerships = new address[](1);
        ownerships[0] = ADDRESS_REGISTRY_PROXY;
        checkOwnerships(ownerships);

        address proxyAdmin = ProxyAdminFactory(proxyAdminFactory).create();

        bytes memory initDataV2 =
            abi.encodeWithSelector(
                PoolTokenV2.initializeUpgrade.selector,
                address(addressRegistry)
            );

        daiDemoPool = _deployDemoPool(
            DAI_ADDRESS,
            "daiDemoPool",
            proxyAdmin,
            initDataV2
        );

        usdcDemoPool = _deployDemoPool(
            USDC_ADDRESS,
            "usdcDemoPool",
            proxyAdmin,
            initDataV2
        );

        usdtDemoPool = _deployDemoPool(
            USDT_ADDRESS,
            "usdtDemoPool",
            proxyAdmin,
            initDataV2
        );

        ProxyAdmin(proxyAdmin).transferOwnership(adminSafe);
    }

    /// @dev Deploy ERC20 allocation and TVL Manager.
    ///      Does not register any roles for contracts.
    function deploy_4_TvlManager()
        external
        onlyOwner
        updateStep(4)
        checkSafeRegistrations
    {
        address[] memory ownerships = new address[](1);
        ownerships[0] = ADDRESS_REGISTRY_PROXY;
        checkOwnerships(ownerships);

        tvlManager = TvlManagerFactory(tvlManagerFactory).create(
            address(addressRegistry)
        );
        _registerAddress("tvlManager", tvlManager);

        erc20Allocation = Erc20AllocationFactory(erc20AllocationFactory).create(
            address(addressRegistry)
        );

        bytes memory data =
            abi.encodeWithSelector(
                IAssetAllocationRegistry.registerAssetAllocation.selector,
                erc20Allocation
            );
        require(
            IGnosisModuleManager(adminSafe).execTransactionFromModule(
                tvlManager,
                0,
                data,
                Enum.Operation.Call
            ),
            "SAFE_TX_FAILED"
        );
    }

    /// @dev register mAPT for a contract role
    function deploy_5_LpAccount()
        external
        onlyOwner
        updateStep(5)
        checkSafeRegistrations
    {
        bytes32[] memory registeredIds = new bytes32[](1);
        address[] memory deployedAddresses = new address[](1);
        (registeredIds[0], deployedAddresses[0]) = ("mApt", mApt);
        checkRegisteredDependencies(registeredIds, deployedAddresses);

        address[] memory ownerships = new address[](1);
        ownerships[0] = ADDRESS_REGISTRY_PROXY;
        checkOwnerships(ownerships);

        address proxyAdmin = ProxyAdminFactory(proxyAdminFactory).create();

        bytes memory initData =
            abi.encodeWithSelector(
                LpAccount.initialize.selector,
                address(addressRegistry)
            );

        lpAccount = LpAccountFactory(lpAccountFactory).create(
            proxyFactory,
            proxyAdmin,
            initData
        );

        _registerAddress("lpAccount", lpAccount);

        ProxyAdmin(proxyAdmin).transferOwnership(adminSafe);
    }

    /// @dev registers mAPT, TvlManager, LpAccount for contract roles
    function deploy_6_OracleAdapter()
        external
        onlyOwner
        updateStep(6)
        checkSafeRegistrations
    {
        bytes32[] memory registeredIds = new bytes32[](3);
        address[] memory deployedAddresses = new address[](3);
        (registeredIds[0], deployedAddresses[0]) = ("mApt", mApt);
        (registeredIds[1], deployedAddresses[1]) = ("tvlManager", tvlManager);
        (registeredIds[2], deployedAddresses[2]) = ("lpAccount", lpAccount);
        checkRegisteredDependencies(registeredIds, deployedAddresses);

        address[] memory ownerships = new address[](1);
        ownerships[0] = ADDRESS_REGISTRY_PROXY;
        checkOwnerships(ownerships);

        address[] memory assets = new address[](3);
        assets[0] = DAI_ADDRESS;
        assets[1] = USDC_ADDRESS;
        assets[2] = USDT_ADDRESS;

        address[] memory sources = new address[](3);
        sources[0] = DAI_USD_AGG_ADDRESS;
        sources[1] = USDC_USD_AGG_ADDRESS;
        sources[2] = USDT_USD_AGG_ADDRESS;

        uint256 aggStalePeriod = 86400;
        uint256 defaultLockPeriod = 270;

        oracleAdapter = OracleAdapterFactory(oracleAdapterFactory).create(
            address(addressRegistry),
            TVL_AGG_ADDRESS,
            assets,
            sources,
            aggStalePeriod,
            defaultLockPeriod
        );

        _registerAddress("oracleAdapter", oracleAdapter);
    }

    /// @notice upgrade from v1 to v2
    /// @dev register mAPT for a contract role
    function deploy_7_PoolTokenV2_upgrade()
        external
        onlyOwner
        updateStep(7)
        checkSafeRegistrations
    {
        bytes32[] memory registeredIds = new bytes32[](1);
        address[] memory deployedAddresses = new address[](1);
        (registeredIds[0], deployedAddresses[0]) = ("mApt", mApt);
        checkRegisteredDependencies(registeredIds, deployedAddresses);

        address[] memory ownerships = new address[](1);
        ownerships[0] = POOL_PROXY_ADMIN;
        checkOwnerships(ownerships);

        bytes memory initData =
            abi.encodeWithSelector(
                PoolTokenV2.initializeUpgrade.selector,
                addressRegistry
            );

        _upgradePool(DAI_POOL_PROXY, POOL_PROXY_ADMIN, initData);
        _upgradePool(USDC_POOL_PROXY, POOL_PROXY_ADMIN, initData);
        _upgradePool(USDT_POOL_PROXY, POOL_PROXY_ADMIN, initData);
    }

    function _registerAddress(bytes32 id, address address_) internal {
        bytes memory data =
            abi.encodeWithSelector(
                AddressRegistryV2.registerAddress.selector,
                id,
                address_
            );

        require(
            IGnosisModuleManager(adminSafe).execTransactionFromModule(
                address(addressRegistry),
                0,
                data,
                Enum.Operation.Call
            ),
            "SAFE_TX_FAILED"
        );
    }

    function _deployDemoPool(
        address token,
        bytes32 id,
        address proxyAdmin,
        bytes memory initData
    ) internal returns (address) {
        bytes memory data =
            abi.encodeWithSelector(
                PoolTokenV2.initialize.selector,
                proxyAdmin,
                token,
                FAKE_AGG_ADDRESS
            );

        address proxy =
            PoolTokenV1Factory(poolTokenV1Factory).create(
                proxyFactory,
                proxyAdmin,
                data
            );

        ProxyAdmin(proxyAdmin).upgradeAndCall(
            TransparentUpgradeableProxy(payable(proxy)),
            poolTokenV2,
            initData
        );

        _registerAddress(id, proxy);

        return proxy;
    }

    function _upgradePool(
        address proxy,
        address proxyAdmin,
        bytes memory initData
    ) internal {
        bytes memory data =
            abi.encodeWithSelector(
                ProxyAdmin.upgradeAndCall.selector,
                TransparentUpgradeableProxy(payable(proxy)),
                poolTokenV2,
                initData
            );

        require(
            IGnosisModuleManager(adminSafe).execTransactionFromModule(
                proxyAdmin,
                0,
                data,
                Enum.Operation.Call
            ),
            "SAFE_TX_FAILED"
        );
    }
}
/* solhint-enable func-name-mixedcase */

