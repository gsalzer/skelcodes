// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";

import "./Subscriptions.sol";
import "./ContractRegistry.sol";

contract MonthlySubscriptionPlan is ContractRegistryAccessor {

    string public tier;
    uint256 public monthlyRate;

    IERC20 public erc20;

    constructor(IContractRegistry _contractRegistry, address _registryAdmin, IERC20 _erc20, string memory _tier, uint256 _monthlyRate) ContractRegistryAccessor(_contractRegistry, _registryAdmin) public {
        require(bytes(_tier).length > 0, "must specify a valid tier label");

        tier = _tier;
        erc20 = _erc20;
        monthlyRate = _monthlyRate;
    }

    /*
     *   External functions
     */

    /// @dev Creates a new VC (msg.sender is the VC owner)
    function createVC(string calldata name, uint256 amount, bool isCertified, string calldata deploymentSubset) external {
        require(amount > 0, "must include funds");

        ISubscriptions subs = ISubscriptions(getSubscriptionsContract());
        require(erc20.transferFrom(msg.sender, address(this), amount), "failed to transfer subscription fees");
        require(erc20.approve(address(subs), amount), "failed to transfer subscription fees");
        subs.createVC(name, tier, monthlyRate, amount, msg.sender, isCertified, deploymentSubset);
    }

    /// @dev Extends the subscription of an existing VC
    function extendSubscription(uint256 vcId, uint256 amount) external {
        require(amount > 0, "must include funds");

        ISubscriptions subs = ISubscriptions(getSubscriptionsContract());
        require(erc20.transferFrom(msg.sender, address(this), amount), "failed to transfer subscription fees from vc payer to subscriber");
        require(erc20.approve(address(subs), amount), "failed to approve subscription fees to subscriptions by subscriber");
        subs.extendSubscription(vcId, amount, tier, monthlyRate, msg.sender);
    }

}

