// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


interface ICurvePairs {
    function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external;
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount) external;
    function balances(uint256 i) external view returns (uint256);
}

interface IGauge {
    function balanceOf(address _address) external view returns (uint256);
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function getReward() external; // For Pickle Farm only
}

interface IMintr {
    function mint(address _address) external;
}

interface IRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}

interface IPickleJar is IERC20 {
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function balance() external view returns (uint256);
}

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function userInfo(uint256, address) external view returns(uint256, uint256);
}

interface IWETH is IERC20 {
    function withdraw(uint256 _amount) external;
}

interface ICitadelVault {
    function getReimburseTokenAmount(uint256) external view returns (uint256);
}

interface IChainlink {
    function latestAnswer() external view returns (int256);
}

interface ISLPToken is IERC20 {
    function getReserves() external view returns (uint112, uint112, uint32);
}

contract CitadelStrategy is Ownable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH;
    using SafeERC20 for IPickleJar;
    using SafeERC20 for ISLPToken;
    using SafeMath for uint256;

    IERC20 private constant WBTC = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    IWETH private constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 private constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 private constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 private constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IRouter private constant router = IRouter(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F); // SushiSwap
    ICitadelVault public vault;

    // Curve
    ICurvePairs private constant cPairs = ICurvePairs(0x4CA9b3063Ec5866A4B82E437059D2C43d1be596F); // HBTC/WBTC
    IERC20 private constant clpToken = IERC20(0xb19059ebb43466C323583928285a49f558E572Fd);
    IERC20 private constant CRV = IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    IGauge private constant gaugeC = IGauge(0x4c18E409Dc8619bFb6a1cB56D114C3f592E0aE79);
    IMintr private constant mintr = IMintr(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);

    // Pickle
    ISLPToken private constant slpWBTC = ISLPToken(0xCEfF51756c56CeFFCA006cD410B03FFC46dd3a58); // WBTC/ETH
    ISLPToken private constant slpDAI = ISLPToken(0xC3D03e4F041Fd4cD388c549Ee2A29a9E5075882f); // DAI/ETH
    IERC20 private constant PICKLE = IERC20(0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5);
    IPickleJar private constant pickleJarWBTC = IPickleJar(0xde74b6c547bd574c3527316a2eE30cd8F6041525);
    IPickleJar private constant pickleJarDAI = IPickleJar(0x55282dA27a3a02ffe599f6D11314D239dAC89135);
    IGauge private constant gaugeP_WBTC = IGauge(0xD55331E7bCE14709d825557E5Bca75C73ad89bFb);
    IGauge private constant gaugeP_DAI = IGauge(0x6092c7084821057060ce2030F9CC11B22605955F);

    // Sushiswap Onsen
    IERC20 private constant DPI = IERC20(0x1494CA1F11D487c2bBe4543E90080AeBa4BA3C2b);
    ISLPToken private constant slpDPI = ISLPToken(0x34b13F8CD184F55d0Bd4Dd1fe6C07D46f245c7eD); // DPI/ETH
    IERC20 private constant SUSHI = IERC20(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);
    IMasterChef private constant masterChef = IMasterChef(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);

    // LP token price in ETH
    uint256 private _HBTCWBTCLPTokenPrice;
    uint256 private _WBTCETHLPTokenPrice;
    uint256 private _DPIETHLPTokenPrice;
    uint256 private _DAIETHLPTokenPrice;

    // Pool in ETH
    uint256 private _poolHBTCWBTC;
    uint256 private _poolWBTCETH;
    uint256 private _poolDPIETH;
    uint256 private _poolDAIETH;
    uint256 private _pool; // For emergencyWithdraw() only

    // Others
    uint256 private constant DENOMINATOR = 10000;
    bool public isVesting;

    // Fees
    uint256 public yieldFeePerc = 1000;
    address public admin;
    address public communityWallet;
    address public strategist;

    event ETHToInvest(uint256 amount);
    event LatestLPTokenPrice(uint256 curveHBTC, uint256 pickleWBTC, uint256 sushiSwapDPI, uint256 pickleDAI);
    event YieldAmount(uint256 curveHBTC, uint256 pickleWBTC, uint256 sushiSwapDPI, uint256 pickleDAI); // in ETH
    event CurrentComposition(uint256 curveHBTC, uint256 pickleWBTC, uint256 sushiSwapDPI, uint256 pickleDAI); // in ETH
    event TargetComposition(uint256 curveHBTC, uint256 pickleWBTC, uint256 sushiSwapDPI, uint256 pickleDAI); // in ETH
    event AddLiquidity(address pairs, uint256 amountA, uint256 amountB, uint256 lpTokenMinted); // in ETH

    modifier onlyVault {
        require(msg.sender == address(vault), "Only vault");
        _;
    }

    constructor(address _communityWallet, address _strategist, address _admin) {
        communityWallet = _communityWallet;
        strategist = _strategist;
        admin = _admin;

        // Sushiswap router
        WETH.safeApprove(address(router), type(uint256).max);
        WBTC.safeApprove(address(router), type(uint256).max);
        DAI.safeApprove(address(router), type(uint256).max);
        slpWBTC.safeApprove(address(router), type(uint256).max);
        slpDAI.safeApprove(address(router), type(uint256).max);
        slpDPI.safeApprove(address(router), type(uint256).max);
        CRV.safeApprove(address(router), type(uint256).max);
        PICKLE.safeApprove(address(router), type(uint256).max);
        SUSHI.safeApprove(address(router), type(uint256).max);
        // Curve
        WBTC.safeApprove(address(cPairs), type(uint256).max);
        clpToken.safeApprove(address(gaugeC), type(uint256).max);
        // Pickle
        slpWBTC.safeApprove(address(pickleJarWBTC), type(uint256).max);
        slpDAI.safeApprove(address(pickleJarDAI), type(uint256).max);
        pickleJarWBTC.safeApprove(address(gaugeP_WBTC), type(uint256).max);
        pickleJarDAI.safeApprove(address(gaugeP_DAI), type(uint256).max);
        // Sushiswap Onsen
        DPI.safeApprove(address(router), type(uint256).max);
        slpDPI.safeApprove(address(masterChef), type(uint256).max);

        // Set first LP tokens price
        (uint256 _clpTokenPriceHBTC, uint256 _pSlpTokenPriceWBTC, uint256 _slpTokenPriceDPI, uint256 _pSlpTokenPriceDAI) = _getLPTokenPrice();
        _HBTCWBTCLPTokenPrice = _clpTokenPriceHBTC;
        _WBTCETHLPTokenPrice = _pSlpTokenPriceWBTC;
        _DPIETHLPTokenPrice = _slpTokenPriceDPI;
        _DAIETHLPTokenPrice = _pSlpTokenPriceDAI;
    }

    /// @notice Function to set vault address that interact with this contract. This function only execute once when deployment
    /// @param _address Address of vault contract 
    function setVault(address _address) external onlyOwner {
        require(address(vault) == address(0), "Vault set");

        vault = ICitadelVault(_address);
    }

    /// @notice Function to invest new funds to farms based on composition
    /// @param _amount Amount to invest in ETH
    function invest(uint256 _amount) external onlyVault {
        _updatePoolForPriceChange();

        WETH.safeTransferFrom(address(vault), address(this), _amount);
        emit ETHToInvest(_amount);
        _updatePoolForProvideLiquidity();
    }

    /// @notice Function to update pool balance because of price change of corresponding LP token 
    function _updatePoolForPriceChange() private {
        (uint256 _clpTokenPriceHBTC, uint256 _pSlpTokenPriceWBTC, uint256 _slpTokenPriceDPI, uint256 _pSlpTokenPriceDAI) = _getLPTokenPrice();
        _poolHBTCWBTC = _poolHBTCWBTC.mul(_clpTokenPriceHBTC).div(_HBTCWBTCLPTokenPrice);
        _poolWBTCETH = _poolWBTCETH.mul(_pSlpTokenPriceWBTC).div(_WBTCETHLPTokenPrice);
        _poolDPIETH = _poolDPIETH.mul(_slpTokenPriceDPI).div(_DPIETHLPTokenPrice);
        _poolDAIETH = _poolDAIETH.mul(_pSlpTokenPriceDAI).div(_DAIETHLPTokenPrice);
        emit CurrentComposition(_poolHBTCWBTC, _poolWBTCETH, _poolDPIETH, _poolDAIETH);
        // Update new LP token price
        _HBTCWBTCLPTokenPrice = _clpTokenPriceHBTC;
        _WBTCETHLPTokenPrice = _pSlpTokenPriceWBTC;
        _DPIETHLPTokenPrice = _slpTokenPriceDPI;
        _DAIETHLPTokenPrice = _pSlpTokenPriceDAI;
        emit LatestLPTokenPrice(_HBTCWBTCLPTokenPrice, _WBTCETHLPTokenPrice, _DPIETHLPTokenPrice, _DAIETHLPTokenPrice);
    }

    /// @notice Function to harvest rewards from farms and reinvest into farms based on composition
    function yield() external onlyVault {
        _updatePoolForPriceChange();

        uint256[] memory _yieldAmts = new uint256[](4); // For emit yield amount of each farm
        // 1) Claim all rewards
        uint256 _yieldFees;
        // Curve HBTC/WBTC
        mintr.mint(address(gaugeC)); // Claim CRV
        uint256 _balanceOfCRV = CRV.balanceOf(address(this));
        if (_balanceOfCRV > 0) {
            uint256[] memory _amounts = _swapExactTokensForTokens(address(CRV), address(WETH), _balanceOfCRV);
            _yieldAmts[0] = _amounts[1];
            uint256 _fee = _amounts[1].mul(yieldFeePerc).div(DENOMINATOR);
            _poolHBTCWBTC = _poolHBTCWBTC.add(_amounts[1].sub(_fee));
            _yieldFees = _yieldFees.add(_fee);
        }
        // Pickle WBTC/ETH
        gaugeP_WBTC.getReward(); // Claim PICKLE
        uint256 _balanceOfPICKLEForWETH = PICKLE.balanceOf(address(this));
        if (_balanceOfPICKLEForWETH > 0) {
            uint256[] memory _amounts = _swapExactTokensForTokens(address(PICKLE), address(WETH), _balanceOfPICKLEForWETH);
            _yieldAmts[1] = _amounts[1];
            uint256 _fee = _amounts[1].mul(yieldFeePerc).div(DENOMINATOR);
            _poolWBTCETH = _poolWBTCETH.add(_amounts[1].sub(_fee));
            _yieldFees = _yieldFees.add(_fee);
        }
        // Sushiswap DPI/ETH
        (uint256 _slpDPIAmt,) = masterChef.userInfo(42, address(this));
        if (_slpDPIAmt > 0) {
            // SushiSwap previous SUSHI reward is auto harvest after new deposit
            // Swap SUSHI to WETH
            uint256 _balanceOfSUSHI = SUSHI.balanceOf(address(this));
            if (_balanceOfSUSHI > 0) {
                uint256[] memory _amounts = _swapExactTokensForTokens(address(SUSHI), address(WETH), _balanceOfSUSHI);
                uint256 _fee = _amounts[1].mul(yieldFeePerc).div(DENOMINATOR);
                _yieldAmts[2] = _amounts[1];
                _poolDPIETH = _poolDPIETH.add(_amounts[1].sub(_fee));
                _yieldFees = _yieldFees.add(_fee);
            }
        }
        // Pickle DAI/ETH
        gaugeP_DAI.getReward(); // Claim PICKLE
        uint256 _balanceOfPICKLEForDAI = PICKLE.balanceOf(address(this));
        if (_balanceOfPICKLEForDAI > 0) {
            uint256[] memory _amounts = _swapExactTokensForTokens(address(PICKLE), address(WETH), _balanceOfPICKLEForDAI);
            _yieldAmts[3] = _amounts[1];
            uint256 _fee = _amounts[1].mul(yieldFeePerc).div(DENOMINATOR);
            _poolDAIETH = _poolDAIETH.add(_amounts[1].sub(_fee));
            _yieldFees = _yieldFees.add(_fee);
        }
        emit YieldAmount(_yieldAmts[0], _yieldAmts[1], _yieldAmts[2], _yieldAmts[3]);

        // 2) Split yield fees
        _splitYieldFees(_yieldFees);

        // 3) Reinvest rewards
        _updatePoolForProvideLiquidity();
    }

    /// @notice Function to transfer fees that collect from yield to wallets
    /// @param _amount Fees to transfer in ETH
    function _splitYieldFees(uint256 _amount) private {
        WETH.withdraw(_amount);
        uint256 _yieldFee = (address(this).balance).mul(2).div(5);
        (bool _a,) = admin.call{value: _yieldFee}(""); // 40%
        require(_a);
        (bool _t,) = communityWallet.call{value: _yieldFee}(""); // 40%
        require(_t);
        (bool _s,) = strategist.call{value: (address(this).balance)}(""); // 20%
        require(_s);
    }

    // To enable receive ETH from WETH in _splitYieldFees()
    receive() external payable {}

    /// @notice Function to provide liquidity into farms and update pool of each farms
    function _updatePoolForProvideLiquidity() private {
        uint256 _totalPool = _getTotalPool().add(WETH.balanceOf(address(this)));
        // Calculate target composition for each farm
        uint256 _thirtyPercOfPool = _totalPool.mul(3000).div(DENOMINATOR);
        uint256 _poolHBTCWBTCTarget = _thirtyPercOfPool; // 30% for Curve HBTC/WBTC
        uint256 _poolWBTCETHTarget = _thirtyPercOfPool; // 30% for Pickle WBTC/ETH
        uint256 _poolDPIETHTarget = _thirtyPercOfPool; // 30% for SushiSwap DPI/ETH
        uint256 _poolDAIETHTarget = _totalPool.sub(_thirtyPercOfPool).sub(_thirtyPercOfPool).sub(_thirtyPercOfPool); // 10% for Pickle DAI/ETH
        emit CurrentComposition(_poolHBTCWBTC, _poolWBTCETH, _poolDPIETH, _poolDAIETH);
        emit TargetComposition(_poolHBTCWBTCTarget, _poolWBTCETHTarget, _poolDPIETHTarget, _poolDAIETHTarget);
        // If there is no negative value(need to remove liquidity from farm in order to drive back the composition)
        // We proceed with split funds into 4 farms and drive composition back to target
        // Else, we put all the funds into the farm that is furthest from target composition
        if (
            _poolHBTCWBTCTarget > _poolHBTCWBTC &&
            _poolWBTCETHTarget > _poolWBTCETH &&
            _poolDPIETHTarget > _poolDPIETH &&
            _poolDAIETHTarget > _poolDAIETH
        ) {
            // invest funds into Curve HBTC/WBTC
            uint256 _investHBTCWBTCAmt = _poolHBTCWBTCTarget.sub(_poolHBTCWBTC);
            _investHBTCWBTC(_investHBTCWBTCAmt);
            // invest funds into Pickle WBTC/ETH
            uint256 _investWBTCETHAmt = _poolWBTCETHTarget.sub(_poolWBTCETH);
            _investWBTCETH(_investWBTCETHAmt);
            // invest funds into Sushiswap Onsen DPI/ETH
            uint256 _investDPIETHAmt = _poolDPIETHTarget.sub(_poolDPIETH);
            _investDPIETH(_investDPIETHAmt);
            // invest funds into Pickle DAI/ETH
            uint256 _investDAIETHAmt = _poolDAIETHTarget.sub(_poolDAIETH);
            _investDAIETH(_investDAIETHAmt);
        } else {
            // Put all the yield into the farm that is furthest from target composition
            uint256 _furthest;
            uint256 _farmIndex;
            // 1. Find out the farm that is furthest from target composition
            if (_poolHBTCWBTCTarget > _poolHBTCWBTC) {
                uint256 _diff = _poolHBTCWBTCTarget.sub(_poolHBTCWBTC);
                _furthest = _diff;
                _farmIndex = 0;
            }
            if (_poolWBTCETHTarget > _poolWBTCETH) {
                uint256 _diff = _poolWBTCETHTarget.sub(_poolWBTCETH);
                if (_diff > _furthest) {
                    _furthest = _diff;
                    _farmIndex = 1;
                }
            }
            if (_poolDPIETHTarget > _poolDPIETH) {
                uint256 _diff = _poolDPIETHTarget.sub(_poolDPIETH);
                if (_diff > _furthest) {
                    _furthest = _diff;
                    _farmIndex = 2;
                }
            }
            if (_poolDAIETHTarget > _poolDAIETH) {
                uint256 _diff = _poolDAIETHTarget.sub(_poolDAIETH);
                if (_diff > _furthest) {
                    _furthest = _diff;
                    _farmIndex = 3;
                }
            }
            // 2. Put all the funds into the farm that is furthest from target composition
            uint256 _balanceOfWETH = WETH.balanceOf(address(this));
            if (_farmIndex == 0) {
                _investHBTCWBTC(_balanceOfWETH);
            } else if (_farmIndex == 1) {
                _investWBTCETH(_balanceOfWETH);
            } else if (_farmIndex == 2) {
                _investDPIETH(_balanceOfWETH);
            } else {
                _investDAIETH(_balanceOfWETH);
            }
        }
        emit CurrentComposition(_poolHBTCWBTC, _poolWBTCETH, _poolDPIETH, _poolDAIETH);
    }

    /// @notice Function to invest funds into Curve HBTC/WBTC pool 
    /// @notice and stake Curve LP token into Curve Gauge(staking contract)
    /// @param _amount Amount to invest in ETH
    function _investHBTCWBTC(uint256 _amount) private {
        uint256[] memory _amounts = _swapExactTokensForTokens(address(WETH), address(WBTC), _amount);
        if (_amounts[1] > 0) {
            cPairs.add_liquidity([0, _amounts[1]], 0);
            uint256 _balanceOfClpToken = clpToken.balanceOf(address(this));
            gaugeC.deposit(_balanceOfClpToken);
            _poolHBTCWBTC = _poolHBTCWBTC.add(_amount);
            emit AddLiquidity(address(cPairs), _amounts[1], 0, _balanceOfClpToken);
        }
    }

    /// @notice Function to invest funds into SushiSwap WBTC/ETH pool, deposit SLP token into Pickle Jar(vault contract)
    /// @notice and stake Pickle LP token into Pickle Farm(staking contract)
    /// @param _amount Amount to invest in ETH
    function _investWBTCETH(uint256 _amount) private {
        uint256 _amountIn = _amount.div(2);
        uint256[] memory _amounts = _swapExactTokensForTokens(address(WETH), address(WBTC), _amountIn);
        if (_amounts[1] > 0) {
            (uint256 _amountA, uint256 _amountB, uint256 _slpWBTC) = router.addLiquidity(
                address(WBTC), address(WETH), 
                _amounts[1], _amountIn,
                0, 0,
                address(this), block.timestamp
            );
            emit AddLiquidity(address(slpWBTC), _amountA, _amountB, _slpWBTC);
            pickleJarWBTC.deposit(_slpWBTC);
            gaugeP_WBTC.deposit(pickleJarWBTC.balanceOf(address(this)));
            _poolWBTCETH = _poolWBTCETH.add(_amount);
        }
    }

    /// @notice Function to invest funds into SushiSwap DPI/ETH pool 
    /// @notice and stake SLP token into SushiSwap MasterChef(staking contract)
    /// @param _amount Amount to invest in ETH
    function _investDPIETH(uint256 _amount) private {
        uint256 _amountIn = _amount.div(2);
        uint256[] memory _amounts = _swapExactTokensForTokens(address(WETH), address(DPI), _amountIn);
        if (_amounts[1] > 0) {
            (uint256 _amountA, uint256 _amountB, uint256 _slpDPI) = router.addLiquidity(address(DPI), address(WETH), _amounts[1], _amountIn, 0, 0, address(this), block.timestamp);
            masterChef.deposit(42, _slpDPI);
            _poolDPIETH = _poolDPIETH.add(_amount);
            emit AddLiquidity(address(slpDPI), _amountA, _amountB, _slpDPI);
        }
    }

    /// @notice Function to invest funds into SushiSwap DAI/ETH pool, deposit SLP token into Pickle Jar(vault contract)
    /// @notice and stake Pickle LP token into Pickle Farm(staking contract)
    /// @param _amount Amount to invest in ETH
    function _investDAIETH(uint256 _amount) private {
        uint256 _amountIn = _amount.div(2);
        uint256[] memory _amounts = _swapExactTokensForTokens(address(WETH), address(DAI), _amountIn);
        if (_amounts[1] > 0) {
            (uint256 _amountA, uint256 _amountB, uint256 _slpDAI) = router.addLiquidity(
                address(DAI), address(WETH), 
                _amounts[1], _amountIn,
                0, 0,
                address(this), block.timestamp
            );
            emit AddLiquidity(address(slpDAI), _amountA, _amountB, _slpDAI); // 1389.083912192186144530 0.335765206816332767 17.202418926243352766
            pickleJarDAI.deposit(_slpDAI);
            gaugeP_DAI.deposit(pickleJarDAI.balanceOf(address(this)));
            _poolDAIETH = _poolDAIETH.add(_amount);
        }
    }

    // @notice Function to reimburse vault minimum keep amount by removing liquidity from all farms
    function reimburse() external onlyVault {
        // Get total reimburse amount (6 decimals)
        uint256 _reimburseUSDT = vault.getReimburseTokenAmount(0);
        uint256 _reimburseUSDC = vault.getReimburseTokenAmount(1);
        uint256 _reimburseDAI = vault.getReimburseTokenAmount(2);
        uint256 _totalReimburse = _reimburseUSDT.add(_reimburseUSDC).add(_reimburseDAI.div(1e12));

        // Get ETH needed from farm (by removing liquidity then swap to ETH)
        uint256[] memory _amounts = router.getAmountsOut(_totalReimburse, _getPath(address(USDT), address(WETH)));
        if (WETH.balanceOf(address(this)) < _amounts[1]) { // Balance of WETH > _amounts[1] when execute emergencyWithdraw()
            _updatePoolForPriceChange();
            uint256 _thirtyPercOfAmtWithdraw = _amounts[1].mul(3000).div(DENOMINATOR);
            _withdrawCurve(_thirtyPercOfAmtWithdraw); // 30% from Curve HBTC/WBTC
            _withdrawPickleWBTC(_thirtyPercOfAmtWithdraw); // 30% from Pickle WBTC/ETH
            _withdrawSushiswap(_thirtyPercOfAmtWithdraw); // 30% from SushiSwap DPI/ETH
            _withdrawPickleDAI(_amounts[1].sub(_thirtyPercOfAmtWithdraw).sub(_thirtyPercOfAmtWithdraw).sub(_thirtyPercOfAmtWithdraw)); // 10% from Pickle DAI/ETH
            _swapAllToETH(); // Swap WBTC, DPI & DAI that get from withdrawal above to WETH
        }

        // Swap WETH to token and transfer back to vault
        uint256 _WETHBalance = WETH.balanceOf(address(this));
        _reimburse(_WETHBalance.mul(_reimburseUSDT).div(_totalReimburse), USDT);
        _reimburse(_WETHBalance.mul(_reimburseUSDC).div(_totalReimburse), USDC);
        _reimburse((WETH.balanceOf(address(this))), DAI);
    }

    /// @notice reimburse() nested function
    /// @param _reimburseAmt Amount to reimburse in ETH
    /// @param _token Type of token to reimburse
    function _reimburse(uint256 _reimburseAmt, IERC20 _token) private {
        if (_reimburseAmt > 0) {
            uint256[] memory _amounts = _swapExactTokensForTokens(address(WETH), address(_token), _reimburseAmt);
            _token.safeTransfer(address(vault), _amounts[1]);
        }
    }

    /// @notice Function to withdraw all funds from all farms 
    function emergencyWithdraw() external onlyVault {
        // 1. Withdraw all token from all farms
        // Since to withdraw all funds, there is no need to _updatePoolForPriceChange()
        // Curve HBTC/WBTC
        mintr.mint(address(gaugeC));
        _withdrawCurve(_poolHBTCWBTC);
        // Pickle WBTC/ETH
        gaugeP_WBTC.getReward();
        _withdrawPickleWBTC(_poolWBTCETH);
        // Sushiswap DPI/ETH
        _withdrawSushiswap(_poolDPIETH);
        // Pickle DAI/ETH
        gaugeP_WBTC.getReward();
        _withdrawPickleDAI(_poolDAIETH);

        // 2.1 Swap all rewards to WETH
        uint256 balanceOfWETHBefore = WETH.balanceOf(address(this));
        _swapExactTokensForTokens(address(CRV), address(WETH), CRV.balanceOf(address(this)));
        _swapExactTokensForTokens(address(PICKLE), address(WETH), PICKLE.balanceOf(address(this)));
        _swapExactTokensForTokens(address(SUSHI), address(WETH), SUSHI.balanceOf(address(this)));
        // Send portion rewards to admin
        uint256 _rewards = (WETH.balanceOf(address(this))).sub(balanceOfWETHBefore);
        uint256 _adminFees = _rewards.mul(yieldFeePerc).div(DENOMINATOR);
        _splitYieldFees(_adminFees);

        // 2.2 Swap WBTC, DPI & DAI to WETH
        _swapAllToETH();
        _pool = WETH.balanceOf(address(this));
        isVesting = true;
    }

    /// @notice Function to invest back WETH into farms after emergencyWithdraw()
    function reinvest() external onlyVault {
        _pool = 0;
        isVesting = false;
        _updatePoolForProvideLiquidity();
    }

    /// @notice Function to swap tokens with SushiSwap
    /// @param _tokenA Token to be swapped
    /// @param _tokenB Token to be received
    /// @param _amountIn Amount of token to be swapped
    /// @return _amounts Array that contains swapped amounts
    function _swapExactTokensForTokens(address _tokenA, address _tokenB, uint256 _amountIn) private returns (uint256[] memory _amounts) {
        address[] memory _path = _getPath(_tokenA, _tokenB);
        uint256[] memory _amountsOut = router.getAmountsOut(_amountIn, _path);
        if (_amountsOut[1] > 0) {
            _amounts = router.swapExactTokensForTokens(_amountIn, 0, _path, address(this), block.timestamp);
        } else {
            // Not enough amount to swap
            uint256[] memory _zeroReturn = new uint256[](2);
            _zeroReturn[0] = 0;
            _zeroReturn[1] = 0;
            return _zeroReturn;
        }
    }

    /// @notice Function to withdraw funds from farms if withdraw amount > amount keep in vault
    /// @param _amount Amount to withdraw in ETH
    function withdraw(uint256 _amount) external onlyVault {
        if (!isVesting) {
            // Update to latest pool
            _updatePoolForPriceChange();
            uint256 _totalPool = _getTotalPool();
            // _WETHAmtBefore: Need this because there will be leftover after provide liquidity to farms
            uint256 _WETHAmtBefore = WETH.balanceOf(address(this));

            // Withdraw from Curve HBTC/WBTC
            _withdrawCurve(_poolHBTCWBTC.mul(_amount).div(_totalPool));
            // Withdraw from Pickle WBTC/ETH
            _withdrawPickleWBTC(_poolWBTCETH.mul(_amount).div(_totalPool));
            // Withdraw from Sushiswap DPI/ETH
            _withdrawSushiswap(_poolDPIETH.mul(_amount).div(_totalPool));
            // Withdraw from Pickle DAI/ETH
            _withdrawPickleDAI(_poolDAIETH.mul(_amount).div(_totalPool));

            _swapAllToETH(); // Swap WBTC, DPI & DAI that get from withdrawal above to WETH
            WETH.safeTransfer(msg.sender, (WETH.balanceOf(address(this))).sub(_WETHAmtBefore));
        } else {
            _pool = _pool.sub(_amount);
            WETH.safeTransfer(msg.sender, _amount);
        }
    }

    /// @notice Function to unstake LP token(gaugeC) and remove liquidity(cPairs) from Curve
    /// @param _amount Amount to withdraw in ETH
    function _withdrawCurve(uint256 _amount) private {
        uint256 _totalClpToken = gaugeC.balanceOf(address(this));
        uint256 _clpTokenShare = _totalClpToken.mul(_amount).div(_poolHBTCWBTC);
        gaugeC.withdraw(_clpTokenShare);
        cPairs.remove_liquidity_one_coin(_clpTokenShare, 1, 0);
        _poolHBTCWBTC = _poolHBTCWBTC.sub(_amount);
    }

    /// @notice Function to unstake LP token from Pickle Farm(gaugeP_WBTC),
    /// @notice withdraw from Pickle Jar(pickleJarWBTC),
    /// @notice and remove liquidity(router) from SushiSwap
    /// @param _amount Amount to withdraw in ETH
    function _withdrawPickleWBTC(uint256 _amount) private {
        uint256 _totalPlpToken = gaugeP_WBTC.balanceOf(address(this));
        uint256 _plpTokenShare = _totalPlpToken.mul(_amount).div(_poolWBTCETH);
        gaugeP_WBTC.withdraw(_plpTokenShare);
        pickleJarWBTC.withdraw(_plpTokenShare);
        router.removeLiquidity(address(WBTC), address(WETH), slpWBTC.balanceOf(address(this)), 0, 0, address(this), block.timestamp);
        _poolWBTCETH = _poolWBTCETH.sub(_amount);
    }

    /// @notice Function to unstake LP token(masterChef) and remove liquidity(router) from SushiSwap
    /// @param _amount Amount to withdraw in ETH
    function _withdrawSushiswap(uint256 _amount) private {
        (uint256 _totalSlpToken,) = masterChef.userInfo(42, address(this));
        uint256 _slpTokenShare = _totalSlpToken.mul(_amount).div(_poolDPIETH);
        masterChef.withdraw(42, _slpTokenShare);
        router.removeLiquidity(address(DPI), address(WETH), _slpTokenShare, 0, 0, address(this), block.timestamp);
        _poolDPIETH = _poolDPIETH.sub(_amount);
    }

    /// @notice Function to unstake LP token from Pickle Farm(gaugeP_DAI),
    /// @notice withdraw from Pickle Jar(pickleJarDAI),
    /// @notice and remove liquidity(router) from SushiSwap
    /// @param _amount Amount to withdraw in ETH
    function _withdrawPickleDAI(uint256 _amount) private {
        uint256 _totalPlpToken = gaugeP_DAI.balanceOf(address(this));
        uint256 _plpTokenShare = _totalPlpToken.mul(_amount).div(_poolDAIETH);
        gaugeP_DAI.withdraw(_plpTokenShare);
        pickleJarDAI.withdraw(_plpTokenShare);
        router.removeLiquidity(address(DAI), address(WETH), slpDAI.balanceOf(address(this)), 0, 0, address(this), block.timestamp);
        _poolDAIETH = _poolDAIETH.sub(_amount);
    }

    /// @notice Function to swap tokens that receive by removing liquidity for all farms
    function _swapAllToETH() private {
        _swapExactTokensForTokens(address(WBTC), address(WETH), WBTC.balanceOf(address(this)));
        _swapExactTokensForTokens(address(DPI), address(WETH), DPI.balanceOf(address(this)));
        _swapExactTokensForTokens(address(DAI), address(WETH), DAI.balanceOf(address(this)));
    }

    /// @notice Function to set new admin address from vault contract
    /// @param _admin Address of new admin
    function setAdmin(address _admin) external onlyVault {
        admin = _admin;
    }

    /// @notice Function to set new strategist address from vault contract
    /// @param _strategist Address of new strategist
    function setStrategist(address _strategist) external onlyVault {
        strategist = _strategist;
    }

    /// @notice Function to approve vault to migrate funds from this contract to new strategy contract
    function approveMigrate() external onlyOwner {
        require(isVesting, "Not in vesting state");

        if (WETH.allowance(address(this), address(vault)) == 0) {
            WETH.safeApprove(address(vault), type(uint256).max);
        }
    }

    /// @notice Function to get path for SushiSwap swap functions
    /// @param _tokenA Token to be swapped
    /// @param _tokenB Token to be received
    /// @return _path Array of address
    function _getPath(address _tokenA, address _tokenB) private pure returns (address[] memory) {
        address[] memory _path = new address[](2);
        _path[0] = _tokenA;
        _path[1] = _tokenB;
        return _path;
    }

    /// @notice Function to get latest LP token price for all farms
    /// @return All LP token price in ETH
    function _getLPTokenPrice() private view returns (uint256, uint256, uint256, uint256) {
        // 1. Get tokens price in ETH
        uint256 _wbtcPrice = (router.getAmountsOut(1e8, _getPath(address(WBTC), address(WETH))))[1];
        uint256 _dpiPrice = _getTokenPriceFromChainlink(0x029849bbc0b1d93b85a8b6190e979fd38F5760E2); // DPI/ETH
        uint256 _daiPrice = _getTokenPriceFromChainlink(0x773616E4d11A78F511299002da57A0a94577F1f4); // DAI/ETH

        // 2. Calculate LP token price
        // Curve HBTC/WBTC
        uint256 _amountACurve = cPairs.balances(0); // HBTC, 18 decimals
        uint256 _amountBCurve = (cPairs.balances(1)).mul(1e10); // WBTC, 8 decimals to 18 decimals
        uint256 _totalValueOfHBTCWBTC = _calcTotalValueOfLiquidityPool(_amountACurve, _wbtcPrice, _amountBCurve, _wbtcPrice);
        uint256 _clpTokenPriceHBTC = _calcValueOf1LPToken(_totalValueOfHBTCWBTC, clpToken.totalSupply());
        // Pickle WBTC/ETH
        uint256 _pSlpTokenPriceWBTC = _calcPslpTokenPrice(pickleJarWBTC, slpWBTC, _wbtcPrice);
        // Sushiswap DPI/ETH
        uint256 _slpTokenPriceDPI = _calcSlpTokenPrice(slpDPI, _dpiPrice);
        // Pickle DAI/ETH
        uint256 _pSlpTokenPriceDAI = _calcPslpTokenPrice(pickleJarDAI, slpDAI, _daiPrice);

        return (_clpTokenPriceHBTC, _pSlpTokenPriceWBTC, _slpTokenPriceDPI, _pSlpTokenPriceDAI);
    }

    /// @notice Function to calculate price of Pickle LP token
    /// @param _pslpToken Type of Pickle SLP token
    /// @param _slpToken Type of SushiSwap LP token
    /// @param _tokenAPrice Price of SushiSwap LP token
    /// @return Price of Pickle LP token in ETH
    function _calcPslpTokenPrice(IPickleJar _pslpToken, ISLPToken _slpToken, uint256 _tokenAPrice) private view returns (uint256) {
        uint256 _slpTokenPrice = _calcSlpTokenPrice(_slpToken, _tokenAPrice);
        uint256 _totalValueOfPSlpToken = _calcTotalValueOfLiquidityPool(_pslpToken.balance(), _slpTokenPrice, 0, 0);
        return _calcValueOf1LPToken(_totalValueOfPSlpToken, _pslpToken.totalSupply());
    }

    /// @notice Function to calculate price of SushiSwap LP Token
    /// @param _slpToken Type of SushiSwap LP token
    /// @param _tokenAPrice Price of SushiSwap LP token
    /// @return Price of SushiSwap LP Token in ETH
    function _calcSlpTokenPrice(ISLPToken _slpToken, uint256 _tokenAPrice) private view returns (uint256) {
        (uint112 _reserveA, uint112 _reserveB,) = _slpToken.getReserves();
        if (_slpToken == slpWBTC) { // Change WBTC to 18 decimals
            _reserveA * 1e10;
        }
        uint256 _totalValueOfLiquidityPool = _calcTotalValueOfLiquidityPool(uint256(_reserveA), _tokenAPrice, uint256(_reserveB), 1e18);
        return _calcValueOf1LPToken(_totalValueOfLiquidityPool, _slpToken.totalSupply());
    }

    /// @notice Calculate total value of liquidity pool
    /// @param _amountA Amount of one side of reserves
    /// @param _priceA Price of one side of reserves
    /// @param _amountB Amount of another side of reserves (if available)
    /// @param _priceB Price of another side of reserves (if available)
    /// @return Total value of liquidity pool (18 decimals)
    function _calcTotalValueOfLiquidityPool(uint256 _amountA, uint256 _priceA, uint256 _amountB, uint256 _priceB) private pure returns (uint256) {
        return (_amountA.mul(_priceA)).add(_amountB.mul(_priceB));
    }

    /// @notice Function to calculate price of 1 LP Token
    /// @param _totalValueOfLiquidityPool Amount from _calcTotalValueOfLiquidityPool()
    /// @param _circulatingSupplyOfLPTokens totalSupply() of LP token
    /// @return Price of 1 LP Token (18 decimals)
    function _calcValueOf1LPToken(uint256 _totalValueOfLiquidityPool, uint256 _circulatingSupplyOfLPTokens) private pure returns (uint256) {
        return _totalValueOfLiquidityPool.div(_circulatingSupplyOfLPTokens);
    }

    /// @notice Function to get token price(only for DPI and DAI in this contract)
    /// @param _priceFeedProxy Address of ChainLink contract that provide oracle price
    /// @return Price in ETH
    function _getTokenPriceFromChainlink(address _priceFeedProxy) private view returns (uint256) {
        IChainlink _pricefeed = IChainlink(_priceFeedProxy);
        int256 _price = _pricefeed.latestAnswer();
        return uint256(_price);
    }

    /// @notice Get current pool(sum of 4 pools with latest price updated)
    /// @return Current pool in ETH
    function getCurrentPool() public view returns (uint256) {
        if (!isVesting) {
            (uint256 _clpTokenPriceHBTC, uint256 _pSlpTokenPriceWBTC, uint256 _slpTokenPriceDPI, uint256 _pSlpTokenPriceDAI) = _getLPTokenPrice();
            uint256 poolHBTCWBTC = _poolHBTCWBTC.mul(_clpTokenPriceHBTC).div(_HBTCWBTCLPTokenPrice);
            uint256 poolWBTCETH = _poolWBTCETH.mul(_pSlpTokenPriceWBTC).div(_WBTCETHLPTokenPrice);
            uint256 poolDPIETH = _poolDPIETH.mul(_slpTokenPriceDPI).div(_DPIETHLPTokenPrice);
            uint256 poolDAIETH = _poolDAIETH.mul(_pSlpTokenPriceDAI).div(_DAIETHLPTokenPrice);
            return poolHBTCWBTC.add(poolWBTCETH).add(poolDPIETH).add(poolDAIETH);
        } else {
            return _pool;
        }
    }

    /// @notice Get total pool(sum of 4 pools)
    /// @return Total pool in ETH
    function _getTotalPool() private view returns (uint256) {
        if (!isVesting) {
            return _poolHBTCWBTC.add(_poolWBTCETH).add(_poolDPIETH).add(_poolDAIETH);
        } else {
            return _pool;
        }
    }
}
