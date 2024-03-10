// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2020 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice Registry for Curve Pools with Utility functions.

// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;

import "../oz/0.8.0/access/Ownable.sol";
import "../oz/0.8.0/token/ERC20/utils/SafeERC20.sol";

interface ICurveAddressProvider {
    function get_registry() external view returns (address);

    function get_address(uint256 _id) external view returns (address);
}

interface ICurveRegistry {
    function get_pool_from_lp_token(address lpToken)
        external
        view
        returns (address);

    function get_lp_token(address swapAddress) external view returns (address);

    function get_n_coins(address _pool)
        external
        view
        returns (uint256[2] memory);

    function get_coins(address _pool) external view returns (address[8] memory);

    function get_underlying_coins(address _pool)
        external
        view
        returns (address[8] memory);
}

interface ICurveFactoryRegistry {
    function get_n_coins(address _pool) external view returns (uint256);

    function get_coins(address _pool) external view returns (address[2] memory);

    function get_underlying_coins(address _pool)
        external
        view
        returns (address[8] memory);
}

interface ICurveV2Pool {
    function price_oracle(uint256 k) external view returns (uint256);
}

contract Curve_Registry_V2_1 is Ownable {
    using SafeERC20 for IERC20;

    ICurveAddressProvider private constant CurveAddressProvider =
        ICurveAddressProvider(0x0000000022D53366457F9d5E68Ec105046FC4383);
    ICurveRegistry public CurveRegistry;

    ICurveFactoryRegistry public FactoryRegistry;

    address private constant wbtcToken =
        0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address private constant sbtcCrvToken =
        0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3;
    address internal constant ETHAddress =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    mapping(address => bool) public shouldAddUnderlying;
    mapping(address => address) private depositAddresses;

    constructor() {
        CurveRegistry = ICurveRegistry(CurveAddressProvider.get_registry());
        FactoryRegistry = ICurveFactoryRegistry(
            CurveAddressProvider.get_address(3)
        );
    }

    /**
    @notice Checks if the pool is an original (non-factory) pool
    @param swapAddress Curve swap address for the pool
    @return true if pool is a non-factory pool, false otherwise
    */
    function isCurvePool(address swapAddress) public view returns (bool) {
        if (CurveRegistry.get_lp_token(swapAddress) != address(0)) {
            return true;
        }
        return false;
    }

    /**
    @notice Checks if the pool is a factory pool
    @param swapAddress Curve swap address for the pool
    @return true if pool is a factory pool, false otherwise
    */
    function isFactoryPool(address swapAddress) public view returns (bool) {
        if (FactoryRegistry.get_coins(swapAddress)[0] != address(0)) {
            return true;
        }
        return false;
    }

    /**
    @notice Checks if the Curve pool is a metapool
    @notice All factory pools are metapools but not all metapools
    * are factory pools! (e.g. dusd)
    @param swapAddress Curve swap address for the pool
    @return true if the pool is a metapool, false otherwise
    */
    function isMetaPool(address swapAddress) public view returns (bool) {
        if (isCurvePool(swapAddress)) {
            uint256[2] memory poolTokenCounts =
                CurveRegistry.get_n_coins(swapAddress);

            if (poolTokenCounts[0] == poolTokenCounts[1]) return false;
            else return true;
        }
        if (isFactoryPool(swapAddress)) return true;
        return false;
    }

    /**
    @notice Checks if the pool is a Curve V2 pool
    @param swapAddress Curve swap address for the pool
    @return true if pool is a V2 pool, false otherwise
    */
    function isV2Pool(address swapAddress) public view returns (bool) {
        try ICurveV2Pool(swapAddress).price_oracle(0) {
            return true;
        } catch {
            return false;
        }
    }

    /**
    @notice Gets the Curve pool deposit address
    @notice The deposit address is used for pools with wrapped (c, y) tokens
    @param swapAddress Curve swap address for the pool
    @return depositAddress Curve pool deposit address or the swap address if not mapped
    */
    function getDepositAddress(address swapAddress)
        external
        view
        returns (address depositAddress)
    {
        depositAddress = depositAddresses[swapAddress];
        if (depositAddress == address(0)) return swapAddress;
    }

    /**
    @notice Gets the Curve pool swap address
    @notice The token and swap address is the same for metapool/factory pools
    @param tokenAddress Curve swap address for the pool
    @return swapAddress Curve pool swap address or address(0) if pool doesnt exist
    */
    function getSwapAddress(address tokenAddress)
        external
        view
        returns (address swapAddress)
    {
        swapAddress = CurveRegistry.get_pool_from_lp_token(tokenAddress);
        if (swapAddress != address(0)) {
            return swapAddress;
        }
        if (isFactoryPool(tokenAddress)) {
            return tokenAddress;
        }
        return address(0);
    }

    /**
    @notice Gets the Curve pool token address
    @notice The token and swap address is the same for metapool/factory pools
    @param swapAddress Curve swap address for the pool
    @return tokenAddress Curve pool token address or address(0) if pool doesnt exist
    */
    function getTokenAddress(address swapAddress)
        external
        view
        returns (address tokenAddress)
    {
        tokenAddress = CurveRegistry.get_lp_token(swapAddress);
        if (tokenAddress != address(0)) {
            return tokenAddress;
        }
        if (isFactoryPool(swapAddress)) {
            return swapAddress;
        }
        return address(0);
    }

    /**
    @notice Gets the number of non-underlying tokens in a pool
    @param swapAddress Curve swap address for the pool
    @return number of underlying tokens in the pool
    */
    function getNumTokens(address swapAddress) public view returns (uint256) {
        if (isCurvePool(swapAddress)) {
            return CurveRegistry.get_n_coins(swapAddress)[0];
        } else {
            return FactoryRegistry.get_n_coins(swapAddress);
        }
    }

    /**
    @notice Gets an array of underlying pool token addresses
    @param swapAddress Curve swap address for the pool
    @return poolTokens returns 4 element array containing the 
    * addresses of the pool tokens (0 address if pool contains < 4 tokens)
    */
    function getPoolTokens(address swapAddress)
        public
        view
        returns (address[4] memory poolTokens)
    {
        if (isMetaPool(swapAddress)) {
            if (isFactoryPool(swapAddress)) {
                address[2] memory poolUnderlyingCoins =
                    FactoryRegistry.get_coins(swapAddress);
                for (uint256 i = 0; i < 2; i++) {
                    poolTokens[i] = poolUnderlyingCoins[i];
                }
            } else {
                address[8] memory poolUnderlyingCoins =
                    CurveRegistry.get_coins(swapAddress);
                for (uint256 i = 0; i < 2; i++) {
                    poolTokens[i] = poolUnderlyingCoins[i];
                }
            }

            return poolTokens;
        } else {
            address[8] memory poolUnderlyingCoins;
            if (isBtcPool(swapAddress)) {
                poolUnderlyingCoins = CurveRegistry.get_coins(swapAddress);
            } else {
                poolUnderlyingCoins = CurveRegistry.get_underlying_coins(
                    swapAddress
                );
            }
            for (uint256 i = 0; i < 4; i++) {
                poolTokens[i] = poolUnderlyingCoins[i];
            }
        }
    }

    /**
    @notice Checks if the Curve pool contains WBTC
    @param swapAddress Curve swap address for the pool
    @return true if the pool contains WBTC, false otherwise
    */
    function isBtcPool(address swapAddress) public view returns (bool) {
        address[8] memory poolTokens = CurveRegistry.get_coins(swapAddress);
        for (uint256 i = 0; i < 4; i++) {
            if (poolTokens[i] == wbtcToken || poolTokens[i] == sbtcCrvToken)
                return true;
        }
        return false;
    }

    /**
    @notice Checks if the Curve pool contains ETH
    @param swapAddress Curve swap address for the pool
    @return true if the pool contains ETH, false otherwise
    */
    function isEthPool(address swapAddress) external view returns (bool) {
        address[8] memory poolTokens = CurveRegistry.get_coins(swapAddress);
        for (uint256 i = 0; i < 4; i++) {
            if (poolTokens[i] == ETHAddress) {
                return true;
            }
        }
        return false;
    }

    /**
    @notice Check if the pool contains the toToken
    @param swapAddress Curve swap address for the pool
    @param toToken contract address of the token
    @return true if the pool contains the token, false otherwise
    @return index of the token in the pool, 0 if pool does not contain the token
    */
    function isUnderlyingToken(address swapAddress, address toToken)
        external
        view
        returns (bool, uint256)
    {
        address[4] memory poolTokens = getPoolTokens(swapAddress);
        for (uint256 i = 0; i < 4; i++) {
            if (poolTokens[i] == address(0)) return (false, 0);
            if (poolTokens[i] == toToken) return (true, i);
        }
        return (false, 0);
    }

    /**
    @notice Updates to the latest Curve registry from the address provider
    */
    function update_curve_registry() external onlyOwner {
        address new_address = CurveAddressProvider.get_registry();

        require(address(CurveRegistry) != new_address, "Already updated");

        CurveRegistry = ICurveRegistry(new_address);
    }

    /**
    @notice Updates to the latest Curve factory registry from the address provider
    */
    function update_factory_registry() external onlyOwner {
        address new_address = CurveAddressProvider.get_address(3);

        require(address(FactoryRegistry) != new_address, "Already updated");

        FactoryRegistry = ICurveFactoryRegistry(new_address);
    }

    /**
    @notice Add new pools which use the _use_underlying bool
    @param swapAddresses Curve swap addresses for the pool
    @param addUnderlying True if underlying tokens are always added
    */
    function updateShouldAddUnderlying(
        address[] calldata swapAddresses,
        bool[] calldata addUnderlying
    ) external onlyOwner {
        require(
            swapAddresses.length == addUnderlying.length,
            "Mismatched arrays"
        );
        for (uint256 i = 0; i < swapAddresses.length; i++) {
            shouldAddUnderlying[swapAddresses[i]] = addUnderlying[i];
        }
    }

    /**
    @notice Add new pools which use uamounts for add_liquidity
    @param swapAddresses Curve swap addresses to map from
    @param _depositAddresses Curve deposit addresses to map to
    */
    function updateDepositAddresses(
        address[] calldata swapAddresses,
        address[] calldata _depositAddresses
    ) external onlyOwner {
        require(
            swapAddresses.length == _depositAddresses.length,
            "Mismatched arrays"
        );
        for (uint256 i = 0; i < swapAddresses.length; i++) {
            depositAddresses[swapAddresses[i]] = _depositAddresses[i];
        }
    }

    /**
    //@notice Withdraw stuck tokens
    */
    function withdrawTokens(address[] calldata tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 qty;

            if (tokens[i] == ETHAddress) {
                qty = address(this).balance;
                Address.sendValue(payable(owner()), qty);
            } else {
                qty = IERC20(tokens[i]).balanceOf(address(this));
                IERC20(tokens[i]).safeTransfer(owner(), qty);
            }
        }
    }
}

