// SPDX-License-Identifier: MIT

pragma solidity ^0.6.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../interface/IAMMV1.sol";
import "../utils/lib_storage/UserProxyStorage.sol";

/**
 * @dev UserProxy contract
 */
contract UserProxyV1 {
    using SafeERC20 for IERC20;

    // Constants do not have storage slot.
    uint256 constant private MAX_UINT = 2**256 - 1;
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant ZERO_ADDRESS = address(0);

    /**
     * @dev Below are the variables which consume storage slots.
     */
    address public owner;


    receive() external payable {
    }

    /**
     * @dev Access control and ownership management.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "UserProxy: not the owner");
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
    function initialize(address _ammWrapperAddr, address _owner) external {
        require(owner == address(0), "UserProxy: already initialized");
        AMMWrapperStorage.getStorage().ammWrapperAddr = _ammWrapperAddr;
        owner = _owner;
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
        // Load the AMMWrapper address
        address _ammWrapperAddr = AMMWrapperStorage.getStorage().ammWrapperAddr;
        
        // Since ABI decoding requires padded data, we cannot use abi.decode(_payload[:4], (bytes4)).
        bytes4 functionSig =
            _payload[0] |
            (bytes4(_payload[1]) >> 8) |
            (bytes4(_payload[2]) >> 16) |
            (bytes4(_payload[3]) >> 24);

         if (functionSig == IAMMV1.trade.selector) {
            // Option 1: parse payload and do a normal function call
            (
                address _pool,
                address _fromAssetAddress,
                address _toAssetAddress,
                uint256 _fromAmount,
                uint256 _minAmount,
                address payable _spender,
                uint256 deadline
            ) = abi.decode(_payload[4:], (address, address, address, uint256, uint256, address, uint256));

            if (_fromAssetAddress != ETH_ADDRESS && _fromAssetAddress != ZERO_ADDRESS) {
                IERC20(_fromAssetAddress).safeTransferFrom(_spender, address(this), _fromAmount);
            }

            uint256 receivedAmount = IAMMV1(_ammWrapperAddr).trade
                {value: msg.value}(
                    _pool,
                    _fromAssetAddress,
                    _toAssetAddress,
                    _fromAmount,
                    _minAmount,
                    payable(address(this)),
                    deadline
                );
            // Option 2: proxy the payload directly with low level call
            // (bool status, bytes memory ret) = ammWrapperAddr.call{value: msg.value}(_payload);
            // uint256 receivedAmount = abi.decode(ret, (uint256));
            if (_toAssetAddress != ETH_ADDRESS && _toAssetAddress != ZERO_ADDRESS) {
                IERC20(_toAssetAddress).safeTransfer(_spender, receivedAmount);
            } else {
                _spender.transfer(receivedAmount);
            }
        } else {
            revert("UserProxy: toAMM function sigature mismatch");
        }
    }
}

