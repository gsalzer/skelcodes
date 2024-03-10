/*

    Copyright 2021 dYdX Trading Inc.

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { I_StarkwareContract } from "../interfaces/I_StarkwareContracts.sol";

/**
 * @title CurrencyConvertor
 * @author dYdX
 *
 * @notice Contract for depositing to dYdX L2 in non-USDC tokens.
 */
contract CurrencyConvertor is BaseRelayRecipient {
  using SafeERC20 for IERC20;

  // ============ State Variables ============

  I_StarkwareContract public immutable STARKWARE_CONTRACT;

  IERC20 immutable USDC_ADDRESS;

  uint256 immutable USDC_ASSET_TYPE;

  address immutable ETH_PLACEHOLDER_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  // ============ Constructor ============

  constructor(
    I_StarkwareContract starkwareContractAddress,
    IERC20 usdcAddress,
    uint256 usdcAssetType,
    address _trustedForwarder
  ) {
    STARKWARE_CONTRACT = starkwareContractAddress;
    USDC_ADDRESS = usdcAddress;
    USDC_ASSET_TYPE = usdcAssetType;

    // Set the allowance to the highest possible value.
    usdcAddress.safeApprove(address(starkwareContractAddress), type(uint256).max);

    _setTrustedForwarder(_trustedForwarder);
  }

  // ============ Events ============

  event LogConvertedDeposit(
    address indexed sender,
    address tokenFrom,
    uint256 tokenFromAmount,
    uint256 usdcAmount
  );

  // ============ External Functions ============

  function versionRecipient() external override pure returns (string memory) {
    return '1';
  }

  /**
    * @notice Make a deposit to the Starkware Layer2 Solution
    *
    * @param  depositAmount      The amount of USDC to deposit.
    * @param  starkKey           The starkKey of the L2 account to deposit into.
    * @param  positionId         The positionId of the L2 account to deposit into.
    * @param  signature          The signature for registering. NOTE: if length is 0, will not try to register.
    */
  function deposit(
    uint256 depositAmount,
    uint256 starkKey,
    uint256 positionId,
    bytes calldata signature
  ) external {
    if (signature.length > 0) {
      STARKWARE_CONTRACT.registerUser(_msgSender(), starkKey, signature);
    }

    // Send fromToken to this contract.
    USDC_ADDRESS.safeTransferFrom(
      _msgSender(),
      address(this),
      depositAmount
    );

    // Deposit USDC to the L2.
    STARKWARE_CONTRACT.deposit(
      starkKey,
      USDC_ASSET_TYPE,
      positionId,
      depositAmount
    );
  }

  /**
    * @notice Approve the token to swap and then makes a deposit with said token.
    * @dev Emits LogConvertedDeposit event.
    *
    * @param  tokenFrom          The token to convert from.
    * @param  tokenFromAmount    The amount of `tokenFrom` tokens to deposit.
    * @param  minUsdcAmount      The minimum USDC amount the user will accept in a swap.
    * @param  starkKey           The starkKey of the L2 account to deposit into.
    * @param  positionId         The positionId of the L2 account to deposit into.
    * @param  exchange           The exchange being used to swap the taker token for USDC.
    * @param  allowanceTarget    The address being approved for the swap.
    * @param  data               Trade parameters for the exchange.
    * @param  signature          The signature for registering. NOTE: if length is 0, will not try to register.
    */
  function approveSwapAndDepositERC20(
    IERC20 tokenFrom,
    uint256 tokenFromAmount,
    uint256 minUsdcAmount,
    uint256 starkKey,
    uint256 positionId,
    address exchange,
    address allowanceTarget,
    bytes calldata data,
    bytes calldata signature
  )
    external
    returns (uint256)
  {
    approveSwap(allowanceTarget, tokenFrom);
    return depositERC20(
      tokenFrom,
      tokenFromAmount,
      minUsdcAmount,
      starkKey,
      positionId,
      exchange,
      data,
      signature
    );
  }

  // ============ Public Functions ============

  /**
  * Approve an exchange to swap an asset
  *
  * @param exchange Address of exchange that will be swapping a token
  * @param token    Address of token that will be swapped by the exchange
  */
  function approveSwap(
    address exchange,
    IERC20 token
  )
    public
  {
    // safeApprove requires unsetting the allowance first.
    token.safeApprove(exchange, 0);
    token.safeApprove(exchange, type(uint256).max);
  }

  /**
    * @notice Make a deposit to the Starkware Layer2 Solution, after converting funds to USDC.
    *  Funds will be withdrawn from the sender and USDC will be deposited into the trading account
    *  specified by the starkKey and positionId.
    * @dev Emits LogConvertedDeposit event.
    *
    * @param  tokenFrom          The ERC20 token to convert from.
    * @param  tokenFromAmount    The amount of `tokenFrom` tokens to deposit.
    * @param  minUsdcAmount      The minimum USDC amount the user will accept in a swap.
    * @param  starkKey           The starkKey of the L2 account to deposit into.
    * @param  positionId         The positionId of the L2 account to deposit into.
    * @param  exchange           The exchange being used to swap the taker token for USDC.
    * @param  data               Trade parameters for the exchange.
    * @param  signature          The signature for registering. NOTE: if length is 0, will not try to register.
    */
  function depositERC20(
    IERC20 tokenFrom,
    uint256 tokenFromAmount,
    uint256 minUsdcAmount,
    uint256 starkKey,
    uint256 positionId,
    address exchange,
    bytes calldata data,
    bytes calldata signature
  )
    public
    returns (uint256)
  {
    if (signature.length > 0) {
      STARKWARE_CONTRACT.registerUser(_msgSender(), starkKey, signature);
    }

    // Send fromToken to this contract.
    tokenFrom.safeTransferFrom(
      _msgSender(),
      address(this),
      tokenFromAmount
    );

    uint256 originalUsdcBalance = USDC_ADDRESS.balanceOf(address(this));

    // Swap token
    // Limit variables on the stack to avoid “Stack too deep” error.
    {
      (bool success, bytes memory returndata) = exchange.call(data);
      require(success, string(returndata));
    }

    // Deposit change in balance of USDC to the L2 exchange account of the sender.
    uint256 usdcBalanceChange = USDC_ADDRESS.balanceOf(address(this)) - originalUsdcBalance;
    require(usdcBalanceChange >= minUsdcAmount, 'Received USDC is less than minUsdcAmount');

    // Deposit USDC to the L2.
    STARKWARE_CONTRACT.deposit(
      starkKey,
      USDC_ASSET_TYPE,
      positionId,
      usdcBalanceChange
    );

    // Log the result.
    emit LogConvertedDeposit(
      _msgSender(),
      address(tokenFrom),
      tokenFromAmount,
      usdcBalanceChange
    );

    return usdcBalanceChange;
  }

  /**
    * @notice Make a deposit to the Starkware Layer2 Solution, after converting funds to USDC.
    *  Funds will be withdrawn from the sender and USDC will be deposited into the trading account
    *  specified by the starkKey and positionId.
    * @dev Emits LogConvertedDeposit event.
    *
    * @param  minUsdcAmount      The minimum USDC amount the user will accept in a swap.
    * @param  starkKey           The starkKey of the L2 account to deposit into.
    * @param  positionId         The positionId of the L2 account to deposit into.
    * @param  exchange           The exchange being used to swap the taker token for USDC.
    * @param  data               Trade parameters for the exchange.
    * @param  signature          The signature for registering. NOTE: if length is 0, will not try to register.
    */
  function depositEth(
    uint256 minUsdcAmount,
    uint256 starkKey,
    uint256 positionId,
    address exchange,
    bytes calldata data,
    bytes calldata signature
  )
    public
    payable
    returns (uint256)
  {
    if (signature.length > 0) {
      STARKWARE_CONTRACT.registerUser(_msgSender(), starkKey, signature);
    }

    uint256 originalUsdcBalance = USDC_ADDRESS.balanceOf(address(this));

    // Swap token
    (bool success, bytes memory returndata) = exchange.call{ value: msg.value }(data);
    require(success, string(returndata));

    // Deposit change in balance of USDC to the L2 exchange account of the sender.
    uint256 usdcBalanceChange = USDC_ADDRESS.balanceOf(address(this)) - originalUsdcBalance;

    require(usdcBalanceChange >= minUsdcAmount, 'Received USDC is less than minUsdcAmount');

    // Deposit USDC to the L2.
    STARKWARE_CONTRACT.deposit(
      starkKey,
      USDC_ASSET_TYPE,
      positionId,
      usdcBalanceChange
    );


    // Log the result.
    emit LogConvertedDeposit(
      _msgSender(),
      ETH_PLACEHOLDER_ADDRESS,
      msg.value,
      usdcBalanceChange
    );

    return usdcBalanceChange;
  }
}

