// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface ITroveManager {

    /**
     * @notice Returns user's trove info.
     * @param _borrower the user address.
     * @return _debt trove debt amount.
     * @return _coll trove collateral amount in ETH.
     * @return _stake trove stake amount.
     * @return _status trove status(nonExistent, active, closed).
     * @return _arrayIndex trove index.
     */ 
    function Troves(address _borrower) external view returns (uint _debt, uint _coll, uint _stake, uint _status, uint128 _arrayIndex);

    /**
     * @notice Returns the `Stability Pool` contract address.
     * @return _stabilityPool `Stability Pool` address. 
     */
    function stabilityPool() external view returns (address _stabilityPool);

    /**
     * @notice Returns the `LQTYStaking` contract address.
     * @return _lqtyStaking `LQTYStaking` address. 
     */
    function lqtyStaking() external view returns (address _lqtyStaking);

    /**
     * @notice Returns the `LQTY Token` contract address.
     * @return _lqtyTokenAddress `LQTY Token` address. 
     */
    function lqtyToken() external view returns (address _lqtyTokenAddress);

    /**
     * @notice Returns the `LUSD Token` contract address.
     * @return _lqtyStaking `LUSD Token` address. 
     */
    function lusdToken() external view returns (address _lqtyStaking);

    /**
     * @notice Returns the user's trove stake amount.
     * @param _borrower the user address.* 
     * @return _stake stake amount.
     */
    function getTroveStake(address _borrower) external view returns (uint _stake);

    /**
     * @notice Returns the user's trove debt amount.
     * @param _borrower the user address.
     * @return _debt debt amount.
     */
    function getTroveDebt(address _borrower) external view returns (uint _debt);

    /**
     * @notice Returns the user's trove collateral amount.
     * @param _borrower the user address.
     * @return _coll debt amount.
     */
    function getTroveColl(address _borrower) external view returns (uint _coll);

    /**
     * @notice Returns TVL amount in troves.
     * @return _tvl tvl amount.
     */
    function totalStakes() external view returns (uint _tvl);
}

