// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.0;

import './IERC20.sol';
import './IMateriaOrchestrator.sol';
import './TransferHelper.sol';
import './IEthItemInteroperableInterface.sol';
import './IERC20WrapperV1.sol';

abstract contract MateriaOperator is IERC1155Receiver, IERC165 {
    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, 'Materia: Expired');
        _;
    }

    function _ensure(uint256 deadline) internal ensure(deadline) {}

    function _isEthItem(address token, address wrapper) internal view returns (bool ethItem, uint256 id) {
        try IEthItemInteroperableInterface(token).mainInterface() {
            ethItem = true;
        } catch {
            ethItem = false;
            id = IERC20WrapperV1(wrapper).object(token);
        }
    }

    function _wrapErc20(
        address token,
        uint256 amount,
        address wrapper
    ) internal returns (address interoperable, uint256 newAmount) {
        if (IERC20(token).allowance(address(this), wrapper) < amount) {
            IERC20(token).approve(wrapper, type(uint256).max);
        }

        (uint256 id, ) = IERC20WrapperV1(wrapper).mint(token, amount);

        newAmount = IERC20(interoperable = address(IERC20WrapperV1(wrapper).asInteroperable(id))).balanceOf(
            address(this)
        );
    }

    function _unwrapErc20(
        uint256 id,
        address tokenOut,
        uint256 amount,
        address wrapper,
        address to
    ) internal {
        IERC20WrapperV1(wrapper).burn(id, amount);
        TransferHelper.safeTransfer(tokenOut, to, IERC20(tokenOut).balanceOf(address(this)));
    }

    function _unwrapEth(
        uint256 id,
        uint256 amount,
        address wrapper,
        address to
    ) internal {
        IERC20WrapperV1(wrapper).burn(id, amount);
        TransferHelper.safeTransferETH(to, amount);
    }

    function _wrapEth(uint256 amount, address wrapper) public payable returns (address interoperable) {
        (, interoperable) = IERC20WrapperV1(wrapper).mintETH{value: amount}();
    }

    function _adjustAmount(address token, uint256 amount) internal view returns (uint256 newAmount) {
        newAmount = amount * (10**(18 - IERC20Data(token).decimals()));
    }

    function _tokenToInteroperable(address token, address wrapper) internal view returns (address interoperable) {
        if (token == address(0))
            interoperable = address(
                IERC20WrapperV1(wrapper).asInteroperable(
                    uint256(IMateriaOrchestrator(address(this)).ETHEREUM_OBJECT_ID())
                )
            );
        else {
            (, uint256 itemId) = _isEthItem(token, wrapper);
            interoperable = address(IERC20WrapperV1(wrapper).asInteroperable(itemId));
        }
    }
}

