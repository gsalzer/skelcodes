// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {
    IERC20,
    IDetailedERC20,
    AccessControl,
    INameIdentifier,
    ReentrancyGuard
} from "contracts/common/Imports.sol";
import {Address, EnumerableSet} from "contracts/libraries/Imports.sol";
import {IAddressRegistryV2} from "contracts/registry/Imports.sol";

import {IErc20Allocation} from "./IErc20Allocation.sol";
import {AssetAllocationBase} from "./AssetAllocationBase.sol";

abstract contract Erc20AllocationConstants is INameIdentifier {
    string public constant override NAME = "erc20Allocation";
}

contract Erc20Allocation is
    IErc20Allocation,
    AssetAllocationBase,
    Erc20AllocationConstants,
    AccessControl,
    ReentrancyGuard
{
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _tokenAddresses;
    mapping(address => TokenData) private _tokenToData;

    constructor(address addressRegistry_) public {
        require(addressRegistry_.isContract(), "INVALID_ADDRESS_REGISTRY");
        IAddressRegistryV2 addressRegistry =
            IAddressRegistryV2(addressRegistry_);
        _setupRole(DEFAULT_ADMIN_ROLE, addressRegistry.emergencySafeAddress());
        _setupRole(CONTRACT_ROLE, addressRegistry.mAptAddress());
        _setupRole(ADMIN_ROLE, addressRegistry.adminSafeAddress());
    }

    function registerErc20Token(IDetailedERC20 token)
        external
        override
        nonReentrant
        onlyAdminOrContractRole
    {
        string memory symbol = token.symbol();
        uint8 decimals = token.decimals();
        _registerErc20Token(token, symbol, decimals);
    }

    function registerErc20Token(IDetailedERC20 token, string calldata symbol)
        external
        override
        nonReentrant
        onlyAdminRole
    {
        uint8 decimals = token.decimals();
        _registerErc20Token(token, symbol, decimals);
    }

    function registerErc20Token(
        IERC20 token,
        string calldata symbol,
        uint8 decimals
    ) external override nonReentrant onlyAdminRole {
        _registerErc20Token(token, symbol, decimals);
    }

    function removeErc20Token(IERC20 token)
        external
        override
        nonReentrant
        onlyAdminRole
    {
        _tokenAddresses.remove(address(token));
        delete _tokenToData[address(token)];

        emit Erc20TokenRemoved(token);
    }

    function isErc20TokenRegistered(IERC20 token)
        external
        view
        override
        returns (bool)
    {
        return _tokenAddresses.contains(address(token));
    }

    function isErc20TokenRegistered(IERC20[] calldata tokens)
        external
        view
        override
        returns (bool)
    {
        uint256 length = tokens.length;
        for (uint256 i = 0; i < length; i++) {
            if (!_tokenAddresses.contains(address(tokens[i]))) {
                return false;
            }
        }

        return true;
    }

    function balanceOf(address account, uint8 tokenIndex)
        external
        view
        override
        returns (uint256)
    {
        address token = addressOf(tokenIndex);
        return IERC20(token).balanceOf(account);
    }

    function tokens() public view override returns (TokenData[] memory) {
        TokenData[] memory _tokens = new TokenData[](_tokenAddresses.length());
        for (uint256 i = 0; i < _tokens.length; i++) {
            address tokenAddress = _tokenAddresses.at(i);
            _tokens[i] = _tokenToData[tokenAddress];
        }
        return _tokens;
    }

    function _registerErc20Token(
        IERC20 token,
        string memory symbol,
        uint8 decimals
    ) internal {
        require(address(token).isContract(), "INVALID_ADDRESS");
        require(bytes(symbol).length != 0, "INVALID_SYMBOL");
        _tokenAddresses.add(address(token));
        _tokenToData[address(token)] = TokenData(
            address(token),
            symbol,
            decimals
        );

        emit Erc20TokenRegistered(token, symbol, decimals);
    }
}

