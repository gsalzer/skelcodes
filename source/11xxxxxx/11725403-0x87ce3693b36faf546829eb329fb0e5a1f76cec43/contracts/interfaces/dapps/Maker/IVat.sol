// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IVat {
    function ilks(bytes32)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function dai(address) external view returns (uint256);

    function urns(bytes32, address) external view returns (uint256, uint256);

    function debt() external view returns (uint256);

    // solhint-disable-next-line
    function Line() external view returns (uint256);
}

