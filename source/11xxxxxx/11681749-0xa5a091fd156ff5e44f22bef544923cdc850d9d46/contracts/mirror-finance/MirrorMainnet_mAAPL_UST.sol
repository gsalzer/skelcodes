pragma solidity 0.5.16;

import "../snx-base/interfaces/SNXRewardInterface.sol";
import "../snx-base/SNXReward2FarmStrategy.sol";

contract MirrorMainnet_mAAPL_UST is SNXReward2FarmStrategy {

  address public mAAPL_USTu = address(0xB022e08aDc8bA2dE6bA4fECb59C6D502f66e953B);
  address public rewardPool = address(0x735659C8576d88A2Eb5C810415Ea51cB06931696);
  address public constant uniswapRouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
  address public mir = address(0x09a3EcAFa817268f77BE1283176B946C4ff2E608);
  address public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  address public farm = address(0xa0246c9032bC3A600820415aE600c6388619A14D);

  constructor(
    address _storage,
    address _vault,
    address _distributionPool,
    address _distributionSwitcher
  )
  SNXReward2FarmStrategy(_storage, mAAPL_USTu, _vault, rewardPool, mir, uniswapRouterAddress, farm, _distributionPool, _distributionSwitcher)
  public {
    require(IVault(_vault).underlying() == mAAPL_USTu, "Underlying mismatch");
    uniswapRoutes[farm] = [mir, weth, farm];

    // adding ability to liquidate reward tokens manually if there is no liquidity
    unsalvagableTokens[mir] = false;
  }
}

