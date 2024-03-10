// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol@v4.3.2

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


// File @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol@v4.3.2





/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}


// File contracts/DAOStackInterfaces.sol





interface Avatar {
	function nativeToken() external view returns (address);

	function nativeReputation() external view returns (address);

	function owner() external view returns (address);
}

interface Controller {
	event RegisterScheme(address indexed _sender, address indexed _scheme);
	event UnregisterScheme(address indexed _sender, address indexed _scheme);

	function genericCall(
		address _contract,
		bytes calldata _data,
		address _avatar,
		uint256 _value
	) external returns (bool, bytes memory);

	function avatar() external view returns (address);

	function unregisterScheme(address _scheme, address _avatar)
		external
		returns (bool);

	function unregisterSelf(address _avatar) external returns (bool);

	function registerScheme(
		address _scheme,
		bytes32 _paramsHash,
		bytes4 _permissions,
		address _avatar
	) external returns (bool);

	function isSchemeRegistered(address _scheme, address _avatar)
		external
		view
		returns (bool);

	function getSchemePermissions(address _scheme, address _avatar)
		external
		view
		returns (bytes4);

	function addGlobalConstraint(
		address _constraint,
		bytes32 _paramHash,
		address _avatar
	) external returns (bool);

	function mintTokens(
		uint256 _amount,
		address _beneficiary,
		address _avatar
	) external returns (bool);

	function externalTokenTransfer(
		address _token,
		address _recipient,
		uint256 _amount,
		address _avatar
	) external returns (bool);

	function sendEther(
		uint256 _amountInWei,
		address payable _to,
		address _avatar
	) external returns (bool);
}

interface GlobalConstraintInterface {
	enum CallPhase {
		Pre,
		Post,
		PreAndPost
	}

	function pre(
		address _scheme,
		bytes32 _params,
		bytes32 _method
	) external returns (bool);

	/**
	 * @dev when return if this globalConstraints is pre, post or both.
	 * @return CallPhase enum indication  Pre, Post or PreAndPost.
	 */
	function when() external returns (CallPhase);
}

interface ReputationInterface {
	function balanceOf(address _user) external view returns (uint256);

	function balanceOfAt(address _user, uint256 _blockNumber)
		external
		view
		returns (uint256);

	function getVotes(address _user) external view returns (uint256);

	function getVotesAt(
		address _user,
		bool _global,
		uint256 _blockNumber
	) external view returns (uint256);

	function totalSupply() external view returns (uint256);

	function totalSupplyAt(uint256 _blockNumber)
		external
		view
		returns (uint256);

	function delegateOf(address _user) external returns (address);
}

interface SchemeRegistrar {
	function proposeScheme(
		Avatar _avatar,
		address _scheme,
		bytes32 _parametersHash,
		bytes4 _permissions,
		string memory _descriptionHash
	) external returns (bytes32);

	event NewSchemeProposal(
		address indexed _avatar,
		bytes32 indexed _proposalId,
		address indexed _intVoteInterface,
		address _scheme,
		bytes32 _parametersHash,
		bytes4 _permissions,
		string _descriptionHash
	);
}

interface IntVoteInterface {
	event NewProposal(
		bytes32 indexed _proposalId,
		address indexed _organization,
		uint256 _numOfChoices,
		address _proposer,
		bytes32 _paramsHash
	);

	event ExecuteProposal(
		bytes32 indexed _proposalId,
		address indexed _organization,
		uint256 _decision,
		uint256 _totalReputation
	);

	event VoteProposal(
		bytes32 indexed _proposalId,
		address indexed _organization,
		address indexed _voter,
		uint256 _vote,
		uint256 _reputation
	);

	event CancelProposal(
		bytes32 indexed _proposalId,
		address indexed _organization
	);
	event CancelVoting(
		bytes32 indexed _proposalId,
		address indexed _organization,
		address indexed _voter
	);

	/**
	 * @dev register a new proposal with the given parameters. Every proposal has a unique ID which is being
	 * generated by calculating keccak256 of a incremented counter.
	 * @param _numOfChoices number of voting choices
	 * @param _proposalParameters defines the parameters of the voting machine used for this proposal
	 * @param _proposer address
	 * @param _organization address - if this address is zero the msg.sender will be used as the organization address.
	 * @return proposal's id.
	 */
	function propose(
		uint256 _numOfChoices,
		bytes32 _proposalParameters,
		address _proposer,
		address _organization
	) external returns (bytes32);

	function vote(
		bytes32 _proposalId,
		uint256 _vote,
		uint256 _rep,
		address _voter
	) external returns (bool);

	function cancelVote(bytes32 _proposalId) external;

	function getNumberOfChoices(bytes32 _proposalId)
		external
		view
		returns (uint256);

	function isVotable(bytes32 _proposalId) external view returns (bool);

	/**
	 * @dev voteStatus returns the reputation voted for a proposal for a specific voting choice.
	 * @param _proposalId the ID of the proposal
	 * @param _choice the index in the
	 * @return voted reputation for the given choice
	 */
	function voteStatus(bytes32 _proposalId, uint256 _choice)
		external
		view
		returns (uint256);

	/**
	 * @dev isAbstainAllow returns if the voting machine allow abstain (0)
	 * @return bool true or false
	 */
	function isAbstainAllow() external pure returns (bool);

	/**
     * @dev getAllowedRangeOfChoices returns the allowed range of choices for a voting machine.
     * @return min - minimum number of choices
               max - maximum number of choices
     */
	function getAllowedRangeOfChoices()
		external
		pure
		returns (uint256 min, uint256 max);
}


