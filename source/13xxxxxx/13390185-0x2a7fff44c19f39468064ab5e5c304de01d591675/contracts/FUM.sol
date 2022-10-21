// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "erc20permit/contracts/ERC20Permit.sol";
import "./IUSM.sol";
import "./IFUM.sol";
import "./OptOutable.sol";
import "./MinOut.sol";

/**
 * @title FUM Token
 * @author Alberto Cuesta Cañada, Jacob Eliosoff, Alex Roan
 *
 * @notice This should be created and owned by the USM instance.
 */
contract FUM is IFUM, ERC20Permit, OptOutable {
    IUSM public immutable usm;

    constructor(address[] memory addressesYouCantSendThisContractsTokensTo,
                address[] memory contractsToAskToRejectSendsToThisContractsAddress)
        ERC20Permit("Minimalist USD Funding v1 - Release Candidate 1", "FUM")
        OptOutable(addressesYouCantSendThisContractsTokensTo, contractsToAskToRejectSendsToThisContractsAddress)
    {
        usm = IUSM(msg.sender);     // FUM constructor can only be called by a USM instance
    }

    /**
     * @notice If anyone sends ETH here, assume they intend it as a `fund`.  If decimals 8 to 11 (inclusive) of the amount of
     * ETH received are `0000`, then the next 7 will be parsed as the minimum number of FUM accepted per input ETH, with the
     * 7-digit number interpreted as "hundredths of a FUM".  See comments in `MinOut`.
     */
    receive() external payable {
        usm.fund{ value: msg.value }(msg.sender, MinOut.parseMinTokenOut(msg.value));
    }

    /**
     * @notice If a user sends FUM tokens directly to this contract (or to the USM contract), assume they intend it as a
     * `defund`.  If using `transfer`/`transferFrom` as `defund`, and if decimals 8 to 11 (inclusive) of the amount transferred
     * are `0000`, then the next 7 will be parsed as the maximum number of FUM tokens sent per ETH received, with the 7-digit
     * number interpreted as "hundredths of a FUM".  See comments in `MinOut`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override noOptOut(recipient) returns (bool)
    {
        if (recipient == address(this) || recipient == address(usm) || recipient == address(0)) {
            usm.defundFrom(sender, payable(sender), amount, MinOut.parseMinEthOut(amount));
        } else {
            super._transfer(sender, recipient, amount);
        }
        return true;
    }

    /**
     * @notice Mint new FUM to the recipient
     *
     * @param recipient address to mint to
     * @param amount amount to mint
     */
    function mint(address recipient, uint amount) external override {
        require(msg.sender == address(usm), "Only USM");
        _mint(recipient, amount);
    }

    /**
     * @notice Burn FUM from holder
     *
     * @param holder address to burn from
     * @param amount amount to burn
     */
    function burn(address holder, uint amount) external override {
        require(msg.sender == address(usm), "Only USM");
        _burn(holder, amount);
    }
}

