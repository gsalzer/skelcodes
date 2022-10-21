// SPDX-License-Identifier: MIT
pragma solidity 0.6.2;

///
/// @title   Combines Uniswap V2 Protocol functions with Primitive V1.
/// @notice  Primitive V1 UniswapConnector03 - @primitivefi/contracts@v0.4.2
/// @author  Primitive
///

// Uniswap V2 & Primitive V1
import {
    IUniswapV2Callee
} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import {
    IUniswapV2Pair
} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {
    IUniswapConnector03,
    IUniswapV2Router02,
    IUniswapV2Factory,
    IOption,
    ITrader,
    IERC20
} from "./interfaces/IUniswapConnector03.sol";
import { UniswapConnectorLib03 } from "./libraries/UniswapConnectorLib03.sol";
// Open Zeppelin
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract UniswapConnector03 is
    IUniswapConnector03,
    IUniswapV2Callee,
    ReentrancyGuard
{
    using SafeERC20 for IERC20; // Reverts when `transfer` or `transferFrom` erc20 calls don't return proper data
    using SafeMath for uint256; // Reverts on math underflows/overflows

    ITrader public override trader; // The Primitive contract used to interact with the protocol
    IUniswapV2Factory public override factory; // The Uniswap V2 factory contract to get pair addresses from
    IUniswapV2Router02 public override router; // The Uniswap contract used to interact with the protocol

    event Initialized(address indexed from); // Emmitted on deployment
    event FlashOpened(address indexed from, uint256 quantity, uint256 premium); // Emmitted on flash opening a long position
    event FlashClosed(address indexed from, uint256 quantity, uint256 payout);

    // ==== Constructor ====

    constructor(
        address router_,
        address factory_,
        address trader_
    ) public {
        require(address(router) == address(0x0), "ERR_INITIALIZED");
        require(address(factory) == address(0x0), "ERR_INITIALIZED");
        require(address(trader) == address(0x0), "ERR_INITIALIZED");
        router = IUniswapV2Router02(router_);
        factory = IUniswapV2Factory(factory_);
        trader = ITrader(trader_);
        emit Initialized(msg.sender);
    }

    // ==== Combo Operations ====

    ///
    /// @dev Mints long + short option tokens, then swaps the shortOptionTokens (redeem) for tokens.
    /// @notice If the first address in the path is not the shortOptionToken address, the tx will fail.
    /// underlyingToken -> shortOptionToken -> quoteToken.
    /// IMPORTANT: redeemTokens = shortOptionTokens
    /// @param optionToken The address of the Option contract.
    /// @param amountIn The quantity of options to mint.
    /// @param amountOutMin The minimum quantity of tokens to receive in exchange for the shortOptionTokens.
    /// @param path The token addresses to trade through using their Uniswap V2 pools. Assumes path[0] = shortOptionToken.
    /// @param to The address to send the shortOptionToken proceeds and longOptionTokens to.
    /// @param deadline The timestamp for a trade to fail at if not successful.
    /// @return bool Whether the transaction was successful or not.
    ///
    function mintShortOptionsThenSwapToTokens(
        IOption optionToken,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override nonReentrant returns (bool) {
        bool success = UniswapConnectorLib03.mintShortOptionsThenSwapToTokens(
            router,
            optionToken,
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );
        return success;
    }

    // ==== Flash Functions ====

    ///
    /// @dev Receives underlyingTokens from a UniswapV2Pair.swap() call from a pair with
    /// reserve0 = shortOptionTokens and reserve1 = underlyingTokens.
    /// Uses underlyingTokens to mint long (option) + short (redeem) tokens.
    /// Sends longOptionTokens to msg.sender, and pays back the UniswapV2Pair the shortOptionTokens,
    /// AND any remainder quantity of underlyingTokens (paid by msg.sender).
    /// @notice If the first address in the path is not the shortOptionToken address, the tx will fail.
    /// @param optionAddress The address of the Option contract.
    /// @param flashLoanQuantity The quantity of options to mint using borrowed underlyingTokens.
    /// @param maxPremium The maximum quantity of underlyingTokens to pay for the optionTokens.
    /// @param path The token addresses to trade through using their Uniswap V2 pools. Assumes path[0] = shortOptionToken.
    /// @param to The address to send the shortOptionToken proceeds and longOptionTokens to.
    /// @return success bool Whether the transaction was successful or not.
    ///
    function flashMintShortOptionsThenSwap(
        address pairAddress,
        address optionAddress,
        uint256 flashLoanQuantity,
        uint256 maxPremium,
        address[] memory path,
        address to
    ) public override returns (uint256, uint256) {
        (uint256 outputOptions, uint256 loanRemainder) = UniswapConnectorLib03
            .flashMintShortOptionsThenSwap(
            router,
            pairAddress,
            optionAddress,
            flashLoanQuantity,
            maxPremium,
            path,
            to
        );
        emit FlashOpened(msg.sender, outputOptions, loanRemainder);
        return (outputOptions, loanRemainder);
    }

    /// @dev Sends shortOptionTokens to msg.sender, and pays back the UniswapV2Pair in underlyingTokens.
    /// @notice IMPORTANT: If minPayout is 0, the `to` address is liable for negative payouts *if* that occurs.
    /// @param pairAddress The address of the redeemToken<>underlyingToken UniswapV2Pair contract.
    /// @param optionAddress The address of the longOptionTokes to close.
    /// @param flashLoanQuantity The quantity of shortOptionTokens borrowed to use to close longOptionTokens.
    /// @param minPayout The minimum payout of underlyingTokens sent to the `to` address.
    /// @param path underlyingTokens -> shortOptionTokens, because we are paying the input of underlyingTokens.
    /// @param to The address which is sent the underlyingToken payout, or liable to pay for a negative payout.
    function flashCloseLongOptionsThenSwap(
        address pairAddress,
        address optionAddress,
        uint256 flashLoanQuantity,
        uint256 minPayout,
        address[] memory path,
        address to
    ) public override returns (uint256, uint256) {
        (
            uint256 outputUnderlyings,
            uint256 underlyingPayout
        ) = UniswapConnectorLib03.flashCloseLongOptionsThenSwap(
            router,
            pairAddress,
            optionAddress,
            flashLoanQuantity,
            minPayout,
            path,
            to
        );
        emit FlashClosed(msg.sender, outputUnderlyings, underlyingPayout);
        return (outputUnderlyings, underlyingPayout);
    }

    ///
    /// @dev Opens a longOptionToken position by minting long + short tokens, then selling the short tokens.
    /// @notice IMPORTANT: amountOutMin parameter is the price to swap shortOptionTokens to underlyingTokens.
    /// IMPORTANT: If the ratio between shortOptionTokens and underlyingTokens is 1:1, then only the swap fee (0.30%) has to be paid.
    /// @param optionToken The option address.
    /// @param amountOptions The quantity of longOptionTokens to purchase.
    /// @param maxPremium The maximum quantity of underlyingTokens to pay for the optionTokens.
    ///
    function openFlashLong(
        IOption optionToken,
        uint256 amountOptions,
        uint256 maxPremium
    ) external override nonReentrant returns (bool) {
        address redeemToken = optionToken.redeemToken();
        address underlyingToken = optionToken.getUnderlyingTokenAddress();
        address pairAddress = factory.getPair(redeemToken, underlyingToken);

        // Build the path to get the appropriate reserves to borrow from, and then pay back.
        // We are borrowing from reserve1 then paying it back mostly in reserve0.
        // Borrowing underlyingTokens, paying back in shortOptionTokens (normal swap). Pay any remainder in underlyingTokens.
        address[] memory path = new address[](2);
        path[0] = redeemToken;
        path[1] = underlyingToken;
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        bytes4 selector = bytes4(
            keccak256(
                bytes(
                    "flashMintShortOptionsThenSwap(address,address,uint256,uint256,address[],address)"
                )
            )
        );
        bytes memory params = abi.encodeWithSelector(
            selector, // function to call in this contract
            pairAddress, // pair contract we are borrowing from
            optionToken, // option token to mint with flash loaned tokens
            amountOptions, // quantity of underlyingTokens from flash loan to use to mint options
            maxPremium, // total price paid (in underlyingTokens) for selling shortOptionTokens
            path, // redeemToken -> underlyingToken
            msg.sender // address to pull the remainder loan amount to pay, and send longOptionTokens to.
        );

        // Receives 0 quoteTokens and `amountOptions` of underlyingTokens to `this` contract address.
        // Then executes `flashMintShortOptionsThenSwap`.
        uint256 amount0Out = pair.token0() == underlyingToken
            ? amountOptions
            : 0;
        uint256 amount1Out = pair.token0() == underlyingToken
            ? 0
            : amountOptions;

        // Borrow the amountOptions quantity of underlyingTokens and execute the callback function using params.
        pair.swap(amount0Out, amount1Out, address(this), params);
        return true;
    }

    ///
    /// @dev Closes a longOptionToken position by flash swapping in redeemTokens,
    /// closing the option, and paying back in underlyingTokens.
    /// @notice IMPORTANT: If minPayout is 0, this function will cost the caller to close the option, for no gain.
    /// @param optionToken The address of the longOptionTokens to close.
    /// @param amountRedeems The quantity of redeemTokens to borrow to close the options.
    /// @param minPayout The minimum payout of underlyingTokens sent out to the user.
    ///
    function closeFlashLong(
        IOption optionToken,
        uint256 amountRedeems,
        uint256 minPayout
    ) external override nonReentrant returns (bool) {
        address redeemToken = optionToken.redeemToken();
        address underlyingToken = optionToken.getUnderlyingTokenAddress();
        address pairAddress = factory.getPair(redeemToken, underlyingToken);

        // Build the path to get the appropriate reserves to borrow from, and then pay back.
        // We are borrowing from reserve1 then paying it back mostly in reserve0.
        // Borrowing redeemTokens, paying back in underlyingTokens (normal swap).
        // Pay any remainder in underlyingTokens.
        address[] memory path = new address[](2);
        path[0] = underlyingToken;
        path[1] = redeemToken;
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        bytes4 selector = bytes4(
            keccak256(
                bytes(
                    "flashCloseLongOptionsThenSwap(address,address,uint256,uint256,address[],address)"
                )
            )
        );
        bytes memory params = abi.encodeWithSelector(
            selector, // function to call in this contract
            pairAddress, // pair contract we are borrowing from
            optionToken, // option token to close with flash loaned redeemTokens
            amountRedeems, // quantity of redeemTokens from flash loan to use to close options
            minPayout, // total remaining underlyingTokens after flash loan is paid
            path, // underlyingToken -> redeemToken
            msg.sender // address to send payout of underlyingTokens to. Will pull underlyingTokens if negative payout and minPayout <= 0.
        );

        // Receives 0 underlyingTokens and `amountRedeems` of redeemTokens to `this` contract address.
        // Then executes `flashCloseLongOptionsThenSwap`.
        uint256 amount0Out = pair.token0() == redeemToken ? amountRedeems : 0;
        uint256 amount1Out = pair.token0() == redeemToken ? 0 : amountRedeems;

        // Borrow the amountRedeems quantity of redeemTokens and execute the callback function using params.
        pair.swap(amount0Out, amount1Out, address(this), params);
        return true;
    }

    // ==== Liquidity Functions ====

    ///
    /// @dev Adds redeemToken liquidity to a redeem<>token pair by minting shortOptionTokens with underlyingTokens.
    /// @notice Pulls underlying tokens from msg.sender and pushes UNI-V2 liquidity tokens to the "to" address.
    /// underlyingToken -> redeemToken -> UNI-V2.
    /// @param optionAddress The address of the optionToken to get the redeemToken to mint then provide liquidity for.
    /// @param quantityOptions The quantity of underlyingTokens to use to mint option + redeem tokens.
    /// @param amountBMax The minimum quantity of shortOptionTokens expected to provide liquidity with.
    /// @param amountBMin The minimum quantity of otherTokens expected to provide liquidity with.
    /// @param to The address that receives UNI-V2 shares.
    /// @param deadline The timestamp to expire a pending transaction.
    ///
    function addShortLiquidityWithUnderlying(
        address optionAddress,
        uint256 quantityOptions,
        uint256 amountBMax,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        override
        nonReentrant
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return
            UniswapConnectorLib03.addShortLiquidityWithUnderlying(
                router,
                optionAddress,
                quantityOptions,
                amountBMax,
                amountBMin,
                to,
                deadline
            );
    }

    ///
    /// @dev Combines Uniswap V2 Router "removeLiquidity" function with Primitive "closeOptions" function.
    /// @notice Pulls UNI-V2 liquidity shares with shortOption<>quote token, and optionTokens from msg.sender.
    /// Then closes the longOptionTokens and withdraws underlyingTokens to the "to" address.
    /// Sends quoteTokens from the burned UNI-V2 liquidity shares to the "to" address.
    /// UNI-V2 -> optionToken -> underlyingToken.
    /// @param optionAddress The address of the option that will be closed from burned UNI-V2 liquidity shares.
    /// @param otherTokenAddress The address of the other token in the option pair.
    /// @param liquidity The quantity of liquidity tokens to pull from msg.sender and burn.
    /// @param amountAMin The minimum quantity of shortOptionTokens to receive from removing liquidity.
    /// @param amountBMin The minimum quantity of quoteTokens to receive from removing liquidity.
    /// @param to The address that receives quoteTokens from burned UNI-V2, and underlyingTokens from closed options.
    /// @param deadline The timestamp to expire a pending transaction.
    ///
    function removeShortLiquidityThenCloseOptions(
        address optionAddress,
        address otherTokenAddress,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external override nonReentrant returns (uint256, uint256) {
        return
            UniswapConnectorLib03.removeShortLiquidityThenCloseOptions(
                factory,
                router,
                trader,
                optionAddress,
                otherTokenAddress,
                liquidity,
                amountAMin,
                amountBMin,
                to,
                deadline
            );
    }

    // ==== Callback Implementation ====

    ///
    /// @dev The callback function triggered in a UniswapV2Pair.swap() call when the `data` parameter has data.
    /// @param sender The original msg.sender of the UniswapV2Pair.swap() call.
    /// @param amount0 The quantity of token0 received to the `to` address in the swap() call.
    /// @param amount1 The quantity of token1 received to the `to` address in the swap() call.
    /// @param data The payload passed in the `data` parameter of the swap() call.
    ///
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        assert(msg.sender == factory.getPair(token0, token1)); /// ensure that msg.sender is actually a V2 pair
        (bool success, bytes memory returnData) = address(this).call(data);
        require(
            success &&
                (returnData.length == 0 || abi.decode(returnData, (bool))),
            "ERR_UNISWAPV2_CALL_FAIL"
        );
    }

    // ==== Management Functions ====

    /// @dev Creates a UniswapV2Pair by calling `createPair` on the UniswapV2Factory.
    function deployUniswapMarket(address optionAddress, address otherToken)
        external
        override
        returns (address)
    {
        address uniswapPair = factory.createPair(optionAddress, otherToken);
        return uniswapPair;
    }

    // ==== View ====

    /// @dev Gets a UniswapV2Pair address for two tokens by calling the UniswapV2Factory.
    function getUniswapMarketForTokens(address token0, address token1)
        public
        override
        view
        returns (address)
    {
        address uniswapPair = factory.getPair(token0, token1);
        require(uniswapPair != address(0x0), "ERR_PAIR_DOES_NOT_EXIST");
        return uniswapPair;
    }

    /// @dev Gets the name of the contract.
    function getName() external override pure returns (string memory) {
        return "PrimitiveV1UniswapConnector03";
    }

    /// @dev Gets the version of the contract.
    function getVersion() external override pure returns (uint8) {
        return uint8(3);
    }
}

