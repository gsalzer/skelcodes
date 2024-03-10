//SPDX-License-Identifier: MIT" 
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../interfaces/ILPPool.sol";
import "../../interfaces/ICurveFi.sol";
import "../../interfaces/IUniswapV2Pair.sol";
import "../../interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FAANGStrategy is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;


    struct mAsset {
        uint256 weight;
        IERC20 mAssetToken;
        ILPPool lpPool;
        IERC20 lpToken;
        uint amountOfATotal;
        uint amountOfBTotal;
    }

    IERC20 constant ust = IERC20(0xa47c8bf37f92aBed4A126BDA807A7b7498661acD);
    IERC20 constant mir = IERC20(0x09a3EcAFa817268f77BE1283176B946C4ff2E608);
    ICurveFi public constant curveFi = ICurveFi(0x890f4e345B1dAED0367A877a1612f86A1f86985f); 
    IUniswapV2Router02 public constant router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory public constant factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    
    address public vault;
    address public treasuryWallet;
    
    address private constant mirustPairAddress = 0x87dA823B6fC8EB8575a235A824690fda94674c88;
    address constant DAIToken = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant mirUstPooltoken = 0x87dA823B6fC8EB8575a235A824690fda94674c88;
    ILPPool mirustPool;

    mapping(address => int128) curveIds;
    mapping(IERC20 => uint256) public userTotalLPToken;
    mapping(IERC20 => uint256) public amountInPool;
    mapping(ILPPool => uint256) public poolStakedMIRLPToken;
    mAsset[] public mAssets;

    uint reInvestedMirUstPooltoken;

    modifier onlyVault {
        require(msg.sender == vault, "only vault");
        _;
    }    

    constructor(
        address _treasuryWallet, 
        address _mirustPool,
        uint[] memory weights,
        IERC20[] memory mAssetsTokens,
        ILPPool[] memory lpPools,
        IERC20[] memory lpTokens

        ) {
        
        
        curveIds[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = 2;
        curveIds[0xdAC17F958D2ee523a2206206994597C13D831ec7] = 3;
        curveIds[0x6B175474E89094C44Da98b954EedeAC495271d0F] = 1;

        treasuryWallet = _treasuryWallet;
        mirustPool = ILPPool(_mirustPool);

        IERC20(0x87dA823B6fC8EB8575a235A824690fda94674c88).approve(_mirustPool, type(uint).max); //approve mirUST uniswap LP token to stake on mirror
        ust.approve(address(router), type(uint256).max);
        ust.approve(address(curveFi), type(uint256).max);
        mir.approve(address(router), type(uint256).max);
        //DAI
        IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F).approve(address(router), type(uint256).max);
        IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F).approve(address(curveFi), type(uint256).max);
        //USDC
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).approve((address(router)), type(uint).max);
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).approve((address(curveFi)), type(uint).max);
        //USDT
        IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7).safeApprove(address(router), type(uint).max);
        IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7).safeApprove((address(curveFi)), type(uint).max);

        for(uint i=0; i<weights.length; i++) {
            mAssets.push(mAsset({
                weight: weights[i],
                mAssetToken : mAssetsTokens[i],
                lpPool:lpPools[i],
                lpToken:lpTokens[i],
                amountOfATotal: 0,
                amountOfBTotal: 0
            }));

            mAssetsTokens[i].approve(address(router), type(uint).max);
            lpTokens[i].approve(_mirustPool, type(uint).max);
            lpTokens[i].approve(address(lpPools[i]), type(uint).max);
            lpTokens[i].approve(address(router), type(uint).max);
            IERC20(mirUstPooltoken).approve(address(router), type(uint).max);
        }



    }
    /**
        @param _amount Amount of tokens to deposit in original decimals
        @param _token Token to deposit
     */
    function deposit(uint256 _amount, IERC20 _token) external onlyVault {
        require(_amount > 0, 'Invalid amount');

        _token.safeTransferFrom(address(vault), address(this), _amount);

        
        address[] memory path = new address[](2);
        path[0] = address(_token);
        path[1] = address(ust);

        uint256 ustAmount = curveFi.exchange_underlying(curveIds[address(_token)], 0, _amount, 0);
        
        uint256[] memory amounts;        

        for (uint256 i = 0; i < mAssets.length; i++) {
            address addr_ = address(mAssets[i].mAssetToken);
            // UST -> mAsset on Uniswap
            path[0] = address(ust);
            path[1] = addr_;
            uint _ustAmount = ustAmount.mul(mAssets[i].weight).div(10000);
            amounts = router.swapExactTokensForTokens(
                _ustAmount,
                0,
                path,
                address(this),
                block.timestamp
            );

            (, , uint256 poolTokenAmount) = router.addLiquidity(addr_,  address(ust), amounts[1], _ustAmount, 0, 0, address(this), block.timestamp);

            // stake LPToken to LPPool
            //no incentives for mFB pool tokens so address(0)
            if(address(mAssets[i].lpPool) != address(0)) {  
                mAssets[i].lpPool.stake(poolTokenAmount);
            }
                        

            userTotalLPToken[mAssets[i].lpToken] = userTotalLPToken[mAssets[i].lpToken].add(poolTokenAmount);
            mAssets[i].amountOfATotal = mAssets[i].amountOfATotal.add(amounts[1]);
            mAssets[i].amountOfBTotal = mAssets[i].amountOfBTotal.add(_ustAmount);
            
        }

        
    }

    /**
        @param _amount Amount of tokens to withdraw. Should be scaled to 18 decimals
        @param _token Token to withdraw
     */
    function withdraw(uint256 _amount, IERC20 _token) external onlyVault {
        require(_amount > 0, "Invalid Amount");
        address[] memory path = new address[](2);
        path[0] = address(mir);
        path[1] = address(ust);

        uint valueInPool = getTotalValueInPool();
        
        for (uint256 i = 0; i < mAssets.length; i++) {
            //_amount should be 18 decimals
            uint amounOfLpTokenToRemove = getDataFromLPPool(address(mAssets[i].lpToken), _amount, valueInPool);
            
            //uniswap LPTokens for mFb-UST are not staked. For others, we need to get from mirror pool
            if(address(mAssets[i].lpPool) != address(0)) {
                mAssets[i].lpPool.withdraw(amounOfLpTokenToRemove);
            } 

            (uint256 mAssetAmount, uint256 ustAmount) =
                router.removeLiquidity(
                    address(mAssets[i].mAssetToken),
                    address(ust),
                    amounOfLpTokenToRemove, 
                    0,
                    0,
                    address(this),
                    block.timestamp
                );
            uint adjustedAmountATotal = mAssets[i].amountOfATotal < mAssetAmount ? mAssets[i].amountOfATotal : mAssetAmount;
            uint adjustedAmountBTotal = mAssets[i].amountOfBTotal < ustAmount ? mAssets[i].amountOfBTotal : ustAmount;
            mAssets[i].amountOfATotal = mAssets[i].amountOfATotal.sub(adjustedAmountATotal);
            mAssets[i].amountOfBTotal = mAssets[i].amountOfBTotal.sub(adjustedAmountBTotal);

            // mAsset -> UST on Uniswap
            path[0] = address(mAssets[i].mAssetToken);
            path[1] = address(ust);
            uint256[] memory amounts =
                router.swapExactTokensForTokens(
                    mAssetAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
            // UST -> principalToken on Uniswap
            curveFi.exchange_underlying(0, curveIds[address(_token)], amounts[1].add(ustAmount), 0);

            userTotalLPToken[mAssets[i].lpToken] = userTotalLPToken[mAssets[i].lpToken].sub(amounOfLpTokenToRemove);

            
        }

        withdrawFromMirUstPool(_amount, valueInPool, false);
        _token.safeTransfer(msg.sender, _token.balanceOf(address(this)));
    }

    function withdrawFromMirUstPool(uint _amount, uint _valueInPool, bool _withdrawAll) internal {
        
        if(reInvestedMirUstPooltoken != 0) {  
    
            address[] memory path = new address[](2);
            uint amountToWithdraw;
            path[0] = address(mir);
            path[1] = address(ust);
 
           
            //_withdrawAll is true only during emergencyWIthdraw and migrateFunds.
            if(_withdrawAll == true) {
                amountToWithdraw = reInvestedMirUstPooltoken;
                mirustPool.getReward();
            } else {
                amountToWithdraw = reInvestedMirUstPooltoken.mul(_amount).div(_valueInPool);
                amountToWithdraw = amountToWithdraw > reInvestedMirUstPooltoken ? reInvestedMirUstPooltoken : amountToWithdraw;
            }           
            
            mirustPool.withdraw(amountToWithdraw);
            
                    router.removeLiquidity(
                        address(mir),
                        address(ust),
                        amountToWithdraw, 
                        0,
                        0,
                        address(this),
                        block.timestamp
                    );

            router.swapExactTokensForTokens(
                        mir.balanceOf(address(this)),
                        0,
                        path,
                        address(this),
                        block.timestamp
                    );

            reInvestedMirUstPooltoken = reInvestedMirUstPooltoken.sub(amountToWithdraw);
        }



    }

    /** @notice This function reinvests the farmed MIR into varioud pools
     */
    function yield() external onlyVault{
        uint256 totalEarnedMIR;
        address[] memory path = new address[](2);
        for (uint256 i = 0; i < mAssets.length; i++) {        
            
            //no incentive on mFB-UST farm
            if(address(mAssets[i].lpPool) != address(0)) {
                uint earnedMIR = mAssets[i].lpPool.earned(address(this));
                if(earnedMIR != 0) {
                    path[0] = address(mir);
                    path[1] = address(ust);
                    mAssets[i].lpPool.getReward();

                    totalEarnedMIR = totalEarnedMIR.add(earnedMIR);
                    //45% of MIR is used in MIR-UST farm. Convert half of MIR(22.5%) to UST 
                    //router.swapExactTokensForTokens(earnedMIR.mul(2250).div(10000), 0, path, address(this), block.timestamp);

                    //45 - MIRUST farm, 10 - to wallet, remaining 45 (22.5 UST, 22.5 mAsset)

                    //22.5(mirUst) + 22.5(mAssetUST)
                    uint[] memory amounts = router.swapExactTokensForTokens(earnedMIR.mul(450).div(1000), 0, path, address(this), block.timestamp);
                    uint _ustAmount = amounts[1].div(2);
                    path[1] = address(mAssets[i].mAssetToken);

                    //22.5% mir to mAsset
                    uint _mirAmount = earnedMIR.mul(2250).div(10000);

                    //pair doesn;t exists for some tokens
                    if(factory.getPair(address(mir), address(mAssets[i].mAssetToken)) == address(0)) {
                        address[] memory pathTemp = new address[](3);
                        uint[] memory amountsTemp ; 
                        pathTemp[0] = address(mir);
                        pathTemp[1] = address(ust);
                        pathTemp[2] = address(mAssets[i].mAssetToken);
                        amountsTemp = router.swapExactTokensForTokens(_mirAmount, 0, pathTemp, address(this), block.timestamp);  
                        amounts[1] = amountsTemp[2];
                    } else {
                        amounts = router.swapExactTokensForTokens(_mirAmount, 0, path, address(this), block.timestamp);
                    }
                    

                    (,,uint poolTokenAmount) = router.addLiquidity(address(mAssets[i].mAssetToken), address(ust), amounts[1], _ustAmount, 0, 0, address(this), block.timestamp);
                    mAssets[i].lpPool.stake(poolTokenAmount);

                    userTotalLPToken[mAssets[i].lpToken] = userTotalLPToken[mAssets[i].lpToken].add(poolTokenAmount);
                    mAssets[i].amountOfATotal = mAssets[i].amountOfATotal.add(amounts[1]);
                    mAssets[i].amountOfBTotal = mAssets[i].amountOfBTotal.add(_ustAmount);
                }
            }
        }

        totalEarnedMIR = totalEarnedMIR.add(mirustPool.earned(address(this)));
        mirustPool.getReward();
        if(totalEarnedMIR > 0) {
            mir.safeTransfer(treasuryWallet, totalEarnedMIR.div(10));//10 % 
                
            (,, uint poolTokenAmount) = router.addLiquidity(address(mir), address(ust), mir.balanceOf(address(this)), ust.balanceOf(address(this)), 0, 0, address(this), block.timestamp);
            mirustPool.stake(poolTokenAmount);

            reInvestedMirUstPooltoken = reInvestedMirUstPooltoken.add(poolTokenAmount);
        }

        
    }

    /**
        @param weights Percentage of mAssets - 750 means 7.5
        @dev Used to change the percentage of funds allocated to each pool
     */
    function reBalance(uint[] memory weights) external onlyOwner{
        require(weights.length == mAssets.length, "Weight length mismatch");
        uint _weightsSum;
        for(uint i=0; i<weights.length; i++) {
            mAsset memory _masset = mAssets[i];
            _masset.weight = weights[i];
            mAssets[i] = _masset;      
            _weightsSum = _weightsSum.add(weights[i]);
        }

        require(_weightsSum == 5000, "Invalid weights percentages"); //50% mAssets 50% UST
    }

    function withdrawAllFunds(IERC20 _tokenToConvert) external onlyVault {

        address[] memory path = new address[](2);
        path[1] = address(ust);
        for(uint i=0; i<mAssets.length; i++) {
            uint amounOfLpTokenToRemove = mAssets[i].lpToken.balanceOf(address(this));

            if(address(mAssets[i].lpPool) != address(0)) {
                mAssets[i].lpPool.getReward(); //withdraw rewards
                //tokens are in mirror's lpPool contract
                amounOfLpTokenToRemove = mAssets[i].lpPool.balanceOf(address(this));
                if(amounOfLpTokenToRemove != 0) {
                    mAssets[i].lpPool.withdraw(amounOfLpTokenToRemove);

                }
            }
            
            if(amounOfLpTokenToRemove != 0) {
                (uint256 mAssetAmount, ) = router.removeLiquidity(address(mAssets[i].mAssetToken), address(ust),amounOfLpTokenToRemove, 0, 0, address(this), block.timestamp);
                path[0] = address(mAssets[i].mAssetToken);
            
                router.swapExactTokensForTokens(
                    mAssetAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );    

                //setting value to zero , since all amounts are withdrawn
                mAssets[i].amountOfATotal = 0;
                mAssets[i].amountOfBTotal = 0;
                userTotalLPToken[mAssets[i].lpToken] = 0;
            }
        
        }
        withdrawFromMirUstPool(0,0, true);

        uint mirWithdrawn = mir.balanceOf(address(this));
        if(mirWithdrawn > 0) {
            path[0] = address(mir);
            router.swapExactTokensForTokens(mirWithdrawn, 0, path, address(this), block.timestamp);
        }

        if(ust.balanceOf(address(this)) != 0) {
            curveFi.exchange_underlying(0, curveIds[address(_tokenToConvert)], ust.balanceOf(address(this)), 0);
            _tokenToConvert.safeTransfer(address(vault), _tokenToConvert.balanceOf(address(this)));
        }
        
    }

    function setVault (address _vault) external onlyOwner{
        require(vault == address(0), "Cannot set vault");
        vault = _vault;
    }


    /**
        @dev amount of mAsset multiplied by price of mAssetInUst
        @return value Returns the value of all funds in all pools (in terms of UST)
     */
    function getTotalValueInPool() public view returns (uint256 value) {
        //get price of mAsset interms of UST
        //value = (amountOfmAsset*priceInUst) + amountOfUST
        address[] memory path = new address[](2);
        for (uint256 i = 0; i < mAssets.length; i++) {
            
            path[0] = address(mAssets[i].mAssetToken);
            path[1] = address(ust);
            uint[] memory priceInUst = router.getAmountsOut(1e18, path);
            
            value = value.add((priceInUst[1].mul(mAssets[i].amountOfATotal)).div(1e18)).add(mAssets[i].amountOfBTotal);
            
        }
        
        //get value of tokens in mirust pool
        (uint mirAmount, uint ustAmount) = calculateAmountWithdrawable(reInvestedMirUstPooltoken);
        
        if(mirAmount > 0) {
            path[0] = address(mir);
            path[1] = address(ust);
            value = value.add(router.getAmountsOut(mirAmount, path)[1]).add(ustAmount);
            //cacluate amount of mir+ust using reInvestedMirUstPooltoken. add to value
        }
        

    }

    /**
        @notice Function to calculate the amount of LPTokens needs to be removed from uniswap.
        @param _lpToken Address of uniswapPool
        @param _amount Amount of tokens needs to be withdrawn
        @param _valueInPool TotalValue in Pool
        @return amounOfLpTokenToRemove Amount of LPTokens to be removed from pool, to get the targetted amount.
       */

    function getDataFromLPPool(address _lpToken, uint _amount, uint _valueInPool) internal view returns (uint amounOfLpTokenToRemove){

        uint lpTokenBalance = userTotalLPToken[IERC20(_lpToken)];        

        amounOfLpTokenToRemove = lpTokenBalance.mul(_amount).div(_valueInPool);
        amounOfLpTokenToRemove = amounOfLpTokenToRemove > lpTokenBalance ? lpTokenBalance : amounOfLpTokenToRemove;
        
    }

    /**
        @dev Function to calculate the amount to tokens that will be received from MIRUST pool, when a specific amount of LPTokens are removed 
        @param _lpTokenAmount Amount of uniswap LPTokens
        @return amountMIR amount of MIR that will be received
        @return amountUST amount of UST that will be received
     */
    function calculateAmountWithdrawable(uint _lpTokenAmount) internal view returns(uint amountMIR , uint amountUST) {
        //get reserves
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(mirustPairAddress).getReserves();
        uint totalLpTOkenSupply = IUniswapV2Pair(mirustPairAddress).totalSupply();
        
        amountMIR = _lpTokenAmount.mul(reserve0).div(totalLpTOkenSupply);
        amountUST = _lpTokenAmount.mul(reserve1).div(totalLpTOkenSupply);

    }

}

