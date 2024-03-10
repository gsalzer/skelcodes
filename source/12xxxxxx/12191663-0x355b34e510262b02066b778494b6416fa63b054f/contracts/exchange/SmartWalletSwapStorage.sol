pragma solidity 0.6.6;

import "../burnHelper/IBurnGasHelper.sol";
import "../interfaces/IKyberProxy.sol";
import "../interfaces/IGasToken.sol";
import "../lending/ISmartWalletLending.sol";
import "@kyber.network/utils-sc/contracts/IERC20Ext.sol";
import "@kyber.network/utils-sc/contracts/Utils.sol";
import "@kyber.network/utils-sc/contracts/Withdrawable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";


contract SmartWalletSwapStorage is Utils, Withdrawable, ReentrancyGuard {

    uint256 constant internal MAX_AMOUNT = uint256(-1);

    mapping (address => mapping(IERC20Ext => uint256)) public platformWalletFees;
    // Proxy and routers will be set only once in constructor
    IKyberProxy public kyberProxy;
    // check if a router (Uniswap or its clones) is supported
    mapping(IUniswapV2Router02 => bool) public isRouterSupported;

    IBurnGasHelper public burnGasHelper;
    mapping (address => bool) public supportedPlatformWallets;

    struct TradeInput {
        uint256 srcAmount;
        uint256 minData; // min rate if Kyber, min return if Uni-pools
        address payable recipient;
        uint256 platformFeeBps;
        address payable platformWallet;
        bytes hint;
    }

    ISmartWalletLending public lendingImpl;

    // bytes32(uint256(keccak256("SmartWalletSwapImplementation")) - 1)
    bytes32 internal constant IMPLEMENTATION = 0x6a7efb0627ddb0e69b773958c7c9c3c9c3dc049819cdf56a8ee84c3074b2a5d7;

    constructor(address _admin) public Withdrawable(_admin) {}
}

