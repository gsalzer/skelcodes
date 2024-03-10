// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./vendor/Owned.sol";

/**
 * @notice Contract to accept requests for upkeep registrations
 */
contract UpkeepRegistrationRequests is Owned {
    bytes4 private constant REGISTER_REQUEST_SELECTOR = this.register.selector;

    uint256 private s_minLINKWei;

    address public immutable LINK_ADDRESS;

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

    constructor(address LINKAddress, uint256 minimumLINKWei) {
        LINK_ADDRESS = LINKAddress;
        s_minLINKWei = minimumLINKWei;
    }

    /**
     * @notice register can only be called through transferAndCall on LINK contract
     * @param name name of the upkeep to be registered
     * @param encryptedEmail Amount of LINK sent (specified in wei)
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
    ) external onlyLINK() {
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
    }

    /**
     * @notice owner calls this function after registering upkeep on the Registry contract
     * @param hash hash of the message data of the registration request that is being approved
     * @param displayName display name for the upkeep being approved
     * @param upkeepId id of the upkeep that has been registered
     */
    function approved(
        bytes32 hash,
        string memory displayName,
        uint256 upkeepId
    ) external onlyOwner() {
        emit RegistrationApproved(hash, displayName, upkeepId);
    }

    /**
     * @notice owner calls this function to set minimum LINK required to send registration request
     * @param minimumLINKWei minimum LINK required to send registration request
     */
    function setMinLINKWei(uint256 minimumLINKWei) external onlyOwner() {
        emit MinLINKChanged(s_minLINKWei, minimumLINKWei);
        s_minLINKWei = minimumLINKWei;
    }

    /**
     * @notice read the minimum LINK required to send registration request
     */
    function getMinLINKWei() external view returns (uint256) {
        return s_minLINKWei;
    }

    /**
     * @notice Called when LINK is sent to the contract via `transferAndCall`
     * @param amount Amount of LINK sent (specified in wei)
     * @param data Payload of the transaction
     */
    function onTokenTransfer(
        address /* sender */,
        uint256 amount,
        bytes calldata data
    ) external onlyLINK() permittedFunctionsForLINK(data) {
        require(amount >= s_minLINKWei, "Insufficient payment");
        (bool success, ) = address(this).delegatecall(data); // calls register
        require(success, "Unable to create request");
    }

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
    modifier permittedFunctionsForLINK(bytes memory _data) {
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

