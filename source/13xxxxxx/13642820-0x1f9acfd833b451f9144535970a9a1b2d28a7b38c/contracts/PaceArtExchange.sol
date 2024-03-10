// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./exchange/Exchange.sol";
import "./registry/ProxyRegistry.sol";
import "./modules/TokenTransferProxy.sol";
import "./modules/ERC20.sol";

contract PaceArtExchange is Exchange {

    string public constant name = "Project Wyvern Exchange";

    string public constant version = "2.2";

    string public constant codename = "Lambton Worm";

    /**
     * @dev Initialize a WyvernExchange instance
     * @param registryAddress Address of the registry instance which this Exchange instance will use
     * @param tokenAddress Address of the token used for protocol fees
     */
    constructor (ProxyRegistry registryAddress, TokenTransferProxy tokenTransferProxyAddress, ERC20 tokenAddress) {
        registry = registryAddress;
        tokenTransferProxy = tokenTransferProxyAddress;
        exchangeToken = tokenAddress;
    }

}

