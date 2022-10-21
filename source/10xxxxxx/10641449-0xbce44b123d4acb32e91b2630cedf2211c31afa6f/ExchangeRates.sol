pragma solidity >=0.5.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ExchangeRates {
    using SafeMath for uint256;
    
    IERC20 public constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    uint256 public constant WETH_DECIMALS = 18;
    
    IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    uint256 public constant USDC_DECIMALS = 6;
    
    address public constant WETH_USDC_UNISWAP_POOL = 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc;
    
    uint256 public constant WETH_USDC_ADDED_PRECISION = 4;
    
    function calculateExchangeRateFor(IERC20 token1, IERC20 token2, address pool, uint256 decimals1, uint256 decimals2, uint256 addedDecimals, bool flip) public view returns(uint256) {
        uint256 token1Pooled = token1.balanceOf(pool);
        uint256 token2Pooled = token2.balanceOf(pool);
        
        uint256 precision = (decimals1 - decimals2) + addedDecimals;
        
        if (flip == false) {
            uint256 price = token2Pooled.mul(10 ** precision).div(token1Pooled);
            return price;
        }
        else {
            uint256 price = token1Pooled.div(token2Pooled.mul(10 ** precision));
            return price;
        }
    }
    
    function calculateUsdForToken(address token, address pool, uint256 tokenDecimals, uint256 precision) public view returns(uint256) {
        uint256 usdEtherPrice = calculateExchangeRateFor(WETH, USDC, WETH_USDC_UNISWAP_POOL, WETH_DECIMALS, USDC_DECIMALS, WETH_USDC_ADDED_PRECISION, false);
        
        IERC20 tokenErc20 = IERC20(token);
        uint256 etherTokenPrice = calculateExchangeRateFor(WETH, tokenErc20, pool, WETH_DECIMALS, tokenDecimals, precision, true);

        return usdEtherPrice * etherTokenPrice;
    }
}
