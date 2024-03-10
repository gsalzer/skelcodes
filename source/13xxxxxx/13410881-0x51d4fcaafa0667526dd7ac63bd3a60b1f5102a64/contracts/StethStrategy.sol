// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interface/IStrategy.sol";
import "./interface/ICurveFi.sol";
import "./interface/IConvexBaseReward.sol";
import "./interface/IConvexBooster.sol";
import "./interface/IUniswapV2Router01.sol";
import "./interface/INativeVault.sol";

contract StethStrategy is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public crvLpToken;
    address public crvPool;
    address public nativeVault;
    address public convexReward;
    uint256 public poolId;
    address public swapRouter;
    address public rewardManager;
    address public constant crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    address public constant cvx = address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    address public constant ldo = address(0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32);
    address public convexBooster = address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);

    // Slippage tolerance accepted (10 = 0.1%)
    uint8 public SLIPPAGE_TOLERANCE = 10;

    event Withdraw(uint256 amount);
    event Deposit(uint256 amount);
    event Harvest(uint256 ldoBal);

    mapping(address => uint256) public balance;

    modifier onlyNativeVault {
        require(msg.sender == nativeVault, "You are not allowed");
        _;
    }

    constructor(address _crvLpToken, address _curvePool, uint256 _poolId, address _convexRewards, address _swapRouter, address _rewardManager) {
        crvLpToken = _crvLpToken;
        crvPool = _curvePool;
        poolId = _poolId;
        convexReward = _convexRewards;
        swapRouter = _swapRouter;
        rewardManager = _rewardManager;
    }

    function deposit() external onlyNativeVault payable returns (uint256){
        require(msg.value > 0, "Deposit positive amount");
        uint256 amountToDeposit = msg.value;

        uint256 lpAmount = _deposit(amountToDeposit);
        return lpAmount;
    }

    function withdraw(uint256 lpAmount) external onlyNativeVault returns (uint256) {
        return _withdraw(lpAmount);
    }

    function withdrawAll() external onlyNativeVault returns (uint256) {
        harvest();
        uint256 lpAmount = IConvexBaseReward(convexReward).balanceOf(address(this));
        return _withdraw(lpAmount);
    }


    function harvest() public {
        require(rewardManager != address(0), "reward manager is not set");
        require(IConvexBaseReward(convexReward).getReward(), "Convex claim failed");

        uint256 crvBal = IERC20(crv).balanceOf(address(this));
        uint256 cvxBal = IERC20(cvx).balanceOf(address(this));
        uint256 ldoBal = IERC20(ldo).balanceOf(address(this));

        if (crvBal > 0) {
            IERC20(crv).transfer(rewardManager, crvBal);
        }

        if (cvxBal > 0) {
            IERC20(cvx).transfer(rewardManager, cvxBal);
        }

        if (ldoBal > 0) {
            _swapRewardForEth(ldo, ldoBal);
        }

        if (address(this).balance > 0) {
            INativeVault(nativeVault).transfer{value: address(this).balance}();
        }

        emit Harvest(ldoBal);
    }

    function _deposit(uint256 _amountToDeposit) internal returns (uint256) {
        uint256 lpAmount = _getCurveLp(_amountToDeposit);

        _depositInConvex(lpAmount);

        emit Deposit(msg.value);
        return lpAmount;
    }

    function _withdraw(uint256 lpAmount) internal returns (uint256) {
        require(lpAmount > 0, "Withdraw positive amount please");

        //get crv lp back from Convex by withdrawAndUnwraping
        IConvexBaseReward(convexReward).withdrawAndUnwrap(lpAmount, false);
        uint256 amountEthOut = _removeCurveLiquidity(lpAmount);

        INativeVault(nativeVault).transfer{value : amountEthOut}();

        emit Withdraw(amountEthOut);
        return amountEthOut;
    }

    function _removeCurveLiquidity(uint256 _amount) internal returns (uint256) {
        //eth is index 0
        uint256 minEthAmount = ICurveFi(crvPool).calc_withdraw_one_coin(_amount, 0);

        //slippage tolerance on our side
        uint256 minEthAmountWithSlippage = minEthAmount.mul(1000 - SLIPPAGE_TOLERANCE).div(1000);
        return ICurveFi(crvPool).remove_liquidity_one_coin(_amount, 0, minEthAmountWithSlippage);
    }

    function _swapRewardForEth(address _tokenReward, uint256 _amount) internal {
        require(IERC20(_tokenReward).approve(swapRouter, _amount), "approved failed");

        address[] memory path = new address[](2);
        path[0] = _tokenReward;
        path[1] = IUniswapV2Router01(swapRouter).WETH();

        IUniswapV2Router01(swapRouter).swapExactTokensForETH(_amount, 0, path, address(this), block.timestamp + 10);
    }

    function _getCurveLp(uint256 _amountToDeposit) internal returns (uint256){
        //Slippage taken into account in calc_token_amount but not fees. Cannot do better
        uint256 minLpMint = ICurveFi(crvPool).calc_token_amount([_amountToDeposit, 0], true);

        //slippage tolerance on our side
        uint256 mintLpWithSlippage = minLpMint.mul(1000 - SLIPPAGE_TOLERANCE).div(1000);
        return ICurveFi(crvPool).add_liquidity{value : _amountToDeposit}([_amountToDeposit, 0], mintLpWithSlippage);
    }

    function _depositInConvex(uint256 _lpAmount) internal {
        IERC20(crvLpToken).approve(convexBooster, _lpAmount);
        require(IConvexBooster(convexBooster).depositAll(poolId, true), 'Convex deposit failed');
    }

    function setPoolId(uint256 _poolId) external onlyOwner {
        poolId = _poolId;
    }

    function setNativeVault(address _nativeVault) external onlyOwner {
        nativeVault = _nativeVault;
    }

    function setSlippageTolerance(uint8 _newSlipTolerance) external onlyOwner {
        SLIPPAGE_TOLERANCE = _newSlipTolerance;
    }

    function setConvexBooster(address _newConvexBooster) external onlyOwner {
        convexBooster = _newConvexBooster;
    }

    function setConvexReward(address _newConvexReward) external onlyOwner {
        convexReward = _newConvexReward;
    }

    function setSwapRouter(address _newSwapRouter) external onlyOwner {
        swapRouter = _newSwapRouter;
    }

    function setRewardManager(address _newRewardManager) external onlyNativeVault {
        rewardManager = _newRewardManager;
    }

    function getVirtualBalance() external returns (uint256) {
        uint256 cvxLpBal = IConvexBaseReward(convexReward).balanceOf(address(this));
        uint256 lpVirtualPrice = ICurveFi(crvPool).get_virtual_price();

        uint256 virtualBal = cvxLpBal * lpVirtualPrice / 1e18;
        return virtualBal;
    }

    // @dev https://news.curve.fi/chainlink-oracles-and-curve-pools/
    function getConvexLpBalance() external view returns (uint256) {
        return IConvexBaseReward(convexReward).balanceOf(address(this));
    }

    receive() external payable {}
}

