// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

import "./Owned.sol";
import "./RootKit.sol";
import "./IRootKitDistribution.sol";
import "./TokensRecoverable.sol";

contract RootKitLiquidityGeneration is Owned, TokensRecoverable
{
    mapping (address => uint256) public contribution;
    address[] public contributors;

    bool public isActive;

    RootKit immutable rootKit;
    IRootKitDistribution public rootKitDistribution;
    uint256 refundsAllowedUntil;

    constructor (RootKit _rootKit)
    {
        rootKit = _rootKit;
    }

    modifier active()
    {
        require (isActive, "Distribution not active");
        _;
    }

    function contributorsCount() public view returns (uint256) { return contributors.length; }

    function activate(IRootKitDistribution _rootKitDistribution) public ownerOnly()
    {
        require (!isActive && contributors.length == 0 && block.timestamp >= refundsAllowedUntil, "Already activated");        
        require (rootKit.balanceOf(address(this)) == rootKit.totalSupply(), "Missing supply");
        require (address(_rootKitDistribution) != address(0));
        rootKitDistribution = _rootKitDistribution;
        isActive = true;
    }

    function setRootKitDistribution(IRootKitDistribution _rootKitDistribution) public ownerOnly() active()
    {
        require (address(_rootKitDistribution) != address(0));
        if (_rootKitDistribution == rootKitDistribution) { return; }
        rootKitDistribution = _rootKitDistribution;

        // Give everyone 1 day to claim refunds if they don't approve of the new distributor
        refundsAllowedUntil = block.timestamp + 86400;
    }

    function complete() public ownerOnly() active()
    {
        require (block.timestamp >= refundsAllowedUntil, "Refund period is still active");
        isActive = false;
        if (address(this).balance == 0) { return; }
        rootKit.approve(address(rootKitDistribution), uint256(-1));
        rootKitDistribution.distribute{ value: address(this).balance }();
    }

    function allowRefunds() public ownerOnly() active()
    {
        isActive = false;
        refundsAllowedUntil = uint256(-1);
    }

    function claim() public
    {
        uint256 amount = contribution[msg.sender];
        require (amount > 0, "Nothing to claim");
        contribution[msg.sender] = 0;
        if (refundsAllowedUntil > block.timestamp) {
            (bool success,) = msg.sender.call{ value: amount }("");
            require (success, "Transfer failed");
        }
        else {
            rootKitDistribution.claim(msg.sender, amount);
        }
    }

    receive() external payable active()
    {
        uint256 oldContribution = contribution[msg.sender];
        uint256 newContribution = oldContribution + msg.value;
        if (oldContribution == 0 && newContribution > 0) {
            contributors.push(msg.sender);
        }
        contribution[msg.sender] = newContribution;
    }
}
