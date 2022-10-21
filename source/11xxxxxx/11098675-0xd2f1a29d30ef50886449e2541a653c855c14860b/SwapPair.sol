// SPDX-License-Identifier: No License (None)
pragma solidity =0.6.12;

import "./SafeMath.sol";
import "./Ownable.sol";

interface ISwapFactory {
    function newFactory() external view returns(address);
}

contract SwapJNTRPair {
    using SafeMath for uint256;

    address public token;               // token address
    address public tokenForeign;        // Foreign token address
    address public foreignSwapPair;     // foreign SwapPair contract address (on other blockchain)
    address public factory;             // factory address


    // balanceOf contain two types of balance:
    // 1. balanceOf[user] - balance of tokens on native chain
    // 2. balanceOf[user+1] - swapped balance of foreign tokens. I.e. on BSC chain it contain amount of ETH that was swapped.  
    mapping (address => uint256) public balanceOf;

    modifier onlyFactory() {
        require(msg.sender == factory, "Caller is not the factory");
        _;
    }

    constructor() public {
        factory = msg.sender;
    }

    // swapAddress = user address + 1.
    // balanceOf contain two types of balance:
    // 1. balanceOf[user] - balance of tokens on native chain
    // 2. balanceOf[user+1] - swapped balance of foreign tokens. I.e. on BSC chain it contain amount of ETH that was swapped.
    function _swapAddress(address user) internal pure returns(address swapAddress) {
        swapAddress = address(uint160(user)+1);
    }

    function initialize(address _foreignPair, address tokenA, address tokenB) public onlyFactory {
        foreignSwapPair = _foreignPair;
        token = tokenA;
        tokenForeign = tokenB;
    }

    function update() public returns(bool) {
        factory = ISwapFactory(factory).newFactory();
        return true;
    }

    // user's deposit to the pool, waiting for swap
    function deposit(address user, uint256 amount) external onlyFactory returns(bool) {
        balanceOf[user] = balanceOf[user].add(amount);
        return true;
    }

    // request to claim token after swap
    function claimApprove(address user, uint256 amount) external onlyFactory returns(address, address) {
        address userSwap = _swapAddress(user);
        balanceOf[userSwap] = balanceOf[userSwap].add(amount);
        return (token, tokenForeign);
    }

}

