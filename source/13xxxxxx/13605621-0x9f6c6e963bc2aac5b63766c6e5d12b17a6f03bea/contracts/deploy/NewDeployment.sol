// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {Address} from "contracts/libraries/Imports.sol";
import {Ownable, ReentrancyGuard} from "contracts/common/Imports.sol";
import {MetaPoolToken} from "contracts/mapt/MetaPoolToken.sol";
import {PoolTokenV2} from "contracts/pool/PoolTokenV2.sol";
import {LpAccount} from "contracts/lpaccount/LpAccount.sol";
import {AddressRegistryV2} from "contracts/registry/AddressRegistryV2.sol";
import {
    ProxyAdmin,
    TransparentUpgradeableProxy
} from "contracts/proxy/Imports.sol";
import {IAssetAllocationRegistry} from "contracts/tvl/Imports.sol";

import {DeploymentConstants} from "./constants.sol";
import {
    AddressRegistryV2FactoryV2,
    Erc20AllocationFactory,
    LpAccountFactory,
    MetaPoolTokenFactory,
    OracleAdapterFactory,
    ProxyFactoryV2,
    ProxyAdminFactory,
    PoolTokenV1Factory,
    PoolTokenV2Factory,
    TvlManagerFactory
} from "./factories/Imports.sol";
import {IGnosisModuleManager, Enum} from "./IGnosisModuleManager.sol";

