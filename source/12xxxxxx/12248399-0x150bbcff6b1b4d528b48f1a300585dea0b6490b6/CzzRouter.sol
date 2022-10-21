pragma solidity =0.6.6;

import './IERC20.sol';
import './IWETH.sol';
import './ISwapFactory.sol';
import './IUniswapV2Router02.sol';

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface ICzzSwap is IERC20 {
    function mint(address _to, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
    function transferOwnership(address newOwner) external;
}

contract CzzRouter is Ownable {
    
    address czzToken;
    uint private _convertType;

    mapping (address => uint8) private managers;
    mapping (address => uint8) private routerAddrs;

    event MintToken(
        address to,
        uint256 mid,
        uint256 gas,
        uint256 amountIn,
        uint256 amountOut
    );

    event BurnToken(
        address     from_,
        uint256     amountIn,
        uint256     amountOut,
        uint256     convertType,
        address[]   toPath,
        address     toRouterAddr,
        uint256     slippage,
        bool        isInsurance,
        bytes       extra
    );

    event SwapToken(
        address indexed to,
        uint256 inAmount,
        uint256 outAmount,
        string   flag
    );
    event TransferToken(
        address  indexed to,
        uint256  amount
    );

    modifier isManager {
        require(
            msg.sender == owner() || managers[msg.sender] == 1);
        _;
    }

    constructor(address _token, uint convertType) public {
        czzToken = _token;
        _convertType = convertType;
    }
    
    receive() external payable {}
    
    function addManager(address manager) public onlyOwner{
        managers[manager] = 1;
    }
    
    function removeManager(address manager) public onlyOwner{
        managers[manager] = 0;
    }

    function addRouterAddr(address routerAddr) public isManager{
        routerAddrs[routerAddr] = 1;
    }
    
    function removeRouterAddr(address routerAddr) public isManager{
        routerAddrs[routerAddr] = 0;
    }

    function HasRegistedRouteraddress(address routerAddr) public view isManager returns(uint8 ){
        return routerAddrs[routerAddr];
    }
    
    function setCzzTonkenAddress(address addr) public isManager {
        czzToken = addr;
    }

    function getCzzTonkenAddress() public view isManager returns(address ){
        return czzToken;
    }

    function approve(address token, address spender, uint256 _amount) public virtual returns (bool) {
        require(address(token) != address(0), "approve token is the zero address");
        require(address(spender) != address(0), "approve spender is the zero address");
        require(_amount != 0, "approve _amount is the zero ");
        require(routerAddrs[spender] == 1, "spender is not router address ");        
        IERC20(token).approve(spender,_amount);
        return true;
    }
    
    function _swapMint(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        address routerAddr,
        uint deadline
        ) internal returns (uint[] memory amounts) {
        uint256 _amount = IERC20(path[0]).allowance(address(this),routerAddr);
        if(_amount < amountIn) {
            approve(path[0], routerAddr,uint256(-1));
        }
       amounts = IUniswapV2Router02(routerAddr).swapExactTokensForTokens(amountIn, amountOutMin,path,to,deadline);
    }

    function _swapBurn(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        address routerAddr,
        uint deadline
        ) internal returns (uint[] memory amounts) {
        uint256 _amount = IERC20(path[0]).allowance(address(this),routerAddr);
        if(_amount < amountIn) {
            approve(path[0], routerAddr,uint256(-1));
        }
        TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), amountIn);
        amounts = IUniswapV2Router02(routerAddr).swapExactTokensForTokens(amountIn, amountOutMin,path,to,deadline);
    }

    function _swapEthBurn(
        uint256 amountInMin,
        address[] memory path,
        address to, 
        address routerAddr,
        uint deadline
        ) internal returns (uint[] memory amounts) {
        uint256 _amount = IERC20(path[0]).allowance(address(this),routerAddr);
        if(_amount < msg.value) {
            approve(path[0], routerAddr,uint256(-1));
        }
        IWETH(path[0]).deposit{value: msg.value}();
        amounts = IUniswapV2Router02(routerAddr).swapExactTokensForTokens(msg.value,amountInMin,path,to,deadline);
    }
    
    function _swapEthMint(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to, 
        address routerAddr,
        uint deadline
        ) internal returns (uint[] memory amounts) {
      
        uint256 _amount = IERC20(path[0]).allowance(address(this),routerAddr);
        if(_amount < amountIn) {
            approve(path[0], routerAddr,uint256(-1));
        }
        amounts = IUniswapV2Router02(routerAddr).swapExactTokensForETH(amountIn, amountOutMin,path,to,deadline);
    }
    
    function swap_burn_get_getReserves(address factory, address tokenA, address tokenB) public view isManager returns (uint reserveA, uint reserveB){
        require(address(0) != factory);
        return  ISwapFactory(factory).getReserves(tokenA, tokenB);
    }
    
    function swapGetAmount(uint256 amountIn, address[] memory path, address routerAddr) public view returns (uint[] memory amounts){
        require(address(0) != routerAddr); 
        return IUniswapV2Router02(routerAddr).getAmountsOut(amountIn,path);
    }
 
    function swapAndBurnWithPath(uint256 _amountIn, uint256 _amountInMin, uint convertType, address routerAddr, address[] memory fromPath, uint deadline, address[] memory toPath, address toRouterAddr, uint slippage, bool isInsurance, bytes memory extradata) payable public
    {
        require(address(0) != routerAddr); 
        require(fromPath[fromPath.length - 1] == czzToken, "last fromPath is not czz"); 

        uint[] memory amounts = _swapBurn(_amountIn, _amountInMin, fromPath, msg.sender, routerAddr, deadline);
        if(convertType != _convertType){
            ICzzSwap(czzToken).burn(msg.sender, amounts[amounts.length - 1]);
            emit BurnToken(msg.sender, _amountIn, amounts[amounts.length - 1], convertType, toPath, toRouterAddr, slippage, isInsurance, extradata);
        }
    }

    function swapAndBurnEthWithPath(uint256 _amountInMin, uint convertType, address routerAddr, address[] memory path, uint deadline, address[] memory toPath, address toRouterAddr, uint slippage, bool isInsurance, bytes memory extradata) payable public
    {
        require(address(0) != routerAddr); 
        require(path[path.length - 1] == czzToken, "last path is not czz"); 
        require(msg.value > 0);
        uint[] memory amounts = _swapEthBurn(_amountInMin, path, msg.sender, routerAddr, deadline);
        if(convertType != _convertType){
            ICzzSwap(czzToken).burn(msg.sender, amounts[amounts.length - 1]);
            emit BurnToken(msg.sender, 0, amounts[amounts.length - 1], convertType, toPath, toRouterAddr, slippage, isInsurance, extradata);

        }
    }
    
    function burn(uint256 _amountIn, uint convertType, address[] memory toPath, address toRouterAddr, uint slippage, bool isInsurance, bytes memory extradata) payable public 
    {
        ICzzSwap(czzToken).burn(msg.sender, _amountIn);
        emit BurnToken(msg.sender, _amountIn, _amountIn, convertType, toPath, toRouterAddr, slippage, isInsurance, extradata);
    }
    
    function swapAndMintTokenWithPath(address _to, uint256 _amountIn, uint256 _amountInMin, uint256 mid, uint256 gas, address routerAddr, address[] memory toPath, uint deadline) payable public isManager {
        require(address(0) != _to);
        require(address(0) != routerAddr); 
        require(_amountIn > 0);
        require(_amountIn > gas, "ROUTER: transfer amount exceeds gas");
        require(toPath[0] == czzToken, "toPath 0 is not czz");

        ICzzSwap(czzToken).mint(address(this), _amountIn);    // mint to contract address   
        if(gas > 0){
            bool success = true;
            (success) = ICzzSwap(czzToken).transfer(msg.sender, gas); 
            require(success, 'swapAndMintTokenWithPath gas Transfer error');
        }
        uint[] memory amounts = _swapMint(_amountIn-gas, _amountInMin, toPath, _to, routerAddr, deadline);
        emit MintToken(_to, mid, gas, _amountIn, amounts[amounts.length - 1]);
    }
    
    function swapAndMintTokenForEthWithPath(address _to, uint256 _amountIn, uint256 _amountInMin, uint256 mid, uint256 gas, address routerAddr, address[] memory toPath, uint deadline) payable public isManager {
        require(address(0) != _to);
        require(address(0) != routerAddr); 
        require(_amountIn > 0);
        require(_amountIn > gas, "ROUTER: transfer amount exceeds gas");
        require(toPath[0] == czzToken, "path 0 is not czz");

        ICzzSwap(czzToken).mint(address(this), _amountIn);    // mint to contract address   
        if(gas > 0){
            bool success = true;
            (success) = ICzzSwap(czzToken).transfer(msg.sender, gas); 
            require(success, 'swapAndMintTokenForEthWithPath gas Transfer error');
        }
        uint[] memory amounts = _swapEthMint(_amountIn - gas, _amountInMin, toPath, _to, routerAddr, deadline);
        emit MintToken(_to, mid, gas, _amountIn, amounts[amounts.length - 1]);
    }
    
    function mintWithGas(address _to, uint256 mid, uint256 _amountIn, uint256 gas)  payable public isManager 
    {
        require(_amountIn > 0);
        require(_amountIn >= gas, "ROUTER: transfer amount exceeds gas");

        if(gas > 0){
           ICzzSwap(czzToken).mint(msg.sender, gas);
        }
        ICzzSwap(czzToken).mint(_to, _amountIn-gas);
        emit MintToken(_to, mid, gas, _amountIn, 0);
    }

    function mint(address _to, uint256 mid, uint256 _amountIn)  payable public isManager 
    {
        ICzzSwap(czzToken).mint(_to, _amountIn);
        emit MintToken(_to, mid, 0, _amountIn, 0);
    }

}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


