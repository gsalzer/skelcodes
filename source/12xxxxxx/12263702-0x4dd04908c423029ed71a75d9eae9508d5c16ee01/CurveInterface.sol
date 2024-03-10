// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

interface CurvePool {

    function get_virtual_price() external view returns(uint256);

    function calc_token_amount(
        uint256[3] memory, 
        bool
    )  external view returns(uint256);

    function add_liquidity(
        uint256[3] memory,
        uint256
    )  external;

    function remove_liquidity(
        uint256,
        uint256[3] memory
    )  external;

    function remove_liquidity_imbalance(
        uint256[3] memory,
        uint256
    )  external;


    function remove_liquidity_one_coin(
        uint256,
        int128,
        uint256
    )  external;
}

interface PoolGauge {
    function deposit(uint256)  external;
    function withdraw(uint256)  external;
    function balanceOf(address)  external view returns (uint256);
    function claimable_tokens(address) external view returns(uint256);
    function totalSupply()  external view returns(uint256);
}

interface Minter {
    function mint(address)  external;
}


interface DepositY{
    function add_liquidity(
        uint256[3] memory,
        uint256
    )  external;


    function remove_liquidity(uint256,uint256[3] memory)  external ;

      function remove_liquidity_imbalance(
        uint256[3] memory,
        uint256
    )  external;

    function calc_withdraw_one_coin(uint256, int128)  external returns(uint256);

    function remove_liquidity_one_coin(uint256, int128,uint256,bool) external ;

}

interface VoteEscrow{
    function create_lock(uint256,uint256) external ;
    function increase_amount(uint256)  external;
    function increase_unlock_time(uint256)  external;
    function withdraw()  external;
    function totalSupply()  external view returns(uint256);
}


interface FeeDistributor{
    function claim()  external;
}
