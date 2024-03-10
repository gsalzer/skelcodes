// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import "./IPCVDeposit.sol";
import "../external/Decimal.sol";

/// @title a Uniswap PCV Controller interface
/// @author Ring Protocol
interface IUniswapPCVController {
    // ----------- Events -----------

    event Reweight(address indexed _caller);

    event Reinvest(address indexed _caller);

    event PCVDepositUpdate(address indexed _pcvDeposit);

    event PCVDepositParametersUpdate(address indexed pcvDeposit, uint24 fee, int24 tickLower, int24 tickUpper);

    event ReweightIncentiveUpdate(uint256 _amount);

    event ReweightMinDistanceUpdate(uint256 _basisPoints);

    event ReweightWithdrawBPsUpdate(uint256 _reweightWithdrawBPs);

    event SwapFeeUpdate(uint24 _fee);

    // ----------- State changing API -----------

    function reweight() external;

    function reinvest() external;

    // ----------- Governor only state changing API -----------

    function forceReweight() external;

    function setPCVDeposit(address _pcvDeposit) external;

    function setPCVDepositParameters(uint24 _fee, int24 _tickLower, int24 _tickUpper) external;

    function setDuration(uint256 _duration) external;

    function setReweightIncentive(uint256 amount) external;

    function setReweightMinDistance(uint256 basisPoints) external;

    function setReweightWithdrawBPs(uint256 _reweightWithdrawBPs) external;

    function setFee(uint24 _fee) external;

    // ----------- Getters -----------

    function fee() external view returns (uint24);

    function pcvDeposit() external view returns (IPCVDeposit);

    function reweightIncentiveAmount() external view returns (uint256);

    function reweightEligible() external view returns (bool);

    function reweightWithdrawBPs() external view returns (uint256);

    function minDistanceForReweight()
        external
        view
        returns (Decimal.D256 memory);
}

