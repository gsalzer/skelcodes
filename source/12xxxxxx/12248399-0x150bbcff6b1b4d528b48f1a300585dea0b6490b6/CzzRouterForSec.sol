pragma solidity =0.6.6;

import './IERC20.sol';
import './ISwapFactory.sol';


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

interface ICzzSecurityPoolSwapPool {
    function securityPoolSwap(
        uint256 _pid,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        uint256 gas,
        address to,
        address routerAddr,
        uint deadline
        ) external returns (uint[] memory amounts);

    function securityPoolSwapEth(
        uint256 _pid,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        uint256 gas,
        address to, 
        address routerAddr,
        uint deadline
        ) external  returns (uint[] memory amounts);

    function securityPoolMint(uint256 _pid, uint256 _swapAmount, address _token) external ; 
    function securityPoolTransferGas(uint256 _pid, uint256 _amount, address _token, address _to) external;
    function securityPoolSwapGetAmount(uint256 amountOut, address[] calldata path, address routerAddr) external view returns (uint[] memory amounts);
}

contract CzzRouterForSec is Ownable {
    
    address czzToken;
    address czzSecurityPoolPoolAddr;
    
    mapping (address => uint8) private managers;
    mapping (address => uint8) private routerAddrs;
    struct KeyFlag { address key; bool deleted; }

    struct MintItem {
        address to;
        uint256 amount;
        uint256 amountIn;
        uint256 gas;
        address toToken;
        address routerAddr;
        address wethAddr;
        uint8 signatureCount;
        uint8 submitOrderEn;
        mapping (address => uint8) signatures;
        KeyFlag[] keys;
    }

    event MintToken(
         address to,
        uint256 mid,
        uint256 gas,
        uint256 amountIn,
        uint256 amountOut
    );

    event SubmitOrder(
        address to,
        uint256 mid,
        uint256 gas,
        uint256 amountIn,
        uint256 amountOut
    );
    
    modifier isManager {
        require(
            msg.sender == owner() || managers[msg.sender] == 1);
        _;
    }

    constructor(address _token, address _czzSecurityPoolPoolAddr) public {
        czzToken = _token;
        czzSecurityPoolPoolAddr = _czzSecurityPoolPoolAddr;
    }
    
    receive() external payable {}
    
    function addManager(address manager) public onlyOwner{
        managers[manager] = 1;
    }
    
    function removeManager(address manager) public onlyOwner{
        managers[manager] = 0;
    }


    function insert_signature(MintItem storage item, address key) internal returns (bool replaced)
    {
        if (item.signatures[key] == 1)
            return false;
        else
        {
            KeyFlag memory key1;
            item.signatures[key] = 1;
            key1.key = key;
            item.keys.push(key1);
            return true;
        }
    }

    function swap_burn_get_amount(uint amountIn, address[] memory path,address routerAddr) public view returns (uint[] memory amounts){
        require(address(0) != routerAddr); 
        return ICzzSecurityPoolSwapPool(czzSecurityPoolPoolAddr).securityPoolSwapGetAmount(amountIn,path,routerAddr);
    }
    
    function submitOrderWithPath(address _to, uint _amountIn, uint _amountInMin, uint256 mid, uint256 gas, address routerAddr, address[] memory userPath, uint deadline) public isManager {
     
        require(address(0) != _to , "address(0) == _to");
        require(address(0) != routerAddr , "address(0) == routerAddr"); 
        require(address(0) != czzSecurityPoolPoolAddr , "address(0) == czzSecurityPoolPoolAddr"); 
        require(userPath[0] == czzToken, "path 0 is not czz");
        require(_amountIn > 0);

        if(gas > 0){
            ICzzSecurityPoolSwapPool(czzSecurityPoolPoolAddr).securityPoolTransferGas(0, gas, czzToken, msg.sender);
        }

        uint[] memory amounts = ICzzSecurityPoolSwapPool(czzSecurityPoolPoolAddr).securityPoolSwap(0, _amountIn, _amountInMin, userPath, gas, _to, routerAddr, deadline);
        emit SubmitOrder(_to, mid, gas, _amountIn, amounts[amounts.length - 1]);
    
    }

    function submitOrderEthWithPath(address _to, uint _amountIn, uint _amountInMin, uint256 mid, uint256 gas, address routerAddr, address[] memory userPath, uint deadline) public isManager {
        
            require(address(0) != _to , "address(0) == _to");
            require(address(0) != routerAddr , "address(0) == routerAddr"); 
            require(address(0) != czzSecurityPoolPoolAddr , "address(0) == czzSecurityPoolPoolAddr"); 
            require(userPath[0] == czzToken, "path 0 is not czz");
            require(_amountIn > 0);
            require(_amountIn > gas, "ROUTER: transfer amount exceeds gas");
            
            if(gas > 0){
                ICzzSecurityPoolSwapPool(czzSecurityPoolPoolAddr).securityPoolTransferGas(0, gas, czzToken, msg.sender);
            }

            uint[] memory amounts = ICzzSecurityPoolSwapPool(czzSecurityPoolPoolAddr).securityPoolSwapEth(0, _amountIn, _amountInMin, userPath, gas, _to, routerAddr, deadline);
            emit SubmitOrder(_to, mid, gas, _amountIn, amounts[amounts.length - 1]);
    }

    function mintAndRepayment(uint amount) public isManager {
        require(address(0) != czzSecurityPoolPoolAddr , "address(0) == czzSecurityPoolPoolAddr"); 
        ICzzSecurityPoolSwapPool(czzSecurityPoolPoolAddr).securityPoolMint(0, amount, czzToken);    // mint to contract address        
        emit MintToken(czzSecurityPoolPoolAddr, 0, 0, amount, amount);  
    }   

    function setCzzTonkenAddress(address addr) public isManager {
        czzToken = addr;
    }

    function getCzzTonkenAddress() public view isManager returns(address ){
        return czzToken;
    }

    function setCzzSecurityPoolPoolAddress(address addr) public isManager {
        czzSecurityPoolPoolAddr = addr;
    }

    function getCzzSecurityPoolPoolAddress() public view isManager returns(address ){
        return czzSecurityPoolPoolAddr;
    }


}




