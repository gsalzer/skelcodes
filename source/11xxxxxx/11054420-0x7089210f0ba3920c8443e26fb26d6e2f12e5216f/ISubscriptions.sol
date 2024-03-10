// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

/// @title Subscriptions contract interface
interface ISubscriptions {
    event SubscriptionChanged(uint256 indexed vcId, address owner, string name, uint256 genRefTime, string tier, uint256 rate, uint256 expiresAt, bool isCertified, string deploymentSubset);
    event Payment(uint256 indexed vcId, address by, uint256 amount, string tier, uint256 rate);
    event VcConfigRecordChanged(uint256 indexed vcId, string key, string value);
    event VcCreated(uint256 indexed vcId);
    event VcOwnerChanged(uint256 indexed vcId, address previousOwner, address newOwner);

    /*
     *   External functions
     */

    /// @dev Called by: authorized subscriber (plan) contracts
    /// Creates a new VC
    function createVC(string calldata name, string calldata tier, uint256 rate, uint256 amount, address owner, bool isCertified, string calldata deploymentSubset) external returns (uint, uint);

    /// @dev Called by: authorized subscriber (plan) contracts
    /// Extends the subscription of an existing VC.
    function extendSubscription(uint256 vcId, uint256 amount, string calldata tier, uint256 rate, address payer) external;

    /// @dev called by VC owner to set a VC config record. Emits a VcConfigRecordChanged event.
    function setVcConfigRecord(uint256 vcId, string calldata key, string calldata value) external /* onlyVcOwner */;

    /// @dev returns the value of a VC config record
    function getVcConfigRecord(uint256 vcId, string calldata key) external view returns (string memory);

    /// @dev Transfers VC ownership to a new owner (can only be called by the current owner)
    function setVcOwner(uint256 vcId, address owner) external /* onlyVcOwner */;

    /// @dev Returns the data of a VC (not including config records)
    function getVcData(uint256 vcId) external view returns (
        string memory name,
        string memory tier,
        uint256 rate,
        uint expiresAt,
        uint256 genRefTime,
        address owner,
        string memory deploymentSubset,
        bool isCertified
    );

    /*
     *   Governance functions
     */

    event SubscriberAdded(address subscriber);
    event SubscriberRemoved(address subscriber);
    event GenesisRefTimeDelayChanged(uint256 newGenesisRefTimeDelay);
    event MinimumInitialVcPaymentChanged(uint256 newMinimumInitialVcPayment);

    /// @dev Called by the owner to authorize a subscriber (plan)
    function addSubscriber(address addr) external /* onlyFunctionalManager */;

    /// @dev Called by the owner to unauthorize a subscriber (plan)
    function removeSubscriber(address addr) external /* onlyFunctionalManager */;

    /// @dev Called by the owner to set the genesis ref time delay
    function setGenesisRefTimeDelay(uint256 newGenesisRefTimeDelay) external /* onlyFunctionalManager */;

    /// @dev Returns the genesis ref time delay
    function getGenesisRefTimeDelay() external view returns (uint256);

    /// @dev Called by the owner to set the minimum initial vc payment
    function setMinimumInitialVcPayment(uint256 minimumInitialVcPayment) external /* onlyFunctionalManager */;

    /// @dev Returns the minimum initial vc payment
    function getMinimumInitialVcPayment() external view returns (uint256);

    /// @dev Returns the settings of this contract
    function getSettings() external view returns(
        uint genesisRefTimeDelay,
        uint256 minimumInitialVcPayment
    );

}

