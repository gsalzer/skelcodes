pragma solidity 0.5.16;

import "../../base/snx-base/interfaces/SNXRewardInterface.sol";
import "../../base/snx-base/SNXReward2FarmStrategyUL.sol";

contract Klondike2FarmStrategyMainnet_WBTC_KLON is SNXReward2FarmStrategyUL {

  address public wbtc = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
  address public wbtc_klon = address(0x734e48A1FfEA1cdF4F5172210C322f3990d6D760);
  address public klon = address(0xB97D5cF2864FB0D08b34a484FF48d5492B2324A0);
  address public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  address public WBTCKLONRewardPool = address(0xC3503F004aa2cd689803A0D4E6ed07E8949525Fd);
  address public constant universalLiquidatorRegistry = address(0x7882172921E99d590E097cD600554339fBDBc480);
  address public constant farm = address(0xa0246c9032bC3A600820415aE600c6388619A14D);

  constructor(
    address _storage,
    address _vault,
    address _distributionPool
  )
  SNXReward2FarmStrategyUL(_storage, wbtc_klon, _vault, WBTCKLONRewardPool, klon, universalLiquidatorRegistry, farm, _distributionPool)
  public {
    require(IVault(_vault).underlying() == wbtc_klon, "Underlying mismatch");
    liquidationPath = [klon, farm];
    liquidationDexes.push(bytes32(uint256(keccak256("uni"))));
  }
}

