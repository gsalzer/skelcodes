// SPDX-License-Identifier: Apache 2.0

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity 0.7.4;

import "../utils/0xUtils/Authorizable.sol";
import "../utils/0xUtils/LibRichErrors.sol";
import "../utils/0xUtils/LibSafeMath.sol";
import "../utils/0xUtils/IAssetProxy.sol";
import "../utils/0xUtils/IAssetData.sol";
import "../utils/0xUtils/IERC20Token.sol";
import "./libs/LibStakingRichErrors.sol";
import "./interfaces/IGrgVault.sol";


contract GrgVault is
    Authorizable,
    IGrgVault
{
    using LibSafeMath for uint256;

    // Address of staking proxy contract
    address public stakingProxyAddress;

    // True iff vault has been set to Catastrophic Failure Mode
    bool public isInCatastrophicFailure;

    // Mapping from staker to GRG balance
    mapping (address => uint256) internal _balances;

    // Grg Asset Proxy
    IAssetProxy public grgAssetProxy;

    // Grg Token
    IERC20Token internal _grgToken;

    // Asset data for the ERC20 Proxy
    bytes internal _grgAssetData;

    /// @dev Only stakingProxy can call this function.
    modifier onlyStakingProxy() {
        _assertSenderIsStakingProxy();
        _;
    }

    /// @dev Function can only be called in catastrophic failure mode.
    modifier onlyInCatastrophicFailure() {
        _assertInCatastrophicFailure();
        _;
    }

    /// @dev Function can only be called not in catastropic failure mode
    modifier onlyNotInCatastrophicFailure() {
        _assertNotInCatastrophicFailure();
        _;
    }

    /// @dev Constructor.
    /// @param _grgProxyAddress Address of the RigoBlock Grg Proxy.
    /// @param _grgTokenAddress Address of the Grg Token.
    constructor(
        address _grgProxyAddress,
        address _grgTokenAddress
    )
        Authorizable()
    {
        grgAssetProxy = IAssetProxy(_grgProxyAddress);
        _grgToken = IERC20Token(_grgTokenAddress);
        _grgAssetData = abi.encodeWithSelector(
            IAssetData(address(0)).ERC20Token.selector,
            _grgTokenAddress
        );
    }

    /// @dev Sets the address of the StakingProxy contract.
    /// Note that only the contract owner can call this function.
    /// @param _stakingProxyAddress Address of Staking proxy contract.
    function setStakingProxy(address _stakingProxyAddress)
        external
        override
        onlyAuthorized
    {
        stakingProxyAddress = _stakingProxyAddress;
        emit StakingProxySet(_stakingProxyAddress);
    }

    /// @dev Vault enters into Catastrophic Failure Mode.
    /// *** WARNING - ONCE IN CATOSTROPHIC FAILURE MODE, YOU CAN NEVER GO BACK! ***
    /// Note that only the contract owner can call this function.
    function enterCatastrophicFailure()
        external
        override
        onlyAuthorized
        onlyNotInCatastrophicFailure
    {
        isInCatastrophicFailure = true;
        emit InCatastrophicFailureMode(msg.sender);
    }

    /// @dev Sets the Grg proxy.
    /// Note that only an authorized address can call this function.
    /// Note that this can only be called when *not* in Catastrophic Failure mode.
    /// @param _grgProxyAddress Address of the RigoBlock Grg Proxy.
    function setGrgProxy(address _grgProxyAddress)
        external
        override
        onlyAuthorized
        onlyNotInCatastrophicFailure
    {
        grgAssetProxy = IAssetProxy(_grgProxyAddress);
        emit GrgProxySet(_grgProxyAddress);
    }

    /// @dev Deposit an `amount` of Grg Tokens from `staker` into the vault.
    /// Note that only the Staking contract can call this.
    /// Note that this can only be called when *not* in Catastrophic Failure mode.
    /// @param staker of Grg Tokens.
    /// @param amount of Grg Tokens to deposit.
    function depositFrom(address staker, uint256 amount)
        external
        override
        onlyStakingProxy
        onlyNotInCatastrophicFailure
    {
        // update balance
        _balances[staker] = _balances[staker].safeAdd(amount);

        // notify
        emit Deposit(staker, amount);

        // deposit GRG from staker
        grgAssetProxy.transferFrom(
            _grgAssetData,
            staker,
            address(this),
            amount
        );
    }

    /// @dev Withdraw an `amount` of Grg Tokens to `staker` from the vault.
    /// Note that only the Staking contract can call this.
    /// Note that this can only be called when *not* in Catastrophic Failure mode.
    /// @param staker of Grg Tokens.
    /// @param amount of Grg Tokens to withdraw.
    function withdrawFrom(address staker, uint256 amount)
        external
        override
        onlyStakingProxy
        onlyNotInCatastrophicFailure
    {
        _withdrawFrom(staker, amount);
    }

    /// @dev Withdraw ALL Grg Tokens to `staker` from the vault.
    /// Note that this can only be called when *in* Catastrophic Failure mode.
    /// @param staker of Grg Tokens.
    function withdrawAllFrom(address staker)
        external
        override
        onlyInCatastrophicFailure
        returns (uint256)
    {
        // get total balance
        uint256 totalBalance = _balances[staker];

        // withdraw GRG to staker
        _withdrawFrom(staker, totalBalance);
        return totalBalance;
    }

    /// @dev Returns the balance in Grg Tokens of the `staker`
    /// @return Balance in Grg.
    function balanceOf(address staker)
        external
        view
        override
        returns (uint256)
    {
        return _balances[staker];
    }

    /// @dev Returns the entire balance of Grg tokens in the vault.
    function balanceOfGrgVault()
        external
        view
        override
        returns (uint256)
    {
        return _grgToken.balanceOf(address(this));
    }

    /// @dev Withdraw an `amount` of Grg Tokens to `staker` from the vault.
    /// @param staker of Grg Tokens.
    /// @param amount of Grg Tokens to withdraw.
    function _withdrawFrom(address staker, uint256 amount)
        internal
    {
        // update balance
        // note that this call will revert if trying to withdraw more
        // than the current balance
        _balances[staker] = _balances[staker].safeSub(amount);

        // notify
        emit Withdraw(staker, amount);

        // withdraw GRG to staker
        _grgToken.transfer(
            staker,
            amount
        );
    }

    /// @dev Asserts that sender is stakingProxy contract.
    function _assertSenderIsStakingProxy()
        private
        view
    {
        if (msg.sender != stakingProxyAddress) {
            LibRichErrors.rrevert(LibStakingRichErrors.OnlyCallableByStakingContractError(
                msg.sender
            ));
        }
    }

    /// @dev Asserts that vault is in catastrophic failure mode.
    function _assertInCatastrophicFailure()
        private
        view
    {
        if (!isInCatastrophicFailure) {
            LibRichErrors.rrevert(LibStakingRichErrors.OnlyCallableIfInCatastrophicFailureError());
        }
    }

    /// @dev Asserts that vault is not in catastrophic failure mode.
    function _assertNotInCatastrophicFailure()
        private
        view
    {
        if (isInCatastrophicFailure) {
            LibRichErrors.rrevert(LibStakingRichErrors.OnlyCallableIfNotInCatastrophicFailureError());
        }
    }
}

