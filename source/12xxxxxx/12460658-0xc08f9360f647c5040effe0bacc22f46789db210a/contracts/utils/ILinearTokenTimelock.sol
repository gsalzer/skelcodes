pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title LinearTokenTimelock interface
/// @author Fei Protocol
interface ILinearTokenTimelock {
    // ----------- Events -----------

    event Release(address indexed _beneficiary, address indexed _recipient, uint256 _amount);
    event BeneficiaryUpdate(address indexed _beneficiary);
    event PendingBeneficiaryUpdate(address indexed _pendingBeneficiary);

    // ----------- State changing api -----------

    function release(address to, uint amount) external;

    function releaseMax(address to) external;

    function setPendingBeneficiary(address _pendingBeneficiary) external;

    function acceptBeneficiary() external;


    // ----------- Getters -----------

    function lockedToken() external view returns (IERC20);

    function beneficiary() external view returns (address);

    function pendingBeneficiary() external view returns (address);

    function initialBalance() external view returns (uint256);

    function availableForRelease() external view returns (uint256);

    function totalToken() external view returns(uint256);

    function alreadyReleasedAmount() external view returns (uint256);
}

