pragma solidity ^0.4.26;


contract DSMath {
    
    

    function add(uint256 x, uint256 y) pure internal returns (uint256 z) {
        assert((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) pure internal returns (uint256 z) {
        assert((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) pure internal returns (uint256 z) {
        assert((z = x * y) >= x);
    }
    
    function div(uint256 x, uint256 y) pure internal returns (uint256 z) {
        require(y > 0);
        z = x / y;
    }
    
    function min(uint256 x, uint256 y) pure internal returns (uint256 z) {
        return x <= y ? x : y;
    }
    function max(uint256 x, uint256 y) pure internal returns (uint256 z) {
        return x >= y ? x : y;
    }

    


    function hadd(uint128 x, uint128 y) pure internal returns (uint128 z) {
        assert((z = x + y) >= x);
    }

    function hsub(uint128 x, uint128 y) pure internal returns (uint128 z) {
        assert((z = x - y) <= x);
    }

    function hmul(uint128 x, uint128 y) pure internal returns (uint128 z) {
        assert((z = x * y) >= x);
    }

    function hdiv(uint128 x, uint128 y) pure internal returns (uint128 z) {
        assert(y > 0);
        z = x / y;
    }

    function hmin(uint128 x, uint128 y) pure internal returns (uint128 z) {
        return x <= y ? x : y;
    }
    function hmax(uint128 x, uint128 y) pure internal returns (uint128 z) {
        return x >= y ? x : y;
    }


    

    function imin(int256 x, int256 y) pure internal returns (int256 z) {
        return x <= y ? x : y;
    }
    function imax(int256 x, int256 y) pure internal returns (int256 z) {
        return x >= y ? x : y;
    }

    

    uint128 constant WAD = 10 ** 18;

    function wadd(uint128 x, uint128 y) pure internal returns (uint128) {
        return hadd(x, y);
    }

    function wsub(uint128 x, uint128 y) pure internal returns (uint128) {
        return hsub(x, y);
    }

    function wmul(uint128 x, uint128 y) view internal returns (uint128 z) {
        z = cast((uint256(x) * y + WAD / 2) / WAD);
    }

    function wdiv(uint128 x, uint128 y) view internal returns (uint128 z) {
        z = cast((uint256(x) * WAD + y / 2) / y);
    }

    function wmin(uint128 x, uint128 y) pure internal returns (uint128) {
        return hmin(x, y);
    }
    function wmax(uint128 x, uint128 y) pure internal returns (uint128) {
        return hmax(x, y);
    }

    

    uint128 constant RAY = 10 ** 27;

    function radd(uint128 x, uint128 y) pure internal returns (uint128) {
        return hadd(x, y);
    }

    function rsub(uint128 x, uint128 y) pure internal returns (uint128) {
        return hsub(x, y);
    }

    function rmul(uint128 x, uint128 y) view internal returns (uint128 z) {
        z = cast((uint256(x) * y + RAY / 2) / RAY);
    }

    function rdiv(uint128 x, uint128 y) view internal returns (uint128 z) {
        z = cast((uint256(x) * RAY + y / 2) / y);
    }

    function rpow(uint128 x, uint64 n) view internal returns (uint128 z) {
        
        
        
        
        
        
        
        
        
        
        
        
        
        

        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }

    function rmin(uint128 x, uint128 y) pure internal returns (uint128) {
        return hmin(x, y);
    }
    function rmax(uint128 x, uint128 y) pure internal returns (uint128) {
        return hmax(x, y);
    }

    function cast(uint256 x) pure internal returns (uint128 z) {
        assert((z = uint128(x)) == x);
    }

}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract WETH is ERC20 {
    function deposit() public payable;
    function withdraw(uint wad) public;
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);
}

interface UniswapExchangeInterface {
    function getEthToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256 eth_sold);
    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns (uint256  eth_sold);
}

interface OracleInterface {
  function bill() external view returns (uint256);
  function update(uint128 payment_, address token_) external;
}

contract MedianizerInterface {
    function oracles(uint256) public view returns (address);
    function peek() public view returns (bytes32, bool);
    function read() public returns (bytes32);
    function poke() public;
    function poke(bytes32) public;
    function fund (uint256 amount, ERC20 token) public;
}

contract FundOracles is DSMath {
  ERC20 link;
  WETH weth;
  UniswapExchangeInterface uniswapExchange;

  MedianizerInterface med;

  constructor(MedianizerInterface med_, ERC20 link_, WETH weth_, UniswapExchangeInterface uniswapExchange_) public {
    med = med_;
    link = link_;
    weth = weth_;
    uniswapExchange = uniswapExchange_;
  }
  
  function billWithEth(uint256 oracle_) public view returns (uint256) {
      return OracleInterface(med.oracles(oracle_)).bill();
  }
  
  function paymentWithEth(uint256 oracle_, uint128 payment_) public view returns(uint256) {
      if (oracle_ < 5) {
          return uniswapExchange.getEthToTokenOutputPrice(payment_);
      } else {
          return uint(payment_);
      }
  }

  function updateWithEth(uint256 oracle_, uint128 payment_, address token_) public payable {
    address oracleAddress = med.oracles(oracle_);
    OracleInterface oracle = OracleInterface(oracleAddress);
    if (oracle_ < 5) {
      
      uint256 ethAmt = msg.value;
      link.approve(address(uniswapExchange), uint(payment_));
      uint256 ethSold = uniswapExchange.ethToTokenSwapOutput.value(msg.value)(uint(payment_), now + 300);
      link.approve(oracleAddress, uint(payment_));
      oracle.update(payment_, token_);
    } else {
      
      weth.deposit.value(msg.value)();
      weth.approve(oracleAddress, uint(payment_));
      oracle.update(payment_, token_);
    }
  }
}
