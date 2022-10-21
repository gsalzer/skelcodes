// SPDX-License-Identifier: GPL-3.0-or-later
// code borrowed from https://etherscan.io/address/0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d#code

pragma solidity 0.8.6;

interface IAaveProtocolDataProvider {
    function getReserveTokensAddresses(address asset) external view returns (address aTokenAddress, address stableDebtTokenAddress, address variableDebtTokenAddress);
    // solhint-disable-next-line func-name-mixedcase
    function ADDRESSES_PROVIDER() external view returns (address);
}

