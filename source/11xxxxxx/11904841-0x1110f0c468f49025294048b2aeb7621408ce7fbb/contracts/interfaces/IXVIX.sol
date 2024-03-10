// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IXVIX {
    function setGov(address gov) external;
    function setFund(address fund) external;
    function createSafe(address account) external;
    function maxSupply() external view returns (uint256);
    function mint(address account, uint256 amount) external returns (bool);
    function burn(address account, uint256 amount) external returns (bool);
    function toast(uint256 amount) external returns (bool);
    function rebase() external returns (bool);
    function setTransferConfig(
        address msgSender,
        uint256 senderBurnBasisPoints,
        uint256 senderFundBasisPoints,
        uint256 receiverBurnBasisPoints,
        uint256 receiverFundBasisPoints
    ) external;
}

