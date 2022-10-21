pragma solidity ^0.6.0;

interface IAMMV1 {
    function getMakerOutAmount(
        address _makerAddress,
        address _fromAssetAddress,
        address _toAssetAddress,
        uint256 _takerAssetAmount
    ) external view returns (uint256);

    function getBestOutAmount(
        address[] memory _makerAddresses,
        address _fromAssetAddress,
        address _toAssetAddress,
        uint256 _takerAssetAmount
    ) external view returns (address bestMaker, uint256 bestAmount);

    function getTakerInAmount(
        address _makerAddress,
        address _fromAssetAddress,
        address _toAssetAddress,
        uint256 _makerAssetAmount
    ) external view returns (uint256);

    function getBestInAmount(
        address[] memory _makerAddresses,
        address _fromAssetAddress,
        address _toAssetAddress,
        uint256 _makerAssetAmount
    ) external view returns (address bestMaker, uint256 bestAmount);

    function trade(
        address _makerAddress,
        address _fromAssetAddress,
        address _toAssetAddress,
        uint256 _takerAssetAmount,
        uint256 _makerAssetAmount,
        address _spender,
        uint256 deadline
    ) payable external returns (uint256);
}
