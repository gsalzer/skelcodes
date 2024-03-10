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

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import { ERC20 } from "../../ERC20.sol";
import { TokenMetadata, Component } from "../../Structs.sol";
import { TokenAdapter } from "../TokenAdapter.sol";

/**
 * @dev CurveRegistry contract interface.
 * Only the functions required for SaddleTokenAdapter contract are added.
 * The CurveRegistry contract is available here
 * github.com/zeriontech/defi-sdk/blob/master/contracts/adapters/curve/CurveRegistry.sol.
 */
interface CurveRegistry {
    function getSwapAndTotalCoins(address) external view returns (address, uint256);
    function getName(address) external view returns (string memory);
}


/**
 * @dev Swap contract interface.
 * Only the functions required for SaddleTokenAdapter contract are added.
 * The Swap contract is available here
 * github.com/saddle-finance/saddle-contract/blob/master/contracts/Swap.sol.
 */
interface Swap {
    function getToken(uint8) external view returns (address);
    function getTokenBalance(uint8) external view returns (uint256);
    function getTokenIndex(address) external view returns (uint8);
}


/**
 * @title Token adapter for Saddle pool tokens.
 * @dev Implementation of TokenAdapter interface.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
contract SaddleTokenAdapter is TokenAdapter {

    address internal constant REGISTRY = 0x86A1755BA805ecc8B0608d56c22716bd1d4B68A8;

    /**
     * @return TokenMetadata struct with ERC20-style token info.
     * @dev Implementation of TokenAdapter interface function.
     */
    function getMetadata(address token) external view override returns (TokenMetadata memory) {
        return TokenMetadata({
            token: token,
            name: getPoolName(token),
            symbol: ERC20(token).symbol(),
            decimals: ERC20(token).decimals()
        });
    }

    /**
     * @return Array of Component structs with underlying tokens rates for the given token.
     * @dev Implementation of TokenAdapter interface function.
     */
    function getComponents(address token) external view override returns (Component[] memory) {
        (address swap, uint256 totalCoins) = CurveRegistry(REGISTRY).getSwapAndTotalCoins(token);

        Component[] memory underlyingComponents= new Component[](totalCoins);

        for (uint256 i = 0; i < totalCoins; i++) {
            address underlyingToken = Swap(swap).getToken(uint8(i));
            underlyingComponents[i] = Component({
                token: underlyingToken,
                tokenType: "ERC20",
                rate: Swap(swap).getTokenBalance(uint8(i)) * 1e18 / ERC20(token).totalSupply()
            });
        }

        return underlyingComponents;
    }

    /**
     * @return Pool name.
     */
    function getPoolName(address token) internal view returns (string memory) {
        return CurveRegistry(REGISTRY).getName(token);
    }
}

