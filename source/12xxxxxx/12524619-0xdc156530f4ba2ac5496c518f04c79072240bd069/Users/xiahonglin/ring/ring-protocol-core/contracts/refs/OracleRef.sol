// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "./IOracleRef.sol";
import "./CoreRef.sol";

/// @title Reference to an Oracle
/// @author Ring Protocol
/// @notice defines some utilities around interacting with the referenced oracle
abstract contract OracleRef is IOracleRef, CoreRef {
    using Decimal for Decimal.D256;

    /// @notice the oracle reference by the contract
    IOracle public override oracle;

    /// @notice OracleRef constructor
    /// @param _core Ring Core to reference
    /// @param _oracle oracle to reference
    constructor(address _core, address _oracle) CoreRef(_core) {
        _setOracle(_oracle);
    }

    /// @notice sets the referenced oracle
    /// @param _oracle the new oracle to reference
    function setOracle(address _oracle) external override onlyGovernor {
        _setOracle(_oracle);
    }

    /// @notice invert a peg price
    /// @param price the peg price to invert
    /// @return the inverted peg as a Decimal
    /// @dev the inverted peg would be X per RUSD
    function invert(Decimal.D256 memory price)
        public
        pure
        override
        returns (Decimal.D256 memory)
    {
        return Decimal.one().div(price);
    }

    /// @notice the peg price of the referenced oracle
    /// @return the peg as a Decimal
    /// @dev the peg is defined as RUSD per X with X being ETH, dollars, etc
    function peg() public view override returns (Decimal.D256 memory) {
        (Decimal.D256 memory _peg, bool valid) = oracle.read();
        require(valid, "OracleRef: oracle invalid");
        return _peg;
    }

    function _setOracle(address _oracle) internal {
        oracle = IOracle(_oracle);
        emit OracleUpdate(_oracle);
    }
}

