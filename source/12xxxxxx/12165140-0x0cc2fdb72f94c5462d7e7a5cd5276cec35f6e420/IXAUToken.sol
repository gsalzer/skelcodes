// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IXAUToken {

    // EIP20 optional
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    // EIP20
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns(uint256);
    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);
    function allowance(address owner_, address spender) external view returns(uint256);
    function approve(address spender, uint256 value) external returns (bool);

    // ERC20 non-standard methods to mitigate the well-known issues around setting allowances
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    // Rebasing related functionality
    event Rebase(uint256 epoch, uint256 oldScalingFactor, uint256 newScalingFactor);
    event NewRebaser(address oldRebaser, address newRebaser);
    function maxScalingFactor() external view returns (uint256);
    function scalingFactor() external view returns (uint256);
    function rebase(uint256 epoch, uint256 indexDelta, bool positive) external returns (uint256);  // onlyRebaser
    function fromUnderlying(uint256 underlying) external view returns (uint256);
    function toUnderlying(uint256 value) external view returns (uint256);
    function balanceOfUnderlying(address who) external view returns(uint256);
    function rebaser() external view returns (address);
    function setRebaser(address _rebaser) external;  // onlyOwner

    // Fee on transfer related functionality
    event NewTransferHandler(address oldTransferHandler, address newTransferHandler);
    event NewFeeDistributor(address oldFeeDistributor, address newFeeDistributor);
    function transferHandler() external view returns (address);
    function setTransferHandler(address _transferHandler) external;  // onlyOwner
    function feeDistributor() external view returns (address);
    function setFeeDistributor(address _feeDistributor) external;  // onlyOwner

    // Service functionality
    function recoverERC20(address token, address to, uint256 amount) external returns (bool);  // onlyOwner
}

