pragma solidity 0.5.0;

//import "/github/CryptoManiacsZone/1inchProtocol/contracts/IOneSplit.sol";
//import "/github/OpenZeppelin/openzeppelin-contracts/contracts/ownership/Ownable.sol";
import "IERC20.sol";
//import "./IChi.sol";
import "IUniswapV2Pair.sol";
import "SafeMath.sol";
//import "/github/ampleforth/uFragments/contracts/lib/SafeMathInt.sol";
import "IOneSplit.sol";

contract CheckPrice{
    // is Ownable
    //IOneSplit public oneSplit;
    address[] public uniPools = [0x3041CbD36888bECc7bbCBc0045E3B1f144466f5f, 0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852];
    mapping (address=>address) public uniGeysers;
    //address public chi = 0x0000000000004946c0e9F43F4Dee607b0eF1fA1c;
    address public denominateTo = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // USDT
    address public holderAddress = 0x8c545be506a335e24145EdD6e01D2754296ff018;
    address public OneSplitAddress = 0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E;
    
    uint fpNumbers = 1e8;
    
    using SafeMath for uint256;
    
    
    constructor() public {
      
        uniGeysers[0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852] = 0x6C3e4cb2E96B01F4b866965A91ed4437839A121a;

    }
    
    function setOneSplit (address inch_address) external returns (bool){
        
        OneSplitAddress = inch_address;
        return true;

    }
    
    
    /*
    modifier discountCHI() {
        
    uint256 gasStart = gasleft();
    address gasUser;
    
    _;
    
    if (IERC20(chi).balanceOf(msg.sender) > 0) {
       if (IERC20(chi).allowance(msg.sender,address(this))!= uint256(-1)) {
            IERC20(chi).approve(address(this), uint(-1));
        }
        gasUser = msg.sender;
    } else {
        gasUser = address(this);
    }
    
    uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
    
    ICHI(chi).freeFromUpTo(gasUser, (gasSpent + 14154) / 41947);
    
    }
    
    function transferTokenToOwner(address TokenAddress) external onlyOwner returns (uint256){
        IERC20 Token = IERC20(TokenAddress);
        uint256 balance = Token.balanceOf(address(this));
        bool result = Token.transfer(owner(), balance);
        
        if (!result) { 
            balance = 0;
        }
        
        return balance;
    }
    
    
    
    
    //onlyOwner
    
    /*
        
    function addUniPool (address pool_address) external returns (bool){
        uniPools.push(pool_address);
        return true;
    }
    
    
    function delUniPool (address pool_address) external returns (bool) {

        uint i = 0;
        while (uniPools[i] != pool_address) {
            require(i < uniPools.length);
            i++;
        }
        
        while (i<uniPools.length-1) {
            uniPools[i] = uniPools[i+1];
            i++;
        }
        uniPools.length--;
        return true;
    }
    */
     
    function getUniPools() public view returns (address[] memory) {
        return uniPools;
    }
    
    function getTotalPrice() public view returns (uint) {
        
        uint totalReserve = 0;
        
        for (uint i=0; i<uniPools.length; i++) {
            
            IUniswapV2Pair uniPool = IUniswapV2Pair(uniPools[i]);
            
            uint totalSupply = uniPool.totalSupply();
            uint holderBalanceOf = uniPool.balanceOf(holderAddress);
            
            if (uniGeysers[uniPools[i]] != address(0)) {
                uint geyserBalance = IERC20(uniGeysers[uniPools[i]]).balanceOf(holderAddress);
                holderBalanceOf += geyserBalance;
            }
            
            uint holderPc = (holderBalanceOf.mul(fpNumbers)).div(totalSupply);
            
            (uint112 reserve0, uint112 reserve1,) = uniPool.getReserves();
            
            uint myreserve0 = (uint(reserve0).mul(holderPc)).div(fpNumbers);
            uint myreserve1 = (uint(reserve1).mul(holderPc)).div(fpNumbers);
            
            if (uniPool.token0() != denominateTo) {
                //get amount and convert to denominate addr;

                IERC20 fromIERC20 = IERC20(uniPool.token0());
                IERC20 toIERC20 = IERC20(denominateTo);

                (uint256 returnAmount0,) = IOneSplit(
                    OneSplitAddress
                ).getExpectedReturn(
                    fromIERC20,
                    toIERC20,
                    myreserve0,
                    100,
                    0
                );
                
                myreserve0 = returnAmount0;
            }
            totalReserve = totalReserve.add(myreserve0);
            
            if (uniPool.token1() != denominateTo) {
                //get amount and convert to denominate addr;
                IERC20 fromIERC20 = IERC20(uniPool.token1());
                IERC20 toIERC20 = IERC20(denominateTo);

                (uint256 returnAmount1,) = IOneSplit(
                    OneSplitAddress
                ).getExpectedReturn(
                    fromIERC20,
                    toIERC20,
                    myreserve1,
                    100,
                    0
                );
                
                myreserve1 = returnAmount1;
            }
            
            totalReserve = totalReserve.add(myreserve1);
        }
        
        return totalReserve;
    }
   
}
