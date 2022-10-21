// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IAvalanche {
    event Activated(address indexed user);
    event Claim(address indexed user, uint256 frostAmount);    
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event FrostRewardAdded(address indexed user, uint256 frostReward);
    event EthRewardAdded(address indexed user, uint256 ethReward);

    function active() external view returns (bool);
    function activate() external;

    function addFrostReward(address _from, uint256 _amount) external;
    // function addEthReward() external virtual payable;
    function deposit(uint256 _amount) external;
    function depositFor(address _from, address _user, uint256 _amount) external;
    function claim() external;
    function claimFor(address _user) external;
    function withdraw(uint256 _amount) external;

    function payoutNumber() external view returns (uint256);
    function timeUntilNextPayout() external view returns (uint256); 
    function rewardAtPayout(uint256 _payoutNumber) external view returns (uint256);
}
