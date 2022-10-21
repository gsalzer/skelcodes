pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./AegisComptrollerCommon.sol";
import "./AegisComptrollerInterface.sol";
import "./Exponential.sol";
import "./Unitroller.sol";
import "./BaseReporter.sol";
import "./EIP20Interface.sol";
import "./AErc20.sol";

/**
 * @notice Aegis Comptroller contract
 * @author Aegis
 */
contract AegisComptroller is AegisComptrollerCommon, AegisComptrollerInterface, Exponential, BaseReporter {
    uint internal constant closeFactorMinMantissa = 0.05e18;
    uint internal constant closeFactorMaxMantissa = 0.9e18;
    uint internal constant collateralFactorMaxMantissa = 0.9e18;
    uint internal constant liquidationIncentiveMinMantissa = 1.0e18;
    uint internal constant liquidationIncentiveMaxMantissa = 1.5e18;

    constructor () public {
        admin = msg.sender;
        liquidateAdmin = msg.sender;
    }

    /**
     * @notice Returns the assets an account has entered
     * @param _account address account
     * @return AToken[]
     */
    function getAssetsIn(address _account) external view returns (AToken[] memory) {
        return accountAssets[_account];
    }

    /**
     * @notice Whether the current account has corresponding assets
     * @param _account address account
     * @param _aToken AToken
     * @return bool
     */
    function checkMembership(address _account, AToken _aToken) external view returns (bool) {
        return markets[address(_aToken)].accountMembership[_account];
    }

    /**
     * @notice Enter Markets
     * @param _aTokens AToken[]
     * @return uint[]
     */
    function enterMarkets(address[] memory _aTokens) public returns (uint[] memory) {
        uint len = _aTokens.length;
        uint[] memory results = new uint[](len);
        for (uint i = 0; i < len; i++) {
            AToken aToken = AToken(_aTokens[i]);
            results[i] = uint(addToMarketInternal(aToken, msg.sender));
        }
        return results;
    }

    /**
     * @notice Add the market to the borrower's "assets in" for liquidity calculations
     * @param _aToken AToken address
     * @param _sender address sender
     * @return Error SUCCESS
     */
    function addToMarketInternal(AToken _aToken, address _sender) internal returns (Error) {
        Market storage marketToJoin = markets[address(_aToken)];
        require(marketToJoin.isListed, "addToMarketInternal marketToJoin.isListed false");
        if (marketToJoin.accountMembership[_sender] == true) {
            return Error.SUCCESS;
        }

        require(accountAssets[_sender].length < maxAssets, "addToMarketInternal: accountAssets[_sender].length >= maxAssets");
        marketToJoin.accountMembership[_sender] = true;
        accountAssets[_sender].push(_aToken);

        emit MarketEntered(_aToken, _sender);
        return Error.SUCCESS;
    }

    /**
     * @notice Removes asset from sender's account liquidity calculation
     * @param _aTokenAddress aToken address
     * @return SUCCESS
     */
    function exitMarket(address _aTokenAddress) external returns (uint) {
        AToken aToken = AToken(_aTokenAddress);
        (uint err, uint tokensHeld, uint borrowBalance,) = aToken.getAccountSnapshot(msg.sender);
        require(err == uint(Error.SUCCESS), "AegisComptroller::exitMarket aToken.getAccountSnapshot failure");
        require(borrowBalance == 0, "AegisComptroller::exitMarket borrowBalance Non-zero");

        uint allowed = redeemAllowedInternal(_aTokenAddress, msg.sender, tokensHeld);
        require(allowed == 0, "AegisComptroller::exitMarket redeemAllowedInternal failure");

        Market storage marketToExit = markets[address(aToken)];
        if (!marketToExit.accountMembership[msg.sender]) {
            return uint(Error.SUCCESS);
        }
        delete marketToExit.accountMembership[msg.sender];

        AToken[] memory userAssetList = accountAssets[msg.sender];
        uint len = userAssetList.length;
        uint assetIndex = len;
        for (uint i = 0; i < len; i++) {
            if (userAssetList[i] == aToken) {
                assetIndex = i;
                break;
            }
        }
        assert(assetIndex < len);
        AToken[] storage storedList = accountAssets[msg.sender];
        storedList[assetIndex] = storedList[storedList.length - 1];
        storedList.length--;

        emit MarketExited(aToken, msg.sender);
        return uint(Error.SUCCESS);
    }

    /**
     * @dev financial risk management
     */

    function mintAllowed() external returns (uint) {
        require(!_mintGuardianPaused, "AegisComptroller::mintAllowed _mintGuardianPaused failure");
        return uint(Error.SUCCESS);
    }
    function repayBorrowAllowed() external returns (uint) {
        require(!_borrowGuardianPaused, "AegisComptroller::repayBorrowAllowed _borrowGuardianPaused failure");
        return uint(Error.SUCCESS);
    }
    function seizeAllowed(address _aTokenCollateral, address _aTokenBorrowed) external returns (uint) {
        require(!seizeGuardianPaused, "AegisComptroller::seizeAllowedseize seizeGuardianPaused failure");
        if (!markets[_aTokenCollateral].isListed || !markets[_aTokenBorrowed].isListed) {
            return uint(Error.ERROR);
        }
        if (AToken(_aTokenCollateral).comptroller() != AToken(_aTokenBorrowed).comptroller()) {
            return uint(Error.ERROR);
        }
        return uint(Error.SUCCESS);
    }
    
    /**
     * @notice Checks if the account should be allowed to redeem tokens in the given market
     * @param _aToken aToken address
     * @param _redeemer address redeemer
     * @param _redeemTokens number
     * @return SUCCESS
     */
    function redeemAllowed(address _aToken, address _redeemer, uint _redeemTokens) external returns (uint) {
        return redeemAllowedInternal(_aToken, _redeemer, _redeemTokens);
    }

    function redeemAllowedInternal(address _aToken, address _redeemer, uint _redeemTokens) internal view returns (uint) {
        require(markets[_aToken].isListed, "AToken must be in the market");
        if (!markets[_aToken].accountMembership[_redeemer]) {
            return uint(Error.SUCCESS);
        }
        (Error err,, uint shortfall) = getHypotheticalAccountLiquidityInternal(_redeemer, AToken(_aToken), _redeemTokens, 0);
        require(err == Error.SUCCESS && shortfall <= 0, "getHypotheticalAccountLiquidityInternal failure");
        return uint(Error.SUCCESS);
    }

    /**
     * @notice Validates redeem and reverts on rejection
     * @param _redeemAmount number
     * @param _redeemTokens number
     */
    function redeemVerify(uint _redeemAmount, uint _redeemTokens) external {
        if (_redeemTokens == 0 && _redeemAmount > 0) {
            revert("_redeemTokens zero");
        }
    }

    /**
     * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
     * @param _aToken AToken address
     * @param _borrower address borrower
     * @param _borrowAmount number
     * @return SUCCESS
     */
    function borrowAllowed(address _aToken, address _borrower, uint _borrowAmount) external returns (uint) {
        require(!borrowGuardianPaused[_aToken], "AegisComptroller::borrowAllowed borrowGuardianPaused failure");
        if (!markets[_aToken].isListed) {
            return uint(Error.ERROR);
        }
        if (!markets[_aToken].accountMembership[_borrower]) {
            require(msg.sender == _aToken, "AegisComptroller::accountMembership failure");
            Error err = addToMarketInternal(AToken(msg.sender), _borrower);
            if (err != Error.SUCCESS) {
                return uint(err);
            }
            assert(markets[_aToken].accountMembership[_borrower]);
        }
        if (oracle.getUnderlyingPrice(_aToken) == 0) {
            return uint(Error.ERROR);
        }
        (Error err,, uint shortfall) = getHypotheticalAccountLiquidityInternal(_borrower, AToken(_aToken), 0, _borrowAmount);
        if (err != Error.SUCCESS) {
            return uint(err);
        }
        if (shortfall > 0) {
            return uint(Error.ERROR);
        }
        return uint(Error.SUCCESS);
    }

    function transferAllowed(address _aToken, address _src, uint _transferTokens) external returns (uint) {
        require(!transferGuardianPaused, "AegisComptroller::transferAllowed failure");
        uint allowed = redeemAllowedInternal(_aToken, _src, _transferTokens); 
        if (allowed != uint(Error.SUCCESS)) {
            return allowed;
        }
        return uint(Error.SUCCESS);
    }

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @param _account address account
     * @return SUCCESS, number, number
     */
    function getAccountLiquidity(address _account) public view returns (uint, uint, uint) {
        (Error err, uint liquidity, uint shortfall) = getHypotheticalAccountLiquidityInternal(_account, AToken(0), 0, 0);
        return (uint(err), liquidity, shortfall);
    }

    event AutoLiquidity(address _account, uint _actualAmount);

    /**
     * @notice owner automatic liquidation
     * @param _account liquidity account
     * @param _liquidityAmount liquidity amount
     * @param _liquidateIncome liquidity income
     * @return SUCCESS, number
     */
    function autoLiquidity(address _account, uint _liquidityAmount, uint _liquidateIncome) public returns (uint) {
        require(msg.sender == liquidateAdmin, "SET_PRICE_ORACLE_OWNER_CHECK");
        (uint err, uint _actualAmount) = autoLiquidityInternal(msg.sender, _account, _liquidityAmount, _liquidateIncome);
        require(err == uint(Error.SUCCESS), "autoLiquidity::autoLiquidityInternal failure");
        emit AutoLiquidity(_account, _actualAmount);
        return uint(Error.SUCCESS);
    }

    struct LiquidationDetail {
        uint aTokenBalance;
        uint aTokenBorrow;
        uint exchangeRateMantissa;
        uint oraclePriceMantissa;
        uint assetAmount;
        uint borrowAmount;
        uint mitem;
        uint repayY;
        uint _liquidate;
        uint _repayLiquidate;
        uint _x;
    }

    /**
     * @notice owner automatic liquidation Internal
     * @param _owner liquidateAdmin
     * @param _account negative account liquidity
     * @param _liquidityAmount liquidity amount
     * @param _liquidateIncome liquidity income
     * @return SUCCESS
     */
    function autoLiquidityInternal(address _owner, address _account, uint _liquidityAmount, uint _liquidateIncome) internal returns (uint, uint) {
        uint err;
        LiquidationDetail memory vars;
        AToken[] memory assets = accountAssets[_account];
        vars.mitem = _liquidateIncome;
        vars.repayY = _liquidityAmount;
        for (uint i = 0; i < assets.length; i++) {
            AToken asset = assets[i];
            (err, vars.aTokenBalance, vars.aTokenBorrow, vars.exchangeRateMantissa) = asset.getAccountSnapshot(_account);
            require(err == uint(Error.SUCCESS), "autoLiquidityInternal::asset.getAccountSnapshot failure");
            vars.oraclePriceMantissa = oracle.getUnderlyingPrice(address(asset));
            require(vars.oraclePriceMantissa > 0, "price must be greater than 0");
            if(vars.aTokenBalance > 0 && vars.mitem != 0) {
                vars.assetAmount = vars.aTokenBalance * vars.exchangeRateMantissa * vars.oraclePriceMantissa / 1e36;
                if(keccak256(abi.encodePacked((asset.symbol()))) != keccak256(abi.encodePacked(("ETH-A")))) {
                    EIP20Interface token = EIP20Interface(AErc20(address(asset)).underlying());
                    uint underlyingDecimals = token.decimals();
                    vars.assetAmount = vars.assetAmount * (10 ** (18 - underlyingDecimals));
                    vars._x = vars.mitem * 1e18 / vars.exchangeRateMantissa * (10**underlyingDecimals) / vars.oraclePriceMantissa;
                }else{
                    vars._x = vars.mitem * 1e18 / vars.exchangeRateMantissa * 1e18 / vars.oraclePriceMantissa;
                }
                if(vars.assetAmount >= vars.mitem) {
                    asset.ownerTransferToken(_owner, _account, vars._x);
                    vars.mitem = 0;
                }else {
                    asset.ownerTransferToken(_owner, _account, vars.aTokenBalance);
                    vars.mitem = vars.mitem - vars.assetAmount;
                }
            }
            if(keccak256(abi.encodePacked((asset.symbol()))) == keccak256(abi.encodePacked(("ETH-A")))) break;
            if(vars.aTokenBorrow > 0 && vars.repayY != 0) {
                vars.borrowAmount = vars.aTokenBorrow * vars.oraclePriceMantissa / 1e18;
                EIP20Interface token = EIP20Interface(AErc20(address(asset)).underlying());
                uint underlyingDecimals = token.decimals();
                vars.borrowAmount = vars.borrowAmount * (10 ** (18 - underlyingDecimals));
                vars._repayLiquidate = vars.repayY * 1e18 / vars.oraclePriceMantissa;
                if(vars.borrowAmount >= vars.repayY) {
                    asset.ownerCompensation(_owner, _account, vars._repayLiquidate / (10 ** (18-underlyingDecimals)));
                    vars.repayY = 0;
                }else {
                    asset.ownerCompensation(_owner, _account, vars.aTokenBorrow);
                    vars.repayY = vars.repayY - vars.borrowAmount;
                }
            }
        }
        return (uint(Error.SUCCESS), vars.repayY);
    }

    function liquidityItem (address _account) public view returns (uint, AccountDetail memory) {
        AToken[] memory assets = accountAssets[_account];
        AccountDetail memory detail;
        AccountLiquidityLocalVars memory vars;
        uint err;
        MathError mErr;
        for (uint i = 0; i < assets.length; i++) {
            AToken asset = assets[i];
            (err, vars.aTokenBalance, vars.borrowBalance, vars.exchangeRateMantissa) = asset.getAccountSnapshot(_account);
            if (err != uint(Error.SUCCESS)) {
                return (uint(Error.ERROR), detail);
            }
            vars.collateralFactor = Exp({mantissa: markets[address(asset)].collateralFactorMantissa});
            vars.exchangeRate = Exp({mantissa: vars.exchangeRateMantissa});
            vars.oraclePriceMantissa = oracle.getUnderlyingPrice(address(asset));
            if (vars.oraclePriceMantissa == 0) {
                return (uint(Error.ERROR), detail);
            }
            vars.oraclePrice = Exp({mantissa: vars.oraclePriceMantissa});
            (mErr, vars.tokensToDenom) = mulExp3(vars.collateralFactor, vars.exchangeRate, vars.oraclePrice);
            if (mErr != MathError.NO_ERROR) {
                return (uint(Error.ERROR), detail);
            }
            (mErr, vars.sumCollateral) = mulScalarTruncateAddUInt(vars.tokensToDenom, vars.aTokenBalance, 0);
            if (mErr != MathError.NO_ERROR) {
                return (uint(Error.ERROR), detail);
            }
            (mErr, vars.sumBorrowPlusEffects) = mulScalarTruncateAddUInt(vars.oraclePrice, vars.borrowBalance, 0);
            if (mErr != MathError.NO_ERROR) {
                return (uint(Error.ERROR), detail);
            }
            if(keccak256(abi.encodePacked((asset.symbol()))) != keccak256(abi.encodePacked(("ETH-A")))) {
                EIP20Interface token = EIP20Interface(AErc20(address(asset)).underlying());
                uint underlyingDecimals = token.decimals();
                detail.totalCollateral = detail.totalCollateral + (vars.sumCollateral * (10 ** (18 - underlyingDecimals)));
                detail.borrowPlusEffects = detail.borrowPlusEffects + (vars.sumBorrowPlusEffects * (10 ** (18 - underlyingDecimals)));
            }else {
                detail.totalCollateral = detail.totalCollateral + vars.sumCollateral;
                detail.borrowPlusEffects = detail.borrowPlusEffects + vars.sumBorrowPlusEffects;
            }
        }
        return (uint(Error.SUCCESS), detail);
    }

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @param _account address account
     * @return SUCCESS, number, number
     */
    function getAccountLiquidityInternal(address _account) internal view returns (Error, uint, uint) {
        return getHypotheticalAccountLiquidityInternal(_account, AToken(0), 0, 0);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param _account address account
     * @param _aTokenModify address aToken
     * @param _redeemTokens number
     * @param _borrowAmount amount
     * @return ERROR, number, number
     */
    function getHypotheticalAccountLiquidity(address _account, address _aTokenModify, uint _redeemTokens, uint _borrowAmount) public view returns (uint, uint, uint) {
        (Error err, uint liquidity, uint shortfall) = getHypotheticalAccountLiquidityInternal(_account, AToken(_aTokenModify), _redeemTokens, _borrowAmount);
        return (uint(err), liquidity, shortfall);
    }

    struct AccountDetail {
        uint totalCollateral;
        uint borrowPlusEffects;
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @dev sumCollateral += tokensToDenom * cTokenBalance
     * @dev sumBorrowPlusEffects += oraclePrice * borrowBalance
     * @dev sumBorrowPlusEffects += tokensToDenom * redeemTokens
     * @dev sumBorrowPlusEffects += oraclePrice * borrowAmount
     * @param _account address account
     * @param _aTokenModify address aToken
     * @param _redeemTokens number
     * @param _borrowAmount amount
     * @return ERROR, number, number
     */
    function getHypotheticalAccountLiquidityInternal(address _account, AToken _aTokenModify, uint _redeemTokens, uint _borrowAmount) internal view returns (Error, uint, uint) {
        AccountLiquidityLocalVars memory vars;
        uint err;
        MathError mErr;
        AToken[] memory assets = accountAssets[_account];
        AccountDetail memory detail;
        for (uint i = 0; i < assets.length; i++) {
            AToken asset = assets[i];
            (err, vars.aTokenBalance, vars.borrowBalance, vars.exchangeRateMantissa) = asset.getAccountSnapshot(_account);
            if (err != uint(Error.SUCCESS)) {
                return (Error.ERROR, 0, 0);
            }
            vars.collateralFactor = Exp({mantissa: markets[address(asset)].collateralFactorMantissa});
            vars.exchangeRate = Exp({mantissa: vars.exchangeRateMantissa});
            vars.oraclePriceMantissa = oracle.getUnderlyingPrice(address(asset));
            if (vars.oraclePriceMantissa == 0) {
                return (Error.ERROR, 0, 0);
            }
            vars.oraclePrice = Exp({mantissa: vars.oraclePriceMantissa});
            (mErr, vars.tokensToDenom) = mulExp3(vars.collateralFactor, vars.exchangeRate, vars.oraclePrice);
            if (mErr != MathError.NO_ERROR) {
                return (Error.ERROR, 0, 0);
            }
            (mErr, vars.sumCollateral) = mulScalarTruncateAddUInt(vars.tokensToDenom, vars.aTokenBalance, 0);
            if (mErr != MathError.NO_ERROR) {
                return (Error.ERROR, 0, 0);
            }
            (mErr, vars.sumBorrowPlusEffects) = mulScalarTruncateAddUInt(vars.oraclePrice, vars.borrowBalance, 0);
            if (mErr != MathError.NO_ERROR) {
                return (Error.ERROR, 0, 0);
            }
            if (asset == _aTokenModify) {
                if(_borrowAmount == 0){
                    (mErr, vars.sumBorrowPlusEffects) = mulScalarTruncateAddUInt(vars.tokensToDenom, _redeemTokens, vars.sumBorrowPlusEffects);
                    if (mErr != MathError.NO_ERROR) {
                        return (Error.ERROR, 0, 0);
                    }
                }
                if(_redeemTokens == 0){
                    (mErr, vars.sumBorrowPlusEffects) = mulScalarTruncateAddUInt(vars.oraclePrice, _borrowAmount, vars.sumBorrowPlusEffects);
                    if (mErr != MathError.NO_ERROR) {
                        return (Error.ERROR, 0, 0);
                    }
                }
            }
            if(keccak256(abi.encodePacked((asset.symbol()))) != keccak256(abi.encodePacked(("ETH-A")))) {
                EIP20Interface token = EIP20Interface(AErc20(address(asset)).underlying());
                uint underlyingDecimals = token.decimals();
                detail.totalCollateral = detail.totalCollateral + (vars.sumCollateral * (10 ** (18 - underlyingDecimals)));
                detail.borrowPlusEffects = detail.borrowPlusEffects + (vars.sumBorrowPlusEffects * (10 ** (18 - underlyingDecimals)));
            }else {
                detail.totalCollateral = detail.totalCollateral + vars.sumCollateral;
                detail.borrowPlusEffects = detail.borrowPlusEffects + vars.sumBorrowPlusEffects;
            }
        }
        if(_redeemTokens == 0 && detail.borrowPlusEffects < minimumLoanAmount) {
            return (Error.ERROR, 0, 0);
        }
        if (detail.totalCollateral > detail.borrowPlusEffects) {
            return (Error.SUCCESS, detail.totalCollateral - detail.borrowPlusEffects, 0);
        } else {
            return (Error.SUCCESS, 0, detail.borrowPlusEffects - detail.totalCollateral);
        }
    }

    /**
     * @notice Calculate number of tokens of collateral asset to seize given an underlying amount
     * @dev seizeAmount = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
     * @dev seizeTokens = seizeAmount / exchangeRate = actualRepayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
     * @param _aTokenBorrowed address borrow
     * @param _aTokenCollateral address collateral
     * @param _actualRepayAmount amount
     * @return SUCCESS, number
     */
    function liquidateCalculateSeizeTokens(address _aTokenBorrowed, address _aTokenCollateral, uint _actualRepayAmount) external view returns (uint, uint) {
        uint priceBorrowedMantissa = oracle.getUnderlyingPrice(_aTokenBorrowed);
        uint priceCollateralMantissa = oracle.getUnderlyingPrice(_aTokenCollateral);
        if (priceBorrowedMantissa == 0 || priceCollateralMantissa == 0) {
            return (uint(Error.ERROR), 0);
        }
        uint exchangeRateMantissa = AToken(_aTokenCollateral).exchangeRateStored();
        uint seizeTokens;
        Exp memory numerator;
        Exp memory denominator;
        Exp memory ratio;
        MathError mathErr;

        (mathErr, numerator) = mulExp(liquidationIncentiveMantissa, priceBorrowedMantissa);
        if (mathErr != MathError.NO_ERROR) {
            return (uint(Error.ERROR), 0);
        }
        (mathErr, denominator) = mulExp(priceCollateralMantissa, exchangeRateMantissa);
        if (mathErr != MathError.NO_ERROR) {
            return (uint(Error.ERROR), 0);
        }
        (mathErr, ratio) = divExp(numerator, denominator);
        if (mathErr != MathError.NO_ERROR) {
            return (uint(Error.ERROR), 0);
        }
        (mathErr, seizeTokens) = mulScalarTruncate(ratio, _actualRepayAmount);
        if (mathErr != MathError.NO_ERROR) {
            return (uint(Error.ERROR), 0);
        }
        return (uint(Error.SUCCESS), seizeTokens);
    }

    event AutoClearance(address _account, uint _liquidateAmount, uint _actualAmount);
    function autoClearance(address _account, uint _liquidateAmount, uint _liquidateIncome) public returns (uint, uint, uint) {
        require(_liquidateAmount > 0, "autoClearance _liquidateAmount must be greater than 0");
        (uint err, uint _actualAmount) = autoClearanceInternal(msg.sender, _account, _liquidateAmount, _liquidateIncome);
        require(err == uint(Error.SUCCESS), "AegisComptroller::autoClearance autoClearanceInternal failure");
        emit AutoClearance(_account, _liquidateAmount, _actualAmount);
        return (err, _liquidateAmount, _actualAmount);
    }

    function autoClearanceInternal(address _owner, address _account, uint _liquidateAmount, uint _liquidateIncome) internal returns(uint, uint) {
        uint err;
        LiquidationDetail memory vars;
        AToken[] memory assets = accountAssets[_account];
        vars._liquidate = _liquidateIncome;
        vars._repayLiquidate = _liquidateAmount;
        for (uint i = 0; i < assets.length; i++) {
            AToken asset = assets[i];
            (err, vars.aTokenBalance, vars.aTokenBorrow, vars.exchangeRateMantissa) = asset.getAccountSnapshot(_account);
            if (err != uint(Error.SUCCESS)) {
                return (uint(Error.ERROR), 0);
            }
            vars.oraclePriceMantissa = oracle.getUnderlyingPrice(address(asset));
            if (vars.oraclePriceMantissa == 0) {
                return (uint(Error.ERROR), 0);
            }
            if(vars.aTokenBalance > 0 && vars._liquidate != 0) {
                vars.assetAmount = vars.aTokenBalance * vars.exchangeRateMantissa * vars.oraclePriceMantissa / 1e36;
                if(keccak256(abi.encodePacked((asset.symbol()))) != keccak256(abi.encodePacked(("ETH-A")))) {
                    EIP20Interface token = EIP20Interface(AErc20(address(asset)).underlying());
                    uint underlyingDecimals = token.decimals();
                    vars.assetAmount = vars.assetAmount * (10 ** (18 - underlyingDecimals));
                    vars._x = vars._liquidate * 1e18 / vars.exchangeRateMantissa * (10**underlyingDecimals) / vars.oraclePriceMantissa;
                }else{
                    vars._x = vars._liquidate * 1e18 / vars.exchangeRateMantissa * 1e18 / vars.oraclePriceMantissa;
                }
                if(vars.assetAmount >= vars._liquidate) {
                    asset.ownerTransferToken(_owner, _account, vars._x);
                    vars._liquidate = 0;
                }else {
                    asset.ownerTransferToken(_owner, _account, vars.aTokenBalance);
                    vars._liquidate = vars._liquidate - vars.assetAmount;
                }
            }
            if(keccak256(abi.encodePacked((asset.symbol()))) == keccak256(abi.encodePacked(("ETH-A")))) break;
            if(vars.aTokenBorrow > 0 && vars._repayLiquidate != 0) {
                vars.borrowAmount = vars.aTokenBorrow * vars.oraclePriceMantissa / 1e18;
                EIP20Interface token = EIP20Interface(AErc20(address(asset)).underlying());
                uint underlyingDecimals = token.decimals();
                vars.borrowAmount = vars.borrowAmount * (10 ** (18 - underlyingDecimals));

                if(vars.borrowAmount >= vars._repayLiquidate) {
                    asset.ownerCompensation(_owner, _account, vars._repayLiquidate * 1e18 / vars.oraclePriceMantissa / (10 ** (18 - underlyingDecimals)));
                    vars._repayLiquidate = 0;
                }else {
                    asset.ownerCompensation(_owner, _account, vars.aTokenBorrow);
                    vars._repayLiquidate = vars._repayLiquidate - vars.borrowAmount;
                }
            }
        }
        return (uint(Error.SUCCESS), vars._repayLiquidate);
    }

    /**
      * @notice Sets a new price oracle
      * @param _newOracle address PriceOracle
      * @return SUCCESS
      */
    function _setPriceOracle(PriceOracle _newOracle) public returns (uint) {
        require(msg.sender == admin, "SET_PRICE_ORACLE_OWNER_CHECK");
        PriceOracle oldOracle = oracle;
        oracle = _newOracle;
        emit NewPriceOracle(oldOracle, _newOracle);
        return uint(Error.SUCCESS);
    }

    /**
     * @notice Sets the closeFactor used when liquidating borrows
     * @param _newCloseFactorMantissa number
     * @return SUCCESS
     */
    function _setCloseFactor(uint _newCloseFactorMantissa) external returns (uint) {
        require(msg.sender == admin, "SET_CLOSE_FACTOR_OWNER_CHECK");
        
        Exp memory newCloseFactorExp = Exp({mantissa: _newCloseFactorMantissa});
        Exp memory lowLimit = Exp({mantissa: closeFactorMinMantissa});
        if (lessThanOrEqualExp(newCloseFactorExp, lowLimit)) {
            return fail(Error.ERROR, ErrorRemarks.SET_CLOSE_FACTOR_VALIDATION, uint(Error.ERROR));
        }

        Exp memory highLimit = Exp({mantissa: closeFactorMaxMantissa});
        if (lessThanExp(highLimit, newCloseFactorExp)) {
            return fail(Error.ERROR, ErrorRemarks.SET_CLOSE_FACTOR_VALIDATION, uint(Error.ERROR));
        }
        uint oldCloseFactorMantissa = closeFactorMantissa;
        closeFactorMantissa = _newCloseFactorMantissa;

        emit NewCloseFactor(oldCloseFactorMantissa, closeFactorMantissa);
        return uint(Error.SUCCESS);
    }

    /**
     * @notice Sets the collateralFactor for a market
     * @param _aToken address AToken
     * @param _newCollateralFactorMantissa uint
     * @return SUCCESS
     */
    function _setCollateralFactor(AToken _aToken, uint _newCollateralFactorMantissa) external returns (uint) {
        require(msg.sender == admin, "SET_COLLATERAL_FACTOR_OWNER_CHECK");
        Market storage market = markets[address(_aToken)];
        if (!market.isListed) {
            return fail(Error.ERROR, ErrorRemarks.SET_COLLATERAL_FACTOR_NO_EXISTS, uint(Error.ERROR));
        }
        Exp memory newCollateralFactorExp = Exp({mantissa: _newCollateralFactorMantissa});
        Exp memory highLimit = Exp({mantissa: collateralFactorMaxMantissa});
        if (lessThanExp(highLimit, newCollateralFactorExp)) {
            return fail(Error.ERROR, ErrorRemarks.SET_COLLATERAL_FACTOR_VALIDATION, uint(Error.ERROR));
        }
        if (_newCollateralFactorMantissa != 0 && oracle.getUnderlyingPrice(address(_aToken)) == 0) {
            return fail(Error.ERROR, ErrorRemarks.SET_COLLATERAL_FACTOR_WITHOUT_PRICE, uint(Error.ERROR));
        }
        uint oldCollateralFactorMantissa = market.collateralFactorMantissa;
        market.collateralFactorMantissa = _newCollateralFactorMantissa;

        emit NewCollateralFactor(_aToken, oldCollateralFactorMantissa, _newCollateralFactorMantissa);
        return uint(Error.SUCCESS);
    }

    /**
      * @notice Sets maxAssets which controls how many markets can be entered
      * @param _newMaxAssets assets
      * @return SUCCESS
      */
    function _setMaxAssets(uint _newMaxAssets) external returns (uint) {
        require(msg.sender == admin, "SET_MAX_ASSETS_OWNER_CHECK");
        
        uint oldMaxAssets = maxAssets;
        maxAssets = _newMaxAssets; // push storage

        emit NewMaxAssets(oldMaxAssets, _newMaxAssets);
        return uint(Error.SUCCESS);
    }

    /**
      * @notice Sets liquidationIncentive
      * @param _newLiquidationIncentiveMantissa uint _newLiquidationIncentiveMantissa
      * @return SUCCESS
      */
    function _setLiquidationIncentive(uint _newLiquidationIncentiveMantissa) external returns (uint) {
        require(msg.sender == admin, "SET_LIQUIDATION_INCENTIVE_OWNER_CHECK");

        Exp memory newLiquidationIncentive = Exp({mantissa: _newLiquidationIncentiveMantissa});
        Exp memory minLiquidationIncentive = Exp({mantissa: liquidationIncentiveMinMantissa});
        if (lessThanExp(newLiquidationIncentive, minLiquidationIncentive)) {
            return fail(Error.ERROR, ErrorRemarks.SET_LIQUIDATION_INCENTIVE_VALIDATION, uint(Error.ERROR));
        }

        Exp memory maxLiquidationIncentive = Exp({mantissa: liquidationIncentiveMaxMantissa});
        if (lessThanExp(maxLiquidationIncentive, newLiquidationIncentive)) {
            return fail(Error.ERROR, ErrorRemarks.SET_LIQUIDATION_INCENTIVE_VALIDATION, uint(Error.ERROR));
        }
        uint oldLiquidationIncentiveMantissa = liquidationIncentiveMantissa;
        liquidationIncentiveMantissa = _newLiquidationIncentiveMantissa; // push storage

        emit NewLiquidationIncentive(oldLiquidationIncentiveMantissa, _newLiquidationIncentiveMantissa);
        return uint(Error.SUCCESS);
    }

    /**
      * @notice Add the market to the markets mapping and set it as listed
      * @param _aToken AToken address
      * @return SUCCESS
      */
    function _supportMarket(AToken _aToken) external returns (uint) {
        require(msg.sender == admin, "change not authorized");
        if (markets[address(_aToken)].isListed) {
            return fail(Error.ERROR, ErrorRemarks.SUPPORT_MARKET_EXISTS, uint(Error.ERROR));
        }
        _aToken.aToken();
        markets[address(_aToken)] = Market({isListed: true, collateralFactorMantissa: 0});
        _addMarketInternal(address(_aToken));
        emit MarketListed(_aToken);
        return uint(Error.SUCCESS);
    }
    function _addMarketInternal(address _aToken) internal {
        for (uint i = 0; i < allMarkets.length; i ++) {
            require(allMarkets[i] != AToken(_aToken), "AegisComptroller::_addMarketInternal failure");
        }
        allMarkets.push(AToken(_aToken));
    }

    /**
     * @notice Admin function to change the Pause Guardian
     * @param _newPauseGuardian uint
     * @return SUCCESS
     */
    function _setPauseGuardian(address _newPauseGuardian) public returns (uint) {
        require(msg.sender == admin, "change not authorized");
        address oldPauseGuardian = pauseGuardian;
        pauseGuardian = _newPauseGuardian;
        emit NewPauseGuardian(oldPauseGuardian, pauseGuardian);
        return uint(Error.SUCCESS);
    }

    function _setMintPaused(AToken _aToken, bool _state) public returns (bool) {
        require(markets[address(_aToken)].isListed, "cannot pause a market that is not listed");
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || _state == true, "only admin can unpause");

        mintGuardianPaused[address(_aToken)] = _state;
        emit ActionPaused(_aToken, "Mint", _state);
        return _state;
    }

    function _setBorrowPaused(AToken _aToken, bool _state) public returns (bool) {
        require(markets[address(_aToken)].isListed, "cannot pause a market that is not listed");
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || _state == true, "only admin can unpause");

        borrowGuardianPaused[address(_aToken)] = _state;
        emit ActionPaused(_aToken, "Borrow", _state);
        return _state;
    }

    function _setTransferPaused(bool _state) public returns (bool) {
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || _state == true, "only admin can unpause");

        transferGuardianPaused = _state;
        emit ActionPaused("Transfer", _state);
        return _state;
    }

    function _setSeizePaused(bool _state) public returns (bool) {
        require(msg.sender == pauseGuardian || msg.sender == admin, "only pause guardian and admin can pause");
        require(msg.sender == admin || _state == true, "only admin can unpause");

        seizeGuardianPaused = _state;
        emit ActionPaused("Seize", _state);
        return _state;
    }

    function _become(Unitroller _unitroller) public {
        require(msg.sender == _unitroller.admin(), "only unitroller admin can change brains");
        require(_unitroller._acceptImplementation() == 0, "change not authorized");
    }

    /**
     * @notice Checks caller is admin, or this contract is becoming the new implementation
     * @return bool
     */
    function adminOrInitializing() internal view returns (bool) {
        return msg.sender == admin || msg.sender == comptrollerImplementation;
    }

    event NewMintGuardianPaused(bool _oldState, bool _newState);
    function _setMintGuardianPaused(bool _state) public returns (bool) {
        require(msg.sender == admin, "change not authorized");
        bool _oldState = _mintGuardianPaused;
        _mintGuardianPaused = _state;
        emit NewMintGuardianPaused(_oldState, _state);
        return _state;
    }

    event NewBorrowGuardianPaused(bool _oldState, bool _newState);
    function _setBorrowGuardianPaused(bool _state) public returns (bool) {
        require(msg.sender == admin, "change not authorized");
        bool _oldState = _borrowGuardianPaused;
        _borrowGuardianPaused = _state;
        emit NewBorrowGuardianPaused(_oldState, _state);
        return _state;
    }

    event NewClearanceMantissa(uint _oldClearanceMantissa, uint _newClearanceMantissa);
    function _setClearanceMantissa(uint _newClearanceMantissa) public returns (uint) {
        require(msg.sender == admin, "AegisComptroller::_setClearanceMantissa change not authorized");
        uint _old = clearanceMantissa;
        clearanceMantissa = _newClearanceMantissa;
        emit NewClearanceMantissa(_old, _newClearanceMantissa);
        return uint(Error.SUCCESS);
    }

    event NewMinimumLoanAmount(uint _oldMinimumLoanAmount, uint _newMinimumLoanAmount);
    function _setminimumLoanAmount(uint _newMinimumLoanAmount) public returns (uint) {
        require(msg.sender == admin, "AegisComptroller::_setClearanceMantissa change not authorized");
        uint _old = minimumLoanAmount;
        minimumLoanAmount = _newMinimumLoanAmount;
        emit NewMinimumLoanAmount(_old, _newMinimumLoanAmount);
        return uint(Error.SUCCESS);
    }

    struct AccountLiquidityLocalVars {
        uint sumCollateral;
        uint sumBorrowPlusEffects;
        uint aTokenBalance;
        uint borrowBalance;
        uint exchangeRateMantissa;
        uint oraclePriceMantissa;
        Exp collateralFactor;
        Exp exchangeRate;
        Exp oraclePrice;
        Exp tokensToDenom;
    }

    event MarketListed(AToken _aToken);
    event MarketEntered(AToken _aToken, address _account);
    event MarketExited(AToken _aToken, address _account);
    event NewCloseFactor(uint _oldCloseFactorMantissa, uint _newCloseFactorMantissa);
    event NewCollateralFactor(AToken _aToken, uint _oldCollateralFactorMantissa, uint _newCollateralFactorMantissa);
    event NewLiquidationIncentive(uint _oldLiquidationIncentiveMantissa, uint _newLiquidationIncentiveMantissa);
    event NewMaxAssets(uint _oldMaxAssets, uint _newMaxAssets);
    event NewPriceOracle(PriceOracle _oldPriceOracle, PriceOracle _newPriceOracle);
    event NewPauseGuardian(address _oldPauseGuardian, address _newPauseGuardian);
    event ActionPaused(string _action, bool _pauseState);
    event ActionPaused(AToken _aToken, string _action, bool _pauseState);
    event NewCompRate(uint _oldCompRate, uint _newCompRate);
    event CompSpeedUpdated(AToken indexed _aToken, uint _newSpeed);
    event DistributedSupplierComp(AToken indexed _aToken, address indexed _supplier, uint _compDelta, uint _compSupplyIndex);
    event DistributedBorrowerComp(AToken indexed _aToken, address indexed _borrower, uint _compDelta, uint _compBorrowIndex);
}
