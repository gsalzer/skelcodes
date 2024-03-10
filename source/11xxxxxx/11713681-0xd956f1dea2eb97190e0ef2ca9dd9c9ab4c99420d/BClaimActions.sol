// SPDX-License-Identifier: GPL-3.0-only

pragma abicoder v2;
pragma solidity ^0.7.6;

import "./SafeMath.sol";

interface ERC20 {
    function approve(address spender, uint amount) external returns (bool);
    function transfer(address dst, uint amt) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function balanceOf(address whom) external view returns (uint);
    function allowance(address, address) external view returns (uint);
}

interface AbstractPool is ERC20 {
    function setSwapFee(uint swapFee) external virtual;
    function setPublicSwap(bool public_) external virtual;
    
    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external virtual;
    function joinswapExternAmountIn(
        address tokenIn, uint tokenAmountIn, uint minPoolAmountOut
    ) external returns (uint poolAmountOut);

    function swapExactAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        address tokenOut,
        uint minAmountOut,
        uint maxPrice
    )
        external
        virtual returns (uint tokenAmountOut, uint spotPriceAfter);

    function swapExactAmountOut(address tokenIn, uint maxAmountIn, address tokenOut, uint tokenAmountOut, uint maxPrice )
        external virtual
        returns (uint tokenAmountIn, uint spotPriceAfter);
}

interface IBPool is AbstractPool {
    function finalize() external virtual;
    function bind(address token, uint balance, uint denorm) external virtual;
    function rebind(address token, uint balance, uint denorm) external virtual;
    function unbind(address token) external virtual;
    function isBound(address t) external view returns (bool);
    function getCurrentTokens() external view returns (address[] memory);
    function getFinalTokens() external view returns(address[] memory);
    function getBalance(address token) external view returns (uint);
    
}

interface MerkleRedeem {
    function claimWeek(address _liquidityProvider, uint _week, uint _claimedBalance, bytes32[] memory _merkleProof) external virtual;
}

interface WETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

/**
 * @dev Claim from MerkleRedeem.sol and pool into BPool.sol for multiple users in single transaction.
 * 
 * WARNING: This contract is meant to be called using DSProxy only. Calling this contract directly
 *          might result in loss of funds.
 * 
 */
contract BClaimActions {

    using SafeMath for uint256;
    /***
        Approximate costs per call per user: Used to reimburse the caller with ETH.
     */
    uint constant base_gas_cost = 205000;
    uint constant cost_per_user = 102000;

    constructor() public { }

    function multiUserPoolJoin (
        ERC20 _token,
        WETH _weth,
        AbstractPool pool,
        address[] memory _users,
        uint _max_price
    ) public {
        uint pooledTokenAmnt = 0;
        uint[] memory userAmounts = new uint[](_users.length);
        for (uint i = 0; i < _users.length; i++) {
            address user = _users[i];
            uint user_bal_balance = _token.balanceOf(user);
            if (user_bal_balance > 0) {
                require(_token.transferFrom(user, address(this), user_bal_balance));//, "t-f");
                pooledTokenAmnt = pooledTokenAmnt.add(user_bal_balance);
            }
            userAmounts[i] = user_bal_balance;
        }
        require(pooledTokenAmnt > 0);//, "p-a");

        _token.approve(address(pool), pooledTokenAmnt);

        uint token_payed = 0;
        uint gasEth =  (base_gas_cost + (cost_per_user.mul(_users.length))).mul(tx.gasprice);

        require (gasEth > 0);//, "n-g");

        // Slippage is checked here by using maxPrice
        (token_payed, ) = pool.swapExactAmountOut(address(_token), pooledTokenAmnt, address(_weth), gasEth, _max_price);
        _weth.withdraw(gasEth);

        uint poolAmountOut = pool.joinswapExternAmountIn(address(_token), pooledTokenAmnt.sub(token_payed), 0);
        uint poolAmountOutLeft = poolAmountOut;
        
        for (uint i = 0; i < _users.length; i++) {
            uint userPoolAmount;
            if (i == _users.length - 1) {
                userPoolAmount = poolAmountOutLeft;
            } else {
                userPoolAmount = userAmounts[i].mul(poolAmountOut).div(pooledTokenAmnt);
            }
            require(pool.transfer(_users[i], userPoolAmount));//, "t-t");
            poolAmountOutLeft =  poolAmountOutLeft.sub(userPoolAmount);
        }
        msg.sender.transfer(gasEth);
    }

    function multiUserClaimPoolJoin(
        MerkleRedeem distribute_contract,
        ERC20 _token,
        WETH _weth,
        AbstractPool pool,
        address[] calldata _users,
        uint _week,
        uint[] calldata _balances,
        bytes32[][] calldata _merkleProofs,
        uint _max_price
    ) external {
        // first claim for each user
        require(_users.length == _balances.length);//, "a-b");
        require(_merkleProofs.length == _users.length);//, "a-m");        
        for (uint i = 0; i < _users.length; i++) {
            if (_merkleProofs[i].length > 0)
                distribute_contract.claimWeek(_users[i], _week, _balances[i], _merkleProofs[i]);
        }
        // then multi pool
        multiUserPoolJoin(_token, _weth, pool, _users, _max_price);
    }

}
