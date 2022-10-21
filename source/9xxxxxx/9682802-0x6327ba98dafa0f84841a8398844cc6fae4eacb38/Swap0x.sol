/*! 0xswap.sol | (c) 2020 Develop by BelovITLab LLC (smartcontract.ru), author @stupidlovejoy | License: MIT */

pragma solidity 0.5.16;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns(uint256);
    function transfer(address recipient, uint256 amount) external returns(bool);
    function allowance(address owner, address spender) external view returns(uint256);
    function approve(address spender, uint256 amount) external returns(bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
}

contract Uniswap {
    function tokenAddress() external view returns (address token);
    function factoryAddress() external view returns (address factory);
    
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
}

contract Swap0x {
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    Uniswap uniswap = Uniswap(0x2a1530C4C41db0B0b2bB646CB5Eb1A67b7158667);

    mapping(address => bytes32) public coins;

    constructor() public {
        coins[ETH_ADDRESS] = "ETH";
        coins[0x6B175474E89094C44Da98b954EedeAC495271d0F] = "DAI";
    }

    function _send(address payable _addr, address _coin, uint256 _value) private {
        if(_coin != ETH_ADDRESS) {
            IERC20 token = IERC20(_coin);
            require(token.transfer(_addr, _value), "Revert transfer");
        }
        else {
            require(address(_addr).send(_value), "Revert transfer");
        }
    }

    function _swap(address payable _addr, address _sell, address _buy, uint256 _sellAmount) private returns(uint256 res) {
        require(coins[_sell].length > 0 && coins[_buy].length > 0 && _sell != _buy, "Bad pair");

        if(_sell != ETH_ADDRESS) {
            IERC20 token = IERC20(_sell);

            require(token.transferFrom(_addr, address(this), _sellAmount), "Failed to transfer");
            require(token.approve(address(uniswap), _sellAmount), "Failed to set allowance");
            
            if(_buy != ETH_ADDRESS) {
                res = uniswap.tokenToTokenSwapInput(_sellAmount, 0, 0, 0, _buy);
            }
            else {
                res = uniswap.tokenToEthSwapInput(_sellAmount, 0, 0);
            }
        }
        else res = uniswap.ethToTokenSwapInput(0, 0);

        require(res > 0, "Bad result");

        _send(_addr, _buy, res);
    }

    function swap(address _buy) payable external {
        _swap(msg.sender, ETH_ADDRESS, _buy, msg.value);
    }

    function swap(address _sell, address _buy, uint256 _sellAmount) external {
        _swap(msg.sender, _sell, _buy, _sellAmount);
    }

    function price(address _sell, address _buy, uint256 _sellAmount) external view returns(uint256) {
        require(coins[_sell].length > 0 && coins[_buy].length > 0 && _sell != _buy, "Bad pair");

        if(_sell != ETH_ADDRESS) {
            if(_buy != ETH_ADDRESS) {
                return uniswap.getTokenToEthInputPrice(_sellAmount);
            }
            else {
                return uniswap.getTokenToEthInputPrice(_sellAmount);
            }
        }
        else return uniswap.getEthToTokenInputPrice(_sellAmount);
    }
}
