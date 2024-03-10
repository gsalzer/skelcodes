pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Instapool.
 * @dev Inbuilt Flash Loan in DSA
 */

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { TokenInterface } from "../../common/interfaces.sol";
import { AccountInterface } from "./interfaces.sol";
import { DSMath } from "../../common/math.sol";
import { Stores } from "../../common/stores.sol";
import { Variables } from "./variables.sol";
import { Events } from "./events.sol";

contract LiquidityResolver is DSMath, Stores, Variables, Events {
    using SafeERC20 for IERC20;

    /**
     * @dev Borrow Flashloan and Cast spells.
     * @param token Token Address.
     * @param amt Token Amount.
     * @param route Flashloan source route.
     * @param data targets & data for cast.
     */
    function flashBorrowAndCast(
        address token,
        uint amt,
        uint route,
        bytes memory data
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        AccountInterface(address(this)).enable(address(instaPool));
        (string[] memory _targets, bytes[] memory callDatas) = abi.decode(data, (string[], bytes[]));

        bytes memory callData = abi.encodeWithSignature("cast(string[],bytes[],address)", _targets, callDatas, address(instaPool));

        instaPool.initiateFlashLoan(token, amt, route, callData);

        AccountInterface(address(this)).disable(address(instaPool));

        _eventName = "LogFlashBorrow(address,uint256)";
        _eventParam = abi.encode(token, amt);
    }

    /**
     * @dev Return token to InstaPool.
     * @param token Token Address.
     * @param amt Token Amount.
     * @param getId Get token amount at this ID from `InstaMemory` Contract.
     * @param setId Set token amount at this ID in `InstaMemory` Contract.
    */
    function flashPayback(
        address token,
        uint amt,
        uint getId,
        uint setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);
        
        IERC20 tokenContract = IERC20(token);

        if (token == ethAddr) {
            Address.sendValue(payable(address(instaPool)), _amt);
        } else {
            tokenContract.safeTransfer(address(instaPool), _amt);
        }

        setUint(setId, _amt);

        _eventName = "LogFlashPayback(address,uint256)";
        _eventParam = abi.encode(token, amt);
    }

    /**
     * @dev Borrow multi-tokens Flashloan and Cast spells.
     * @param tokens_ Array of Token Addresses.
     * @param amts_ Array of Token Amounts.
     * @param route Flashloan source route.
     * @param data targets & data for cast.
     */
    function flashMultiBorrowAndCast(
        address[] memory tokens_,
        uint[] memory amts_,
        uint route,
        bytes memory data
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        AccountInterface(address(this)).enable(address(instaPool));
        (string[] memory _targets, bytes[] memory callDatas) = abi.decode(data, (string[], bytes[]));

        bytes memory callData = abi.encodeWithSignature("cast(string[],bytes[],address)", _targets, callDatas, address(instaPool));

        instaPool.initiateMultiFlashLoan(tokens_, amts_, route, callData);

        AccountInterface(address(this)).disable(address(instaPool));
        _eventName = "LogFlashMultiBorrow(address[],uint256[])";
        _eventParam = abi.encode(tokens_, amts_);
    }

    /**
     * @dev Return multi-tokens to InstaPool.
     * @param tokens_ Array of Token Addresses.
     * @param amts_ Array of Token Amounts.
     * @param getIds Array of getId token amounts.
     * @param setIds Array of setId token amounts.
    */
    function flashMultiPayback(
        address[] memory tokens_,
        uint[] memory amts_,
        uint[] memory getIds,
        uint[] memory setIds
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        for (uint i = 0; i < tokens_.length; i++) {
            amts_[i] = getUint(getIds[i], amts_[i]);

            if (tokens_[i] == ethAddr) {
                Address.sendValue(payable(address(instaPool)), amts_[i]);
            } else {
                IERC20(tokens_[i]).safeTransfer(address(instaPool), amts_[i]);
            }

            setUint(setIds[i], amts_[i]);
        }

        _eventName = "LogFlashMultiPayback(address[],uint256[])";
        _eventParam = abi.encode(tokens_, amts_);
    }

}

contract ConnectV2InstaPoolV3 is LiquidityResolver {
    string public name = "Instapool-v3";
}

