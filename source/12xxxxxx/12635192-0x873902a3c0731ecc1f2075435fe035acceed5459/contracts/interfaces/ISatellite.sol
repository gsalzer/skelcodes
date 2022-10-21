// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

interface ISatellite {

    function getPowah(address instance, address user, bytes32 params) external view returns(uint powah);
    function getSupply(address instance) external view returns(uint supply);
}
