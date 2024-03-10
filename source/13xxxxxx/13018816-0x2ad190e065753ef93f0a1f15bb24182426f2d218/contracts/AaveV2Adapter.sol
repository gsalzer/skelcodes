// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

// ============ Contract information ============

/**
 * @title  AaveV2Adapter
 * @notice Aave V2 integrations for Greenwood interest rate swap pools
 * @author Greenwood Labs
 */

 // ============ Imports ============

 import '@openzeppelin/contracts/math/SafeMath.sol';
 import { ILendingPool } from '@aave/protocol-v2/contracts/interfaces/ILendingPool.sol';
 import { DataTypes } from '@aave/protocol-v2/contracts/protocol/libraries/types/DataTypes.sol';
 import '../interfaces/IAdapter.sol';
 
contract AaveV2Adapter is IAdapter {

     using SafeMath for uint256;

    // ============ Immutable storage ============
     
    address public immutable factory;
    address public immutable governance;

    uint256 public constant TEN_EXP_9 = 1000000000;

    // ============ Mutable storage ============

    ILendingPool private lendingPool;


    // ============ Constructor ============

    constructor(
        address _factory,
        address _governance,
        address _lending_pool
    ) public {
        factory = _factory;
        governance = _governance;
        lendingPool = ILendingPool(_lending_pool);
    }
     
    // ============ External methods ============

    // ============ Get the current variable borrow rate ============

    function getBorrowRate(address _market) external view override returns(uint256) {
        // get the reserve data from Aave
        DataTypes.ReserveData memory reserveData = lendingPool.getReserveData(_market);

        // the variable borrow rate in ray
        uint256 variableBorrowRate = reserveData.currentVariableBorrowRate;

        // return the scaled variable borrow rate
        return variableBorrowRate.div(TEN_EXP_9);
    }

    // ============ Get the current borrow index ============

    function getBorrowIndex(address _market) external view override returns(uint256) {
        // get the reserve data from Aave
        DataTypes.ReserveData memory reserveData = lendingPool.getReserveData(_market);

        // the variable borrow index in ray
        uint256 variableBorrowIndex = reserveData.variableBorrowIndex;

        // return the scaled variable borrow index
        return variableBorrowIndex.div(TEN_EXP_9);
    }
     
 }

