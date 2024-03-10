// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;
import "IERC20.sol";
import "SafeERC20.sol";
import "Initializable.sol";

interface Vault is IERC20 {
    function decimals() external view returns (uint256);

    function deposit() external returns (uint256);

    function deposit(uint256 amount) external returns (uint256);

    function deposit(uint256 amount, address recipient)
        external
        returns (uint256);

    function withdraw() external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient)
        external
        returns (uint256);

    function token() external view returns (address);

    function pricePerShare() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bool);
}

interface StableSwap {
    function remove_liquidity_one_coin(
        uint256 amount,
        int128 i,
        uint256 min_amount
    ) external;

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount)
        external;

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount)
        external;

    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount)
        external;

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i)
        external
        view
        returns (uint256);

    function calc_token_amount(uint256[2] calldata amounts, bool is_deposit)
        external
        view
        returns (uint256);

    function calc_token_amount(uint256[3] calldata amounts, bool is_deposit)
        external
        view
        returns (uint256);

    function calc_token_amount(uint256[4] calldata amounts, bool is_deposit)
        external
        view
        returns (uint256);
}

interface Registry {
    function get_pool_from_lp_token(address lp) external view returns (address);

    function get_lp_token(address pool) external view returns (address);

    function get_n_coins(address) external view returns (uint256[2] memory);

    function get_coins(address) external view returns (address[8] memory);
}

