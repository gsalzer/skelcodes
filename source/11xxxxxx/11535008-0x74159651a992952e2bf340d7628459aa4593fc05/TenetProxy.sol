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

contract TenetProxy is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    uint256 public constant MINLPTOKEN_AMOUNT = 10000000000;
    uint public constant MINIMUM_LIQUIDITY = 10**3;
    uint256 public constant PERSHARERATE = 1000000000000;

    Tenet public tenet;
    TenetMine public tenetmine;
    constructor(Tenet _tenet) public {
        tenet = _tenet;
        tenetmine = tenet.tenMineCalc();
    }
    function set_tenet(Tenet _tenet) public onlyOwner {
        tenet = _tenet;
        tenetmine = tenet.tenMineCalc();
    }     
    function getPoolAllInfo(uint256 _pid) public view returns (address[3] memory retData1,uint256[6] memory retData2,uint256[8] memory retData3) {
        (retData1) = getPoolSettingInfo1(_pid);
        (retData2) = getPoolSettingInfo2(_pid);
        (retData3) = getPoolInfo(_pid);
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
    
    function getPendingTenByProject(uint _pid) public view returns (uint256) {
        ( , ,uint256[8] memory retData3) = getPoolAllInfo(_pid);
        if(retData3[1] <= MINLPTOKEN_AMOUNT){
            return 0;
        }
        if(retData3[5] <= MINLPTOKEN_AMOUNT){
            return 0;
        }
        uint256[4] memory tenPoolInfo;
        (tenPoolInfo[0],tenPoolInfo[1],tenPoolInfo[2],tenPoolInfo[3]) = tenet.tenProjectPool();
        if(tenPoolInfo[3] < MINLPTOKEN_AMOUNT){
            return 0;
        }          
        if (block.number > tenPoolInfo[0] && retData3[5] != 0) {
            uint256 tenReward = tenetmine.calcMineTenReward(tenPoolInfo[0], block.number);
            tenReward = tenReward.mul(tenPoolInfo[2]).div(tenet.totalAllocPoint());
            tenPoolInfo[1] = tenPoolInfo[1].add(tenReward.mul(1e12).div(tenPoolInfo[3]));
        }
        return retData3[5].mul(tenPoolInfo[1]).div(1e12).sub(retData3[6]);
    }
    function _calcFreezeTen(uint256[6] memory userInfo,uint256 accTenPerShare) internal view returns (uint256 pendingTen,uint256 freezeBlocks,uint256 freezeTen){
        pendingTen = userInfo[0].mul(accTenPerShare).div(PERSHARERATE).sub(userInfo[2]);
        uint256 blockNow = block.number.sub(userInfo[3]);
        uint256 periodBlockNumer = tenetmine.subBlockNumerPeriod();
        freezeBlocks = blockNow.add(userInfo[4]);
        if(freezeBlocks <= periodBlockNumer){
            freezeTen = pendingTen.add(userInfo[5]);
            pendingTen = 0;
        }else{
            if(pendingTen == 0){
                freezeBlocks = 0;
                freezeTen = 0;
                pendingTen = userInfo[5];
            }else{
                freezeTen = pendingTen.add(userInfo[5]).mul(periodBlockNumer).div(freezeBlocks);
                pendingTen = pendingTen.add(userInfo[5]).sub(freezeTen);
                freezeBlocks = periodBlockNumer;
            }            
        }        
    }    
    
    function getPendingTenByUser(address _user) public view returns (uint256,uint256,uint256) {
        uint256[6] memory userInfo;
        (userInfo[0],userInfo[1],userInfo[2],userInfo[3],userInfo[4],userInfo[5]) = tenet.userInfoUserPool(_user);
        if(userInfo[0] <= MINLPTOKEN_AMOUNT){
            if(block.number.sub(userInfo[3])>tenetmine.subBlockNumerPeriod()){
                return (userInfo[5],0,0);
            }else{
                return (0,0,userInfo[5]);
            }
        }
        uint256[4] memory tenPoolInfo;
        (tenPoolInfo[0],tenPoolInfo[1],tenPoolInfo[2],tenPoolInfo[3]) = tenet.tenUserPool();
        if(tenPoolInfo[3] <= MINLPTOKEN_AMOUNT){
            if(block.number.sub(userInfo[3])>tenetmine.subBlockNumerPeriod()){
                return (userInfo[5],0,0);
            }else{
                return (0,0,userInfo[5]);
            }
        }  
        if (block.number > tenPoolInfo[0]) {
            uint256 tenReward = tenetmine.calcMineTenReward(tenPoolInfo[0], block.number);
            tenReward = tenReward.mul(tenPoolInfo[2]).div(tenet.totalAllocPoint());
            tenPoolInfo[1] = tenPoolInfo[1].add(tenReward.mul(1e12).div(tenPoolInfo[3]));
        }
        (uint256 pendingTen,uint256 freezeBlocks,uint256 freezeTen) = _calcFreezeTen(userInfo,tenPoolInfo[1]);
        return (pendingTen,freezeBlocks,freezeTen);
    }

    
    function getPendingTen(uint256 _pid, address _user) public view returns (uint256,uint256,uint256) {
        uint256[6] memory userInfo;
        (userInfo[0], ,userInfo[2],userInfo[3],userInfo[4],userInfo[5]) = tenet.userInfo(_pid,_user);
        if(userInfo[0] <= MINLPTOKEN_AMOUNT){
            if(block.number.sub(userInfo[3])>tenetmine.subBlockNumerPeriod()){
                return (userInfo[5],0,0);
            }else{
                return (0,0,userInfo[5]);
            }
        }
        ( , ,uint256[8] memory retData3) = getPoolAllInfo(_pid);
        if(retData3[1] <= MINLPTOKEN_AMOUNT){
            if(block.number.sub(userInfo[3])>tenetmine.subBlockNumerPeriod()){
                return (userInfo[5],0,0);
            }else{
                return (0,0,userInfo[5]);
            }
        } 
        uint256 pending = getPendingTenByProject(_pid);
        retData3[3] = retData3[3].add(pending.mul(1e12).div(retData3[1]));
        (uint256 pendingTen,uint256 freezeBlocks,uint256 freezeTen) = _calcFreezeTen(userInfo,retData3[3]);
        return (pendingTen,freezeBlocks,freezeTen);        
     }

    
    function getPendingToken(uint256 _pid, address _user) public view returns (uint256) {
        ( ,uint256[6] memory retData2,uint256[8] memory retData3) = getPoolAllInfo(_pid);
        if(retData3[1] <= MINLPTOKEN_AMOUNT){
            return 0;
        }
        uint256[6] memory userInfo;
        (userInfo[0],userInfo[2], , , , ) = tenet.userInfo(_pid,_user);
        if(userInfo[0] <= MINLPTOKEN_AMOUNT){
            return 0;
        }        
        if (block.number > retData3[0] && retData3[1] != 0) {
            uint256 tokenReward = retData2[3].mul(tenetmine.getMultiplier(retData3[0], block.number,retData2[2],retData2[4],retData2[5]));
            retData3[2] = retData3[2].add(tokenReward.mul(1e12).div(retData3[1]));
        }
        return userInfo[0].mul(retData3[2]).div(1e12).sub(userInfo[2]);
    }       
    function calcLiquidity2(address _pairAddr,uint256 _token0Amount,uint256 _token1Amount) public view returns (uint256 liquidity) {
        uint256 totalSupply = IUniswapV2Pair(_pairAddr).totalSupply();
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(_pairAddr).getReserves();
        if(totalSupply == 0){
            liquidity = sqrt(_token0Amount.mul(_token1Amount)).sub(MINIMUM_LIQUIDITY);
        }else {
            liquidity = min(_token0Amount.mul(totalSupply) / reserve0, _token1Amount.mul(totalSupply) / reserve1);
        }
    }
    function calcLiquidity(address _pairAddr,address _tokenAddr,uint256 _tokenAmount) public view returns (uint256 liquidity) {
        uint256[2] memory tokenAmountOut;
        if(_tokenAddr == IUniswapV2Pair(_pairAddr).token0()){
            (tokenAmountOut[0],tokenAmountOut[1]) = calcTokenXOut(_pairAddr,_tokenAddr,_tokenAmount,0);
        }else if(_tokenAddr == IUniswapV2Pair(_pairAddr).token1()){
            (tokenAmountOut[0],tokenAmountOut[1]) = calcTokenXOut(_pairAddr,_tokenAddr,_tokenAmount,1);
        }else{
            (tokenAmountOut[0],tokenAmountOut[1]) = calcTokensOut(_pairAddr,_tokenAddr,_tokenAmount);
        }
        if(tokenAmountOut[0] == 0){
            liquidity = 0;
        }else if(tokenAmountOut[0] == 0){
            liquidity = 0;
        }else{
            uint256 totalSupply = IUniswapV2Pair(_pairAddr).totalSupply();
            (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(_pairAddr).getReserves();
            if(totalSupply == 0){
                liquidity = sqrt(tokenAmountOut[0].mul(tokenAmountOut[1])).sub(MINIMUM_LIQUIDITY);
            }else {
                liquidity = min(tokenAmountOut[0].mul(totalSupply) / reserve0, tokenAmountOut[1].mul(totalSupply) / reserve1);
            }
        }
    }    
    
    function getAmountOut(address _pairAddr, address _fromAddr,uint amountIn) public view virtual returns (uint256){
        //require(amountIn > 0, 'getAmountOut: INSUFFICIENT_INPUT_AMOUNT');
        if(amountIn == 0){
            return 0;
        }         
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(_pairAddr).getReserves();
        //require(reserve0 > 0 && reserve1 > 0, 'getAmountOut: INSUFFICIENT_LIQUIDITY');
        if(reserve0 == 0){
            return 0;
        } 
        if(reserve1 == 0){
            return 0;
        }                
        uint amountInWithFee = amountIn.mul(997);
        if(_fromAddr == IUniswapV2Pair(_pairAddr).token0()){
            uint numerator = amountInWithFee.mul(reserve1);
            uint denominator = reserve0.mul(1000).add(amountInWithFee);
            return numerator.div(denominator);
        }else{
            uint numerator = amountInWithFee.mul(reserve0);
            uint denominator = reserve1.mul(1000).add(amountInWithFee);
            return numerator.div(denominator);
        }
    }         
    
    function getPrice(address _pairAddr, address _fromAddr) public view returns (uint256) {
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(_pairAddr).getReserves();
        if(_fromAddr == IUniswapV2Pair(_pairAddr).token0()){
            return reserve1.mul(1e12).div(reserve0);
        }else{
            return reserve0.mul(1e12).div(reserve1);
        }
    }    
    
    function calcTokensOut(address _pairAddr,address _tokenAddr,uint256 _tokenAmount) public view returns (uint256,uint256) {
        IUniswapV2Factory factory = IUniswapV2Factory(IUniswapV2Pair(_pairAddr).factory());
        //require(address(factory) != address(0), 'calcTokensOut: INSUFFICIENT_PAIRADDR');
        if(address(factory) == address(0)){
            return (0,0);
        }        
        uint256[8] memory dataAll;
        (dataAll[6], dataAll[7],) = IUniswapV2Pair(_pairAddr).getReserves();
        //require(dataAll[6] > 0, 'calcTokenOut: INSUFFICIENT_RESERVE0');
        //require(dataAll[7] > 0, 'calcTokenOut: INSUFFICIENT_RESERVE1');   
        if(dataAll[6] == 0){
            return (0,0);
        } 
        if(dataAll[7] == 0){
            return (0,0);
        }         
        address[2] memory allPairAddr;
        allPairAddr[0] = factory.getPair(_tokenAddr,IUniswapV2Pair(_pairAddr).token0());
        //require(allPairAddr[0] != address(0), 'calcToken: INVALID_PAIR0');
        if(allPairAddr[0] == address(0)){
            return (0,0);
        }          
        dataAll[0] = getPrice(allPairAddr[0],_tokenAddr);
        allPairAddr[1] = factory.getPair(_tokenAddr,IUniswapV2Pair(_pairAddr).token1());
        //require(allPairAddr[1] != address(0), 'calcToken: INVALID_PAIR1');
        if(allPairAddr[1] == address(0)){
            return (0,0);
        }   
        dataAll[1] = getPrice(allPairAddr[1],_tokenAddr);
        
        dataAll[2] = _tokenAmount.mul(dataAll[1]).mul(dataAll[6]).div(dataAll[0].mul(dataAll[7]).add(dataAll[1].mul(dataAll[6])));
        
        dataAll[3] = _tokenAmount.sub(dataAll[2]);
        dataAll[4] = getAmountOut(allPairAddr[0],_tokenAddr,dataAll[2]);
        dataAll[5] = getAmountOut(allPairAddr[1],_tokenAddr,dataAll[3]);
        return (dataAll[4],dataAll[5]);
    }
    
    function calcTokenXOut(address _pairAddr,address _tokenAddr,uint256 _tokenAmount,uint256 tokenType) public view returns (uint256,uint256) {
        IUniswapV2Factory factory = IUniswapV2Factory(IUniswapV2Pair(_pairAddr).factory());
        //require(address(factory) != address(0), 'calcTokenXOut: INSUFFICIENT_PAIRADDR');
        if(address(factory) == address(0)){
            return (0,0);
        }
        uint256[5] memory dataAll;
        (dataAll[0], dataAll[1],) = IUniswapV2Pair(_pairAddr).getReserves();
        //require(dataAll[0] > 0, 'calcTokenXOut: INSUFFICIENT_RESERVE0');
        //require(dataAll[1] > 0, 'calcTokenXOut: INSUFFICIENT_RESERVE1');   
        if(dataAll[0] == 0){
            return (0,0);
        } 
        if(dataAll[1] == 0){
            return (0,0);
        }         
        // (reserv_USDT * amount / (reserv_USDT + reserv_TEN) )
        dataAll[2] = _tokenAmount.div(2);
        dataAll[3] = _tokenAmount.sub(dataAll[2]);
        dataAll[4] = getAmountOut(_pairAddr,_tokenAddr,dataAll[3]);
        if(tokenType == 0){
            return (dataAll[2],dataAll[4]);
        }else{
            return (dataAll[4],dataAll[2]);
        }
    }
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }                
}
