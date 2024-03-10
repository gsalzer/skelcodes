// SPDX-License-Identifier: MIT

pragma solidity ^0.6.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interface/IAMM.sol";
import "../interface/IPMM.sol";
import "../interface/IPermanentStorage.sol";
import "../utils/lib_storage/UserProxyStorage.sol";

/**
 * @dev UserProxy contract
 */
contract UserProxyV3 {
    using SafeERC20 for IERC20;

    // Constants do not have storage slot.
    uint256 private constant MAX_UINT = 2**256 - 1;
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant ZERO_ADDRESS = address(0);

    /**
     * @dev Below are the variables which consume storage slots.
     */
    address public owner;
    uint256 public version;  // Current version of the contract
    IPermanentStorage public permStorage;

    receive() external payable {
    }

    /**
     * @dev Access control and ownership management.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "UserProxy: not the owner");
        _;
    }

    modifier onlyAMMorPMM() {
        require(
            (msg.sender == AMMWrapperStorage.getStorage().ammWrapperAddr) ||
            (msg.sender == PMMStorage.getStorage().pmmAddr),
            "UserProxy: not a valid contract"
        );
        _;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "UserProxy: owner can not be zero address");
        owner = _newOwner;
    }
    /* End of access control and ownership management */


    /**
     * @dev Replacing constructor and initialize the contract. This function should only be called once.
     */
    function initialize(IPermanentStorage _permStorage, address _pmmAddr) external {
        require(version == 2, "UserProxy: not upgrading from version 2");

        // Upgrade version
        version = 3;
        // Set permanent storage
        permStorage = _permStorage;
        // Plug in and enable PMM
        PMMStorage.getStorage().pmmAddr = _pmmAddr;
        PMMStorage.getStorage().isEnabled = true;
    }


    function ammWrapperAddr() public view returns (address) {
        return AMMWrapperStorage.getStorage().ammWrapperAddr;
    }

    function setAMMStatus(bool _enable) public onlyOwner {
        AMMWrapperStorage.getStorage().isEnabled = _enable;
    }

    function isAMMEnabled() public view returns (bool) {
        return AMMWrapperStorage.getStorage().isEnabled;
    }

    /**
     * @dev Update AMMWrapper contract address. Used only when ABI of AMMWrapeer remain unchanged.
     * Otherwise, UserProxy contract should be upgraded altogether.
     */
    function upgradeAMMWrapper(address _newAMMWrapperAddr) external onlyOwner {
        AMMWrapperStorage.getStorage().ammWrapperAddr = _newAMMWrapperAddr;
    }

    /**
     * @dev proxy to AMM
     */
    // function toAMM(bytes calldata _payload, bytes memory _sig) external payable {
    function toAMM(bytes calldata _payload) external payable {
        require(isAMMEnabled(), "UserProxy: AMM is disabled");
        address _ammWrapperAddr = ammWrapperAddr();

        // Since ABI decoding requires padded data, we cannot use abi.decode(_payload[:4], (bytes4)).
        bytes4 functionSig =
            _payload[0] |
            (bytes4(_payload[1]) >> 8) |
            (bytes4(_payload[2]) >> 16) |
            (bytes4(_payload[3]) >> 24);

        if (functionSig == IAMM.trade.selector) {
            (bool callSucceed,) = _ammWrapperAddr.call{value: msg.value}(_payload);
            if (callSucceed == false) {
                // Get the error message returned
                assembly {
                    let ptr := mload(0x40)
                    let size := returndatasize()
                    returndatacopy(ptr, 0, size)
                    revert(ptr, size)
                }
            }
        } else {
            revert("UserProxy: toAMM function sigature mismatch");
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
    function upgradePMM(address _newPMMAddr) external onlyOwner {
        PMMStorage.getStorage().pmmAddr = _newPMMAddr;
    }

    function setPMMStatus(bool _enable) public onlyOwner {
        PMMStorage.getStorage().isEnabled = _enable;
    }

    function toPMM(bytes calldata _payload) external payable {
        require(isPMMEnabled(), "UserProxy: PMM is disabled");

        address _pmmAddr = pmmAddr();
        IPMM pmm = IPMM(_pmmAddr);
        // Since ABI decoding requires padded data, we cannot use abi.decode(_payload[:4], (bytes4)).
        bytes4 functionSig =
            _payload[0] |
            (bytes4(_payload[1]) >> 8) |
            (bytes4(_payload[2]) >> 16) |
            (bytes4(_payload[3]) >> 24);
        (
            uint256 userSalt,
            bytes memory data,
            bytes memory userSignature
        ) = abi.decode(_payload[4:], (uint256, bytes, bytes));

        if (functionSig == IPMM.fill.selector) {
            pmm.fill
                {value: msg.value}(
                    userSalt,
                    data,
                    userSignature
                );
        } else {
            revert("UserProxy: toPMM function sigature mismatch");
        }
    }

    function spendFromUser(address user, address takerAssetAddr, uint256 takerAssetAmount) external onlyAMMorPMM() {
        if (takerAssetAddr != ETH_ADDRESS &&
            takerAssetAddr != ZERO_ADDRESS &&
            takerAssetAddr != permStorage.wethAddr()) {
            IERC20(takerAssetAddr).safeTransferFrom(user, msg.sender, takerAssetAmount);
        }
    }
}

