// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {INameIdentifier} from "contracts/common/Imports.sol";
import {Curve3poolUnderlyerConstants} from "contracts/protocols/curve/3pool/Constants.sol";

abstract contract CurveUsdtConstants is
    Curve3poolUnderlyerConstants,
    INameIdentifier
{
    string public constant override NAME = "curve-usdt";

    address public constant STABLE_SWAP_ADDRESS =
        0x52EA46506B9CC5Ef470C5bf89f17Dc28bB35D85C;
    address public constant DEPOSIT_ZAP_ADDRESS =
        0xac795D2c97e60DF6a99ff1c814727302fD747a80;
    address public constant LP_TOKEN_ADDRESS =
        0x9fC689CCaDa600B6DF723D9E47D84d76664a1F23;
    address public constant LIQUIDITY_GAUGE_ADDRESS =
        0xBC89cd85491d81C6AD2954E6d0362Ee29fCa8F53;

    address public constant CDAI_ADDRESS =
        0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address public constant CUSDC_ADDRESS =
        0x39AA39c021dfbaE8faC545936693aC917d5E7563;
}

