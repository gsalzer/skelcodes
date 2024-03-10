// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

interface IATokenV1 {
    function UINT_MAX_VALUE() external view returns (uint256);

    function allowInterestRedirectionTo(address _to) external;

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function balanceOf(address _user) external view returns (uint256);

    function burnOnLiquidation(address _account, uint256 _value) external;

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function getInterestRedirectionAddress(address _user) external view returns (address);

    function getRedirectedBalance(address _user) external view returns (uint256);

    function getUserIndex(address _user) external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function isTransferAllowed(address _user, uint256 _amount) external view returns (bool);

    function mintOnDeposit(address _account, uint256 _amount) external;

    function name() external view returns (string memory);

    function principalBalanceOf(address _user) external view returns (uint256);

    function redeem(uint256 _amount) external;

    function redirectInterestStream(address _to) external;

    function redirectInterestStreamOf(address _from, address _to) external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferOnLiquidation(
        address _from,
        address _to,
        uint256 _value
    ) external;

    function underlyingAssetAddress() external view returns (address);
}