// File @openzeppelin/contracts-upgradeable/proxy/beacon/IBeaconUpgradeable.sol@v4.3.2





/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}


// File @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol@v4.3.2





/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


// File @openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol@v4.3.2





/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}


// File @openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol@v4.3.2








/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol@v4.3.2






/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}


// File contracts/utils/DataTypes.sol




library DataTypes {
	// refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
	struct ReserveData {
		//stores the reserve configuration
		ReserveConfigurationMap configuration;
		//the liquidity index. Expressed in ray
		uint128 liquidityIndex;
		//variable borrow index. Expressed in ray
		uint128 variableBorrowIndex;
		//the current supply rate. Expressed in ray
		uint128 currentLiquidityRate;
		//the current variable borrow rate. Expressed in ray
		uint128 currentVariableBorrowRate;
		//the current stable borrow rate. Expressed in ray
		uint128 currentStableBorrowRate;
		uint40 lastUpdateTimestamp;
		//tokens addresses
		address aTokenAddress;
		address stableDebtTokenAddress;
		address variableDebtTokenAddress;
		//address of the interest rate strategy
		address interestRateStrategyAddress;
		//the id of the reserve. Represents the position in the list of the active reserves
		uint8 id;
	}

	struct ReserveConfigurationMap {
		//bit 0-15: LTV
		//bit 16-31: Liq. threshold
		//bit 32-47: Liq. bonus
		//bit 48-55: Decimals
		//bit 56: Reserve is active
		//bit 57: reserve is frozen
		//bit 58: borrowing is enabled
		//bit 59: stable rate borrowing enabled
		//bit 60-63: reserved
		//bit 64-79: reserve factor
		uint256 data;
	}
	enum InterestRateMode { NONE, STABLE, VARIABLE }
}


// File contracts/Interfaces.sol







interface ERC20 {
	function balanceOf(address addr) external view returns (uint256);

	function transfer(address to, uint256 amount) external returns (bool);

	function approve(address spender, uint256 amount) external returns (bool);

	function decimals() external view returns (uint8);

	function mint(address to, uint256 mintAmount) external returns (uint256);

	function totalSupply() external view returns (uint256);

	function allowance(address owner, address spender)
		external
		view
		returns (uint256);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

	function name() external view returns (string memory);

	function symbol() external view returns (string memory);

	event Transfer(address indexed from, address indexed to, uint256 amount);
	event Transfer(
		address indexed from,
		address indexed to,
		uint256 amount,
		bytes data
	);
}

interface cERC20 is ERC20 {
	function mint(uint256 mintAmount) external returns (uint256);

	function redeemUnderlying(uint256 mintAmount) external returns (uint256);

	function redeem(uint256 mintAmount) external returns (uint256);

	function exchangeRateCurrent() external returns (uint256);

	function exchangeRateStored() external view returns (uint256);

	function underlying() external returns (address);
}

interface IGoodDollar is ERC20 {
	function getFees(uint256 value) external view returns (uint256, bool);

	function burn(uint256 amount) external;

	function burnFrom(address account, uint256 amount) external;

	function renounceMinter() external;

	function addMinter(address minter) external;

	function isMinter(address minter) external view returns (bool);

	function transferAndCall(
		address to,
		uint256 value,
		bytes calldata data
	) external returns (bool);

	function formula() external view returns (address);
}

interface IERC2917 is ERC20 {
	/// @dev This emit when interests amount per block is changed by the owner of the contract.
	/// It emits with the old interests amount and the new interests amount.
	event InterestRatePerBlockChanged(uint256 oldValue, uint256 newValue);

	/// @dev This emit when a users' productivity has changed
	/// It emits with the user's address and the the value after the change.
	event ProductivityIncreased(address indexed user, uint256 value);

	/// @dev This emit when a users' productivity has changed
	/// It emits with the user's address and the the value after the change.
	event ProductivityDecreased(address indexed user, uint256 value);

	/// @dev Return the current contract's interests rate per block.
	/// @return The amount of interests currently producing per each block.
	function interestsPerBlock() external view returns (uint256);

	/// @notice Change the current contract's interests rate.
	/// @dev Note the best practice will be restrict the gross product provider's contract address to call this.
	/// @return The true/fase to notice that the value has successfully changed or not, when it succeed, it will emite the InterestRatePerBlockChanged event.
	function changeInterestRatePerBlock(uint256 value) external returns (bool);

	/// @notice It will get the productivity of given user.
	/// @dev it will return 0 if user has no productivity proved in the contract.
	/// @return user's productivity and overall productivity.
	function getProductivity(address user)
		external
		view
		returns (uint256, uint256);

	/// @notice increase a user's productivity.
	/// @dev Note the best practice will be restrict the callee to prove of productivity's contract address.
	/// @return true to confirm that the productivity added success.
	function increaseProductivity(address user, uint256 value)
		external
		returns (bool);

	/// @notice decrease a user's productivity.
	/// @dev Note the best practice will be restrict the callee to prove of productivity's contract address.
	/// @return true to confirm that the productivity removed success.
	function decreaseProductivity(address user, uint256 value)
		external
		returns (bool);

	/// @notice take() will return the interests that callee will get at current block height.
	/// @dev it will always calculated by block.number, so it will change when block height changes.
	/// @return amount of the interests that user are able to mint() at current block height.
	function take() external view returns (uint256);

	/// @notice similar to take(), but with the block height joined to calculate return.
	/// @dev for instance, it returns (_amount, _block), which means at block height _block, the callee has accumulated _amount of interests.
	/// @return amount of interests and the block height.
	function takeWithBlock() external view returns (uint256, uint256);

