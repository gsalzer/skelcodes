// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "../interfaces/IStakeUniswapV3Proxy2.sol";
import "../interfaces/IStakeCoinageFactory.sol";
import "../interfaces/IStakeRegistry.sol";

import "./StakeUniswapV3Storage.sol";
import "../common/AccessibleCommon.sol";
import "./ProxyBase.sol";
import "./CoinageFactorySLOT.sol";

/// @title Proxy for stake based coinage contract
contract StakeUniswapV3Proxy2 is
    StakeUniswapV3Storage,
    AccessibleCommon,
    ProxyBase,
    CoinageFactorySLOT,
    IStakeUniswapV3Proxy2
{
    mapping(uint256 => address) public proxyImplementation;
    mapping(address => bool) public aliveImplementation;
    mapping(bytes4 => address) public selectorImplementation;

    constructor() {
    }

    /// @dev view implementation address of the proxy[index]
    /// @param _index index of proxy
    /// @return address of the implementation
    function implementation2(uint256 _index)
        external
        view
        override
        returns (address)
    {
        return _implementation2(_index);
    }

    /// @dev set the implementation address and status of the proxy[index]
    /// @param newImplementation Address of the new implementation.
    /// @param _index index
    /// @param _alive _alive
    function setImplementation2(
        address newImplementation,
        uint256 _index,
        bool _alive
    ) external override onlyOwner {
        _setImplementation2(newImplementation, _index, _alive);
    }

    /// @dev set alive status of implementation
    /// @param newImplementation Address of the new implementation.
    /// @param _alive alive status
    function setAliveImplementation2(address newImplementation, bool _alive)
        public
        override
        onlyOwner
    {
        _setAliveImplementation2(newImplementation, _alive);
    }

    /// @dev set selectors of Implementation
    /// @param _selectors being added selectors
    /// @param _imp implementation address
    function setSelectorImplementations2(
        bytes4[] calldata _selectors,
        address _imp
    ) public override onlyOwner {
        require(
            _selectors.length > 0,
            "Stake1Proxy: _selectors's size is zero"
        );
        require(aliveImplementation[_imp], "StakeUniswapV3Proxy2: _imp is not alive");

        for (uint256 i = 0; i < _selectors.length; i++) {
            require(
                selectorImplementation[_selectors[i]] != _imp,
                "StakeUniswapV3Proxy2: same imp"
            );
            selectorImplementation[_selectors[i]] = _imp;
        }
    }

    /// @dev set the implementation address and status of the proxy[index]
    /// @param newImplementation Address of the new implementation.
    /// @param _index index of proxy
    /// @param _alive alive status
    function _setImplementation2(
        address newImplementation,
        uint256 _index,
        bool _alive
    ) internal {
        require(
            Address.isContract(newImplementation),
            "StakeUniswapV3Proxy2: Cannot set a proxy implementation to a non-contract address"
        );
        if (_alive) proxyImplementation[_index] = newImplementation;
        _setAliveImplementation2(newImplementation, _alive);
    }

    /// @dev set alive status of implementation
    /// @param newImplementation Address of the new implementation.
    /// @param _alive alive status
    function _setAliveImplementation2(address newImplementation, bool _alive)
        internal
    {
        aliveImplementation[newImplementation] = _alive;
    }

    /// @dev view implementation address of the proxy[index]
    /// @param _index index of proxy
    /// @return impl address of the implementation
    function _implementation2(uint256 _index)
        internal
        view
        returns (address impl)
    {
        return proxyImplementation[_index];
    }

    /// @dev view implementation address of selector of function
    /// @param _selector selector of function
    /// @return impl address of the implementation
    function getSelectorImplementation2(bytes4 _selector)
        public
        view
        override
        returns (address impl)
    {
        if (selectorImplementation[_selector] == address(0))
            return proxyImplementation[0];
        else if (aliveImplementation[selectorImplementation[_selector]])
            return selectorImplementation[_selector];
        else return proxyImplementation[0];
    }

    /// @dev receive ether
    receive() external payable {
        _fallback();
    }

    /// @dev fallback function , execute on undefined function call
    fallback() external payable {
        _fallback();
    }

    /// @dev fallback function , execute on undefined function call
    function _fallback() internal {
        address _impl = getSelectorImplementation2(msg.sig);
        require(_impl != address(0) && !pauseProxy, "StakeUniswapV3Proxy2: impl OR proxy is false");

        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
                // delegatecall returns 0 on error.
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }
}

