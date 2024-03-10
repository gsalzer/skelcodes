// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IHegicETHPoolV888 {
    function INITIAL_RATE() external view returns (uint256);

    function _revertTransfersInLockUpPeriod(address)
        external
        view
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function lastProvideTimestamp(address) external view returns (uint256);

    function lockedAmount() external view returns (uint256);

    function lockedLiquidity(uint256)
        external
        view
        returns (
            uint256 amount,
            uint256 premium,
            bool locked
        );

    function lockedPremium() external view returns (uint256);

    function lockupPeriod() external view returns (uint256);

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferOwnership(address newOwner) external;

    function setLockupPeriod(uint256 value) external;

    function revertTransfersInLockUpPeriod(bool value) external;

    function provide(uint256 minMint) external returns (uint256 mint);

    function withdraw(uint256 amount, uint256 maxBurn)
        external
        returns (uint256 burn);

    function lock(uint256 id, uint256 amount) external;

    function unlock(uint256 id) external;

    function send(
        uint256 id,
        address to,
        uint256 amount
    ) external;

    function shareOf(address account) external view returns (uint256 share);

    function availableBalance() external view returns (uint256 balance);

    function totalBalance() external view returns (uint256 balance);
}

