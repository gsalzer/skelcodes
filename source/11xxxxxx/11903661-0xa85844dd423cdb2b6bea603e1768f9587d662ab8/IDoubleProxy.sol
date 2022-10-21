// SPDX-License-Identifier: GPL3

pragma solidity =0.8.0;

interface IDoubleProxy {
    function init(address[] calldata proxyList, address currentProxy) external;

    function proxy() external view returns (address);

    function setProxy() external;

    function isProxy(address) external view returns (bool);

    function proxiesLength() external view returns (uint256);

    function proxies(uint256 start, uint256 offset) external view returns (address[] memory);

    function proxies() external view returns (address[] memory);
}

