// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "../interface/IERC1363.sol";
import "../interface/IERC1363Receiver.sol";
import "../interface/IERC1363Spender.sol";

abstract contract ERC1363Transfer is ERC20, IERC1363Transfer {
    function transferAndCall(address to, uint256 value) public override returns (bool) {
        return transferAndCall(to, value, bytes(""));
    }

    function transferAndCall(address to, uint256 value, bytes memory data) public override returns (bool) {
        require(transfer(to, value));
        try IERC1363Receiver(to).onTransferReceived(_msgSender(), _msgSender(), value, data) returns (bytes4 selector) {
            require(selector == IERC1363Receiver(to).onTransferReceived.selector, "ERC1363: onTransferReceived invalid result");
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("ERC1363: onTransferReceived reverted without reason");
        }
        return true;
    }

    function transferFromAndCall(address from, address to, uint256 value) public override returns (bool) {
        return transferFromAndCall(from, to, value, bytes(""));
    }

    function transferFromAndCall(address from, address to, uint256 value, bytes memory data) public override returns (bool) {
        require(transferFrom(from, to, value));
        try IERC1363Receiver(to).onTransferReceived(_msgSender(), from, value, data) returns (bytes4 selector) {
            require(selector == IERC1363Receiver(to).onTransferReceived.selector, "ERC1363: onTransferReceived invalid result");
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("ERC1363: onTransferReceived reverted without reason");
        }
        return true;
    }
}

abstract contract ERC1363Approve is ERC20, IERC1363Approve {
    function approveAndCall(address spender, uint256 value) public override returns (bool) {
        return approveAndCall(spender, value, bytes(""));
    }

    function approveAndCall(address spender, uint256 value, bytes memory data) public override returns (bool) {
        require(approve(spender, value));
        try IERC1363Spender(spender).onApprovalReceived(_msgSender(), value, data) returns (bytes4 selector) {
            require(selector == IERC1363Spender(spender).onApprovalReceived.selector, "ERC1363: onApprovalReceived invalid result");
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("ERC1363: onApprovalReceived reverted without reason");
        }
        return true;
    }
}

abstract contract ERC1363 is ERC1363Transfer, ERC1363Approve {}

