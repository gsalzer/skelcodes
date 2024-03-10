pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import "@studydefi/money-legos/dydx/contracts/DydxFlashloanBase.sol";
import "@studydefi/money-legos/dydx/contracts/ICallee.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import './IUniswapV2Router02.sol';
import './IFraxPool.sol';

// FROM: https://money-legos.studydefi.com/#/dydx

contract MintThenUni is ICallee, DydxFlashloanBase {
    address constant public USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant public WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant public FRAX_ADDRESS = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
    address constant public FXS_ADDRESS = 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0;

    address public owner_address;
    address payable public owner_address_payable;
    bool public is_paused;

    modifier onlyOwner {
        require(msg.sender == owner_address, "Only the contract owner may perform this action");
        _;
    }

    modifier notPaused {
        require(is_paused == false, "Contract is paused");
        _;
    }

    struct CustomParams {
        address token;
        uint256 repayAmount;
        uint256 collatForFXSUni;
        uint256 collatForMint;
        uint256 fxsAmountForMint;
        uint256 expectedFrax;
        address poolAddress;
        address routerAddress;
    }

    constructor () public {
        owner_address = msg.sender;
        owner_address_payable = msg.sender;
        is_paused = false;
    }

    // This is the function that will be called postLoan
    // i.e. Encode the logic to handle your flashloaned funds here
    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    ) public notPaused {
        CustomParams memory cust_params = abi.decode(data, (CustomParams));
        uint256 balOfLoanedToken = IERC20(cust_params.token).balanceOf(address(this));

        // Note that you can ignore the line below
        // if your dydx account (this contract in this case)
        // has deposited at least ~2 Wei of assets into the account
        // to balance out the collaterization ratio
        require(
            balOfLoanedToken >= cust_params.repayAmount,
            "Not enough funds to repay DyDx loan!"
        );

        require(
            cust_params.collatForFXSUni +  cust_params.collatForMint <= cust_params.repayAmount,
            "Not enough collat for both FXS Uniswap and the mint"
        );

        // TODO: Encode your logic here
        // E.g. arbitrage, liquidate accounts, 

        // Approve the collat for the router
        IERC20(cust_params.token).approve(cust_params.routerAddress, cust_params.collatForFXSUni);

        address[] memory FXS_USDC_PATH = new address[](2);
        FXS_USDC_PATH[0] = FXS_ADDRESS;
        FXS_USDC_PATH[1] = USDC_ADDRESS;

        // Buy some FXS
        IUniswapV2Router02(cust_params.routerAddress).swapExactTokensForTokens(
            cust_params.collatForFXSUni,
            0,
            FXS_USDC_PATH,
            address(this),
            2105300114 // A long time from now
        );

        // Approve the Collat for the FraxPool
        IERC20(cust_params.token).approve(cust_params.poolAddress, cust_params.collatForMint);

        // Approve the FXS for the FraxPool
        IERC20(FXS_ADDRESS).approve(cust_params.poolAddress, cust_params.fxsAmountForMint);

        // Mint
        IFraxPool(cust_params.poolAddress).mintFractionalFRAX(cust_params.collatForMint, cust_params.fxsAmountForMint, 0);

        address[] memory FRAX_USDC_PATH = new address[](2);
        FRAX_USDC_PATH[0] = FRAX_ADDRESS;
        FRAX_USDC_PATH[1] = USDC_ADDRESS;

        // Approve the FRAX for the router
        IERC20(FRAX_ADDRESS).approve(cust_params.routerAddress, cust_params.expectedFrax);

        // Sell the FRAX for USDC
        IUniswapV2Router02(cust_params.routerAddress).swapExactTokensForTokens(
            cust_params.expectedFrax,
            0,
            FRAX_USDC_PATH,
            address(this),
            2105300114 // A long time from now
        );
        
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner_address, tokenAmount);
    }

    function selfDestruct() external payable onlyOwner {
        selfdestruct(owner_address_payable);
    }

    function initiateFlashLoan(
        address _solo, 
        address _token, 
        uint256 _amount,
        uint256 _collat_for_FXS_uni,
        uint256 _collat_for_mint,
        uint256 _fxs_amount_for_mint,
        uint256 _expected_frax,
        address _pool_address,
        address _router_address
    ) external notPaused {
        ISoloMargin solo = ISoloMargin(_solo);

        // Get marketId from token address
        uint256 marketId = _getMarketIdFromTokenAddress(_solo, _token);

        // Calculate repay amount (_amount + (2 wei))
        // Approve transfer from for _solo to take back the loaned amount at the end
        uint256 repayAmount = _getRepaymentAmountInternal(_amount);
        IERC20(_token).approve(_solo, repayAmount);

        // 1. Withdraw $
        // 2. Call callFunction(...)
        // 3. Deposit back $
        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = _getWithdrawAction(marketId, _amount);
        operations[1] = _getCallAction(
            // Encode CustomParams for callFunction
            abi.encode(CustomParams({
                token: _token, 
                repayAmount: repayAmount,
                collatForFXSUni: _collat_for_FXS_uni,
                collatForMint: _collat_for_mint,
                fxsAmountForMint: _fxs_amount_for_mint,
                expectedFrax: _expected_frax,
                poolAddress: _pool_address,
                routerAddress: _router_address
            }))
        );
        operations[2] = _getDepositAction(marketId, repayAmount);

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        solo.operate(accountInfos, operations);
    }

    function togglePaused() external onlyOwner {
        is_paused = !is_paused;
    }

    function () external payable {}  
}
