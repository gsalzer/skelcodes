// SPDX-License-Identifier: MIT

pragma solidity ^0.6.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../interface/IAMM.sol";
import "../interface/IPermanentStorage.sol";
import "../utils/lib_storage/UserProxyStorage.sol";

/**
 * @dev UserProxy contract
 */
contract UserProxyV2 {
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
    function initialize(IPermanentStorage _permStorage, address _newAMMWrapperAddr) external {
        require(version == 0, "UserProxy: already initialized");

        // Upgrade version
        version = 2;
        // Set permanent storage
        permStorage = _permStorage;
        // Upgrade AMMWrapper
        AMMWrapperStorage.getStorage().ammWrapperAddr = _newAMMWrapperAddr;
        AMMWrapperStorage.getStorage().isEnabled = true;
    }


    /**
     * @dev Spender logic: managing allowance
     */
    function setAllowance(address[] calldata tokenAddrs, address spender) external onlyOwner {
        for (uint i = 0; i < tokenAddrs.length; i++) {
            IERC20 token = IERC20(tokenAddrs[i]);
            token.safeApprove(spender, MAX_UINT);
            token.safeApprove(address(this), MAX_UINT);
        }
    }

    function closeAllowance(address[] calldata tokenAddrs, address spender) external onlyOwner {
        for (uint i = 0; i < tokenAddrs.length; i++) {
            IERC20 token = IERC20(tokenAddrs[i]);
            token.safeApprove(spender, 0);
            token.safeApprove(address(this), 0);
        }
    }
    /* End of Spender logic */


    function ammWrapperAddr() external view returns (address) {
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
     * Otherwise, UserProxy contract should be upgraded altogeth.
     */
    function upgradeAMMWrapper(address _newAMMWrapperAddr) external onlyOwner {
        AMMWrapperStorage.getStorage().ammWrapperAddr = _newAMMWrapperAddr;
    }

    /**
     * @dev proxy to AMM
     */
    function toAMM(bytes calldata _payload) external payable {
        require(isAMMEnabled(), "UserProxy: AMM is disabled");
        // Load the AMMWrapper address
        address _ammWrapperAddr = AMMWrapperStorage.getStorage().ammWrapperAddr;
        
        // Since ABI decoding requires padded data, we cannot use abi.decode(_payload[:4], (bytes4)).
        bytes4 functionSig =
            _payload[0] |
            (bytes4(_payload[1]) >> 8) |
            (bytes4(_payload[2]) >> 16) |
            (bytes4(_payload[3]) >> 24);

         if (functionSig == IAMM.trade.selector) {
            (bool status,) = _ammWrapperAddr.call{value: msg.value}(_payload);
            require(status, "UserProxy: ammWrapper call failed");
        } else {
            revert("UserProxy: toAMM function sigature mismatch");
        }
    }

    function toPMM(bytes calldata payload) external payable {
        // require(isMarketMakerProxy[order.makerAddress], "MAKER_ADDRESS_ERROR");
    }

    function spendFromUser(address user, address takerAssetAddr, uint256 takerAssetAmount) external onlyAMMorPMM() {
        if (takerAssetAddr != ETH_ADDRESS && takerAssetAddr != ZERO_ADDRESS && takerAssetAddr != permStorage.wethAddr()) {
            IERC20(takerAssetAddr).safeTransferFrom(user, msg.sender, takerAssetAmount);
        }
    }
}
