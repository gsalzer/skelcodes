pragma solidity ^0.6.0;

interface IPermanentStorageV1 {
    function wethAddr() external view returns (address);
    function getCurveTokenIndex(address _makerAddr, address _assetAddr) external view returns (int128);
    function setCurveTokenIndex(address _makerAddr, address[] calldata _assetAddrs) external;
    function getNonce(address _user) external view returns (uint256);
    function increNonce(address _user) external;
    function getTransactionUser(bytes32 _transactionHash) external view returns (address);
    function setTransactionUser(bytes32 _transactionHash, address _user) external;
    function isValidMM(address _marketMaker) external view returns (bool);
    function registerMM(address _marketMaker, bool _add) external;
}
