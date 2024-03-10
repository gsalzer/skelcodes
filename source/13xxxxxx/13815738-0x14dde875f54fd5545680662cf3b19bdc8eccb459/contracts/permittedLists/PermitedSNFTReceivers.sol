// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IPermittedSNFTReceivers.sol";
import "../utils/Ownable.sol";

/**
 * @title  PermittedSNFTReceivers
 * @author NFTfi
 * @dev Registry for contract addresses supported by NFTfi as SmartNFTs receiver. Each address is
 * associated with a boolean permit.
 */
contract PermittedSNFTReceivers is Ownable, IPermittedSNFTReceivers {
    using Address for address;

    /* ******* */
    /* STORAGE */
    /* ******* */

    /**
     * @notice A mapping from an contract address to whether that contract is permitted to receive a SmartNft.
     */
    mapping(address => bool) private sNftReceiver;

    /* ****** */
    /* EVENTS */
    /* ****** */

    /**
     * @notice This event is fired whenever the admin sets a contract permit.
     *
     * @param contractAddress - Address of the contract.
     * @param isPermitted - Signals contract permit.
     */
    event SNFTReceiverPermit(address indexed contractAddress, bool isPermitted);

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    /**
     * @notice Initialize `sNftReceiver` with a batch of permitted contracts.
     *
     * @param _admin - Initial admin of this contract.
     * @param _permittedSNFTReceivers - The batch of addresses initially permitted.
     */
    constructor(address _admin, address[] memory _permittedSNFTReceivers) Ownable(_admin) {
        for (uint256 i = 0; i < _permittedSNFTReceivers.length; i++) {
            _setSNFTReceiverPermit(_permittedSNFTReceivers[i], true);
        }
    }

    /* ********* */
    /* FUNCTIONS */
    /* ********* */

    /**
     * @notice This function can be called by admins to change the permitted status of an contract. This includes
     * both adding a contract address to the permitted list and removing it.
     *
     * @param _receiver - The address of the contreact whose permit list status changed.
     * @param _permit - The new status of whether the currency is permitted or not.
     */
    function setSNFTReceiverPermit(address _receiver, bool _permit) external onlyOwner {
        _setSNFTReceiverPermit(_receiver, _permit);
    }

    /**
     * @notice This function can be called by admins to change the permitted status of a batch of contract addresses.
     * This includes both adding a contract address to the permitted list and removing it.
     *
     * @param _receivers - The addresses of the contracts whose permit list status changed.
     * @param _permits - The new statuses of whether the currency is permitted or not.
     */
    function setSNFTReceiverPermits(address[] memory _receivers, bool[] memory _permits) external onlyOwner {
        require(_receivers.length == _permits.length, "setSNFTReceiverPermits function information arity mismatch");

        for (uint256 i = 0; i < _receivers.length; i++) {
            _setSNFTReceiverPermit(_receivers[i], _permits[i]);
        }
    }

    /**
     * @notice This function can be called by anyone to get the permit associated with the contract address.
     *
     * @param _receiver - The address of the contract.
     *
     * @return Returns whether the contract address is permitted
     */
    function isValidReceiver(address _receiver) external view override returns (bool) {
        return sNftReceiver[_receiver];
    }

    /**
     * @notice This function can be called by admins to change the permitted status of a contract address. This includes
     * both adding a contract address to the permitted list and removing it.
     *
     * @param _receiver - The address of the ERC20 currency whose permit list status changed.
     * @param _permit - The new status of whether the currency is permitted or not.
     */
    function _setSNFTReceiverPermit(address _receiver, bool _permit) internal {
        require(_receiver != address(0), "receiver is zero address");

        sNftReceiver[_receiver] = _permit;

        emit SNFTReceiverPermit(_receiver, _permit);
    }
}

