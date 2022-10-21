/**
Author: Loopring Foundation (Loopring Project Ltd)
*/

pragma solidity ^0.5.11;


contract ITokenSeller {
    
    
    
    
    function sellToken(
        address tokenS,
        address tokenB
        )
        external
        payable
        returns (bool success);
}

contract ERC20 {
    function totalSupply()
        public
        view
        returns (uint);

    function balanceOf(
        address who
        )
        public
        view
        returns (uint);

    function allowance(
        address owner,
        address spender
        )
        public
        view
        returns (uint);

    function transfer(
        address to,
        uint value
        )
        public
        returns (bool);

    function transferFrom(
        address from,
        address to,
        uint    value
        )
        public
        returns (bool);

    function approve(
        address spender,
        uint    value
        )
        public
        returns (bool);
}

library MathUint {
    function mul(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a * b;
        require(a == 0 || c / a == b, "MUL_OVERFLOW");
    }

    function sub(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint)
    {
        require(b <= a, "SUB_UNDERFLOW");
        return a - b;
    }

    function add(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a + b;
        require(c >= a, "ADD_OVERFLOW");
    }

    function decodeFloat(
        uint f
        )
        internal
        pure
        returns (uint value)
    {
        uint numBitsMantissa = 23;
        uint exponent = f >> numBitsMantissa;
        uint mantissa = f & ((1 << numBitsMantissa) - 1);
        value = mantissa * (10 ** exponent);
    }
}

contract ReentrancyGuard {
    
    uint private _guardValue;

    
    modifier nonReentrant()
    {
        
        require(_guardValue == 0, "REENTRANCY");

        
        _guardValue = 1;

        
        _;

        
        _guardValue = 0;
    }
}

contract UniswapExchangeInterface {
    
    function tokenAddress() external view returns (address token);
    
    function factoryAddress() external view returns (address factory);
    
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
    function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
    
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
    function getEthToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256 eth_sold);
    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought);
    function getTokenToEthOutputPrice(uint256 eth_bought) external view returns (uint256 tokens_sold);
    
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256  tokens_bought);
    function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns (uint256  tokens_bought);
    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns (uint256  eth_sold);
    function ethToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256  eth_sold);
    
    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external returns (uint256  eth_bought);
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient) external returns (uint256  eth_bought);
    function tokenToEthSwapOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline) external returns (uint256  tokens_sold);
    function tokenToEthTransferOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline, address recipient) external returns (uint256  tokens_sold);
    
    function tokenToTokenSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address token_addr) external returns (uint256  tokens_sold);
    function tokenToTokenTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_sold);
    
    function tokenToExchangeSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address exchange_addr) external returns (uint256  tokens_sold);
    function tokenToExchangeTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_sold);
    
    bytes32 public name;
    bytes32 public symbol;
    uint256 public decimals;
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    
    function setup(address token_addr) external;
}

contract UniswapFactoryInterface {
    
    address public exchangeTemplate;
    uint256 public tokenCount;
    
    function createExchange(address token) external returns (address exchange);
    
    function getExchange(address token) external view returns (address exchange);
    function getToken(address exchange) external view returns (address token);
    function getTokenWithId(uint256 tokenId) external view returns (address token);
    
    function initializeFactory(address template) external;
}

contract UniswapTokenSeller is ReentrancyGuard, ITokenSeller {

    using MathUint for uint;

    uint256 constant MAX_UINT = ~uint(0);
    uint    public constant MAX_SLIPPAGE_BIPS = 100; 
    address public uniswapFactoryAddress; 
    address public recipient;

    event TokenSold (
        address indexed seller,
        address indexed recipient,
        address         tokenS,
        address         tokenB,
        uint            amountS,
        uint            amountB,
        uint8           slippage,
        uint64          time
    );

    constructor(
        address _uniswapFactoryAddress,
        address _recipient
        )
        public
    {
        require(_uniswapFactoryAddress != address(0), "ZERO_ADDRESS");
        uniswapFactoryAddress = _uniswapFactoryAddress;
        recipient = _recipient;
    }

    function sellToken(
        address tokenS,
        address tokenB
        )
        external
        payable
        nonReentrant
        returns (bool success)
    {
        require(tokenS != tokenB, "SAME_TOKEN");

        
        address _recipient = recipient == address(0) ? msg.sender : recipient;
        uint  amountS; 
        uint  amountB; 
        uint8 slippage;
        UniswapExchangeInterface exchange;

        if (tokenS == address(0)) {
            
            amountS = address(this).balance;
            require(amountS > 0, "ZERO_AMOUNT");
            exchange = getUniswapExchange(tokenB);

            slippage = getSlippage(
                exchange.getEthToTokenInputPrice(amountS),
                exchange.getEthToTokenInputPrice(amountS.mul(2))
            );

            amountB = exchange.ethToTokenTransferInput.value(amountS)(
                1,  
                MAX_UINT,
                _recipient
            );
        } else {
            
            amountS = ERC20(tokenS).balanceOf(address(this));
            require(amountS > 0, "ZERO_AMOUNT");
            exchange = getUniswapExchange(tokenS);

            approveUniswapExchange(exchange, tokenS, amountS);

            if (tokenB == address(0)) {
                
                slippage = getSlippage(
                    exchange.getTokenToEthInputPrice(amountS),
                    exchange.getTokenToEthInputPrice(amountS.mul(2))
                );

                amountB = exchange.tokenToEthTransferInput(
                    amountS,
                    1,  
                    MAX_UINT,
                    _recipient
                );
            } else {
                
                UniswapExchangeInterface exchangeB = getUniswapExchange(tokenB);
                slippage = getSlippage(
                    exchangeB.getEthToTokenInputPrice(exchange.getTokenToEthInputPrice(amountS)),
                    exchangeB.getEthToTokenInputPrice(exchange.getTokenToEthInputPrice(amountS.mul(2)))
                );

                amountB = exchange.tokenToTokenTransferInput(
                    amountS,
                    1, 
                    1, 
                    MAX_UINT,
                    _recipient,
                    tokenB
                );
            }
        }

        emit TokenSold(
            msg.sender,
            _recipient,
            tokenS,
            tokenB,
            amountS,
            amountB,
            slippage,
            uint64(now)
        );

        return true;
    }

    function getUniswapExchange(address token)
        private
        view
        returns (UniswapExchangeInterface)
    {
        UniswapFactoryInterface factory = UniswapFactoryInterface(uniswapFactoryAddress);
        return UniswapExchangeInterface(factory.getExchange(token));
    }

    function approveUniswapExchange(
        UniswapExchangeInterface exchange,
        address tokenS,
        uint    amountS
        )
        private
    {
        ERC20 token = ERC20(tokenS);
        uint allowance = token.allowance(address(this), address(exchange));
        if (allowance < amountS) {
            require(
                token.approve(address(exchange), MAX_UINT),
                "APPROVAL_FAILURE"
            );
        }
    }

    function getSlippage(
        uint amountB,
        uint amountB2
        )
        private
        pure
        returns (uint8)
    {
        require(amountB > 0 && amountB2 > 0, "INVALID_PRICE");
        uint slippageBips = amountB.mul(2).sub(amountB2).mul(10000) / amountB;
        require(slippageBips <= MAX_SLIPPAGE_BIPS, "SLIPPAGE_TOO_LARGE");
        return uint8(slippageBips);
    }
}
