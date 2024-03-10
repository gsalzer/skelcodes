// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

import {MCD_MANAGER} from "../../constants/CMaker.sol";
import {INSTA_MAPPING} from "../../constants/CInstaDapp.sol";
import {
    ITokenJoinInterface
} from "../../interfaces/dapps/Maker/ITokenJoinInterface.sol";
import {IMcdManager} from "../../interfaces/dapps/Maker/IMcdManager.sol";
import {InstaMapping} from "../../interfaces/InstaDapp/IInstaDapp.sol";
import {IVat} from "../../interfaces/dapps/Maker/IVat.sol";
import {RAY, add, sub, mul} from "../../vendor/DSMath.sol";
import {_stringToBytes32, _convertTo18} from "../../vendor/Convert.sol";

function _getMakerVaultDebt(uint256 _vaultId) view returns (uint256 wad) {
    IMcdManager manager = IMcdManager(MCD_MANAGER);

    (bytes32 ilk, address urn) = _getVaultData(manager, _vaultId);
    IVat vat = IVat(manager.vat());
    (, uint256 rate, , , ) = vat.ilks(ilk);
    (, uint256 art) = vat.urns(ilk, urn);
    uint256 dai = vat.dai(urn);

    uint256 rad = sub(mul(art, rate), dai);
    wad = rad / RAY;

    wad = mul(wad, RAY) < rad ? wad + 1 : wad;
}

function _getMakerRawVaultDebt(uint256 _vaultId) view returns (uint256 tab) {
    IMcdManager manager = IMcdManager(MCD_MANAGER);

    (bytes32 ilk, address urn) = _getVaultData(manager, _vaultId);
    IVat vat = IVat(manager.vat());
    (, uint256 rate, , , ) = vat.ilks(ilk);
    (, uint256 art) = vat.urns(ilk, urn);

    uint256 rad = mul(art, rate);

    tab = rad / RAY;
    tab = mul(tab, RAY) < rad ? tab + 1 : tab;
}

function _getMakerVaultCollateralBalance(uint256 _vaultId)
    view
    returns (uint256)
{
    IMcdManager manager = IMcdManager(MCD_MANAGER);

    IVat vat = IVat(manager.vat());
    (bytes32 ilk, address urn) = _getVaultData(manager, _vaultId);
    (uint256 ink, ) = vat.urns(ilk, urn);

    return ink;
}

function _vaultWillBeSafe(
    uint256 _vaultId,
    uint256 _amtToBorrow,
    uint256 _colToDeposit
) view returns (bool) {
    require(_vaultId != 0, "_vaultWillBeSafe: invalid vault id.");

    IMcdManager manager = IMcdManager(MCD_MANAGER);

    (bytes32 ilk, address urn) = _getVaultData(manager, _vaultId);

    ITokenJoinInterface tokenJoinContract =
        ITokenJoinInterface(InstaMapping(INSTA_MAPPING).gemJoinMapping(ilk));

    IVat vat = IVat(manager.vat());
    (, uint256 rate, uint256 spot, , ) = vat.ilks(ilk);
    (uint256 ink, uint256 art) = vat.urns(ilk, urn);
    uint256 dai = vat.dai(urn);

    uint256 dink = _convertTo18(tokenJoinContract.dec(), _colToDeposit);
    uint256 dart = _getBorrowAmt(_amtToBorrow, dai, rate);

    ink = add(ink, dink);
    art = add(art, dart);

    uint256 tab = mul(rate, art);

    return tab <= mul(ink, spot);
}

function _newVaultWillBeSafe(
    string memory _colType,
    uint256 _amtToBorrow,
    uint256 _colToDeposit
) view returns (bool) {
    IMcdManager manager = IMcdManager(MCD_MANAGER);
    IVat vat = IVat(manager.vat());

    bytes32 ilk = _stringToBytes32(_colType);

    (, uint256 rate, uint256 spot, , ) = vat.ilks(ilk);

    ITokenJoinInterface tokenJoinContract =
        ITokenJoinInterface(InstaMapping(INSTA_MAPPING).gemJoinMapping(ilk));

    uint256 ink = _convertTo18(tokenJoinContract.dec(), _colToDeposit);
    uint256 art = _getBorrowAmt(_amtToBorrow, 0, rate);

    uint256 tab = mul(rate, art);

    return tab <= mul(ink, spot);
}