contract VaultSwapper is Initializable {
    Registry constant registry =
        Registry(0x90E00ACe148ca3b23Ac1bC8C240C2a7Dd9c2d7f5);
    uint256 constant private MIN_AMOUNT_OUT = 1;
    uint256 constant private MAX_DONATION = 10_000;
    uint256 constant private DEFAULT_DONATION = 30;
    uint256 constant private UNKNOWN_ORIGIN = 0;
    address public owner;

    event Orgin(uint256 origin);
    struct Swap {
        bool deposit;
        address pool;
        uint128 n;
    }

    function initialize(address _owner) initializer public {
        owner = _owner;
    }

    function set_owner(address new_owner) public {
        require(owner == msg.sender);
        require(new_owner != address(0));
        owner = new_owner;
    }

    /*
        @notice Swap with apoval using eip-2612
        @param from_vault The vault tokens should be taken from
        @param to_vault The vault tokens should be deposited to
        @param amount The amount of tokens you whish to use from the from_vault
        @param min_amount_out The minimal amount of tokens you would expect from the to_vault
        @param expiry signature expiry
        @param signature signature
    */
    function metapool_swap_with_signature(
        address from_vault,
        address to_vault,
        uint256 amount,
        uint256 min_amount_out,
        uint256 expiry,
        bytes calldata signature
    ) public {
        metapool_swap_with_signature(
            from_vault,
            to_vault,
            amount,
            min_amount_out,
            expiry,
            signature,
            DEFAULT_DONATION,
            UNKNOWN_ORIGIN
        );
    }

    function metapool_swap_with_signature(
        address from_vault,
        address to_vault,
        uint256 amount,
        uint256 min_amount_out,
        uint256 expiry,
        bytes calldata signature,
        uint256 donation,
        uint256 origin
    ) public {
        assert(
            Vault(from_vault).permit(
                msg.sender,
                address(this),
                amount,
                expiry,
                signature
            )
        );
        metapool_swap(from_vault, to_vault, amount, min_amount_out, donation, origin);
    }

    /**
        @notice swap tokens from one meta pool vault to an other
        @dev Remove funds from a vault, move one side of 
        the asset from one curve pool to an other and 
        deposit into the new vault.
        @param from_vault The vault tokens should be taken from
        @param to_vault The vault tokens should be deposited to
        @param amount The amount of tokens you whish to use from the from_vault
        @param min_amount_out The minimal amount of tokens you would expect from the to_vault
    */
    function metapool_swap(
        address from_vault,
        address to_vault,
        uint256 amount,
        uint256 min_amount_out
    ) public {
        metapool_swap(from_vault, to_vault, amount, min_amount_out, DEFAULT_DONATION, UNKNOWN_ORIGIN);
    }

    function metapool_swap(
        address from_vault,
        address to_vault,
        uint256 amount,
        uint256 min_amount_out,
        uint256 donation,
        uint256 origin
    ) public {
        address underlying = Vault(from_vault).token();
        address target = Vault(to_vault).token();

        address underlying_pool = registry.get_pool_from_lp_token(underlying);
        address target_pool = registry.get_pool_from_lp_token(target);

        Vault(from_vault).transferFrom(msg.sender, address(this), amount);
        uint256 underlying_amount = Vault(from_vault).withdraw(
            amount,
            address(this)
        );
        StableSwap(underlying_pool).remove_liquidity_one_coin(
            underlying_amount,
            1,
            1
        );

        IERC20 underlying_coin = IERC20(registry.get_coins(underlying_pool)[1]);
        uint256 liquidity_amount = underlying_coin.balanceOf(address(this));

        underlying_coin.approve(target_pool, liquidity_amount);

        StableSwap(target_pool).add_liquidity(
            [0, liquidity_amount],
            MIN_AMOUNT_OUT
        );

        uint256 target_amount = IERC20(target).balanceOf(address(this));
        if(donation != 0) {
            uint256 donating = (target_amount * donation) / MAX_DONATION;
            SafeERC20.safeTransfer(IERC20(target), owner, donating);
            target_amount -= donating;
        }

        approve(target, to_vault, target_amount);

        uint256 out = Vault(to_vault).deposit(target_amount, msg.sender);

        require(out >= min_amount_out, "out too low");
        if (origin != UNKNOWN_ORIGIN) {
            emit Orgin(origin);
        }
    }

    /**
        @notice estimate the amount of tokens out
        @param from_vault The vault tokens should be taken from
        @param to_vault The vault tokens should be deposited to
        @param amount The amount of tokens you whish to use from the from_vault
        @return the amount of token shared expected in the to_vault
     */
    function metapool_estimate_out(
        address from_vault,
        address to_vault,
        uint256 amount,
        uint256 donation
    ) public view returns (uint256) {
        address underlying = Vault(from_vault).token();
        address target = Vault(to_vault).token();

        address underlying_pool = registry.get_pool_from_lp_token(underlying);
        address target_pool = registry.get_pool_from_lp_token(target);

        uint256 pricePerShareFrom = Vault(from_vault).pricePerShare();
        uint256 pricePerShareTo = Vault(to_vault).pricePerShare();

        uint256 amount_out = (pricePerShareFrom * amount) /
            (10**Vault(from_vault).decimals());
        amount_out = StableSwap(underlying_pool).calc_withdraw_one_coin(
            amount_out,
            1
        );
        amount_out = StableSwap(target_pool).calc_token_amount(
            [0, amount_out],
            true
        );
        amount_out -= (amount_out * (MAX_DONATION - donation) / MAX_DONATION);
        return
            (amount_out * (10**Vault(to_vault).decimals())) / pricePerShareTo;
    }

    function swap_with_signature(
        address from_vault,
        address to_vault,
        uint256 amount,
        uint256 min_amount_out,
        Swap[] calldata instructions,
        uint256 expiry,
        bytes calldata signature
    ) public {
        swap_with_signature(
            from_vault,
            to_vault,
            amount,
            min_amount_out,
            instructions,
            expiry,
            signature,
            DEFAULT_DONATION,
            UNKNOWN_ORIGIN
        );
    }

    function swap_with_signature(
        address from_vault,
        address to_vault,
        uint256 amount,
        uint256 min_amount_out,
        Swap[] calldata instructions,
        uint256 expiry,
        bytes calldata signature,
        uint256 donation,
        uint256 origin
    ) public {
        assert(
            Vault(from_vault).permit(
                msg.sender,
                address(this),
                amount,
                expiry,
                signature
            )
        );
        swap(
            from_vault,
            to_vault,
            amount,
            min_amount_out,
            instructions,
            donation,
            origin
        );
    }

    function swap(
        address from_vault,
        address to_vault,
        uint256 amount,
        uint256 min_amount_out,
        Swap[] calldata instructions
    ) public {
        swap(from_vault, to_vault, amount, min_amount_out, instructions, DEFAULT_DONATION, UNKNOWN_ORIGIN);
    }

    function swap(
        address from_vault,
        address to_vault,
        uint256 amount,
        uint256 min_amount_out,
        Swap[] calldata instructions,
        uint256 donation,
        uint256 origin
    ) public {
        address token = Vault(from_vault).token();
        address target = Vault(to_vault).token();

        Vault(from_vault).transferFrom(msg.sender, address(this), amount);

        amount = Vault(from_vault).withdraw(amount, address(this));
        uint256 n_coins;
        for (uint256 i = 0; i < instructions.length; i++) {
            if (instructions[i].deposit) {
                n_coins = registry.get_n_coins(instructions[i].pool)[0];
                uint256[] memory list = new uint256[](n_coins);
                list[instructions[i].n] = amount;
                approve(token, instructions[i].pool, amount);

                if (n_coins == 2) {
                    StableSwap(instructions[i].pool).add_liquidity(
                        [list[0], list[1]],
                        1
                    );
                } else if (n_coins == 3) {
                    StableSwap(instructions[i].pool).add_liquidity(
                        [list[0], list[1], list[2]],
                        1
                    );
                } else if (n_coins == 4) {
                    StableSwap(instructions[i].pool).add_liquidity(
                        [list[0], list[1], list[2], list[3]],
                        1
                    );
                }

                token = registry.get_lp_token(instructions[i].pool);
                amount = IERC20(token).balanceOf(address(this));
            } else {
                token = registry.get_coins(instructions[i].pool)[
                    instructions[i].n
                ];
                amount = remove_liquidity_one_coin(
                    token,
                    instructions[i].pool,
                    amount,
                    instructions[i].n
                );
            }
        }

        require(target == token, "!path");

        if(donation != 0) {
            uint256 donating = (amount * donation) / MAX_DONATION;
            SafeERC20.safeTransfer(IERC20(target), owner, donating);
            amount -= donating;
        }
        approve(target, to_vault, amount);
        uint256 out  = Vault(to_vault).deposit(amount, msg.sender);

        require(out >= min_amount_out, "out too low");
        if (origin != UNKNOWN_ORIGIN){
            emit Orgin(origin);
        }
    }

    function remove_liquidity_one_coin(
        address token,
        address pool,
        uint256 amount,
        uint128 n
    ) internal returns (uint256) {
        uint256 amountBefore = IERC20(token).balanceOf(address(this));
        pool.call(
            abi.encodeWithSignature(
                "remove_liquidity_one_coin(uint256,int128,uint256)",
                amount,
                int128(n),
                1
            )
        );

        uint256 newAmount = IERC20(token).balanceOf(address(this));

        if (newAmount > amountBefore) {
            return newAmount;
        }

        pool.call(
            abi.encodeWithSignature(
                "remove_liquidity_one_coin(uint256,uint256,uint256)",
                amount,
                uint256(n),
                1
            )
        );
        return IERC20(token).balanceOf(address(this));
    }

    function estimate_out(
        address from_vault,
        address to_vault,
        uint256 amount,
        Swap[] calldata instructions,
        uint256 donation
    ) public view returns (uint256) {
        uint256 pricePerShareFrom = Vault(from_vault).pricePerShare();
        uint256 pricePerShareTo = Vault(to_vault).pricePerShare();
        amount =
            (amount * pricePerShareFrom) /
            (10**Vault(from_vault).decimals());
        for (uint256 i = 0; i < instructions.length; i++) {
            uint256 n_coins = registry.get_n_coins(instructions[i].pool)[0];
            if (instructions[i].deposit) {
                n_coins = registry.get_n_coins(instructions[i].pool)[0];
                uint256[] memory list = new uint256[](n_coins);
                list[instructions[i].n] = amount;

                if (n_coins == 2) {
                    amount = StableSwap(instructions[i].pool).calc_token_amount(
                            [list[0], list[1]],
                            true
                        );
                } else if (n_coins == 3) {
                    amount = StableSwap(instructions[i].pool).calc_token_amount(
                            [list[0], list[1], list[2]],
                            true
                        );
                } else if (n_coins == 4) {
                    amount = StableSwap(instructions[i].pool).calc_token_amount(
                            [list[0], list[1], list[2], list[3]],
                            true
                        );
                }
            } else {
                amount = calc_withdraw_one_coin(
                    instructions[i].pool,
                    amount,
                    instructions[i].n
                );
            }
        }
        amount -= (amount * (MAX_DONATION - donation) / MAX_DONATION);
        return (amount * (10**Vault(to_vault).decimals())) / pricePerShareTo;
    }

    function approve(
        address target,
        address to_vault,
        uint256 amount
    ) internal {
        if (IERC20(target).allowance(address(this), to_vault) < amount) {
            SafeERC20.safeApprove(IERC20(target), to_vault, 0);
            SafeERC20.safeApprove(IERC20(target), to_vault, type(uint256).max);
        }
    }

    function calc_withdraw_one_coin(
        address pool,
        uint256 amount,
        uint128 n
    ) internal view returns (uint256) {
        (bool success, bytes memory returnData) = pool.staticcall(
            abi.encodeWithSignature(
                "calc_withdraw_one_coin(uint256,uint256)",
                amount,
                uint256(n)
            )
        );
        if (success) {
            return abi.decode(returnData, (uint256));
        }
        (success, returnData) = pool.staticcall(
            abi.encodeWithSignature(
                "calc_withdraw_one_coin(uint256,int128)",
                amount,
                int128(n)
            )
        );

        require(success, "!success");

        return abi.decode(returnData, (uint256));
    }
}

