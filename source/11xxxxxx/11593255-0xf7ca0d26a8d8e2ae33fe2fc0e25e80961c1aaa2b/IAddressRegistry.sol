// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IAddressRegistry {
    event AvalancheUpdated(address indexed newAddress);
    event LGEUpdated(address indexed newAddress);
    event LodgeUpdated(address indexed newAddress);
    event LoyaltyUpdated(address indexed newAddress);
    event FrostUpdated(address indexed newAddress);
    event FrostPoolUpdated(address indexed newAddress);
    event SlopesUpdated(address indexed newAddress);
    event SnowPatrolUpdated(address indexed newAddress);
    event TreasuryUpdated(address indexed newAddress);
    event UniswapRouterUpdated(address indexed newAddress);
    event VaultUpdated(address indexed newAddress);
    event WethUpdated(address indexed newAddress);
    
    function getAvalanche() external view returns (address);
    function setAvalanche(address _address) external;

    function getLGE() external view returns (address);
    function setLGE(address _address) external;

    function getLodge() external view returns (address);
    function setLodge(address _address) external;

    function getLoyalty() external view returns (address);
    function setLoyalty(address _address) external;

    function getFrost() external view returns (address);
    function setFrost(address _address) external;

    function getFrostPool() external view returns (address);
    function setFrostPool(address _address) external;

    function getSlopes() external view returns (address);
    function setSlopes(address _address) external;

    function getSnowPatrol() external view returns (address);
    function setSnowPatrol(address _address) external;

    function getTreasury() external view returns (address payable);
    function setTreasury(address _address) external;

    function getUniswapRouter() external view returns (address);
    function setUniswapRouter(address _address) external;

    function getVault() external view returns (address);
    function setVault(address _address) external;

    function getWeth() external view returns (address);
    function setWeth(address _address) external;
}
