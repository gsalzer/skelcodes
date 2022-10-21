// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

interface IveCurveVault {
    function CRV() external view returns (address);

    function DELEGATION_TYPEHASH() external view returns (bytes32);

    function DOMAINSEPARATOR() external view returns (bytes32);

    function DOMAIN_TYPEHASH() external view returns (bytes32);

    function LOCK() external view returns (address);

    function PERMIT_TYPEHASH() external view returns (bytes32);

    function acceptGovernance() external;

    function allowance(address account, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function bal() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function checkpoints(address, uint32) external view returns (uint32 fromBlock, uint256 votes);

    function claim() external;

    function claimFor(address recipient) external;

    function claimable(address) external view returns (uint256);

    function decimals() external view returns (uint8);

    function delegate(address delegatee) external;

    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function delegates(address) external view returns (address);

    function deposit(uint256 _amount) external;

    function depositAll() external;

    function feeDistribution() external view returns (address);

    function getCurrentVotes(address account) external view returns (uint256);

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256);

    function governance() external view returns (address);

    function index() external view returns (uint256);

    function name() external view returns (string memory);

    function nonces(address) external view returns (uint256);

    function numCheckpoints(address) external view returns (uint32);

    function pendingGovernance() external view returns (address);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function proxy() external view returns (address);

    function rewards() external view returns (address);

    function setFeeDistribution(address _feeDistribution) external;

    function setGovernance(address _governance) external;

    function setProxy(address _proxy) external;

    function supplyIndex(address) external view returns (uint256);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function update() external;

    function updateFor(address recipient) external;
}

