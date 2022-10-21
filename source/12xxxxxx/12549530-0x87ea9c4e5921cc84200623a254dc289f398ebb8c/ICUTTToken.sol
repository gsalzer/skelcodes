// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICUTTToken {
    function setTreasuryAddress() external;
    
    function mintLiquidityToken() external;

    function mintCuttiesToken() external;

    function mintV3StakingToken() external;

    function mintNFTStakingToken() external;

    function mintSmartFarmingToken() external;

    function setPoolAddress(address pool) external;

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function burn(uint256 amount) external returns (bool);
}

