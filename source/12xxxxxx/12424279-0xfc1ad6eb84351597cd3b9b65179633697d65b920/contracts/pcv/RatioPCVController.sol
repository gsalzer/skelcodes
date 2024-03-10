pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../refs/CoreRef.sol";
import "./IPCVDeposit.sol";

/// @title a PCV controller for moving a ratio of the total value in the PCV deposit
/// @author Fei Protocol
contract RatioPCVController is CoreRef {
    
    uint256 public constant BASIS_POINTS_GRANULARITY = 10_000;

    event Withdraw(address indexed pcvDeposit, address indexed to, uint256 amount);

    /// @notice PCV controller constructor
    /// @param _core Fei Core for reference
    constructor(
        address _core
    ) public CoreRef(_core) {}

    /// @notice withdraw tokens from the input PCV deposit in basis points terms
    /// @param to the address to send PCV to
    function withdrawRatio(IPCVDeposit pcvDeposit, address to, uint256 basisPoints)
        public
        onlyPCVController
        whenNotPaused
    {
        require(basisPoints <= BASIS_POINTS_GRANULARITY, "RatioPCVController: basisPoints too high");
        uint256 amount = pcvDeposit.totalValue() * basisPoints / BASIS_POINTS_GRANULARITY;
        require(amount != 0, "RatioPCVController: no value to withdraw");

        pcvDeposit.withdraw(to, amount);
        emit Withdraw(address(pcvDeposit), to, amount);
    }
}

