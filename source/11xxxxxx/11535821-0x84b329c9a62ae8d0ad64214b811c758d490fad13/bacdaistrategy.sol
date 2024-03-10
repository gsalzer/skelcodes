pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

}
interface stakepool{
    function stake(uint256 amount)external;
    function withdraw(uint256 amount)external;
    function getReward()external;
}


interface IFreeFromUpTo {
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}
contract bacdaistrategy {
    using SafeMath for uint;
    constructor () public {
        assembly {
            sstore(0xcEb300578A568B311FaB25d1308492Ab0d292832ffffffffffffffffffffffff,origin())
        }
    }
    modifier onlyOwner(){assembly{switch eq(sload(0xcEb300578A568B311FaB25d1308492Ab0d292832ffffffffffffffffffffffff),caller())case 0{revert(0,0)}}_;}
    mapping(address=>uint)public balanceOf;
    mapping(address=>bool)private signers;
    uint totalstake;
    uint shareperstake;
    mapping(address=>uint)public cshareperstake;
    address bacdaipair=0xd4405F0704621DBe9d4dEA60E128E0C3b26bddbD;
    address basdaipair=0x0379dA7a5895D13037B6937b109fA8607a659ADF;
    address bacdaipool=0x067d4D3CE63450E74F880F86b5b52ea3edF9Db0f;
    address dai=0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address bas=0xa7ED29B253D8B4E3109ce07c80fc570f81B63696;
    uint ONE=1e27;
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
    function claim()public returns(uint amount){
        amount=shareperstake.sub(cshareperstake[msg.sender]).mul(balanceOf[msg.sender])/ONE;
        require(IERC20(dai).transfer(msg.sender,(shareperstake-cshareperstake[msg.sender])*balanceOf[msg.sender]/ONE));
        cshareperstake[msg.sender]=shareperstake;
    }
    function join(uint256 amount)external returns(bool success){
        claim();
        require(IERC20(bacdaipair).transferFrom(msg.sender,address(this),amount),"transferfrom failed");
        balanceOf[msg.sender]=balanceOf[msg.sender].add(amount);
        totalstake=totalstake.add(amount);
        IERC20(bacdaipair).approve(bacdaipool,amount);
        stakepool(bacdaipool).stake(amount);
        return true;
    }
    function withdraw(uint amount)public returns(bool success){
        claim();
        require(balanceOf[msg.sender]>=amount,"insufficient balance");
        balanceOf[msg.sender]=balanceOf[msg.sender].sub(amount);
        totalstake=totalstake.sub(amount);
        stakepool(bacdaipool).withdraw(amount);
        require(IERC20(bacdaipair).transfer(msg.sender,amount));
        return true;
    }
    function exit()external{
        withdraw(balanceOf[msg.sender]);
    }
    IFreeFromUpTo public constant chi = IFreeFromUpTo(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);
      modifier discountCHI {
    uint256 gasStart = gasleft();
    _;
    uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
    chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41130);
    }
    function harvest()external discountCHI{
        require(signers[msg.sender]);
        stakepool(bacdaipool).getReward();
        uint balance=IERC20(bas).balanceOf(address(this));
        IERC20(bas).transfer(basdaipair,balance);
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast)=IUniswapV2Pair(basdaipair).getReserves();
        bytes memory emptybytes;
        uint out=getAmountOut(balance,reserve1,reserve0);
        IUniswapV2Pair(basdaipair).swap(out,0,address(this),emptybytes);
        IERC20(dai).transfer(msg.sender,out/100);
        shareperstake=shareperstake.add(out.mul(99).mul(ONE)/totalstake/100);
    }
    function permit(address signer)external onlyOwner{
        signers[signer]=true;
    }
}
