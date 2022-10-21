// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.5.0;

import "@openzeppelin/contracts/crowdsale/Crowdsale.sol";
import "@openzeppelin/contracts/crowdsale/validation/PausableCrowdsale.sol";
import "@openzeppelin/contracts/crowdsale/validation/CappedCrowdsale.sol";
import "@openzeppelin/contracts/crowdsale/validation/TimedCrowdsale.sol";
import "@openzeppelin/contracts/crowdsale/distribution/FinalizableCrowdsale.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";

contract HyperHoldingCrowdsalePhase2 is Crowdsale, CappedCrowdsale, TimedCrowdsale, FinalizableCrowdsale, PausableCrowdsale, Ownable {

    uint256 private _changeableRate;
    IERC777 __token;

    constructor()
        Ownable()
        FinalizableCrowdsale()
        PausableCrowdsale()
        CappedCrowdsale(
          600000 * 10 ** 18      // total cap, in wei
        )
        TimedCrowdsale(
          1612630800,              // opening time in unix epoch seconds
          1612630800 + 30*24*3600  // closing time in unix epoch seconds
        )
        Crowdsale(
          7666,                    // rate, in TKNbits ( (ETH price in USD) /  (Token price in USD) )
          0x230660DD3beF18cCeCD529786944050E11b99681, // wallet to send Ether
          IERC20(0x63Ba6efA6f7F69c4774Cff0A6DaC8f3C77dD81B8) // the token
        ) public
    {
      _changeableRate = 7666; 
      __token = IERC777(0x63Ba6efA6f7F69c4774Cff0A6DaC8f3C77dD81B8);
    }

    event RateChanged(uint256 newRate);

    function setRate(uint256 newRate) public onlyOwner {
        require(newRate > 0, "Crowdsale: rate is 0");
        _changeableRate = newRate;
        emit RateChanged(newRate);
    }

    function rate() public view returns (uint256) {     
          return _changeableRate;
    }

    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_changeableRate);
    }

    function _finalization() internal {
        _deliverTokens(wallet(), __token.balanceOf(address(this)));
    }

}
