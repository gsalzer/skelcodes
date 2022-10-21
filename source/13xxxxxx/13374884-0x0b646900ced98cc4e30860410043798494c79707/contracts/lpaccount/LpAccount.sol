// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {
    IAssetAllocation,
    IERC20,
    IEmergencyExit
} from "contracts/common/Imports.sol";
import {
    Address,
    NamedAddressSet,
    SafeERC20
} from "contracts/libraries/Imports.sol";
import {
    Initializable,
    ReentrancyGuardUpgradeSafe,
    AccessControlUpgradeSafe
} from "contracts/proxy/Imports.sol";
import {ILiquidityPoolV2} from "contracts/pool/Imports.sol";
import {IAddressRegistryV2} from "contracts/registry/Imports.sol";
import {
    IAssetAllocationRegistry,
    IErc20Allocation,
    Erc20AllocationConstants
} from "contracts/tvl/Imports.sol";

import {
    IZap,
    ISwap,
    ILpAccount,
    IZapRegistry,
    ISwapRegistry
} from "./Imports.sol";

import {ILockingOracle} from "contracts/oracle/Imports.sol";

contract LpAccount is
    Initializable,
    AccessControlUpgradeSafe,
    ReentrancyGuardUpgradeSafe,
    ILpAccount,
    IZapRegistry,
    ISwapRegistry,
    Erc20AllocationConstants,
    IEmergencyExit
{
    using Address for address;
    using SafeERC20 for IERC20;
    using NamedAddressSet for NamedAddressSet.ZapSet;
    using NamedAddressSet for NamedAddressSet.SwapSet;

    uint256 private constant _DEFAULT_LOCK_PERIOD = 135;

    IAddressRegistryV2 public addressRegistry;
    uint256 public lockPeriod;

    NamedAddressSet.ZapSet private _zaps;
    NamedAddressSet.SwapSet private _swaps;

    /** @notice Log when the address registry is changed */
    event AddressRegistryChanged(address);

    /** @notice Log when the lock period is changed */
    event LockPeriodChanged(uint256);

    /**
     * @dev Since the proxy delegate calls to this "logic" contract, any
     * storage set by the logic contract's constructor during deploy is
     * disregarded and this function is needed to initialize the proxy
     * contract's storage according to this contract's layout.
     *
     * Since storage is not set yet, there is no simple way to protect
     * calling this function with owner modifiers.  Thus the OpenZeppelin
     * `initializer` modifier protects this function from being called
     * repeatedly.  It should be called during the deployment so that
     * it cannot be called by someone else later.
     */
    function initialize(address addressRegistry_) external initializer {
        // initialize ancestor storage
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __ReentrancyGuard_init_unchained();

        // initialize impl-specific storage
        _setAddressRegistry(addressRegistry_);
        _setupRole(DEFAULT_ADMIN_ROLE, addressRegistry.emergencySafeAddress());
        _setupRole(EMERGENCY_ROLE, addressRegistry.emergencySafeAddress());
        _setupRole(ADMIN_ROLE, addressRegistry.adminSafeAddress());
        _setupRole(LP_ROLE, addressRegistry.lpSafeAddress());
        _setupRole(CONTRACT_ROLE, addressRegistry.mAptAddress());

        lockPeriod = _DEFAULT_LOCK_PERIOD;
    }

    /**
     * @dev Dummy function to show how one would implement an init function
     * for future upgrades.  Note the `initializer` modifier can only be used
     * once in the entire contract, so we can't use it here.  Instead, we
     * protect the upgrade init with the `onlyProxyAdmin` modifier, which
     * checks `msg.sender` against the proxy admin slot defined in EIP-1967.
     * This will only allow the proxy admin to call this function during upgrades.
     */
    // solhint-disable-next-line no-empty-blocks
    function initializeUpgrade() external virtual nonReentrant onlyProxyAdmin {}

    /**
     * @notice Sets the address registry
     * @param addressRegistry_ the address of the registry
     */
    function emergencySetAddressRegistry(address addressRegistry_)
        external
        nonReentrant
        onlyEmergencyRole
    {
        _setAddressRegistry(addressRegistry_);
    }

    /**
     * @notice Set the lock period
     * @param lockPeriod_ The new lock period
     */
    function setLockPeriod(uint256 lockPeriod_)
        external
        nonReentrant
        onlyAdminRole
    {
        lockPeriod = lockPeriod_;
        emit LockPeriodChanged(lockPeriod_);
    }

    function deployStrategy(string calldata name, uint256[] calldata amounts)
        external
        override
        nonReentrant
        onlyLpRole
    {
        IZap zap = _zaps.get(name);
        require(address(zap) != address(0), "INVALID_NAME");

        bool isAssetAllocationRegistered =
            _checkAllocationRegistrations(zap.assetAllocations());
        require(isAssetAllocationRegistered, "MISSING_ASSET_ALLOCATIONS");

        bool isErc20TokenRegistered =
            _checkErc20Registrations(zap.erc20Allocations());
        require(isErc20TokenRegistered, "MISSING_ERC20_ALLOCATIONS");

        address(zap).functionDelegateCall(
            abi.encodeWithSelector(IZap.deployLiquidity.selector, amounts)
        );
        _lockOracleAdapter(lockPeriod);
    }

    function unwindStrategy(
        string calldata name,
        uint256 amount,
        uint8 index
    ) external override nonReentrant onlyLpRole {
        address zap = address(_zaps.get(name));
        require(zap != address(0), "INVALID_NAME");

        zap.functionDelegateCall(
            abi.encodeWithSelector(IZap.unwindLiquidity.selector, amount, index)
        );
        _lockOracleAdapter(lockPeriod);
    }

    function registerZap(IZap zap)
        external
        override
        nonReentrant
        onlyAdminRole
    {
        _zaps.add(zap);

        emit ZapRegistered(zap);
    }

    function removeZap(string calldata name)
        external
        override
        nonReentrant
        onlyAdminRole
    {
        _zaps.remove(name);

        emit ZapRemoved(name);
    }

    function transferToPool(address pool, uint256 amount)
        external
        override
        nonReentrant
        onlyContractRole
    {
        IERC20 underlyer = ILiquidityPoolV2(pool).underlyer();
        underlyer.safeTransfer(pool, amount);
    }

    function swap(
        string calldata name,
        uint256 amount,
        uint256 minAmount
    ) external override nonReentrant onlyLpRole {
        ISwap swap_ = _swaps.get(name);
        require(address(swap_) != address(0), "INVALID_NAME");

        bool isErc20TokenRegistered =
            _checkErc20Registrations(swap_.erc20Allocations());

        require(isErc20TokenRegistered, "MISSING_ERC20_ALLOCATIONS");

        address(swap_).functionDelegateCall(
            abi.encodeWithSelector(ISwap.swap.selector, amount, minAmount)
        );
        _lockOracleAdapter(lockPeriod);
    }

    function registerSwap(ISwap swap_)
        external
        override
        nonReentrant
        onlyAdminRole
    {
        _swaps.add(swap_);

        emit SwapRegistered(swap_);
    }

    function removeSwap(string calldata name)
        external
        override
        nonReentrant
        onlyAdminRole
    {
        _swaps.remove(name);

        emit SwapRemoved(name);
    }

    function claim(string calldata name)
        external
        override
        nonReentrant
        onlyLpRole
    {
        IZap zap = _zaps.get(name);
        require(address(zap) != address(0), "INVALID_NAME");

        bool isErc20TokenRegistered =
            _checkErc20Registrations(zap.erc20Allocations());
        require(isErc20TokenRegistered, "MISSING_ERC20_ALLOCATIONS");

        address(zap).functionDelegateCall(
            abi.encodeWithSelector(IZap.claim.selector)
        );
        _lockOracleAdapter(lockPeriod);
    }

    function emergencyExit(address token) external override onlyEmergencyRole {
        address emergencySafe = addressRegistry.emergencySafeAddress();
        IERC20 token_ = IERC20(token);
        uint256 balance = token_.balanceOf(address(this));
        token_.safeTransfer(emergencySafe, balance);

        emit EmergencyExit(emergencySafe, token_, balance);
    }

    function zapNames() external view override returns (string[] memory) {
        return _zaps.names();
    }

    function swapNames() external view override returns (string[] memory) {
        return _swaps.names();
    }

    /**
     * @notice Lock oracle adapter for the configured period
     * @param lockPeriod_ The number of blocks to lock for
     */
    function _lockOracleAdapter(uint256 lockPeriod_) internal {
        ILockingOracle oracleAdapter =
            ILockingOracle(addressRegistry.oracleAdapterAddress());
        oracleAdapter.lockFor(lockPeriod_);
    }

    function _setAddressRegistry(address addressRegistry_) internal {
        require(Address.isContract(addressRegistry_), "INVALID_ADDRESS");
        addressRegistry = IAddressRegistryV2(addressRegistry_);
        emit AddressRegistryChanged(addressRegistry_);
    }

    /**
     * @notice Check if multiple asset allocations are ALL registered
     * @param allocationNames An array of asset allocation names to check
     * @return `true` if every asset allocation is registered, otherwise `false`
     */
    function _checkAllocationRegistrations(string[] memory allocationNames)
        internal
        view
        returns (bool)
    {
        IAssetAllocationRegistry tvlManager =
            IAssetAllocationRegistry(addressRegistry.getAddress("tvlManager"));

        return tvlManager.isAssetAllocationRegistered(allocationNames);
    }

    /**
     * @notice Check if multiple ERC20 asset allocations are ALL registered
     * @param tokens An array of ERC20 tokens to check
     * @return `true` if every ERC20 is registered, otherwise `false`
     */
    function _checkErc20Registrations(IERC20[] memory tokens)
        internal
        view
        returns (bool)
    {
        IAssetAllocationRegistry tvlManager =
            IAssetAllocationRegistry(addressRegistry.getAddress("tvlManager"));
        IErc20Allocation erc20Allocation =
            IErc20Allocation(
                address(
                    tvlManager.getAssetAllocation(Erc20AllocationConstants.NAME)
                )
            );

        return erc20Allocation.isErc20TokenRegistered(tokens);
    }
}

