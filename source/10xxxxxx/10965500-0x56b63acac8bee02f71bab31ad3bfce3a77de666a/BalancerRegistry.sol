pragma solidity 0.5.15;
pragma experimental ABIEncoderV2;

import "./IBalancerPool.sol";
import "./IBalancerFactory.sol";

contract BalancerRegistry {
  uint constant BONE = 10**18;
  address public balancerFactoryAddress;
  mapping(uint => address) poolLookup;

  constructor(
    address _balancerFactoryAddress
  ) public {
    balancerFactoryAddress = _balancerFactoryAddress;
  }

  function getPool(address tokenFrom, address tokenTo) public view returns (address) {
    uint key = calcKey(tokenFrom, tokenTo);
    return poolLookup[key];
  }

  function addPool(address pool) public {
    if (!IBalancerFactory(balancerFactoryAddress).isBPool(pool)) return;
    if (!IBalancerPool(pool).isFinalized()) return;
    address[] memory tokens = IBalancerPool(pool).getCurrentTokens();
    for (uint i = 0; i < tokens.length - 1; ++i) {
      for (uint j = i + 1; j < tokens.length; ++j) {
        uint key = calcKey(tokens[i], tokens[j]);
        address incumbentPool = poolLookup[key];
        if (pool != incumbentPool) {
          if (incumbentPool == address(0)) {
            poolLookup[key] = pool;
          } else {
            uint scoreNew = scorePool(pool, tokens[i], tokens[j]);
            uint scoreOld = scorePool(incumbentPool, tokens[i], tokens[j]);
            if (scoreNew > scoreOld) {
              poolLookup[key] = pool;
            }
          }
        }
      }
    }
  }

  function addPools(address[] calldata pools) external {
    for (uint i = 0; i < pools.length; ++i) {
      addPool(pools[i]);
    }
  }

  function checkPool(address pool) public view returns (bool) {
    if (!IBalancerFactory(balancerFactoryAddress).isBPool(pool)) return false;
    if (!IBalancerPool(pool).isFinalized()) return false;
    address[] memory tokens = IBalancerPool(pool).getCurrentTokens();
    for (uint i = 0; i < tokens.length - 1; ++i) {
      for (uint j = i + 1; j < tokens.length; ++j) {
        uint key = calcKey(tokens[i], tokens[j]);
        address incumbentPool = poolLookup[key];
        if (pool != incumbentPool) {
          if (incumbentPool == address(0)) {
            return true;
          } else {
            uint scoreNew = scorePool(pool, tokens[i], tokens[j]);
            uint scoreOld = scorePool(incumbentPool, tokens[i], tokens[j]);
            if (scoreNew > scoreOld) {
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  function checkPools(address[] calldata pools) external view returns (address[] memory poolsUpdated) {
    address[] memory _poolsUpdated = new address[](pools.length);
    uint count = 0;
    for (uint i = 0; i < pools.length; ++i) {
      if (checkPool(pools[i])) {
        _poolsUpdated[count++] = pools[i];
      }
    }
    poolsUpdated = new address[](count);
    for (uint i = 0; i < count; ++i) {
      poolsUpdated[i] = _poolsUpdated[i];
    }
    return poolsUpdated;
  }

  function scorePool(address pool, address token1, address token2) internal view returns (uint) {
    uint balance1 = IBalancerPool(pool).getBalance(token1);
    uint balance2 = IBalancerPool(pool).getBalance(token2);
    uint weight1 = IBalancerPool(pool).getDenormalizedWeight(token1);
    uint weight2 = IBalancerPool(pool).getDenormalizedWeight(token2);
    uint fee = IBalancerPool(pool).getSwapFee(); // BONE = 100%
    // Divide balances by weight factors to get liquidity values
    // Then divide by (the fee in %) + 1
    // So - 10% fee (i.e. BONE / 10) results in divide by 11
    //    - 1% fee (i.e. BONE / 100) results in divide by 2
    //    - 0% fee results in divide by 1 (no change)
    // Finally multiply the two results to get a score
    uint weightSum = weight1 + weight2;
    uint feePlusOne = fee + BONE / 100;
    return ((balance1 * weightSum / weight1) * (BONE / 100) / feePlusOne)
         * ((balance2 * weightSum / weight2) * (BONE / 100) / feePlusOne);
  }

  function calcKey(address token1, address token2) internal pure returns (uint) {
    if (token1 < token2) {
      return (uint(token1) << (256 - 160)) ^ uint(token2);
    } else {
      return (uint(token2) << (256 - 160)) ^ uint(token1);
    }
  }
}

