// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import { ERC20 } from "../../interfaces/ERC20.sol";
import { SafeERC20 } from "../../shared/SafeERC20.sol";
import { TokenAmount } from "../../shared/Structs.sol";
import { ERC20ProtocolAdapter } from "../../adapters/ERC20ProtocolAdapter.sol";
import { InteractiveAdapter } from "../InteractiveAdapter.sol";
import { IAmunLendingToken } from "../../interfaces/IAmunLendingToken.sol";
import { IAmunLendingTokenStorage } from "../../interfaces/IAmunLendingTokenStorage.sol";
import { YVault } from "../../interfaces/YVault.sol";

/**
 * @title Interactive adapter for AmunLending.
 * @dev Implementation of InteractiveAdapter abstract contract.
 * @author Timo <Timo@amun.com>
 */
contract AmunLendingInteractiveAdapter is InteractiveAdapter, ERC20ProtocolAdapter {
    using SafeERC20 for ERC20;
    uint16 internal constant REFERRAL_CODE = 101;

    /**
     * @notice Deposits tokens to the AmunLending.
     * @param tokenAmounts Array of underlying TokenAmounts - TokenAmount struct with
     * underlying tokens addresses, underlying tokens amounts to be deposited, and amount types.
     * @param data ABI-encoded additional parameters:
     *     - lendingToken - AmunLending address.
     * @return tokensToBeWithdrawn Array with one element - AmunLending address.
     * @dev Implementation of InteractiveAdapter function.
     */
    function deposit(TokenAmount[] calldata tokenAmounts, bytes calldata data)
        external
        payable
        override
        returns (address[] memory tokensToBeWithdrawn)
    {
        require(tokenAmounts.length == 1, "ALIA[1]: should be 1 tokenAmount");

        address lendingToken = abi.decode(data, (address));
        require(
            tokenAmounts[0].token == getUnderlyingStablecoin(lendingToken),
            "ALIA: should be underling stablecoin"
        );

        tokensToBeWithdrawn = new address[](1);
        tokensToBeWithdrawn[0] = lendingToken;
        uint256 amount = getAbsoluteAmountDeposit(tokenAmounts[0]);
        ERC20(tokenAmounts[0].token).safeApproveMax(lendingToken, amount, "ALIA[1]");
        try
            IAmunLendingToken(lendingToken).create(
                tokenAmounts[0].token,
                amount,
                address(this),
                0,
                REFERRAL_CODE
            )
        {} catch Error(string memory reason) {
            // solhint-disable-previous-line no-empty-blocks
            revert(reason);
        } catch {
            revert("ALIA: create fail");
        }
    }

    /**
     * @notice Withdraws tokens from the AmunLending.
     * @param tokenAmounts Array with one element - TokenAmount struct with
     *     AmunLending token address, AmunLending token amount to be redeemed, and amount type.
     * @return tokensToBeWithdrawn Array with amun token underlying.
     * @dev Implementation of InteractiveAdapter function.
     */
    function withdraw(TokenAmount[] calldata tokenAmounts, bytes calldata)
        external
        payable
        override
        returns (address[] memory tokensToBeWithdrawn)
    {
        require(tokenAmounts.length == 1, "ALIA[2]: should be 1 tokenAmount");
        address lendingToken = tokenAmounts[0].token;
        uint256 amount = getAbsoluteAmountWithdraw(tokenAmounts[0]);

        tokensToBeWithdrawn = new address[](1);
        tokensToBeWithdrawn[0] = getUnderlyingStablecoin(lendingToken);

        try
            IAmunLendingToken(lendingToken).redeem(
                tokensToBeWithdrawn[0],
                amount,
                address(this),
                0,
                REFERRAL_CODE
            )
        {} catch Error(string memory reason) {
            // solhint-disable-previous-line no-empty-blocks
            revert(reason);
        } catch {
            revert("ALIA: redeem fail");
        }
    }

    function getUnderlyingStablecoin(address lendingToken) internal view returns (address) {
        address limaTokenHelper = IAmunLendingToken(lendingToken).limaTokenHelper();
        address underlyingToken =
            IAmunLendingTokenStorage(limaTokenHelper).currentUnderlyingToken();

        return YVault(underlyingToken).token();
    }
}

