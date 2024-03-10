// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./vendor/Owned.sol";
import "./KeeperRegistryInterface.sol";

/**
 * @notice Contract to accept requests for upkeep registrations
 * @dev There are 2 registration workflows in this contract
 * Flow 1. auto approve OFF / manual registration - UI calls `register` function on this contract, this contract owner at a later time then manually
 *  calls `approve` to register upkeep and emit events to inform UI and others interested.
 * Flow 2. auto approve ON / real time registration - UI calls `register` function as before, which calls the `registerUpkeep` function directly on
 *  keeper registry and then emits approved event to finish the flow automatically without manual intervention.
 * The idea is to have same interface(functions,events) for UI or anyone using this contract irrespective of auto approve being enabled or not.
 * they can just listen to `RegistrationRequested` & `RegistrationApproved` events and know the status on registrations.
 */
contract UpkeepRegistrationRequests is Owned {
    bytes4 private constant REGISTER_REQUEST_SELECTOR = this.register.selector;

    uint256 private s_minLINKJuels;

    address public immutable LINK_ADDRESS;

    struct AutoApprovedConfig {
        bool enabled;
        uint16 allowedPerWindow;
        uint32 windowSizeInBlocks;
        uint64 windowStart;
        uint16 approvedInCurrentWindow;
    }

    AutoApprovedConfig private s_config;
    KeeperRegistryBaseInterface private s_keeperRegistry;

    event MinLINKChanged(uint256 from, uint256 to);

    event RegistrationRequested(
        bytes32 indexed hash,
        string name,
        bytes encryptedEmail,
        address indexed upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes checkData,
        uint8 indexed source
    );

    event RegistrationApproved(
        bytes32 indexed hash,
        string displayName,
        uint256 indexed upkeepId
    );

    constructor(
        address LINKAddress, 
        uint256 minimumLINKJuels
    ) 
    {
        LINK_ADDRESS = LINKAddress;
        s_minLINKJuels = minimumLINKJuels;
    }

    //EXTERNAL

    /**
     * @notice register can only be called through transferAndCall on LINK contract
     * @param name name of the upkeep to be registered
     * @param encryptedEmail Amount of LINK sent (specified in Juels)
     * @param upkeepContract address to peform upkeep on
     * @param gasLimit amount of gas to provide the target contract when
     * performing upkeep
     * @param adminAddress address to cancel upkeep and withdraw remaining funds
     * @param checkData data passed to the contract when checking for upkeep
     * @param source application sending this request
     */
    function register(
        string memory name,
        bytes calldata encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        uint8 source
    ) 
      external 
      onlyLINK() 
    {
        bytes32 hash = keccak256(msg.data);

        emit RegistrationRequested(
            hash,
            name,
            encryptedEmail,
            upkeepContract,
            gasLimit,
            adminAddress,
            checkData,
            source
        );

        AutoApprovedConfig memory config = s_config;

        // if auto approve is true send registration request to the Keeper Registry contract
        if (config.enabled) {
            _resetWindowIfRequired(config);
            if (config.approvedInCurrentWindow < config.allowedPerWindow) {
                config.approvedInCurrentWindow++;
                s_config = config;

                _approve(
                    name,
                    upkeepContract,
                    gasLimit,
                    adminAddress,
                    checkData,
                    hash
                );
            }
        }
    }

    /**
     * @dev register upkeep on KeeperRegistry contract and emit RegistrationApproved event
     */
    function approve(
        string memory name,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        bytes32 hash
    ) 
      external 
      onlyOwner() 
    {
        _approve(
            name,
            upkeepContract,
            gasLimit,
            adminAddress,
            checkData,
            hash
        );    
    }

    /**
     * @notice owner calls this function to set minimum LINK required to send registration request
     * @param minimumLINKJuels minimum LINK required to send registration request
     */
    function setMinLINKJuels(
        uint256 minimumLINKJuels
    ) 
      external 
      onlyOwner() 
    {
        emit MinLINKChanged(s_minLINKJuels, minimumLINKJuels);
        s_minLINKJuels = minimumLINKJuels;
    }

    /**
     * @notice read the minimum LINK required to send registration request
     */
    function getMinLINKJuels() 
      external 
      view 
      returns (
          uint256
      )
    {
        return s_minLINKJuels;
    }

    /**
     * @notice owner calls this function to set if registration requests should be sent directly to the Keeper Registry
     * @param enabled setting for autoapprove registrations
     * @param windowSizeInBlocks window size defined in number of blocks
     * @param allowedPerWindow number of registrations that can be auto approved in above window
     * @param keeperRegistry new keeper registry address
     */
    function setRegistrationConfig(
        bool enabled,
        uint32 windowSizeInBlocks,
        uint16 allowedPerWindow,
        address keeperRegistry
    )
      external 
      onlyOwner() 
    {
        s_config = AutoApprovedConfig({
            enabled: enabled,
            allowedPerWindow: allowedPerWindow,
            windowSizeInBlocks: windowSizeInBlocks,
            windowStart: 0,
            approvedInCurrentWindow: 0
        });
        s_keeperRegistry = KeeperRegistryBaseInterface(keeperRegistry);
    }

    /**
     * @notice read the current registration configuration
     */
    function getRegistrationConfig()
        external
        view
        returns (
            bool enabled,
            uint32 windowSizeInBlocks,
            uint16 allowedPerWindow,
            address keeperRegistry,
            uint64 windowStart,
            uint16 approvedInCurrentWindow
        )
    {
        AutoApprovedConfig memory config = s_config;
        return (
            config.enabled,
            config.windowSizeInBlocks,
            config.allowedPerWindow,
            address(s_keeperRegistry),
            config.windowStart,
            config.approvedInCurrentWindow
        );
    }

    /**
     * @notice Called when LINK is sent to the contract via `transferAndCall`
     * @param amount Amount of LINK sent (specified in Juels)
     * @param data Payload of the transaction
     */
    function onTokenTransfer(
        address, /* sender */
        uint256 amount,
        bytes calldata data
    ) 
      external 
      onlyLINK() 
      permittedFunctionsForLINK(data) 
    {
        require(amount >= s_minLINKJuels, "Insufficient payment");
        (bool success, ) = address(this).delegatecall(data); // calls register
        require(success, "Unable to create request");
    }

    //PRIVATE

    /**
     * @dev reset auto approve window if passed end of current window
     */
    function _resetWindowIfRequired(
        AutoApprovedConfig memory config
    ) 
      private 
    {
        uint64 blocksPassed = uint64(block.number - config.windowStart);
        if (blocksPassed >= config.windowSizeInBlocks) {
            config.windowStart = uint64(block.number);
            config.approvedInCurrentWindow = 0;
            s_config = config;
        }
    }

    /**
     * @dev register upkeep on KeeperRegistry contract and emit RegistrationApproved event
     */
    function _approve(
        string memory name,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        bytes32 hash
    ) 
      private 
    {
        //call register on keeper Registry
        uint256 upkeepId =
            s_keeperRegistry.registerUpkeep(
                upkeepContract,
                gasLimit,
                adminAddress,
                checkData
            );

        // emit approve event
        emit RegistrationApproved(hash, name, upkeepId);
    }

    //MODIFIERS

    /**
     * @dev Reverts if not sent from the LINK token
     */
    modifier onlyLINK() {
        require(msg.sender == LINK_ADDRESS, "Must use LINK token");
        _;
    }

    /**
     * @dev Reverts if the given data does not begin with the `register` function selector
     * @param _data The data payload of the request
     */
    modifier permittedFunctionsForLINK(
        bytes memory _data
    ) 
    {
        bytes4 funcSelector;
        assembly {
            // solhint-disable-next-line avoid-low-level-calls
            funcSelector := mload(add(_data, 32))
        }
        require(
            funcSelector == REGISTER_REQUEST_SELECTOR,
            "Must use whitelisted functions"
        );
        _;
    }
}