	/// @notice mint the avaiable interests to callee.
	/// @dev once it mint, the amount of interests will transfer to callee's address.
	/// @return the amount of interests minted.
	function mint() external returns (uint256);
}

interface Staking {
	struct Staker {
		// The staked DAI amount
		uint256 stakedDAI;
		// The latest block number which the
		// staker has staked tokens
		uint256 lastStake;
	}

	function stakeDAI(uint256 amount) external;

	function withdrawStake() external;

	function stakers(address staker) external view returns (Staker memory);
}

interface Uniswap {
	function swapExactETHForTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function swapExactTokensForETH(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function WETH() external pure returns (address);

	function factory() external pure returns (address);

	function quote(
		uint256 amountA,
		uint256 reserveA,
		uint256 reserveB
	) external pure returns (uint256 amountB);

	function getAmountIn(
		uint256 amountOut,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256 amountIn);

	function getAmountOut(
		uint256 amountI,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256 amountOut);

	function getAmountsOut(uint256 amountIn, address[] memory path)
		external
		pure
		returns (uint256[] memory amounts);
}

interface UniswapFactory {
	function getPair(address tokenA, address tokenB)
		external
		view
		returns (address);
}

interface UniswapPair {
	function getReserves()
		external
		view
		returns (
			uint112 reserve0,
			uint112 reserve1,
			uint32 blockTimestampLast
		);

	function kLast() external view returns (uint256);

	function token0() external view returns (address);

	function token1() external view returns (address);

	function totalSupply() external view returns (uint256);

	function balanceOf(address owner) external view returns (uint256);
}

interface Reserve {
	function buy(
		address _buyWith,
		uint256 _tokenAmount,
		uint256 _minReturn
	) external returns (uint256);
}

interface IIdentity {
	function isWhitelisted(address user) external view returns (bool);

	function addWhitelistedWithDID(address account, string memory did) external;

	function removeWhitelisted(address account) external;

	function addIdentityAdmin(address account) external returns (bool);

	function setAvatar(address _avatar) external;

	function isIdentityAdmin(address account) external view returns (bool);

	function owner() external view returns (address);

	event WhitelistedAdded(address user);
}

interface IUBIScheme {
	function currentDay() external view returns (uint256);

	function periodStart() external view returns (uint256);

	function hasClaimed(address claimer) external view returns (bool);
}

interface IFirstClaimPool {
	function awardUser(address user) external returns (uint256);

	function claimAmount() external view returns (uint256);
}

interface ProxyAdmin {
	function getProxyImplementation(address proxy)
		external
		view
		returns (address);

	function getProxyAdmin(address proxy) external view returns (address);

	function upgrade(address proxy, address implementation) external;

	function owner() external view returns (address);

	function transferOwnership(address newOwner) external;
}

/**
 * @dev Interface for chainlink oracles to obtain price datas
 */
interface AggregatorV3Interface {
	function decimals() external view returns (uint8);

	function description() external view returns (string memory);

	function version() external view returns (uint256);

	// getRoundData and latestRoundData should both raise "No data present"
	// if they do not have data to report, instead of returning unset values
	// which could be misinterpreted as actual reported values.
	function getRoundData(uint80 _roundId)
		external
		view
		returns (
			uint80 roundId,
			int256 answer,
			uint256 startedAt,
			uint256 updatedAt,
			uint80 answeredInRound
		);

	function latestAnswer() external view returns (int256);
}

/**
	@dev interface for AAVE lending Pool
 */
interface ILendingPool {
	/**
	 * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
	 * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
	 * @param asset The address of the underlying asset to deposit
	 * @param amount The amount to be deposited
	 * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
	 *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
	 *   is a different wallet
	 * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
	 *   0 if the action is executed directly by the user, without any middle-man
	 **/
	function deposit(
		address asset,
		uint256 amount,
		address onBehalfOf,
		uint16 referralCode
	) external;

	/**
	 * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
	 * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
	 * @param asset The address of the underlying asset to withdraw
	 * @param amount The underlying amount to be withdrawn
	 *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
	 * @param to Address that will receive the underlying, same as msg.sender if the user
	 *   wants to receive it on his own wallet, or a different address if the beneficiary is a
	 *   different wallet
	 * @return The final amount withdrawn
	 **/
	function withdraw(
		address asset,
		uint256 amount,
		address to
	) external returns (uint256);

	/**
	 * @dev Returns the state and configuration of the reserve
	 * @param asset The address of the underlying asset of the reserve
	 * @return The state of the reserve
	 **/
	function getReserveData(address asset)
		external
		view
		returns (DataTypes.ReserveData memory);
}

interface IDonationStaking {
	function stakeDonations() external payable;
}

interface INameService {
	function getAddress(string memory _name) external view returns (address);
}

interface IAaveIncentivesController {
	/**
	 * @dev Claims reward for an user, on all the assets of the lending pool, accumulating the pending rewards
	 * @param amount Amount of rewards to claim
	 * @param to Address that will be receiving the rewards
	 * @return Rewards claimed
	 **/
	function claimRewards(
		address[] calldata assets,
		uint256 amount,
		address to
	) external returns (uint256);

	/**
	 * @dev Returns the total of rewards of an user, already accrued + not yet accrued
	 * @param user The address of the user
	 * @return The rewards
	 **/
	function getRewardsBalance(address[] calldata assets, address user)
		external
		view
		returns (uint256);
}

interface IGoodStaking {
	function collectUBIInterest(address recipient)
		external
		returns (
			uint256,
			uint256,
			uint256
		);

	function iToken() external view returns (address);

