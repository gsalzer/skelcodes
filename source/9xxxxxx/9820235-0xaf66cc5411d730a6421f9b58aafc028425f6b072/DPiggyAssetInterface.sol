pragma solidity ^0.6.4;

/**
 * @title DPiggyAssetInterface
 * @dev DPiggyAsset interface for external functions used directly on dPiggy.
 */
interface DPiggyAssetInterface {
    function getUserProfitsAndFeeAmount(address user) external view returns(uint256, uint256, uint256);
    function setMinimumTimeBetweenExecutions(uint256 time) external;
    function deposit(address user, uint256 amount) external;
    function addEscrow(address user) external returns(bool);
}
