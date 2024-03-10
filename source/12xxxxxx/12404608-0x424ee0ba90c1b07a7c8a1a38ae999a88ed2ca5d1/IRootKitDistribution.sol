// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

interface IRootKitDistribution
{
    function distributionComplete() external view returns (bool);
    
    function distribute() external payable;
    function claim(address _to, uint256 _contribution) external;
}
