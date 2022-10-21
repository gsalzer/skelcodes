pragma solidity ^0.6.4;

/**
 * @title CompoundInterface
 * @dev Compound CErc20Interface for external functions used on dPiggy.
 * https://github.com/compound-finance/compound-protocol/tree/master/contracts
 */
interface CompoundInterface {
    function balanceOf(address owner) external view returns(uint256);
    function exchangeRateStored() external view returns(uint256);
    function exchangeRateCurrent() external returns(uint256);
    function mint(uint mintAmount) external returns(uint256);
    function redeemUnderlying(uint redeemAmount) external returns(uint256);
    function balanceOfUnderlying(address account) external returns(uint256);
}
