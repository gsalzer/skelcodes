// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./TenetMine.sol";
import "./Tenet.sol";

contract TenetProxyInner is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant MINLPTOKEN_AMOUNT = 10000000000;
    uint256 public constant MINWEALTH_AMOUNT = 1000000000000000000;
    Tenet public tenet;
    TenetMine public tenetmine;
    address public wethAddr;
    address public wusdtAddr;
    IUniswapV2Factory public uniFactory;
    constructor(Tenet _tenet,address _weth,address _wusdt) public {
        tenet = _tenet;
        tenetmine = tenet.tenMineCalc();
        wethAddr = _weth;
        wusdtAddr = _wusdt;
        uniFactory = IUniswapV2Factory(IUniswapV2Pair(address(tenet.lpTokenTen())).factory());
    }
    function set_tenet(Tenet _tenet) public onlyOwner {
        tenet = _tenet;
        tenetmine = tenet.tenMineCalc();
    }    
    
    function getTenPoolNewInfo() public view returns (uint256[6] memory retDatas1,uint256[6] memory retDatas2,uint256[8] memory retDatas3) {
        retDatas1 = getTenUserPool();//(lastRewardBlock,accTenPerShare,allocPoint,lpTokenTotalAmount,totalAllocPoint,newBlockTen);
        retDatas2 = getTenProjectPool();//(lastRewardBlock,accTenPerShare,allocPoint,lpTokenTotalAmount,totalAllocPoint,newBlockTen);
        retDatas3 = getPoolPriceInfo(address(tenet.lpTokenTen()),address(tenet.ten()));//(lpSupply,reserve0,reserve1,pricetype,price0,price1,tokeneth,tokenusdt);
    }
    
    function getTokenPoolNewInfo(uint256 _pid) public view returns (uint256[8] memory retDatas1,uint256 newTenPerBlock,uint256[8] memory retDatas3) {
        retDatas1 = getPoolInfo(_pid);//(lastRewardBlock,lpTokenTotalAmount,accTokenPerShare,accTenPerShare,userCount,tenLPTokenAmount,rewardTenDebt,mineTokenAmount)
        newTenPerBlock = getTenPerBlockByProjectID(_pid);
        (address pairAddr,address tokenAddr, , , , , , , ) = tenet.poolSettingInfo(_pid);
        retDatas3 = getPoolPriceInfo(pairAddr,tokenAddr);//(lpSupply,reserve0,reserve1,pricetype,price0,price1,tokeneth,tokenusdt);
    }
    
    function getTenPoolBasicInfo() public view returns (address[5] memory retData1,uint256[3] memory retData2,uint256[8] memory retData3,uint256[50] memory retData4,string memory retData5,string memory retData6,string memory retData7) {
        address pairAddr = address(tenet.lpTokenTen());
        address tokenAddr = address(tenet.ten());
        (retData1,retData2,retData5,retData6,retData7) = getPairBasicInfo(pairAddr,tokenAddr);
        (retData3,retData4) = getTenPoolMineInfo();
    }
    
    function getTokenPoolBasicInfo(uint256 _pid) public view returns (address[5] memory retData1,uint256[3] memory retData2,address[3] memory retData3,uint256[6] memory retData4,string memory retData5,string memory retData6,string memory retData7) {
        (address pairAddr,address tokenAddr, , , , , , , ) = tenet.poolSettingInfo(_pid);
        (retData1,retData2,retData5,retData6,retData7) = getPairBasicInfo(pairAddr,tokenAddr);
        (retData3,retData4) = getTokenPoolMineInfo(_pid);
    }
    
    function getPoolPriceInfo(address pairAddr,address tokenAddr) public view returns (uint256[8] memory retDatas) {
        address factory = IUniswapV2Pair(pairAddr).factory();
        address token0Addr = IUniswapV2Pair(pairAddr).token0();
        address token1Addr = IUniswapV2Pair(pairAddr).token1();
        retDatas[0] = IUniswapV2Pair(pairAddr).totalSupply();
        (retDatas[1], retDatas[2],) = IUniswapV2Pair(pairAddr).getReserves();
        (retDatas[3],retDatas[4],retDatas[5]) = calcTokenPrice(IUniswapV2Factory(factory),token0Addr,token1Addr);
        (retDatas[6],retDatas[7]) = calcPrice(uniFactory,tokenAddr);
    }
    function getPairBasicInfo(address pairAddr,address tokenAddr) public view returns (address[5] memory retData1,uint256[3] memory retData2,string memory retData3,string memory retData4,string memory retData5) {
        retData1[0] = IUniswapV2Pair(pairAddr).factory();
        retData1[1] = pairAddr;
        retData1[2] = tokenAddr;
        retData1[3] = IUniswapV2Pair(pairAddr).token0();
        retData1[4] = IUniswapV2Pair(pairAddr).token1();
        (retData2[0],retData3) = getTokenInfo(retData1[2]);
        (retData2[1],retData4) = getTokenInfo(retData1[3]);
        (retData2[2],retData5) = getTokenInfo(retData1[4]);
    }    
    
    function getTenUserPool() public view returns (uint256[6] memory) {
        uint256[6] memory retDatas;
        (retDatas[0],retDatas[1],retDatas[2],retDatas[3]) = tenet.tenUserPool();
        retDatas[4] = tenet.totalAllocPoint();
        retDatas[5] = getTenPerBlockByUser();
        return retDatas;//(lastRewardBlock,accTenPerShare,allocPoint,lpTokenTotalAmount,totalAllocPoint,newBlockTen);
    }
    
    function getTenProjectPool() public view returns (uint256[6] memory) {
        uint256[6] memory retDatas;
        (retDatas[0],retDatas[1],retDatas[2],retDatas[3]) = tenet.tenProjectPool();
        retDatas[4] = tenet.totalAllocPoint();
        retDatas[5] = getTenPerBlockByProject();
        return retDatas;//(lastRewardBlock,accTenPerShare,allocPoint,lpTokenTotalAmount,totalAllocPoint,newBlockTen);
    }
    
    function getTenPoolMineInfo() public view returns (uint256[8] memory retData1,uint256[50] memory retData2) {
        retData1[0] = tenetmine.startBlock();
        retData1[1] = tenetmine.endBlock();
        retData1[2] = tenetmine.bonusEndBlock();
        retData1[3] = tenetmine.bonus_multiplier();
        retData1[4] = tenetmine.bonusTenPerBlock();
        retData1[5] = tenetmine.subBlockNumerPeriod();
        retData1[6] = tenetmine.totalSupply();
        retData1[7] = tenetmine.getMinePeriodCount();
        for(uint256 i=0;i<tenetmine.getMinePeriodCount();i++){
            if(i >= 50){
                break;
            }
            (retData2[i], )= tenetmine.allMinePeriodInfo(i);
        }
    }
    
    function getTokenPoolMineInfo(uint256 _pid) public view returns (address[3] memory retData1,uint256[6] memory retData2) {
        (retData1) = getPoolSettingInfo1(_pid);
        (retData2) = getPoolSettingInfo2(_pid);
    }
    function getPoolSettingInfo1(uint256 _pid) public view returns (address[3] memory retData1) {
        (retData1[0],retData1[1],retData1[2],,,,,,) = tenet.poolSettingInfo(_pid);
    }  
    function getPoolSettingInfo2(uint256 _pid) public view returns (uint256[6] memory retData2) {
        (,,,retData2[0],retData2[1],retData2[2],retData2[3],retData2[4],retData2[5]) = tenet.poolSettingInfo(_pid);
    }                    
    function getPoolInfo(uint256 _pid) public view returns (uint256[8] memory retData3) {
        (retData3[0],retData3[1],retData3[2],retData3[3],retData3[4],retData3[5],retData3[6],retData3[7]) = tenet.poolInfo(_pid);
    }    
    function getTokenInfo(address tokenAddr) public view returns (uint256 retData1,string memory retData2) {
        retData1 = ERC20(tokenAddr).decimals();
        retData2 = ERC20(tokenAddr).symbol();
    }
    
    function calcPrice(IUniswapV2Factory _factory,address tokenAddr) public view returns (uint256,uint256) {
        uint256 price0 = calcTokenWealth(_factory,tokenAddr,wethAddr);
        uint256 price1 = calcTokenWealth(_factory,tokenAddr,wusdtAddr);
        return (price0,price1);    
    }   
    
    function calcTokenPrice(IUniswapV2Factory _factory,address token0Addr,address token1Addr) public view returns (uint256,uint256,uint256) {
        uint256 pricetype = 0;
        uint256 price0 = 0;
        uint256 price1 = 0;     
        price0 = calcTokenWealth(_factory,token0Addr,wethAddr);
        if(price0 == 0){
            price1 = calcTokenWealth(_factory,token1Addr,wethAddr);
            if(price1 == 0){
                pricetype = 1;
                price0 = calcTokenWealth(_factory,token0Addr,wusdtAddr);
                if(price0 == 0){
                    price1 = calcTokenWealth(_factory,token1Addr,wusdtAddr);
                }
            }
        }
        return (pricetype,price0,price1);    
    }
    
    function calcETHPrice() public view returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(uniFactory.getPair(wethAddr,wusdtAddr));
        if (address(pair) == address(0)) {
            return 0;
        }
        address token0 = pair.token0();
        (uint reserve0, uint reserve1,) = pair.getReserves();
        if(token0 == wethAddr){
            return reserve1.mul(MINWEALTH_AMOUNT).div(reserve0);
        }
        return reserve0.mul(MINWEALTH_AMOUNT).div(reserve1);
    }    
    
    function calcTokenWealth(IUniswapV2Factory _factory,address token,address wealth) public view returns (uint256) {
        if (token == wealth) {
           return MINWEALTH_AMOUNT;
        }
        IUniswapV2Pair pair = IUniswapV2Pair(_factory.getPair(token, wealth));
        if (address(pair) == address(0)) {
            return 0;
        }
        (uint reserve0, uint reserve1,) = pair.getReserves();
        if(token == pair.token0()){
            return reserve1.mul(MINWEALTH_AMOUNT).div(reserve0);
        }
        return reserve0.mul(MINWEALTH_AMOUNT).div(reserve1);
    }
    
    function getTenPerBlockByUser() public view returns (uint256 tenReward) {
        uint256[2] memory allTmpData; //allocPoint,lpSupply
        (,,allTmpData[0],allTmpData[1]) = tenet.tenUserPool();
        if (allTmpData[1] <= MINLPTOKEN_AMOUNT) {
            return 0;
        }        
        tenReward = tenetmine.calcMineTenReward(block.number-1, block.number);
        tenReward = tenReward.mul(allTmpData[0]).div(tenet.totalAllocPoint());
    }
    
    function getTenPerBlockByProject() public view returns (uint256 tenReward) {
        uint256[3] memory allTmpData; //lpTokenAmount,allocPoint,tenLPTokenAmount
        ( , ,allTmpData[0],allTmpData[1]) = tenet.tenProjectPool();
        if (allTmpData[1] <= MINLPTOKEN_AMOUNT) {
            return 0;
        }        
        tenReward = tenetmine.calcMineTenReward(block.number-1, block.number);
        tenReward = tenReward.mul(allTmpData[0]).div(tenet.totalAllocPoint());
    }      
    
    function getTenPerBlockByProjectID(uint _pid) public view returns (uint256 tenReward) {
        uint256[4] memory allTmpData; //lpTokenAmount,allocPoint,tenLPTokenAmount
        ( ,allTmpData[0], , , ,allTmpData[3], , ) = tenet.poolInfo(_pid);
        if(allTmpData[0] <= MINLPTOKEN_AMOUNT){
            return 0;
        }
        if (allTmpData[3] <= MINLPTOKEN_AMOUNT) {
            return 0;
        }
        ( , ,allTmpData[1],allTmpData[2]) = tenet.tenProjectPool();
        tenReward = tenetmine.calcMineTenReward(block.number-1, block.number);
        tenReward = tenReward.mul(allTmpData[3]).mul(allTmpData[1]).div(tenet.totalAllocPoint()).div(allTmpData[2]);
    }            
}
