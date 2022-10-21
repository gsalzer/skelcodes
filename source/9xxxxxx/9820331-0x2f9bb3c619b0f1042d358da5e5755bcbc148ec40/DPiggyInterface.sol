pragma solidity ^0.6.4;

/**
 * @title DPiggyDataInterface
 * @dev DPiggyData interface with stored data used by other contracts.
 */
interface DPiggyDataInterface {
    function auc() external view returns(address);
    function dai() external view returns(address);
    function compound() external view returns(address);
    function exchange() external view returns(address);
    function percentagePrecision() external view returns(uint256);
}

/**
 * @title DPiggyInterface
 * @dev DPiggy interface with stored data and functions used by other contracts.
 */
interface DPiggyInterface is DPiggyDataInterface {
    function executionFee(uint256 baseTime) external view returns(uint256);
    function escrowStart(address user) external view returns(uint256);
}
