pragma solidity ^0.6.0;

import "./ISetAllowance.sol";

interface IAMM is ISetAllowance {
    function trade(
        address _makerAddress,
        address _fromAssetAddress,
        address _toAssetAddress,
        uint256 _takerAssetAmount,
        uint256 _makerAssetAmount,
        uint256 _feeFactor,
        address _spender,
        address payable _receiver,
        uint256 _nonce,
        uint256 _deadline,
        bytes memory _sig
    ) payable external returns (uint256);
}