/** @dev
# New Deployment

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

OracleAdapter

- emergencySafe (emergency role, default admin role)
- adminSafe (admin role)
- tvlManager (contract role)
- mApt (contract role)

LpAccount

- emergencySafe (emergency role, default admin role)
- adminSafe (admin role)
- lpSafe (LP role)

Note the order of dependencies: a contract requires contracts
above it in the list to be deployed first. Thus we need
to deploy in the order given, starting with the Safes.

*/
contract NewDeployment is Ownable, ReentrancyGuard, DeploymentConstants {
    using Address for address;

    struct Factories {
        ProxyAdminFactory proxyAdminFactory;
        ProxyFactoryV2 proxyFactory;
        AddressRegistryV2FactoryV2 addressRegistryV2Factory;
        MetaPoolTokenFactory mAptFactory;
        PoolTokenV1Factory poolTokenV1Factory;
        PoolTokenV2Factory poolTokenV2Factory;
        TvlManagerFactory tvlManagerFactory;
        Erc20AllocationFactory erc20AllocationFactory;
        OracleAdapterFactory oracleAdapterFactory;
        LpAccountFactory lpAccountFactory;
    }

    struct Safes {
        IGnosisModuleManager lpSafe;
        IGnosisModuleManager adminSafe;
        IGnosisModuleManager emergencySafe;
    }

    struct Dependency {
        bytes32 registeredId;
        address registeredAddress;
    }

    // TODO: figure out a versioning scheme
    string public constant VERSION = "1.0.0";

    address private constant FAKE_AGG_ADDRESS =
        0xCAfEcAfeCAfECaFeCaFecaFecaFECafECafeCaFe;

    ProxyAdminFactory public immutable proxyAdminFactory;
    ProxyFactoryV2 public immutable proxyFactory;
    AddressRegistryV2FactoryV2 public immutable addressRegistryV2Factory;
    MetaPoolTokenFactory public immutable mAptFactory;
    PoolTokenV1Factory public immutable poolTokenV1Factory;
    PoolTokenV2Factory public immutable poolTokenV2Factory;
    TvlManagerFactory public immutable tvlManagerFactory;
    Erc20AllocationFactory public immutable erc20AllocationFactory;
    OracleAdapterFactory public immutable oracleAdapterFactory;
    LpAccountFactory public immutable lpAccountFactory;

    IGnosisModuleManager public immutable emergencySafe;
    IGnosisModuleManager public immutable adminSafe;
    IGnosisModuleManager public immutable lpSafe;

    uint256 public step;

    // step 0
    AddressRegistryV2 public addressRegistryV2;

    // step 1
    address public mApt;

    // step 2
    address public poolTokenV2;

    // step 3
    address public daiPool;
    address public usdcPool;
    address public usdtPool;

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
            addressRegistryV2.getAddress("emergencySafe") ==
                address(emergencySafe),
            "INVALID_EMERGENCY_SAFE"
        );

        require(
            addressRegistryV2.getAddress("adminSafe") == address(adminSafe),
            "INVALID_ADMIN_SAFE"
        );

        require(
            addressRegistryV2.getAddress("lpSafe") == address(lpSafe),
            "INVALID_LP_SAFE"
        );

        _;
    }

    modifier checkAddressRegistryOwnership() {
        address[] memory ownerships = new address[](1);
        ownerships[0] = address(addressRegistryV2);
        _checkOwnerships(ownerships);

        _;
    }

    constructor(Factories memory factories, Safes memory safes) public {
        proxyAdminFactory = factories.proxyAdminFactory;
        proxyFactory = factories.proxyFactory;
        addressRegistryV2Factory = factories.addressRegistryV2Factory;
        mAptFactory = factories.mAptFactory;
        poolTokenV1Factory = factories.poolTokenV1Factory;
        poolTokenV2Factory = factories.poolTokenV2Factory;
        tvlManagerFactory = factories.tvlManagerFactory;
        erc20AllocationFactory = factories.erc20AllocationFactory;
        oracleAdapterFactory = factories.oracleAdapterFactory;
        lpAccountFactory = factories.lpAccountFactory;

        emergencySafe = safes.emergencySafe;
        adminSafe = safes.adminSafe;
        lpSafe = safes.lpSafe;
    }

    function deploy0AddressRegistryV2()
        external
        onlyOwner
        nonReentrant
        updateStep(0)
    {
        address proxyAdmin = proxyAdminFactory.create();

        bytes memory initData =
            abi.encodeWithSelector(
                AddressRegistryV2.initialize.selector,
                proxyAdmin
            );

        addressRegistryV2 = AddressRegistryV2(
            addressRegistryV2Factory.create(
                address(proxyFactory),
                proxyAdmin,
                initData
            )
        );

        ProxyAdmin(proxyAdmin).transferOwnership(address(adminSafe));
    }

    function deploy1RegisterSafes()
        external
        onlyOwner
        nonReentrant
        checkAddressRegistryOwnership
        updateStep(1)
    {
        _registerAddress("lpSafe", address(lpSafe));
        _registerAddress("adminSafe", address(adminSafe));
        _registerAddress("emergencySafe", address(emergencySafe));
    }

    function deploy2MetaPoolToken()
        external
        onlyOwner
        nonReentrant
        updateStep(2)
        checkAddressRegistryOwnership
        checkSafeRegistrations
    {
        address proxyAdmin = proxyAdminFactory.create();

        bytes memory initData =
            abi.encodeWithSelector(
                MetaPoolToken.initialize.selector,
                addressRegistryV2
            );

        mApt = mAptFactory.create(address(proxyFactory), proxyAdmin, initData);

        _registerAddress("mApt", mApt);

        ProxyAdmin(proxyAdmin).transferOwnership(address(adminSafe));
    }

    function deploy3DaiPoolTokenV2()
        external
        onlyOwner
        nonReentrant
        updateStep(3)
        checkAddressRegistryOwnership
        checkSafeRegistrations
    {
        daiPool = _deployPool(DAI_ADDRESS, "daiPool");
    }

    function deploy4UsdcPoolTokenV2()
        external
        onlyOwner
        nonReentrant
        updateStep(4)
        checkAddressRegistryOwnership
        checkSafeRegistrations
    {
        usdcPool = _deployPool(USDC_ADDRESS, "usdcPool");
    }

    function deploy5UsdtPoolTokenV2()
        external
        onlyOwner
        nonReentrant
        updateStep(5)
        checkAddressRegistryOwnership
        checkSafeRegistrations
    {
        usdtPool = _deployPool(USDT_ADDRESS, "usdtPool");
    }

    function deploy6TvlManager()
        external
        onlyOwner
        nonReentrant
        updateStep(6)
        checkAddressRegistryOwnership
        checkSafeRegistrations
    {
        tvlManager = tvlManagerFactory.create(address(addressRegistryV2));

        _registerAddress("tvlManager", tvlManager);

        erc20Allocation = erc20AllocationFactory.create(
            address(addressRegistryV2)
        );

        _registerAddress("erc20Allocation", erc20Allocation);
    }

    function deploy7LpAccount()
        external
        onlyOwner
        nonReentrant
        updateStep(7)
        checkAddressRegistryOwnership
        checkSafeRegistrations
    {
        Dependency[] memory dependencies = new Dependency[](1);
        dependencies[0] = Dependency("mApt", mApt);
        _checkRegisteredDependencies(dependencies);

        address proxyAdmin = proxyAdminFactory.create();

        bytes memory initData =
            abi.encodeWithSelector(
                LpAccount.initialize.selector,
                address(addressRegistryV2)
            );

        lpAccount = lpAccountFactory.create(
            address(proxyFactory),
            proxyAdmin,
            initData
        );

        _registerAddress("lpAccount", lpAccount);

        ProxyAdmin(proxyAdmin).transferOwnership(address(adminSafe));
    }

    function deploy8OracleAdapter()
        external
        onlyOwner
        nonReentrant
        updateStep(8)
        checkAddressRegistryOwnership
        checkSafeRegistrations
    {
        Dependency[] memory dependencies = new Dependency[](4);
        dependencies[0] = Dependency("mApt", mApt);
        dependencies[1] = Dependency("lpAccount", lpAccount);
        dependencies[2] = Dependency("tvlManager", tvlManager);
        dependencies[3] = Dependency("erc20Allocation", erc20Allocation);
        _checkRegisteredDependencies(dependencies);

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

        oracleAdapter = oracleAdapterFactory.create(
            address(addressRegistryV2),
            TVL_AGG_ADDRESS,
            assets,
            sources,
            aggStalePeriod,
            defaultLockPeriod
        );

        _registerAddress("oracleAdapter", oracleAdapter);
    }

    function deploy9TransferOwnership()
        external
        onlyOwner
        nonReentrant
        updateStep(9)
        checkAddressRegistryOwnership
        checkSafeRegistrations
    {
        AddressRegistryV2(addressRegistryV2).transferOwnership(
            address(adminSafe)
        );
    }

    function _registerAddress(bytes32 id, address address_) internal {
        addressRegistryV2.registerAddress(id, address_);

        //bytes memory data =
        //    abi.encodeWithSelector(
        //        AddressRegistryV2.registerAddress.selector,
        //        id,
        //        address_
        //    );

        //require(
        //    adminSafe.execTransactionFromModule(
        //        address(addressRegistryV2),
        //        0,
        //        data,
        //        Enum.Operation.Call
        //    ),
        //    "SAFE_TX_FAILED"
        //);
    }

    function _deployPool(address token, bytes32 id) internal returns (address) {
        Dependency[] memory dependencies = new Dependency[](1);
        dependencies[0] = Dependency("mApt", mApt);
        _checkRegisteredDependencies(dependencies);

        address proxyAdmin = proxyAdminFactory.create();

        bytes memory initData =
            abi.encodeWithSelector(
                PoolTokenV2.initialize.selector,
                proxyAdmin,
                token,
                FAKE_AGG_ADDRESS
            );

        address proxy =
            poolTokenV1Factory.create(
                address(proxyFactory),
                proxyAdmin,
                initData
            );

        address logic = poolTokenV2Factory.create(initData);

        bytes memory upgradeData =
            abi.encodeWithSelector(
                PoolTokenV2.initializeUpgrade.selector,
                address(addressRegistryV2)
            );

        ProxyAdmin(proxyAdmin).upgradeAndCall(
            TransparentUpgradeableProxy(payable(proxy)),
            logic,
            upgradeData
        );

        ProxyAdmin(proxyAdmin).transferOwnership(address(adminSafe));

        _registerAddress(id, proxy);

        return proxy;
    }

    /**
     * @dev Check the deployment contract has ownership of necessary
     * contracts to perform actions, e.g. register an address or upgrade
     * a proxy.
     *
     * @param ownedContracts addresses that should be owned by the admin Safe
     */
    function _checkOwnerships(address[] memory ownedContracts)
        internal
        view
        virtual
    {
        for (uint256 i = 0; i < ownedContracts.length; i++) {
            require(
                Ownable(ownedContracts[i]).owner() == address(this),
                "MISSING_OWNERSHIP"
            );
        }
    }

    /**
     * @dev Check a contract address from a previous step's deployment
     * is registered with expected ID.
     *
     * @param dependencies Pairs of IDs and addresses that should be registered
     */
    function _checkRegisteredDependencies(Dependency[] memory dependencies)
        internal
        view
        virtual
    {
        for (uint256 i = 0; i < dependencies.length; i++) {
            require(
                addressRegistryV2.getAddress(dependencies[i].registeredId) ==
                    dependencies[i].registeredAddress,
                "MISSING_DEPLOYED_ADDRESS"
            );
        }
    }
}

