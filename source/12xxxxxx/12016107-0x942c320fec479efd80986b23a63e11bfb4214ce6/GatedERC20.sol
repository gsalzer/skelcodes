// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

/* ROOTKIT:
A standard ERC20 with an extra hook: An installable transfer
gate allowing for token tax and burn on transfer
*/

import "./ERC20.sol";
import "./ITransferGate.sol";
import "./Owned.sol";
import "./SafeMath.sol";
import "./TokensRecoverable.sol";
import "./IGatedERC20.sol";

abstract contract GatedERC20 is ERC20, TokensRecoverable, IGatedERC20
{
    using SafeMath for uint256;

    ITransferGate public override transferGate;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol)
    {
    }

    function setTransferGate(ITransferGate _transferGate) public override ownerOnly()
    {
        transferGate = _transferGate;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override 
    {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        ITransferGate _transferGate = transferGate;
        uint256 remaining = amount;
        if (address(_transferGate) != address(0)) {
            (uint256 burn, TransferGateTarget[] memory targets) = _transferGate.handleTransfer(msg.sender, sender, recipient, amount);            
            if (burn > 0) {
                amount = remaining = remaining.sub(burn, "Burn too much");
                _burn(sender, burn);
            }
            for (uint256 x = 0; x < targets.length; ++x) {
                (address dest, uint256 amt) = (targets[x].destination, targets[x].amount);
                remaining = remaining.sub(amt, "Transfer too much");
                _balanceOf[dest] = _balanceOf[dest].add(amt);
                emit Transfer(sender, dest, amt);
            }
        }
        _balanceOf[sender] = _balanceOf[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balanceOf[recipient] = _balanceOf[recipient].add(remaining);
        emit Transfer(sender, recipient, remaining);
    }
}
