// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20, IDetailedERC20, Ownable} from "contracts/common/Imports.sol";
import {Address, SafeMath, SafeERC20} from "contracts/libraries/Imports.sol";
import {MetaPoolToken} from "contracts/mapt/MetaPoolToken.sol";
import {AggregatorV3Interface} from "contracts/oracle/Imports.sol";
import {PoolToken} from "contracts/pool/PoolToken.sol";
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
import {PoolTokenV2Factory} from "./factories/Imports.sol";
import {IGnosisModuleManager, Enum} from "./IGnosisModuleManager.sol";

/* solhint-disable max-states-count, func-name-mixedcase */
contract PoolTokenV2Upgrader is Ownable, DeploymentConstants {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // TODO: figure out a versioning scheme
    string public constant VERSION = "1.0.0";

    address private constant FAKE_AGG_ADDRESS =
        0xCAfEcAfeCAfECaFeCaFecaFecaFECafECafeCaFe;

    IAddressRegistryV2 public addressRegistry;

    address public poolTokenV2Factory;

    address public immutable emergencySafe;
    address public immutable adminSafe;
    address public immutable lpSafe;

    constructor(address poolTokenV2Factory_) public {
        addressRegistry = IAddressRegistryV2(ADDRESS_REGISTRY_PROXY);

        // The Safe addresses are also checked on each upgrade to ensure
        // they haven't changed.
        emergencySafe = addressRegistry.getAddress("emergencySafe");
        adminSafe = addressRegistry.getAddress("adminSafe");
        lpSafe = addressRegistry.getAddress("lpSafe");

        setPoolTokenV2Factory(poolTokenV2Factory_);
    }

    /// @notice upgrade from v1 to v2
    /// @dev register mAPT for a contract role
    function upgrade(address payable proxy) external onlyOwner {
        _upgrade(proxy);
    }

    /// @notice upgrade from v1 to v2
    /// @dev register mAPT for a contract role
    function upgradeAll() external onlyOwner {
        upgradeDaiPool();
        upgradeUsdcPool();
        upgradeUsdtPool();
    }

    function upgradeDaiPool() public onlyOwner {
        _upgrade(payable(DAI_POOL_PROXY));
    }

    function upgradeUsdcPool() public onlyOwner {
        _upgrade(payable(USDC_POOL_PROXY));
    }

    function upgradeUsdtPool() public onlyOwner {
        _upgrade(payable(USDT_POOL_PROXY));
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

    function deployV2Logic() public onlyOwner returns (address) {
        bytes memory initData =
            abi.encodeWithSelector(
                PoolTokenV2.initialize.selector,
                POOL_PROXY_ADMIN,
                IDetailedERC20(DAI_ADDRESS),
                AggregatorV3Interface(FAKE_AGG_ADDRESS)
            );
        address logic = PoolTokenV2Factory(poolTokenV2Factory).create(initData);
        return logic;
    }

    /// @dev register mAPT for a contract role
    function _upgrade(address payable proxy) internal {
        _checkSafeRegistrations();
        _checkEnabledModule();
        _checkOwnerships();

        address mApt = addressRegistry.mAptAddress();

        PoolToken poolV1 = PoolToken(payable(proxy));
        IERC20 underlyer = poolV1.underlyer();

        uint256 underlyerBalance = underlyer.balanceOf(address(this));
        require(underlyerBalance > 0, "FUND_UPGRADER_WITH_STABLE");

        underlyer.safeApprove(address(poolV1), 0);
        underlyer.safeApprove(address(poolV1), underlyerBalance);
        poolV1.addLiquidity(underlyerBalance);

        uint256 aptBalance = poolV1.balanceOf(address(this));
        require(aptBalance > 0, "USE_LARGER_DEPOSIT");

        uint256 allowance = aptBalance.div(2);
        require(allowance > 0, "USE_LARGER_DEPOSIT");
        poolV1.approve(msg.sender, allowance);

        address logicV2 = deployV2Logic();
        _executeUpgradeAsModule(proxy, logicV2, POOL_PROXY_ADMIN);

        PoolTokenV2 poolV2 = PoolTokenV2(proxy);
        // after upgrade, we need to check:
        // 1. _balances mapping uses the correct slot
        require(
            poolV2.balanceOf(address(this)) == aptBalance,
            "BALANCEOF_TEST_FAILED"
        );
        // 2. _allowances mapping uses the correct slot
        require(
            poolV2.allowance(address(this), msg.sender) == allowance,
            "ALLOWANCES_TEST_FAILED"
        );

        poolV2.redeem(aptBalance);
        // In theory, Tether can charge a fee, so pull balance again
        underlyerBalance = underlyer.balanceOf(address(this));
        underlyer.safeTransfer(msg.sender, underlyerBalance);

        require(
            poolV2.addressRegistry() == addressRegistry,
            "INCORRECT_ADDRESS_REGISTRY"
        );

        bytes32 DEFAULT_ADMIN_ROLE = poolV2.DEFAULT_ADMIN_ROLE();
        bytes32 EMERGENCY_ROLE = poolV2.EMERGENCY_ROLE();
        bytes32 ADMIN_ROLE = poolV2.ADMIN_ROLE();
        bytes32 CONTRACT_ROLE = poolV2.CONTRACT_ROLE();
        require(
            poolV2.hasRole(DEFAULT_ADMIN_ROLE, emergencySafe),
            "ROLE_TEST_FAILED"
        );
        require(
            poolV2.hasRole(EMERGENCY_ROLE, emergencySafe),
            "ROLE_TEST_FAILED"
        );
        require(poolV2.hasRole(ADMIN_ROLE, adminSafe), "ROLE_TEST_FAILED");
        require(poolV2.hasRole(CONTRACT_ROLE, mApt), "ROLE_TEST_FAILED");

        _lockPool(proxy);
    }

    function _executeUpgradeAsModule(
        address proxy,
        address logic,
        address proxyAdmin
    ) internal {
        bytes memory initData =
            abi.encodeWithSelector(
                PoolTokenV2.initializeUpgrade.selector,
                addressRegistry
            );
        bytes memory data =
            abi.encodeWithSelector(
                ProxyAdmin.upgradeAndCall.selector,
                TransparentUpgradeableProxy(payable(proxy)),
                logic,
                initData
            );

        require(
            IGnosisModuleManager(emergencySafe).execTransactionFromModule(
                proxyAdmin,
                0,
                data,
                Enum.Operation.Call
            ),
            "SAFE_TX_FAILED"
        );
    }

    function _lockPool(address proxy) internal {
        bytes memory data =
            abi.encodeWithSelector(
                PoolTokenV2.emergencyLockAddLiquidity.selector
            );
        require(
            IGnosisModuleManager(emergencySafe).execTransactionFromModule(
                proxy,
                0,
                data,
                Enum.Operation.Call
            ),
            "SAFE_TX_FAILED"
        );
    }

    /**
     * @dev Uses `getAddress` in case `AddressRegistry` has not been upgraded
     */
    function _checkSafeRegistrations() internal view {
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
    }

    function _checkEnabledModule() internal view {
        address[] memory emergencyModules =
            IGnosisModuleManager(emergencySafe).getModules();
        bool emergencyEnabled = false;
        for (uint256 i = 0; i < emergencyModules.length; i++) {
            if (emergencyModules[i] == address(this)) {
                emergencyEnabled = true;
                break;
            }
        }
        require(emergencyEnabled, "ENABLE_AS_EMERGENCY_MODULE");
    }

    function _checkOwnerships() internal view {
        require(
            Ownable(POOL_PROXY_ADMIN).owner() == emergencySafe,
            "MISSING_OWNERSHIP"
        );
    }
}
/* solhint-enable func-name-mixedcase */

