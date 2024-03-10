pragma solidity ^0.6.0;

interface IPermanentStorage {
    function wethAddr() external view returns (address);
    function getCurveTokenIndex(address _makerAddr, address _assetAddr) external view returns (int128);
    function setCurveTokenIndex(address _makerAddr, address[] calldata _assetAddrs) external;
    function isTransactionSeen(bytes32 _transactionHash) external view returns (bool);
    function isRelayerValid(address _relayer) external view returns (bool);
    function setTransactionSeen(bytes32 _transactionHash) external;
    function setRelayersValid(address[] memory _relayers, bool[] memory _isValids) external;
}