function _debtCeilingIsReachedNewVault(
    string memory _colType,
    uint256 _amtToBorrow
) view returns (bool) {
    IMcdManager manager = IMcdManager(MCD_MANAGER);
    IVat vat = IVat(manager.vat());

    bytes32 ilk = _stringToBytes32(_colType);

    (uint256 Art, uint256 rate, , uint256 line, ) = vat.ilks(ilk);
    uint256 Line = vat.Line();
    uint256 debt = vat.debt();

    uint256 dart = _getBorrowAmt(_amtToBorrow, 0, rate);
    uint256 dtab = mul(rate, dart);

    debt = add(debt, dtab);
    Art = add(Art, dart);

    return mul(Art, rate) > line || debt > Line;
}

function _debtCeilingIsReached(uint256 _vaultId, uint256 _amtToBorrow)
    view
    returns (bool)
{
    IMcdManager manager = IMcdManager(MCD_MANAGER);
    IVat vat = IVat(manager.vat());

    (bytes32 ilk, address urn) = _getVaultData(manager, _vaultId);

    (uint256 Art, uint256 rate, , uint256 line, ) = vat.ilks(ilk);
    uint256 dai = vat.dai(urn);
    uint256 Line = vat.Line();
    uint256 debt = vat.debt();

    uint256 dart = _getBorrowAmt(_amtToBorrow, dai, rate);
    uint256 dtab = mul(rate, dart);

    debt = add(debt, dtab);
    Art = add(Art, dart);

    return mul(Art, rate) > line || debt > Line;
}

function _debtIsDustNewVault(string memory _colType, uint256 _amtToBorrow)
    view
    returns (bool)
{
    IMcdManager manager = IMcdManager(MCD_MANAGER);
    IVat vat = IVat(manager.vat());

    bytes32 ilk = _stringToBytes32(_colType);

    (, uint256 rate, , , uint256 dust) = vat.ilks(ilk);
    uint256 art = _getBorrowAmt(_amtToBorrow, 0, rate);

    uint256 tab = mul(rate, art);

    return tab < dust;
}

function _debtIsDust(uint256 _vaultId, uint256 _amtToBorrow)
    view
    returns (bool)
{
    IMcdManager manager = IMcdManager(MCD_MANAGER);
    IVat vat = IVat(manager.vat());

    (bytes32 ilk, address urn) = _getVaultData(manager, _vaultId);
    (, uint256 art) = vat.urns(ilk, urn);
    (, uint256 rate, , , uint256 dust) = vat.ilks(ilk);

    uint256 dai = vat.dai(urn);
    uint256 dart = _getBorrowAmt(_amtToBorrow, dai, rate);
    art = add(art, dart);
    uint256 tab = mul(rate, art);

    return tab < dust;
}

function _getVaultData(IMcdManager manager, uint256 vault)
    view
    returns (bytes32 ilk, address urn)
{
    ilk = manager.ilks(vault);
    urn = manager.urns(vault);
}

function _getBorrowAmt(
    uint256 _amt,
    uint256 _dai,
    uint256 _rate
) pure returns (uint256 dart) {
    dart = sub(mul(_amt, RAY), _dai) / _rate;
    dart = mul(dart, _rate) < mul(_amt, RAY) ? dart + 1 : dart;
}

function _isVaultOwner(uint256 _vaultId, address _owner) view returns (bool) {
    if (_vaultId == 0) return false;

    try IMcdManager(MCD_MANAGER).owns(_vaultId) returns (address owner) {
        return _owner == owner;
    } catch Error(string memory error) {
        revert(string(abi.encodePacked("FMaker._isVaultOwner:", error)));
    } catch {
        revert("FMaker._isVaultOwner:undefined");
    }
}

