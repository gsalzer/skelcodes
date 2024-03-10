pragma solidity 0.5.17;


contract MomaFactoryProxyStorage {

    address public admin;
    address public pendingAdmin;
    address public momaFactoryImplementation;
    address public pendingMomaFactoryImplementation;

    address public feeAdmin;
    address payable public defualtFeeReceiver;
}


contract MomaFactoryStorage is MomaFactoryProxyStorage {

    address public momaFarming;
    address public farmingDelegate;

    address public oracle;
    address public timelock;
    address public momaMaster;
    address public mEther;
    address public mErc20;
    address public mEtherImplementation;
    address public mErc20Implementation;

    uint public defualtFeeFactorMantissa;
    uint public lendingPoolNum;
    bool public allowUpgrade;

    struct PoolInfo {
        address creator;
        address poolFeeAdmin;
        address payable poolFeeReceiver;
        uint feeFactor;
        bool noFee;
        bool isLending;
        bool allowUpgrade;
    }

    mapping(address => bool) public noFeeTokens;
    mapping(address => uint) public tokenFeeFactors;
    mapping(address => PoolInfo) public pools;
    address[] public allPools;

}

