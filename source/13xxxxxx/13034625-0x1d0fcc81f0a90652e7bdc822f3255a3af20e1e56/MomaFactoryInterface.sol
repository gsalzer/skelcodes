pragma solidity 0.5.17;

interface MomaFactoryInterface {

    event PoolCreated(address pool, address creator, uint poolLength);
    event NewMomaFarming(address oldMomaFarming, address newMomaFarming);
    event NewFarmingDelegate(address oldDelegate, address newDelegate);
    event NewFeeAdmin(address oldFeeAdmin, address newFeeAdmin);
    event NewDefualtFeeReceiver(address oldFeeReceiver, address newFeeReceiver);
    event NewDefualtFeeFactor(uint oldFeeFactor, uint newFeeFactor);
    event NewNoFeeTokenStatus(address token, bool oldNoFeeTokenStatus, bool newNoFeeTokenStatus);
    event NewTokenFeeFactor(address token, uint oldFeeFactor, uint newFeeFactor);
    event NewOracle(address oldOracle, address newOracle);
    event NewTimelock(address oldTimelock, address newTimelock);
    event NewMomaMaster(address oldMomaMaster, address newMomaMaster);
    event NewMEther(address oldMEther, address newMEther);
    event NewMErc20(address oldMErc20, address newMErc20);
    event NewMErc20Implementation(address oldMErc20Implementation, address newMErc20Implementation);
    event NewMEtherImplementation(address oldMEtherImplementation, address newMEtherImplementation);
    event NewLendingPool(address pool);
    event NewPoolFeeAdmin(address pool, address oldPoolFeeAdmin, address newPoolFeeAdmin);
    event NewPoolFeeReceiver(address pool, address oldPoolFeeReceiver, address newPoolFeeReceiver);
    event NewPoolFeeFactor(address pool, uint oldPoolFeeFactor, uint newPoolFeeFactor);
    event NewPoolFeeStatus(address pool, bool oldPoolFeeStatus, bool newPoolFeeStatus);

    function isMomaFactory() external view returns (bool);
    function oracle() external view returns (address);
    function momaFarming() external view returns (address);
    function farmingDelegate() external view returns (address);
    function mEtherImplementation() external view returns (address);
    function mErc20Implementation() external view returns (address);
    function admin() external view returns (address);
    function feeAdmin() external view returns (address);
    function defualtFeeReceiver() external view returns (address);
    function defualtFeeFactorMantissa() external view returns (uint);
    function feeFactorMaxMantissa() external view returns (uint);

    function tokenFeeFactors(address token) external view returns (uint);
    // function pools(address pool) external view returns (PoolInfo memory);
    function allPools(uint) external view returns (address);

    function createPool() external returns (address);
    function allPoolsLength() external view returns (uint);
    function getMomaFeeAdmin(address pool) external view returns (address);
    function getMomaFeeReceiver(address pool) external view returns (address payable);
    function getMomaFeeFactorMantissa(address pool, address underlying) external view returns (uint);
    function isMomaPool(address pool) external view returns (bool);
    function isLendingPool(address pool) external view returns (bool);
    function isTimelock(address b) external view returns (bool);
    function isMomaMaster(address b) external view returns (bool);
    function isMEtherImplementation(address b) external view returns (bool);
    function isMErc20Implementation(address b) external view returns (bool);
    function isMToken(address b) external view returns (bool);
    function isCodeSame(address a, address b) external view returns (bool);

    function upgradeLendingPool() external returns (bool);
    
    function setFeeAdmin(address _newFeeAdmin) external;
    function setDefualtFeeReceiver(address payable _newFeeReceiver) external;
    function setDefualtFeeFactor(uint _newFeeFactor) external;
    function setTokenFeeFactor(address token, uint _newFeeFactor) external;

    function setPoolFeeAdmin(address pool, address _newPoolFeeAdmin) external;
    function setPoolFeeReceiver(address pool, address payable _newPoolFeeReceiver) external;
    function setPoolFeeFactor(address pool, uint _newFeeFactor) external;
    function setPoolFeeStatus(address pool, bool _noFee) external;
}

