// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./Tenet.sol";
interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}
contract TenetSwap is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    Tenet public tenetAddr;
    address public wethAddr;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'TenetSwap: EXPIRED');
        _;
    }
    event TransferTokenToLPToken(address indexed user, uint256 indexed pid, address tokenAddr,uint256 tokenAmount,address lpTokenAddr, uint256 lpTenAmount);
    event TransferTokensToLPToken(address indexed user, uint256 indexed pid, uint256 token0Amount,uint256 token1Amount,address lpTokenAddr, uint256 lpTenAmount);
    event ChangeLPToken(address indexed user,address lpTokenAddr,uint256 token0Amount,uint256 token1Amount,uint256 lpTenAmount);

    constructor(address _tenetAddr,address _wethAddr) public {
         tenetAddr = Tenet(_tenetAddr);
         wethAddr = _wethAddr;
    }
    function set_tenet(Tenet _tenet) public onlyOwner {
        tenetAddr = _tenet;
    }    
    receive() external payable {
        assert(msg.sender == wethAddr); // only accept ETH via fallback from the WETH contract
    }
    function _calcLiquidAmountIn(address _pairAddr,uint256[2] memory _amountDesired,uint256 _amountMinRate) internal virtual view returns (uint amount0, uint amount1) {
        require(_amountMinRate <= 1000, 'addLiquidity: INSUFFICIENT_AMOUNT_MINRATE');
        uint256[2] memory _amountMin;
        _amountMin[0] = _amountDesired[0].mul(_amountMinRate).div(1000);
        _amountMin[1] = _amountDesired[1].mul(_amountMinRate).div(1000);
        uint256[2] memory _reserve;
        (_reserve[0],_reserve[1],) = IUniswapV2Pair(_pairAddr).getReserves();
        uint amount1Optimal = _amountDesired[0].mul(_reserve[1]).div(_reserve[0]);
        if (amount1Optimal <= _amountDesired[1]) {
            require(amount1Optimal >= _amountMin[1], '_addLiquidity: INSUFFICIENT_1_AMOUNT');
            (amount0, amount1) = (_amountDesired[0], amount1Optimal);
        } else {
            uint amount0Optimal = _amountDesired[1].mul(_reserve[0]).div(_reserve[1]);
            assert(amount0Optimal <= _amountDesired[0]);
            require(amount0Optimal >= _amountMin[0], '_addLiquidity: INSUFFICIENT_0_AMOUNT');
            (amount0, amount1) = (amount0Optimal, _amountDesired[1]);
        }
    }
    function _transferToPair(address _tokenAddr,address _fromAddr, address _toAddr, uint256 _value) internal {
        if(_tokenAddr == wethAddr){
            IWETH(_tokenAddr).transfer(_toAddr, _value);
        }else{
            if(_fromAddr == address(this)){
                IERC20(_tokenAddr).transfer(_toAddr, _value);
            }else{
                IERC20(_tokenAddr).transferFrom(_fromAddr,_toAddr, _value);
            }
        }
    }
    function _returnToUser(address _tokenAddr,address _fromAddr,uint256 _value) internal{
        if(_value > 0){
            if(_tokenAddr == wethAddr){
                IWETH(_tokenAddr).withdraw(_value);
                msg.sender.transfer(_value);
            }else{
                if(_fromAddr == address(this)){
                    IERC20(_tokenAddr).transfer(msg.sender, _value);
                }
            }
        }
    }    
    function _addLiquidity(address _fromAddr,address _pairAddr,uint256[2] memory _amountDesired,address to,uint256 _amountMinRate) internal returns (uint256) {
        address[2] memory _tokenAddr;
        _tokenAddr[0] = IUniswapV2Pair(_pairAddr).token0();
        _tokenAddr[1] = IUniswapV2Pair(_pairAddr).token1();        
        (uint256 amountA,uint256 amountB) = _calcLiquidAmountIn(_pairAddr, _amountDesired, _amountMinRate);
        _transferToPair(_tokenAddr[0],_fromAddr,_pairAddr,amountA);
        _transferToPair(_tokenAddr[1],_fromAddr,_pairAddr,amountB);
        uint256 liquidity = IUniswapV2Pair(_pairAddr).mint(to);
        _returnToUser(_tokenAddr[0],_fromAddr,_amountDesired[0].sub(amountA));
        _returnToUser(_tokenAddr[1],_fromAddr,_amountDesired[1].sub(amountB));
        return liquidity;
    }    
    function getPrice(address _pairAddr, address _fromAddr) public view returns (uint256) {
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(_pairAddr).getReserves();
        if(_fromAddr == IUniswapV2Pair(_pairAddr).token0()){
            return reserve1.mul(1e12).div(reserve0);
        }else{
            return reserve0.mul(1e12).div(reserve1);
        }
    }
    function getAmountOut(address _pairAddr, address _fromAddr,uint amountIn) public view virtual returns (uint256){
        require(amountIn > 0, 'getAmountOut: INSUFFICIENT_INPUT_AMOUNT');
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(_pairAddr).getReserves();
        require(reserve0 > 0 && reserve1 > 0, 'getAmountOut: INSUFFICIENT_LIQUIDITY');
        if(_fromAddr == IUniswapV2Pair(_pairAddr).token0()){
            uint amountInWithFee = amountIn.mul(997);
            uint numerator = amountInWithFee.mul(reserve1);
            uint denominator = reserve0.mul(1000).add(amountInWithFee);
            return numerator.div(denominator);
        }else{
            uint amountInWithFee = amountIn.mul(997);
            uint numerator = amountInWithFee.mul(reserve0);
            uint denominator = reserve1.mul(1000).add(amountInWithFee);
            return numerator.div(denominator);
        }
    }
    function _swapToken(address _pairAddr, address _fromAddr,uint256 _tokenAmount) internal returns (uint256) {
        uint256 tokenAmountOut = getAmountOut(_pairAddr,_fromAddr,_tokenAmount);
        if(_fromAddr == wethAddr){
            IWETH(_fromAddr).transfer(_pairAddr, _tokenAmount);
        }else{
            IERC20(_fromAddr).transfer(_pairAddr, _tokenAmount);
        }
        if(_fromAddr == IUniswapV2Pair(_pairAddr).token0()){
            IUniswapV2Pair(_pairAddr).swap(0, tokenAmountOut, address(this), new bytes(0));
        }else{
            IUniswapV2Pair(_pairAddr).swap(tokenAmountOut, 0, address(this), new bytes(0));
        }
        return tokenAmountOut;
    }
    function _transferTokensOut(address _pairAddr,address _tokenAddr,uint256 _tokenAmount) internal returns (uint256,uint256) {
        IUniswapV2Factory factory = IUniswapV2Factory(IUniswapV2Pair(_pairAddr).factory());
        require(address(factory) != address(0), 'transferTokensOut: INSUFFICIENT_PAIR');
        uint256[8] memory dataAll;
        (dataAll[6], dataAll[7],) = IUniswapV2Pair(_pairAddr).getReserves();
        require(dataAll[6] > 0, 'transferTokensOut: INSUFFICIENT_RESERVE0');
        require(dataAll[7] > 0, 'transferTokensOut: INSUFFICIENT_RESERVE1');   
        address[2] memory allPairAddr;
        allPairAddr[0] = factory.getPair(_tokenAddr,IUniswapV2Pair(_pairAddr).token0());
        require(allPairAddr[0] != address(0), 'transferTokensOut: INVALID_PAIR0');
        dataAll[0] = getPrice(allPairAddr[0],_tokenAddr);
        allPairAddr[1] = factory.getPair(_tokenAddr,IUniswapV2Pair(_pairAddr).token1());
        require(allPairAddr[1] != address(0), 'transferTokensOut: INVALID_PAIR1');
        dataAll[1] = getPrice(allPairAddr[1],_tokenAddr);
        dataAll[2] = _tokenAmount.mul(dataAll[1]).mul(dataAll[6]).div(dataAll[0].mul(dataAll[7]).add(dataAll[1].mul(dataAll[6])));
        dataAll[3] = _tokenAmount.sub(dataAll[2]);
        dataAll[4] = _swapToken(allPairAddr[0],_tokenAddr,dataAll[2]);
        dataAll[5] = _swapToken(allPairAddr[1],_tokenAddr,dataAll[3]);
        return (dataAll[4],dataAll[5]);            
    }
    function _transferTokenXOut(address _pairAddr,address _tokenAddr,uint256 _tokenAmount,uint256 tokenType) internal returns (uint256,uint256) {
        IUniswapV2Factory factory = IUniswapV2Factory(IUniswapV2Pair(_pairAddr).factory());
        require(address(factory) != address(0), 'transferTokenXOut: INSUFFICIENT_PAIR');
        uint256[4] memory dataAll;
        (dataAll[0], dataAll[1],) = IUniswapV2Pair(_pairAddr).getReserves();
        require(dataAll[0] > 0, 'transferTokenXOut: INSUFFICIENT_RESERVE0');
        require(dataAll[1] > 0, 'transferTokenXOut: INSUFFICIENT_RESERVE1');   
        dataAll[2] = _tokenAmount.div(2);
        dataAll[3] = _swapToken(_pairAddr,_tokenAddr,dataAll[2]);
        if(tokenType == 0){
            return (dataAll[2],dataAll[3]);
        }else{
            return (dataAll[3],dataAll[2]);
        }
    }
    function _transferLPToken(uint256 _poolType,uint256 _pid,address _pairAddr,uint256[2] memory _tokenAmountOut,uint256 _amountMinRate) internal returns (uint256) {
        uint liquidity = _addLiquidity(address(this),_pairAddr,_tokenAmountOut,address(this),_amountMinRate);
        IERC20(_pairAddr).approve(address(tenetAddr),liquidity);
        if(_poolType == 0){
            tenetAddr.depositTenByUserFrom(msg.sender,liquidity);
        }else{
            tenetAddr.depositLPTokenFrom(msg.sender,_pid,liquidity);
        }
        return liquidity;
    }
    function transferTokenToLPToken(uint256 _poolType,uint256 _pid,address _pairAddr,address _tokenAddr,uint256 _tokenAmount,uint256 _amountMinRate,uint256 deadline) public virtual ensure(deadline) {
        if(_tokenAddr != wethAddr){
            IERC20(_tokenAddr).transferFrom(msg.sender, address(this),_tokenAmount);
        }
        uint256[2] memory tokenAmountOut;
        if(_tokenAddr == IUniswapV2Pair(_pairAddr).token0()){
            (tokenAmountOut[0],tokenAmountOut[1]) = _transferTokenXOut(_pairAddr,_tokenAddr,_tokenAmount,0);
        }else if(_tokenAddr == IUniswapV2Pair(_pairAddr).token1()){
            (tokenAmountOut[0],tokenAmountOut[1]) = _transferTokenXOut(_pairAddr,_tokenAddr,_tokenAmount,1);
        }else{
            (tokenAmountOut[0],tokenAmountOut[1]) = _transferTokensOut(_pairAddr,_tokenAddr,_tokenAmount);
        }
        uint liquidity = _transferLPToken(_poolType,_pid,_pairAddr,tokenAmountOut,_amountMinRate);
        emit TransferTokenToLPToken(msg.sender,_pid,_tokenAddr,_tokenAmount,_pairAddr,liquidity);
    }
    function transferETHToLPToken(uint256 _poolType,uint256 _pid,address _pairAddr,uint256 _amountMinRate,uint256 deadline) external virtual payable ensure(deadline) {
        IWETH(wethAddr).deposit{value: msg.value}();
        transferTokenToLPToken(_poolType,_pid,_pairAddr,wethAddr,msg.value,_amountMinRate,deadline);
    }
    function transferTokensToLPToken(uint256 _poolType,uint256 _pid,address _pairAddr,uint256 _token0Amount,uint256 _token1Amount,uint256 _amountMinRate,uint256 deadline) public virtual ensure(deadline) {
        uint256[2] memory tokenAmountOut;
        tokenAmountOut[0] = _token0Amount;
        tokenAmountOut[1] = _token1Amount;
        if(wethAddr != IUniswapV2Pair(_pairAddr).token0()){
            IERC20(IUniswapV2Pair(_pairAddr).token0()).transferFrom(msg.sender, address(this), tokenAmountOut[0]);
        }
        if(wethAddr != IUniswapV2Pair(_pairAddr).token1()){
            IERC20(IUniswapV2Pair(_pairAddr).token1()).transferFrom(msg.sender, address(this), tokenAmountOut[1]);
        }
        uint liquidity = _transferLPToken(_poolType,_pid,_pairAddr,tokenAmountOut,_amountMinRate);  
        emit TransferTokensToLPToken(msg.sender,_pid,tokenAmountOut[0],tokenAmountOut[1],_pairAddr,liquidity);
    }
    function transferETHsToLPToken(uint256 _poolType,uint256 _pid,address _pairAddr,uint256 _tokenAmount,uint256 _amountMinRate,uint256 deadline) external virtual payable ensure(deadline) {    
        IWETH(wethAddr).deposit{value: msg.value}();
        if(wethAddr == IUniswapV2Pair(_pairAddr).token0()){
            transferTokensToLPToken(_poolType,_pid,_pairAddr,msg.value,_tokenAmount,_amountMinRate,deadline);
        }else{
            transferTokensToLPToken(_poolType,_pid,_pairAddr,_tokenAmount,msg.value,_amountMinRate,deadline);
        }        
    }    
    function changeLPToken(address _pairAddr,uint256[2] memory _tokenAmountOut,uint256 _amountMinRate,uint256 deadline) public ensure(deadline){
        uint liquidity = _addLiquidity(msg.sender,_pairAddr,_tokenAmountOut,msg.sender,_amountMinRate);
        emit ChangeLPToken(msg.sender,_pairAddr,_tokenAmountOut[0],_tokenAmountOut[1],liquidity);
    }   
    function changeWethLPToken(address _pairAddr,uint256 _tokenAmount,uint256 _amountMinRate,uint256 deadline) external payable ensure(deadline){
        uint256[2] memory tokenAmountOut;
        if(wethAddr == IUniswapV2Pair(_pairAddr).token0()){
            tokenAmountOut[0] = msg.value;
            tokenAmountOut[1] = _tokenAmount;
        }else{
            tokenAmountOut[0] = _tokenAmount;
            tokenAmountOut[1] = msg.value;
        }
        IWETH(wethAddr).deposit{value: msg.value}();
        changeLPToken(_pairAddr,tokenAmountOut,_amountMinRate,deadline);
    }
}

