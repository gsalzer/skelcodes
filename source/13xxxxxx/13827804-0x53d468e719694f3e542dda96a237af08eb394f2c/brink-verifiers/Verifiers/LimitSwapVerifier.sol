// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

/**
 *    ,,                           ,,                                
 *   *MM                           db                      `7MM      
 *    MM                                                     MM      
 *    MM,dMMb.      `7Mb,od8     `7MM      `7MMpMMMb.        MM  ,MP'
 *    MM    `Mb       MM' "'       MM        MM    MM        MM ;Y   
 *    MM     M8       MM           MM        MM    MM        MM;Mm   
 *    MM.   ,M9       MM           MM        MM    MM        MM `Mb. 
 *    P^YbmdP'      .JMML.       .JMML.    .JMML  JMML.    .JMML. YA.
 *
 *    LimitSwapVerifier.sol :: 0x53D468E719694f3e542Dda96a237Af08eb394f2C
 *    etherscan.io verified 2021-12-18
 */ 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Interfaces/ICallExecutor.sol";
import "../Libraries/Bit.sol";

/// @title Verifier for ERC20 limit swaps
/// @notice These functions should be executed by metaPartialSignedDelegateCall() on Brink account proxy contracts
contract LimitSwapVerifier {
  /// @dev Revert when limit swap is expired
  error Expired();

  /// @dev Revert when swap has not received enough of the output asset to be fulfilled
  error NotEnoughReceived(uint256 amountReceived);

  ICallExecutor internal immutable CALL_EXECUTOR;

  constructor(ICallExecutor callExecutor) {
    CALL_EXECUTOR = callExecutor;
  }

  /// @dev Executes an ERC20 to ERC20 limit swap
  /// @notice This should be executed by metaDelegateCall() or metaDelegateCall_EIP1271() with the following signed and unsigned params
  /// @param bitmapIndex The index of the replay bit's bytes32 slot [signed]
  /// @param bit The value of the replay bit [signed]
  /// @param tokenIn The input token provided for the swap [signed]
  /// @param tokenOut The output token required to be received from the swap [signed]
  /// @param tokenInAmount Amount of tokenIn provided [signed]
  /// @param tokenOutAmount Amount of tokenOut required to be received [signed]
  /// @param expiryBlock The block when the swap expires [signed]
  /// @param to Address of the contract that will fulfill the swap [unsigned]
  /// @param data Data to execute on the `to` contract to fulfill the swap [unsigned]
  function tokenToToken(
    uint256 bitmapIndex, uint256 bit, IERC20 tokenIn, IERC20 tokenOut, uint256 tokenInAmount, uint256 tokenOutAmount,
    uint256 expiryBlock, address to, bytes calldata data
  )
    external
  {
    if (expiryBlock <= block.number) {
      revert Expired();
    }
  
    Bit.useBit(bitmapIndex, bit);

    uint256 tokenOutBalance = tokenOut.balanceOf(address(this));

    tokenIn.transfer(to, tokenInAmount);

    CALL_EXECUTOR.proxyCall(to, data);

    uint256 tokenOutAmountReceived = tokenOut.balanceOf(address(this)) - tokenOutBalance;
    if (tokenOutAmountReceived < tokenOutAmount) {
      revert NotEnoughReceived(tokenOutAmountReceived);
    }
  }

  /// @dev Executes an ETH to ERC20 limit swap
  /// @notice This should be executed by metaDelegateCall() or metaDelegateCall_EIP1271() with the following signed and unsigned params
  /// @param bitmapIndex The index of the replay bit's bytes32 slot [signed]
  /// @param bit The value of the replay bit [signed]
  /// @param token The output token required to be received from the swap [signed]
  /// @param ethAmount Amount of ETH provided [signed]
  /// @param tokenAmount Amount of token required to be received [signed]
  /// @param expiryBlock The block when the swap expires [signed]
  /// @param to Address of the contract that will fulfill the swap [unsigned]
  /// @param data Data to execute on the `to` contract to fulfill the swap [unsigned]
  function ethToToken(
    uint256 bitmapIndex, uint256 bit, IERC20 token, uint256 ethAmount, uint256 tokenAmount, uint256 expiryBlock,
    address to, bytes calldata data
  )
    external
  {
    if (expiryBlock <= block.number) {
      revert Expired();
    }

    Bit.useBit(bitmapIndex, bit);

    uint256 tokenBalance = token.balanceOf(address(this));

    CALL_EXECUTOR.proxyCall{value: ethAmount}(to, data);

    uint256 tokenAmountReceived = token.balanceOf(address(this)) - tokenBalance;
    if (tokenAmountReceived < tokenAmount) {
      revert NotEnoughReceived(tokenAmountReceived);
    }
  }

  /// @dev Executes an ERC20 to ETH limit swap
  /// @notice This should be executed by metaDelegateCall() or metaDelegateCall_EIP1271() with the following signed and unsigned params
  /// @param bitmapIndex The index of the replay bit's bytes32 slot [signed]
  /// @param bit The value of the replay bit [signed]
  /// @param token The input token provided for the swap [signed]
  /// @param tokenAmount Amount of tokenIn provided [signed]
  /// @param ethAmount Amount of ETH to receive [signed]
  /// @param expiryBlock The block when the swap expires [signed]
  /// @param to Address of the contract that will fulfill the swap [unsigned]
  /// @param data Data to execute on the `to` contract to fulfill the swap [unsigned]
  function tokenToEth(
    uint256 bitmapIndex, uint256 bit, IERC20 token, uint256 tokenAmount, uint256 ethAmount, uint256 expiryBlock,
    address to, bytes calldata data
  )
    external
  {
    if (expiryBlock <= block.number) {
      revert Expired();
    }

    Bit.useBit(bitmapIndex, bit);
    
    uint256 ethBalance = address(this).balance;

    token.transfer(to, tokenAmount);

    CALL_EXECUTOR.proxyCall(to, data);

    uint256 ethAmountReceived = address(this).balance - ethBalance;
    if (ethAmountReceived < ethAmount) {
      revert NotEnoughReceived(ethAmountReceived);
    }
  }
}

