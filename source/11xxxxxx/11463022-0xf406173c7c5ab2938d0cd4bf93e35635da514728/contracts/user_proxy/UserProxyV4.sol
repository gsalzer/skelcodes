// SPDX-License-Identifier: MIT

pragma solidity ^0.6.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interface/IPMM.sol";
import "../interface/IPermanentStorage.sol";
import "../utils/lib_storage/UserProxyStorage.sol";

/**
 * @dev UserProxy contract
 */
contract UserProxyV4 {
    using SafeERC20 for IERC20;

    // Constants do not have storage slot.
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant ZERO_ADDRESS = address(0);

    /**
     * @dev Below are the variables which consume storage slots.
     */
    address public operator;
    string public version;  // Current version of the contract

    receive() external payable {
    }

    /**
     * @dev Access control and ownership management.
     */
    modifier onlyOperator() {
        require(operator == msg.sender, "UserProxy: not the operator");
        _;
    }

    function transferOwnership(address _newOperator) external onlyOperator {
        require(_newOperator != address(0), "UserProxy: operator can not be zero address");
        operator = _newOperator;
    }
    /* End of access control and ownership management */

    /**
     * @dev Replacing constructor and initialize the contract. This function should only be called once.
     */
    function initialize(address _newAMMWrapper, address _newPMM) external {
        require(_newAMMWrapper != address(0), "UserProxy: _newAMMWrapper should not be 0");
        require(_newPMM != address(0), "UserProxy: _newPMM should not be 0");

        // Set amm/pmm
        AMMWrapperStorage.getStorage().ammWrapperAddr = _newAMMWrapper;
        PMMStorage.getStorage().pmmAddr = _newPMM;
    }

    function ammWrapperAddr() public view returns (address) {
        return AMMWrapperStorage.getStorage().ammWrapperAddr;
    }

    function setAMMStatus(bool _enable) public onlyOperator {
        AMMWrapperStorage.getStorage().isEnabled = _enable;
    }

    function isAMMEnabled() public view returns (bool) {
        return AMMWrapperStorage.getStorage().isEnabled;
    }

    /**
     * @dev Update AMMWrapper contract address. Used only when ABI of AMMWrapeer remain unchanged.
     * Otherwise, UserProxy contract should be upgraded altogether.
     */
    function upgradeAMMWrapper(address _newAMMWrapperAddr, bool _enable) external onlyOperator {
        AMMWrapperStorage.getStorage().ammWrapperAddr = _newAMMWrapperAddr;
        AMMWrapperStorage.getStorage().isEnabled = _enable;
    }

    /**
     * @dev proxy to AMM
     */
    function toAMM(bytes calldata _payload) external payable {
        require(isAMMEnabled(), "UserProxy: AMM is disabled");

        (bool callSucceed,) = ammWrapperAddr().call{value: msg.value}(_payload);
        if (callSucceed == false) {
            // Get the error message returned
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }

    function pmmAddr() public view returns (address) {
        return PMMStorage.getStorage().pmmAddr;
    }

    function isPMMEnabled() public view returns (bool) {
        return PMMStorage.getStorage().isEnabled;
    }
    /**
     * @dev Update PMM contract address. Used only when ABI of PMM remain unchanged.
     * Otherwise, UserProxy contract should be upgraded altogether.
     */
    function upgradePMM(address _newPMMAddr, bool _enable) external onlyOperator {
        PMMStorage.getStorage().pmmAddr = _newPMMAddr;
        PMMStorage.getStorage().isEnabled = _enable;
    }

    function setPMMStatus(bool _enable) public onlyOperator {
        PMMStorage.getStorage().isEnabled = _enable;
    }

    /**
     * @dev proxy to PMM
     */
    function toPMM(bytes calldata _payload) external payable {
        require(isPMMEnabled(), "UserProxy: PMM is disabled");

        (bool callSucceed,) = pmmAddr().call{value: msg.value}(_payload);
        if (callSucceed == false) {
            // Get the error message returned
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }
}

