pragma solidity >=0.5.0 <0.7.0;

interface ICToken {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function underlying() external view returns (address);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function balanceOf(address user) external view returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

