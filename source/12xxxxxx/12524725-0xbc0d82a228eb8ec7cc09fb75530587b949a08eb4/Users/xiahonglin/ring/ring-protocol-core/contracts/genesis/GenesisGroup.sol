// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "./IGenesisGroup.sol";
import "./IDOInterface.sol";
import "../refs/CoreRef.sol";
import "../external/Decimal.sol";

/// @title Equal access to the first bonding curve transaction and the IDO
/// @author Ring Protocol
contract GenesisGroup is IGenesisGroup, CoreRef {
    using Decimal for Decimal.D256;

    IDOInterface private ido;

    /// @notice the block number of the genesis launch
    uint256 public override launchBlock;

    /// @notice GenesisGroup constructor
    /// @param _core Ring Core address to reference
    /// @param _ido IDO contract to deploy
    constructor(
        address _core,
        address _ido
    )
        CoreRef(_core)
    {
        ido = IDOInterface(_ido);
    }

    /// @notice launch Ring Protocol. Callable once Genesis Period has ended
    function launch() external override nonContract {

        // Complete Genesis
        core().completeGenesisGroup();
        launchBlock = block.number;

        ido.deploy();

        // solhint-disable-next-line not-rely-on-time
        emit Launch(block.timestamp);
    }
}

