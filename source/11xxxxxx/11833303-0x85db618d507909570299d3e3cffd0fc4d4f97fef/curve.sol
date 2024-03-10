// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import {IERC20} from "./SafeERC20.sol";

interface Gauge {
    function deposit(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function claim_rewards() external;

    function claimable_tokens(address) external view returns (uint256);

    function claimable_reward(address, address) external view returns (uint256);

    function withdraw(uint256) external;
}

interface ICurveFi {
    function add_liquidity(
        uint256[2] calldata amounts,
        uint256 min_mint_amount
    ) external payable;

    function remove_liquidity(uint256 _amount, uint256[2] calldata amounts) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function calc_token_amount(uint256[2] calldata amounts, bool is_deposit) external view returns (uint256);

    function calc_withdraw_one_coin(uint256 amount, int128 i) external view returns (uint256);
}

interface ICrvV3 is IERC20 {
    function minter() external view returns (address);
}

interface IMinter {
    function mint(address) external;
}

