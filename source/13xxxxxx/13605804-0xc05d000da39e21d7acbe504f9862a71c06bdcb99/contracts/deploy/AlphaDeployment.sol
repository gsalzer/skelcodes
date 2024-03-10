// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IDetailedERC20, Ownable} from "contracts/common/Imports.sol";
import {Address} from "contracts/libraries/Imports.sol";
import {MetaPoolToken} from "contracts/mapt/MetaPoolToken.sol";
import {AggregatorV3Interface} from "contracts/oracle/Imports.sol";
import {PoolToken} from "contracts/pool/PoolToken.sol";
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
    PoolTokenV1Factory,
    TvlManagerFactory
} from "./factories/Imports.sol";
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
- erc20Allocation (contract role)
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

    address public proxyFactory;
    address public addressRegistryV2Factory;
    address public mAptFactory;
    address public poolTokenV1Factory;
    address public poolTokenV2Factory;
    address public tvlManagerFactory;
    address public erc20AllocationFactory;
    address public oracleAdapterFactory;
    address public lpAccountFactory;

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

        setProxyFactory(proxyFactory_);
        setAddressRegistryV2Factory(addressRegistryV2Factory_);
        setMetaPoolTokenFactory(mAptFactory_);
        setPoolTokenV1Factory(poolTokenV1Factory_);
        setPoolTokenV2Factory(poolTokenV2Factory_);
        setTvlManagerFactory(tvlManagerFactory_);
        setErc20AllocationFactory(erc20AllocationFactory_);
        setOracleAdapterFactory(oracleAdapterFactory_);
        setLpAccountFactory(lpAccountFactory_);
    }

    function deploy_0_AddressRegistryV2_upgrade()
        external
        onlyOwner
        updateStep(0)
        checkSafeRegistrations
    {
        address[] memory ownerships = new address[](2);
        ownerships[0] = ADDRESS_REGISTRY_PROXY;
        ownerships[1] = POOL_PROXY_ADMIN;
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
            IGnosisModuleManager(emergencySafe).execTransactionFromModule(
                POOL_PROXY_ADMIN,
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
        AddressRegistryV2(addressRegistryV2).initialize(POOL_PROXY_ADMIN);
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

        bytes memory initData =
            abi.encodeWithSelector(
                MetaPoolToken.initialize.selector,
                addressRegistry
            );

        mApt = MetaPoolTokenFactory(mAptFactory).create(
            proxyFactory,
            POOL_PROXY_ADMIN,
            initData
        );

        _registerAddress("mApt", mApt);
    }

    /// @dev Deploy ERC20 allocation and TVL Manager.
    ///      Does not register any roles for contracts.
    function deploy_2_TvlManager()
        external
        onlyOwner
        updateStep(2)
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

        _registerAddress("erc20Allocation", erc20Allocation);
    }

    /// @dev register mAPT for a contract role
    function deploy_3_LpAccount()
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

        bytes memory initData =
            abi.encodeWithSelector(
                LpAccount.initialize.selector,
                address(addressRegistry)
            );

        lpAccount = LpAccountFactory(lpAccountFactory).create(
            proxyFactory,
            POOL_PROXY_ADMIN,
            initData
        );

        _registerAddress("lpAccount", lpAccount);
    }

    /// @dev registers mAPT, TvlManager, Erc20Allocation, LpAccount for contract roles
    function deploy_4_OracleAdapter()
        external
        onlyOwner
        updateStep(4)
        checkSafeRegistrations
    {
        bytes32[] memory registeredIds = new bytes32[](4);
        address[] memory deployedAddresses = new address[](4);
        (registeredIds[0], deployedAddresses[0]) = ("mApt", mApt);
        (registeredIds[1], deployedAddresses[1]) = ("lpAccount", lpAccount);
        (registeredIds[2], deployedAddresses[2]) = ("tvlManager", tvlManager);
        (registeredIds[3], deployedAddresses[3]) = (
            "erc20Allocation",
            erc20Allocation
        );
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

        // Must register the ERC20 Allocation after the Oracle Adapter deploy
        // since registration will lock the Adapter.
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

    /**
     * @dev V1 proxy deploy for the demo pools.  V2 upgrade will be done
     * through the pool upgrader.
     * @dev V2 will register mAPT for a contract role so we pre-emptively
     * check it here.
     */
    function deploy_5_DemoPools()
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

        daiDemoPool = _deployDemoPool(
            "daiDemoPool",
            DAI_ADDRESS,
            DAI_ETH_AGG_ADDRESS
        );

        usdcDemoPool = _deployDemoPool(
            "usdcDemoPool",
            USDC_ADDRESS,
            USDC_ETH_AGG_ADDRESS
        );

        usdtDemoPool = _deployDemoPool(
            "usdtDemoPool",
            USDT_ADDRESS,
            USDT_ETH_AGG_ADDRESS
        );
    }

    function setProxyFactory(address proxyFactory_) public onlyOwner {
        require(Address.isContract(proxyFactory_), "INVALID_FACTORY_ADDRESS");
        proxyFactory = proxyFactory_;
    }

    function setAddressRegistryV2Factory(address addressRegistryV2Factory_)
        public
        onlyOwner
    {
        require(
            Address.isContract(addressRegistryV2Factory_),
            "INVALID_FACTORY_ADDRESS"
        );
        addressRegistryV2Factory = addressRegistryV2Factory_;
    }

    function setErc20AllocationFactory(address erc20AllocationFactory_)
        public
        onlyOwner
    {
        require(
            Address.isContract(erc20AllocationFactory_),
            "INVALID_FACTORY_ADDRESS"
        );
        erc20AllocationFactory = erc20AllocationFactory_;
    }

    function setLpAccountFactory(address lpAccountFactory_) public onlyOwner {
        require(
            Address.isContract(lpAccountFactory_),
            "INVALID_FACTORY_ADDRESS"
        );
        lpAccountFactory = lpAccountFactory_;
    }

    function setMetaPoolTokenFactory(address mAptFactory_) public onlyOwner {
        require(Address.isContract(mAptFactory_), "INVALID_FACTORY_ADDRESS");
        mAptFactory = mAptFactory_;
    }

    function setOracleAdapterFactory(address oracleAdapterFactory_)
        public
        onlyOwner
    {
        require(
            Address.isContract(oracleAdapterFactory_),
            "INVALID_FACTORY_ADDRESS"
        );
        oracleAdapterFactory = oracleAdapterFactory_;
    }

    function setTvlManagerFactory(address tvlManagerFactory_) public onlyOwner {
        require(
            Address.isContract(tvlManagerFactory_),
            "INVALID_FACTORY_ADDRESS"
        );
        tvlManagerFactory = tvlManagerFactory_;
    }

    function setPoolTokenV1Factory(address poolTokenV1Factory_)
        public
        onlyOwner
    {
        require(
            Address.isContract(poolTokenV1Factory_),
            "INVALID_FACTORY_ADDRESS"
        );
        poolTokenV1Factory = poolTokenV1Factory_;
    }

    function setPoolTokenV2Factory(address poolTokenV2Factory_)
        public
        onlyOwner
    {
        require(
            Address.isContract(poolTokenV2Factory_),
            "INVALID_FACTORY_ADDRESS"
        );
        poolTokenV2Factory = poolTokenV2Factory_;
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
                Ownable(ownedContracts[i]).owner() == emergencySafe,
                "MISSING_OWNERSHIP"
            );
        }
    }

    function _registerAddress(bytes32 id, address address_) internal {
        bytes memory data =
            abi.encodeWithSelector(
                AddressRegistryV2.registerAddress.selector,
                id,
                address_
            );

        require(
            IGnosisModuleManager(emergencySafe).execTransactionFromModule(
                address(addressRegistry),
                0,
                data,
                Enum.Operation.Call
            ),
            "SAFE_TX_FAILED"
        );
    }

    /**
     * @dev Deploys only the V1 pool.  Pool upgrader should be used
     * to upgrade to V2.
     */
    function _deployDemoPool(
        bytes32 id,
        address token,
        address agg
    ) internal returns (address) {
        bytes memory initData =
            abi.encodeWithSelector(
                PoolToken.initialize.selector,
                POOL_PROXY_ADMIN,
                token,
                agg
            );

        address proxy =
            PoolTokenV1Factory(poolTokenV1Factory).create(
                proxyFactory,
                POOL_PROXY_ADMIN,
                initData
            );

        _registerAddress(id, proxy);

        return proxy;
    }
}
/* solhint-enable func-name-mixedcase */

