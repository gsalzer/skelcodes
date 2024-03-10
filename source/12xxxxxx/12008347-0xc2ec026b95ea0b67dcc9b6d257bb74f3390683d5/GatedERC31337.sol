// SPDX-License-Identifier: P-P-P-PONZO!!!
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

/* ROOTKIT:
A standard ERC31337 with an extra hook: An installable transfer
gate allowing for burn on transfer
*/

import "./IERC20.sol";
import "./ERC31337.sol";
import "./ITransferGateLite.sol";
import "./Owned.sol";
import "./SafeMath.sol";
import "./TokensRecoverable.sol";
import "./IGatedERC20.sol";

abstract contract GatedERC31337 is ERC31337
{
    using SafeMath for uint256;

    ITransferGateLite public transferGate;

    constructor(IERC20 _wrappedToken, string memory _name, string memory _symbol) ERC31337(_wrappedToken, _name, _symbol)
    {
    }

    function setTransferGate(ITransferGateLite _transferGate) public ownerOnly()
    {
        transferGate = _transferGate;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override 
    {
        require(sender != address(0), "ERC31337: transfer from the zero address");
        require(recipient != address(0), "ERC31337: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        ITransferGateLite _transferGate = transferGate;
        uint256 remaining = amount;
        if (address(_transferGate) != address(0)) 
        {
            uint256 burn = _transferGate.handleTransfer(msg.sender, sender, recipient, amount);            
            if (burn > 0) 
            {
                amount = remaining = remaining.sub(burn, "Burn too much");
                _burn(sender, burn);
            }
        }
        _balanceOf[sender] = _balanceOf[sender].sub(amount, "ERC31337: transfer amount exceeds balance");
        _balanceOf[recipient] = _balanceOf[recipient].add(remaining);
        emit Transfer(sender, recipient, remaining);
    }
}
