// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../ImplBase.sol";
import "../../helpers/errors.sol";
import "../../interfaces/hop/IHopL1Bridge.sol";

/**
// @title Hop Protocol Implementation.
// @notice This is the L1 implementation, so this is used when transferring from l1 to supported l2s
//         Called by the registry if the selected bridge is HOP.
// @dev Follows the interface of ImplBase.
// @author Movr Network.
*/
contract HopImpl is ImplBase, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // solhint-disable-next-line
    constructor(address _registry) ImplBase(_registry) {}

    /**
    // @notice Function responsible for cross chain transfers from L1 to L2. 
    // @dev When calling the registry the allowance should be given to this contract, 
    //      that is the implementation contract for HOP.
    // @param _amount amount to be transferred to L2.
    // @param _from userAddress or address from which the transfer was made.
    // @param _receiverAddress address that will receive the funds on the destination chain.
    // @param _token address of the token to be used for cross chain transfer.
    // @param _toChainId chain Id for the destination chain 
    // @param _extraData parameters required to call the hop function in bytes 
    */
    function outboundTransferTo(
        uint256 _amount,
        address _from,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        bytes memory _extraData
    ) external payable override onlyRegistry nonReentrant {
        // decode extra data
        (
            address _l1bridgeAddr,
            address _relayer,
            uint256 _amountOutMin,
            uint256 _relayerFee,
            uint256 _deadline
        ) = abi.decode(
                _extraData,
                (address, address, uint256, uint256, uint256)
            );
        if (_token == NATIVE_TOKEN_ADDRESS) {
            require(msg.value == _amount, MovrErrors.VALUE_NOT_EQUAL_TO_AMOUNT);
            IHopL1Bridge(_l1bridgeAddr).sendToL2{value: _amount}(
                _toChainId,
                _receiverAddress,
                _amount,
                _amountOutMin,
                _deadline,
                _relayer,
                _relayerFee
            );
            return;
        }
        require(msg.value == 0, MovrErrors.VALUE_SHOULD_BE_ZERO);
        IERC20(_token).safeTransferFrom(_from, address(this), _amount);
        IERC20(_token).safeIncreaseAllowance(_l1bridgeAddr, _amount);

        // perform bridging
        IHopL1Bridge(_l1bridgeAddr).sendToL2(
            _toChainId,
            _receiverAddress,
            _amount,
            _amountOutMin,
            _deadline,
            _relayer,
            _relayerFee
        );
    }
}

