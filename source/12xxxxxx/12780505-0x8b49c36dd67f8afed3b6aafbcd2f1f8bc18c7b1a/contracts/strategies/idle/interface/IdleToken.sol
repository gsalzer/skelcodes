/**
 * @title: Idle Token interface
 * @author: Idle Labs Inc., idle.finance
 */
pragma solidity 0.7.3;

interface IIdleTokenV3_1 {
    function tokenPrice() external view returns (uint256 price);
    function token() external view returns (address);
    function getAPRs() external view returns (address[] memory addresses, uint256[] memory aprs);
    function mintIdleToken(uint256 _amount, bool _skipRebalance, address _referral) external returns (uint256 mintedTokens);
    function redeemIdleToken(uint256 _amount) external returns (uint256 redeemedTokens);
    function redeemInterestBearingTokens(uint256 _amount) external;
    function rebalance() external returns (bool);
}

