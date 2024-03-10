// SPDX-License-Identifier: MIT
pragma solidity =0.7.5;


import "LibBaseAuth.sol";


contract WithCoeff is BaseAuth {
    uint16 private _v1ClaimRatio;
    uint16 private _v2ClaimRatio;
    uint16 private _v1BonusCoeff;
    uint16 private _v2BonusCoeff;


    constructor ()
    {
        _v1ClaimRatio = 133;
        _v2ClaimRatio = 200;
        _v1BonusCoeff = 50;
        _v2BonusCoeff = 100;
    }

    function setCoeff(
        uint16 v1ClaimRatio_,
        uint16 v2ClaimRatio_,
        uint16 v1BonusCoeff_,
        uint16 v2BonusCoeff_
    )
        external
        onlyAgent
    {
        _v1ClaimRatio = v1ClaimRatio_;
        _v2ClaimRatio = v2ClaimRatio_;
        _v1BonusCoeff = v1BonusCoeff_;
        _v2BonusCoeff = v2BonusCoeff_;
    }

    function v1ClaimRatio()
        internal
        view
        returns (uint16)
    {
        return _v1ClaimRatio;
    }

    function v2ClaimRatio()
        internal
        view
        returns (uint16)
    {
        return _v2ClaimRatio;
    }

    function v1BonusCoeff()
        internal
        view
        returns (uint16)
    {
        return _v1BonusCoeff;
    }

    function v2BonusCoeff()
        internal
        view
        returns (uint16)
    {
        return _v2BonusCoeff;
    }
}