	function currentGains(
		bool _returnTokenBalanceInUSD,
		bool _returnTokenGainsInUSD
	)
		external
		view
		returns (
			uint256,
			uint256,
			uint256,
			uint256,
			uint256
		);

	function getRewardEarned(address user) external view returns (uint256);

	function getGasCostForInterestTransfer() external view returns (uint256);

	function rewardsMinted(
		address user,
		uint256 rewardsPerBlock,
		uint256 blockStart,
		uint256 blockEnd
	) external returns (uint256);
}

interface IHasRouter {
	function getRouter() external view returns (Uniswap);
}

interface IAdminWallet {
	function addAdmins(address payable[] memory _admins) external;

	function removeAdmins(address[] memory _admins) external;

	function owner() external view returns (address);

	function transferOwnership(address _owner) external;
}


// File contracts/utils/DAOContract.sol






/**
@title Simple contract that keeps DAO contracts registery
*/

contract DAOContract {
	Controller public dao;

	address public avatar;

	INameService public nameService;

	function _onlyAvatar() internal view {
		require(
			address(dao.avatar()) == msg.sender,
			"only avatar can call this method"
		);
	}

	function setDAO(INameService _ns) internal {
		nameService = _ns;
		updateAvatar();
	}

	function updateAvatar() public {
		dao = Controller(nameService.getAddress("CONTROLLER"));
		avatar = dao.avatar();
	}

	function nativeToken() public view returns (IGoodDollar) {
		return IGoodDollar(nameService.getAddress("GOODDOLLAR"));
	}

	uint256[50] private gap;
}


// File contracts/utils/DAOUpgradeableContract.sol






/**
@title Simple contract that adds upgradability to DAOContract
*/

contract DAOUpgradeableContract is Initializable, UUPSUpgradeable, DAOContract {
	function _authorizeUpgrade(address) internal virtual override {
		_onlyAvatar();
	}
}


// File contracts/governance/CompoundVotingMachine.sol





/**
 * based on https://github.com/compound-finance/compound-protocol/blob/b9b14038612d846b83f8a009a82c38974ff2dcfe/contracts/Governance/GovernorAlpha.sol
 * CompoundVotingMachine based on Compound's governance with a few differences
 * 1. no timelock. once vote has passed it stays open for 'queuePeriod' (2 days by default).
 * if vote decision has changed, execution will be delayed so at least 24 hours are left to vote.
 * 2. execution modified to support DAOStack Avatar/Controller
 */
contract CompoundVotingMachine is ContextUpgradeable, DAOUpgradeableContract {
	/// @notice The name of this contract
	string public constant name = "GoodDAO Voting Machine";

	/// @notice timestamp when foundation releases guardian veto rights
	uint64 public foundationGuardianRelease;

	/// @notice the number of blocks a proposal is open for voting (before passing quorum)
	uint256 public votingPeriod;

	/// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
	uint256 public quoromPercentage;

	function quorumVotes() public view returns (uint256) {
		return (rep.totalSupply() * quoromPercentage) / 1000000;
	} //3%

	/// @notice The number of votes required in order for a voter to become a proposer
	uint256 public proposalPercentage;

	function proposalThreshold(uint256 blockNumber)
		public
		view
		returns (uint256)
	{
		return (rep.totalSupplyAt(blockNumber) * proposalPercentage) / 1000000; //0.25%
	}

	/// @notice The maximum number of actions that can be included in a proposal
	uint256 public proposalMaxOperations; //10

	/// @notice The delay in blocks before voting on a proposal may take place, once proposed
	uint256 public votingDelay; //1 block

	/// @notice The duration of time after proposal passed thershold before it can be executed
	uint256 public queuePeriod; // 2 days

	/// @notice The duration of time after proposal passed with absolute majority before it can be executed
	uint256 public fastQueuePeriod; //1 days/8 = 3hours

	/// @notice During the queue period if vote decision has changed, we extend queue period time duration so
	/// that at least gameChangerPeriod is left
	uint256 public gameChangerPeriod; //1 day

	/// @notice the duration of time a succeeded proposal has to be executed on the blockchain
	uint256 public gracePeriod; // 3days

	/// @notice The address of the DAO reputation token
	ReputationInterface public rep;

	/// @notice The address of the Governor Guardian
	address public guardian;

	/// @notice The total number of proposals
	uint256 public proposalCount;

	struct Proposal {
		// Unique id for looking up a proposal
		uint256 id;
		// Creator of the proposal
		address proposer;
		// The timestamp that the proposal will be available for execution, set once the vote succeeds
		uint256 eta;
		// the ordered list of target addresses for calls to be made
		address[] targets;
		// The ordered list of values (i.e. msg.value) to be passed to the calls to be made
		uint256[] values;
		// The ordered list of function signatures to be called
		string[] signatures;
		// The ordered list of calldata to be passed to each call
		bytes[] calldatas;
		// The block at which voting begins: holders must delegate their votes prior to this block
		uint256 startBlock;
		// The block at which voting ends: votes must be cast prior to this block
		uint256 endBlock;
		// Current number of votes in favor of this proposal
		uint256 forVotes;
		// Current number of votes in opposition to this proposal
		uint256 againstVotes;
		// Flag marking whether the proposal has been canceled
		bool canceled;
		// Flag marking whether the proposal has been executed
		bool executed;
		// Receipts of ballots for the entire set of voters
		mapping(address => Receipt) receipts;
		// quorom required at time of proposing
		uint256 quoromRequired;
		// support proposal voting bridge
		uint256 forBlockchain;
	}

	/// @notice Ballot receipt record for a voter
	struct Receipt {
		//Whether or not a vote has been cast
		bool hasVoted;
		// Whether or not the voter supports the proposal
		bool support;
		// The number of votes the voter had, which were cast
		uint256 votes;
	}

	/// @notice Possible states that a proposal may be in
	enum ProposalState {
		Pending,
		Active,
		ActiveTimelock, // passed quorom, time lock of 2 days activated, still open for voting
		Canceled,
		Defeated,
		Succeeded,
		// Queued, we dont have queued status, we use game changer period instead
		Expired,
		Executed
	}

	/// @notice The official record of all proposals ever proposed
	mapping(uint256 => Proposal) public proposals;

	/// @notice The latest proposal for each proposer
	mapping(address => uint256) public latestProposalIds;

	/// @notice The EIP-712 typehash for the contract's domain
	bytes32 public constant DOMAIN_TYPEHASH =
		keccak256(
			"EIP712Domain(string name,uint256 chainId,address verifyingContract)"
		);

	/// @notice The EIP-712 typehash for the ballot struct used by the contract
	bytes32 public constant BALLOT_TYPEHASH =
		keccak256("Ballot(uint256 proposalId,bool support)");

	/// @notice An event emitted when a new proposal is created
	event ProposalCreated(
		uint256 id,
		address proposer,
		address[] targets,
		uint256[] values,
		string[] signatures,
		bytes[] calldatas,
		uint256 startBlock,
		uint256 endBlock,
		string description
	);

	/// @notice An event emitted when using blockchain proposal bridge
	event ProposalSucceeded(
		uint256 id,
		address proposer,
		address[] targets,
		uint256[] values,
		string[] signatures,
		bytes[] calldatas,
		uint256 startBlock,
		uint256 endBlock,
		uint256 forBlockchain,
		uint256 eta,
		uint256 forVotes,
		uint256 againstVotes
	);

	/// @notice event when proposal made for a different blockchain
	event ProposalBridge(uint256 id, uint256 indexed forBlockchain);

	/// @notice An event emitted when a vote has been cast on a proposal
	event VoteCast(
		address voter,
		uint256 proposalId,
		bool support,
		uint256 votes
	);

	/// @notice An event emitted when a proposal has been canceled
	event ProposalCanceled(uint256 id);

	/// @notice An event emitted when a proposal has been queued
	event ProposalQueued(uint256 id, uint256 eta);

	/// @notice An event emitted when a proposal has been executed
	event ProposalExecuted(uint256 id);

	/// @notice An event emitted when a proposal call has been executed
	event ProposalExecutionResult(
		uint256 id,
		uint256 index,
		bool ok,
		bytes result
	);

	event GuardianSet(address newGuardian);

	event ParametersSet(uint256[9] params);

	function initialize(
		INameService ns_, // the DAO avatar
		uint256 votingPeriodBlocks_, //number of blocks a proposal is open for voting before expiring
		address guardian_,
		address reputation_
	) public initializer {
		foundationGuardianRelease = 1672531200; //01/01/2023
		setDAO(ns_);
		rep = ReputationInterface(reputation_);

		uint256[9] memory params = [
			votingPeriodBlocks_,
			30000, //3% quorum
			2500, //0.25% proposing threshold
			10, //max operations
			1, //voting delay blocks
			2 days, //queue period
			1 days / 8, //fast queue period
			1 days, //game change period
			3 days //grace period
		];
		_setVotingParameters(params);
		guardian = guardian_;
	}

	//upgrade to fix bad guardian deployment
	function fixGuardian(address _guardian) public {
		if (guardian == address(0x4659176E962763e7C8A4eF965ecfD0fdf9f52057)) {
			guardian = _guardian;
		}
	}

	function updateRep() public {
		rep = ReputationInterface(nameService.getAddress("REPUTATION"));
	}

	///@notice set the different voting parameters, value of 0 is ignored
	///cell 0 - votingPeriod blocks, 1 - quoromPercentage, 2 - proposalPercentage,3 - proposalMaxOperations, 4 - voting delay blocks, 5 - queuePeriod time
	///6 - fastQueuePeriod time, 7 - gameChangerPeriod time, 8 - gracePeriod	time
	function setVotingParameters(uint256[9] calldata _newParams) external {
		_onlyAvatar();
		_setVotingParameters(_newParams);
	}

	function _setVotingParameters(uint256[9] memory _newParams) internal {
		require(
			(quoromPercentage == 0 || _newParams[1] <= quoromPercentage * 2) &&
				_newParams[1] < 1000000,
			"percentage should not double"
		);
		require(
			(proposalPercentage == 0 || _newParams[2] <= proposalPercentage * 2) &&
				_newParams[2] < 1000000,
			"percentage should not double"
		);
		votingPeriod = _newParams[0] > 0 ? _newParams[0] : votingPeriod;
		quoromPercentage = _newParams[1] > 0 ? _newParams[1] : quoromPercentage;
		proposalPercentage = _newParams[2] > 0 ? _newParams[2] : proposalPercentage;
		proposalMaxOperations = _newParams[3] > 0
			? _newParams[3]
			: proposalMaxOperations;
		votingDelay = _newParams[4] > 0 ? _newParams[4] : votingDelay;
		queuePeriod = _newParams[5] > 0 ? _newParams[5] : queuePeriod;
		fastQueuePeriod = _newParams[6] > 0 ? _newParams[6] : fastQueuePeriod;
		gameChangerPeriod = _newParams[7] > 0 ? _newParams[7] : gameChangerPeriod;
		gracePeriod = _newParams[8] > 0 ? _newParams[8] : gracePeriod;

		emit ParametersSet(_newParams);
	}

	/// @notice make a proposal to be voted on
	/// @param targets list of contracts to be excuted on
	/// @param values list of eth value to be used in each contract call
	/// @param signatures the list of functions to execute
	/// @param calldatas the list of parameters to pass to each function
	/// @return uint256 proposal id
	function propose(
		address[] memory targets,
		uint256[] memory values,
		string[] memory signatures,
		bytes[] memory calldatas,
		string memory description
	) public returns (uint256) {
		return
			propose(
				targets,
				values,
				signatures,
				calldatas,
				description,
				getChainId()
			);
	}

	/// @notice make a proposal to be voted on
	/// @param targets list of contracts to be excuted on
	/// @param values list of eth value to be used in each contract call
	/// @param signatures the list of functions to execute
	/// @param calldatas the list of parameters to pass to each function
	/// @return uint256 proposal id
	function propose(
		address[] memory targets,
		uint256[] memory values,
		string[] memory signatures,
		bytes[] memory calldatas,
		string memory description,
		uint256 forBlockchain
	) public returns (uint256) {
		require(
			rep.getVotesAt(_msgSender(), true, block.number - 1) >
				proposalThreshold(block.number - 1),
			"CompoundVotingMachine::propose: proposer votes below proposal threshold"
		);
		require(
			targets.length == values.length &&
				targets.length == signatures.length &&
				targets.length == calldatas.length,
			"CompoundVotingMachine::propose: proposal function information arity mismatch"
		);
		require(
			targets.length != 0,
			"CompoundVotingMachine::propose: must provide actions"
		);
		require(
			targets.length <= proposalMaxOperations,
			"CompoundVotingMachine::propose: too many actions"
		);

		uint256 latestProposalId = latestProposalIds[_msgSender()];

		if (latestProposalId != 0) {
			ProposalState proposersLatestProposalState = state(latestProposalId);
			require(
				proposersLatestProposalState != ProposalState.Active &&
					proposersLatestProposalState != ProposalState.ActiveTimelock,
				"CompoundVotingMachine::propose: one live proposal per proposer, found an already active proposal"
			);
			require(
				proposersLatestProposalState != ProposalState.Pending,
				"CompoundVotingMachine::propose: one live proposal per proposer, found an already pending proposal"
			);
		}

		uint256 startBlock = block.number + votingDelay;
		uint256 endBlock = startBlock + votingPeriod;

		proposalCount++;
		Proposal storage newProposal = proposals[proposalCount];
		newProposal.id = proposalCount;
		newProposal.proposer = _msgSender();
		newProposal.eta = 0;
		newProposal.targets = targets;
		newProposal.values = values;
		newProposal.signatures = signatures;
		newProposal.calldatas = calldatas;
		newProposal.startBlock = startBlock;
		newProposal.endBlock = endBlock;
		newProposal.forVotes = 0;
		newProposal.againstVotes = 0;
		newProposal.canceled = false;
		newProposal.executed = false;
		newProposal.quoromRequired = quorumVotes();
		newProposal.forBlockchain = forBlockchain;
		latestProposalIds[newProposal.proposer] = newProposal.id;

		emit ProposalCreated(
			newProposal.id,
			_msgSender(),
			targets,
			values,
			signatures,
			calldatas,
			startBlock,
			endBlock,
			description
		);

		if (getChainId() != forBlockchain) {
			emit ProposalBridge(proposalCount, forBlockchain);
		}

		return newProposal.id;
	}

	/// @notice helper to set the effective time of a proposal that passed quorom
	/// @dev also extends the ETA in case of a game changer in vote decision
	/// @param proposal the proposal to set the eta
	/// @param hasVoteChanged did the current vote changed the decision
	function _updateETA(Proposal storage proposal, bool hasVoteChanged) internal {
		//if absolute majority allow to execute quickly
		if (proposal.forVotes > rep.totalSupplyAt(proposal.startBlock) / 2) {
			proposal.eta = block.timestamp + fastQueuePeriod;
		}
		//first time we have a quorom we ask for a no change in decision period
		else if (proposal.eta == 0) {
			proposal.eta = block.timestamp + queuePeriod;
		}
		//if we have a gamechanger then we extend current eta to have at least gameChangerPeriod left
		else if (hasVoteChanged) {
			uint256 timeLeft = proposal.eta - block.timestamp;
			proposal.eta += timeLeft > gameChangerPeriod
				? 0
				: gameChangerPeriod - timeLeft;
		} else {
			return;
		}
		emit ProposalQueued(proposal.id, proposal.eta);
	}

	/// @notice execute the proposal list of transactions
	/// @dev anyone can call this once its ETA has arrived
	function execute(uint256 proposalId) public payable {
		require(
			state(proposalId) == ProposalState.Succeeded,
			"CompoundVotingMachine::execute: proposal can only be executed if it is succeeded"
		);

		require(
			proposals[proposalId].forBlockchain == getChainId(),
			"CompoundVotingMachine::execute: proposal for wrong blockchain"
		);

		proposals[proposalId].executed = true;
		address[] memory _targets = proposals[proposalId].targets;
		uint256[] memory _values = proposals[proposalId].values;
		string[] memory _signatures = proposals[proposalId].signatures;
		bytes[] memory _calldatas = proposals[proposalId].calldatas;

		for (uint256 i = 0; i < _targets.length; i++) {
			(bool ok, bytes memory result) = _executeTransaction(
				_targets[i],
				_values[i],
				_signatures[i],
				_calldatas[i]
			);
			emit ProposalExecutionResult(proposalId, i, ok, result);
		}
		emit ProposalExecuted(proposalId);
	}

	/// @notice internal helper to execute a single transaction of a proposal
	/// @dev special execution is done if target is a method in the DAO controller
	function _executeTransaction(
		address target,
		uint256 value,
		string memory signature,
		bytes memory data
	) internal returns (bool, bytes memory) {
		bytes memory callData;

		if (bytes(signature).length == 0) {
			callData = data;
		} else {
			callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
		}

		bool ok;
		bytes memory result;

		if (target == address(dao)) {
			(ok, result) = target.call{ value: value }(callData);
		} else {
			if (value > 0) payable(address(avatar)).transfer(value); //make sure avatar have the funds to pay
			(ok, result) = dao.genericCall(target, callData, address(avatar), value);
		}
		require(
			ok,
			"CompoundVotingMachine::executeTransaction: Transaction execution reverted."
		);

		return (ok, result);
	}

	/// @notice cancel a proposal in case proposer no longer holds the votes that were required to propose
	/// @dev could be cheating trying to bypass the single proposal per address by delegating to another address
	/// or when delegators do not concur with the proposal done in their name, they can withdraw
	function cancel(uint256 proposalId) public {
		ProposalState pState = state(proposalId);
		require(
			pState != ProposalState.Executed,
			"CompoundVotingMachine::cancel: cannot cancel executed proposal"
		);

		Proposal storage proposal = proposals[proposalId];
		require(
			_msgSender() == guardian ||
				rep.getVotesAt(proposal.proposer, true, block.number - 1) <
				proposalThreshold(proposal.startBlock),
			"CompoundVotingMachine::cancel: proposer above threshold"
		);

		proposal.canceled = true;

		emit ProposalCanceled(proposalId);
	}

	/// @notice get the actions to be done in a proposal
	function getActions(uint256 proposalId)
		public
		view
		returns (
			address[] memory targets,
			uint256[] memory values,
			string[] memory signatures,
			bytes[] memory calldatas
		)
	{
		Proposal storage p = proposals[proposalId];
		return (p.targets, p.values, p.signatures, p.calldatas);
	}

	/// @notice get the receipt of a single voter in a proposal
	function getReceipt(uint256 proposalId, address voter)
		public
		view
		returns (Receipt memory)
	{
		return proposals[proposalId].receipts[voter];
	}

	/// @notice get the current status of a proposal
	function state(uint256 proposalId) public view returns (ProposalState) {
		require(
			proposalCount >= proposalId && proposalId > 0,
			"CompoundVotingMachine::state: invalid proposal id"
		);

		Proposal storage proposal = proposals[proposalId];

		if (proposal.canceled) {
			return ProposalState.Canceled;
		} else if (block.number <= proposal.startBlock) {
			return ProposalState.Pending;
		} else if (proposal.executed) {
			return ProposalState.Executed;
		} else if (
			proposal.eta > 0 && block.timestamp < proposal.eta //passed quorum but not executed yet, in time lock
		) {
			return ProposalState.ActiveTimelock;
		} else if (
			//regular voting period
			proposal.eta == 0 && block.number <= proposal.endBlock
		) {
			//proposal is active if we are in the gameChanger period (eta) or no decision yet and in voting period
			return ProposalState.Active;
		} else if (
			proposal.forVotes <= proposal.againstVotes ||
			proposal.forVotes < proposal.quoromRequired
		) {
			return ProposalState.Defeated;
		} else if (
			proposal.eta > 0 && block.timestamp >= proposal.eta + gracePeriod
		) {
			//expired if not executed gracePeriod after eta
			return ProposalState.Expired;
		} else {
			return ProposalState.Succeeded;
		}
	}

	/// @notice cast your vote on a proposal
	/// @param proposalId the proposal to vote on
	/// @param support for or against
	function castVote(uint256 proposalId, bool support) public {
		//get all votes in all blockchains including delegated
		Proposal storage proposal = proposals[proposalId];
		uint256 votes = rep.getVotesAt(_msgSender(), true, proposal.startBlock);
		return _castVote(_msgSender(), proposal, support, votes);
	}

	struct VoteSig {
		bool support;
		uint8 v;
		bytes32 r;
		bytes32 s;
	}

	// function ecRecoverTest(
	// 	uint256 proposalId,
	// 	VoteSig[] memory votesFor,
	// 	VoteSig[] memory votesAgainst
	// ) public {
	// 	bytes32 domainSeparator =
	// 		keccak256(
	// 			abi.encode(
	// 				DOMAIN_TYPEHASH,
	// 				keccak256(bytes(name)),
	// 				getChainId(),
	// 				address(this)
	// 			)
	// 		);
	// 	bytes32 structHashFor =
	// 		keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, true));
	// 	bytes32 structHashAgainst =
	// 		keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, false));
	// 	bytes32 digestFor =
	// 		keccak256(
	// 			abi.encodePacked("\x19\x01", domainSeparator, structHashFor)
	// 		);
	// 	bytes32 digestAgainst =
	// 		keccak256(
	// 			abi.encodePacked("\x19\x01", domainSeparator, structHashAgainst)
	// 		);

	// 	Proposal storage proposal = proposals[proposalId];

	// 	uint256 total;
	// 	for (uint32 i = 0; i < votesFor.length; i++) {
	// 		bytes32 digest = digestFor;

	// 		address signatory =
	// 			ecrecover(digest, votesFor[i].v, votesFor[i].r, votesFor[i].s);
	// 		require(
	// 			signatory != address(0),
	// 			"CompoundVotingMachine::castVoteBySig: invalid signature"
	// 		);
	// 		require(
	// 			votesFor[i].support == true,
	// 			"CompoundVotingMachine::castVoteBySig: invalid support value in for batch"
	// 		);
	// 		total += rep.getVotesAt(signatory, true, proposal.startBlock);
	// 		Receipt storage receipt = proposal.receipts[signatory];
	// 		receipt.hasVoted = true;
	// 		receipt.support = true;
	// 	}
	// 	if (votesFor.length > 0) {
	// 		address voteAddressHash =
	// 			address(uint160(uint256(keccak256(abi.encode(votesFor)))));
	// 		_castVote(voteAddressHash, proposalId, true, total);
	// 	}

	// 	total = 0;
	// 	for (uint32 i = 0; i < votesAgainst.length; i++) {
	// 		bytes32 digest = digestAgainst;

	// 		address signatory =
	// 			ecrecover(
	// 				digest,
	// 				votesAgainst[i].v,
	// 				votesAgainst[i].r,
	// 				votesAgainst[i].s
	// 			);
	// 		require(
	// 			signatory != address(0),
	// 			"CompoundVotingMachine::castVoteBySig: invalid signature"
	// 		);
	// 		require(
	// 			votesAgainst[i].support == false,
	// 			"CompoundVotingMachine::castVoteBySig: invalid support value in against batch"
	// 		);
	// 		total += rep.getVotesAt(signatory, true, proposal.startBlock);
	// 		Receipt storage receipt = proposal.receipts[signatory];
	// 		receipt.hasVoted = true;
	// 		receipt.support = true;
	// 	}
	// 	if (votesAgainst.length > 0) {
	// 		address voteAddressHash =
	// 			address(uint160(uint256(keccak256(abi.encode(votesAgainst)))));
	// 		_castVote(voteAddressHash, proposalId, false, total);
	// 	}
	// }

	/// @notice helper to cast a vote for someone else by using eip712 signatures
	function castVoteBySig(
		uint256 proposalId,
		bool support,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public {
		bytes32 domainSeparator = keccak256(
			abi.encode(
				DOMAIN_TYPEHASH,
				keccak256(bytes(name)),
				getChainId(),
				address(this)
			)
		);
		bytes32 structHash = keccak256(
			abi.encode(BALLOT_TYPEHASH, proposalId, support)
		);
		bytes32 digest = keccak256(
			abi.encodePacked("\x19\x01", domainSeparator, structHash)
		);
		address signatory = ecrecover(digest, v, r, s);
		require(
			signatory != address(0),
			"CompoundVotingMachine::castVoteBySig: invalid signature"
		);

		//get all votes in all blockchains including delegated
		Proposal storage proposal = proposals[proposalId];
		uint256 votes = rep.getVotesAt(signatory, true, proposal.startBlock);
		return _castVote(signatory, proposal, support, votes);
	}

	/// @notice internal helper to cast a vote
	function _castVote(
		address voter,
		Proposal storage proposal,
		bool support,
		uint256 votes
	) internal {
		uint256 proposalId = proposal.id;
		require(
			state(proposalId) == ProposalState.Active ||
				state(proposalId) == ProposalState.ActiveTimelock,
			"CompoundVotingMachine::_castVote: voting is closed"
		);

		Receipt storage receipt = proposal.receipts[voter];
		require(
			receipt.hasVoted == false,
			"CompoundVotingMachine::_castVote: voter already voted"
		);

		bool hasChanged = proposal.forVotes > proposal.againstVotes;
		if (support) {
			proposal.forVotes += votes;
		} else {
			proposal.againstVotes += votes;
		}

		hasChanged = hasChanged != (proposal.forVotes > proposal.againstVotes);
		receipt.hasVoted = true;
		receipt.support = support;
		receipt.votes = votes;

		// if quorom passed then start the queue period
		if (
			proposal.forVotes >= proposal.quoromRequired ||
			proposal.againstVotes >= proposal.quoromRequired
		) _updateETA(proposal, hasChanged);
		emit VoteCast(voter, proposalId, support, votes);
	}

	function getChainId() public view returns (uint256) {
		uint256 chainId;
		assembly {
			chainId := chainid()
		}
		return chainId;
	}

	function renounceGuardian() public {
		require(_msgSender() == guardian, "CompoundVotingMachine: not guardian");
		guardian = address(0);
		foundationGuardianRelease = 0;
		emit GuardianSet(guardian);
	}

	function setGuardian(address _guardian) public {
		require(
			_msgSender() == address(avatar) || _msgSender() == guardian,
			"CompoundVotingMachine: not avatar or guardian"
		);

		require(
			_msgSender() == guardian || block.timestamp > foundationGuardianRelease,
			"CompoundVotingMachine: foundation expiration not reached"
		);

		guardian = _guardian;
		emit GuardianSet(guardian);
	}

	/// @notice allow anyone to emit details about proposal that passed. can be used for cross-chain proposals using blockheader proofs
	function emitSucceeded(uint256 _proposalId) public {
		require(
			state(_proposalId) == ProposalState.Succeeded,
			"CompoundVotingMachine: not Succeeded"
		);
		Proposal storage proposal = proposals[_proposalId];
		//also mark in storage as executed for cross chain voting. can be used by storage proofs, to verify proposal passed
		if (proposal.forBlockchain != getChainId()) {
			proposal.executed = true;
		}

		emit ProposalSucceeded(
			_proposalId,
			proposal.proposer,
			proposal.targets,
			proposal.values,
			proposal.signatures,
			proposal.calldatas,
			proposal.startBlock,
			proposal.endBlock,
			proposal.forBlockchain,
			proposal.eta,
			proposal.forVotes,
			proposal.againstVotes
		);
	}
}
