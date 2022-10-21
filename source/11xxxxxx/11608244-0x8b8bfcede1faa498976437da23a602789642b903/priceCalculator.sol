//////////////////////////////////////////////////
//SYNLEV Price Calculator Contract V 1.3
//////////////////////////

pragma solidity >= 0.6.6;

import './ownable.sol';
import './SafeMath.sol';
import './SignedSafeMath.sol';
import './IERC20.sol';
import './vaultInterface.sol';
import './priceAggregatorInterface.sol';

contract priceCalculator is Owned {
  using SafeMath for uint256;
  using SignedSafeMath for int256;

  constructor() public {
    lossLimit = 9 * 10**8;
    kControl = 15 * 10**8;
    proposeDelay = 2 days;
    proposeDelayPropose = 2 days;
    priceAggregator = priceAggregatorInterface(0x717584a1DC53DAFddE10b9819601A7082536E79e);
  }

  uint256 public constant uSmallFactor = 10**9;
  int256 public constant smallFactor = 10**9;

  uint256 public lossLimit;
  uint256 public kControl;
  priceAggregatorInterface public priceAggregator;
  address public priceAggregatorPropose;
  uint256 public priceAggregatorProposeTimestamp;

  uint256 public proposeDelay;
  uint256 public proposeDelayPropose;
  uint256 public proposeDelayTimestamp;

  /*
   * @notice Calculates the most recent price data.
   * @dev If there is no new price data it returns current price/equity data.
   * Safety checks are done by SynLev price aggregator. All calcualtions done
   * via equity in ETH, not price to avoid rounding errors. Caculates price
   * based on the "losing side", then subracts from the other. Mitigates a
   * prefrence in rounding error to either bull or bear tokens.
   */
  function getUpdatedPrice(address vault, uint256 latestRoundId)
  public
  view
  returns(
    uint256[6] memory latestPrice,
    uint256 rRoundId,
    bool updated
  ) {
    //Requests price data from price aggregator proxy
    (
      int256[] memory priceData,
      uint256 roundId
    ) = priceAggregator.priceRequest(vault, latestRoundId);
    vaultInterface ivault = vaultInterface(vault);
    address bull = ivault.getBullToken();
    address bear = ivault.getBearToken();
    uint256 bullEquity = ivault.getTokenEquity(bull);
    uint256 bearEquity = ivault.getTokenEquity(bear);
    //Only update if price data if price array contains 2 or more values
    //If there is no new price data pricedate array will have 0 length
    if(priceData.length > 0 && bullEquity != 0 && bearEquity != 0) {
      (uint256 rBullEquity, uint256 rBearEquity) = priceCalc(priceData, bullEquity, bearEquity, ivault);
      uint256[6] memory data = equityToReturnData(bull, bear, rBullEquity, rBearEquity, ivault);
      return(data, roundId, true);
    }
    else {
      return(
        [ivault.getPrice(bull),
        ivault.getPrice(bear),
        ivault.getLiqEquity(bull),
        ivault.getLiqEquity(bear),
        ivault.getEquity(bull),
        ivault.getEquity(bear)],
        roundId,
        false
      );
    }
  }

  function priceCalc(
    int256[] memory priceData,
    uint256 bullEquity,
    uint256 bearEquity,
    vaultInterface ivault
    )
    public
    view
    returns(uint256 rBullEquity, uint256 rBearEquity)
    {
      uint256 multiplier = ivault.getMultiplier();
      uint256 totalEquity = ivault.getTotalEquity();
      uint256 movement;
      uint256 bearKFactor = getKFactor(bearEquity, bullEquity, bearEquity, totalEquity);
      uint256 bullKFactor = getKFactor(bullEquity, bullEquity, bearEquity, totalEquity);
      int256  signedPriceDelta;
      uint256 pricedelta;

      if(priceData[0] != priceData[1]) {
        //Treats 0 price value as 1, 0 causes divides by 0 error
        if(priceData[0] == 0) priceData[0] = 1;
        //Bearish movement, calc equity from the perspective of bull
        if(priceData[0] > priceData[1]) {
          //Gets price change in absolute terms.
          signedPriceDelta = priceData[0].sub(priceData[1]);
          signedPriceDelta = signedPriceDelta.mul(smallFactor);
          signedPriceDelta = signedPriceDelta.div(priceData[0]);
          pricedelta = uint256(signedPriceDelta);

          //Converts price change to be in terms of bull equity change
          //As a percentage
          pricedelta = pricedelta.mul(multiplier.mul(bullKFactor)).div(uSmallFactor);
          //Dont allow loss to be greater than set loss limit
          pricedelta = pricedelta < lossLimit ? pricedelta : lossLimit;
          //Calculate equity loss of bull equity
          movement = bullEquity.mul(pricedelta);
          movement = movement.div(uSmallFactor);
          //Adds equity movement to running bear euqity and removes that
          //Loss from running bull equity
          bearEquity = bearEquity.add(movement);
          bullEquity = totalEquity.sub(bearEquity);
        }
        //Bullish movement, calc equity from the perspective of bear
        //Same process as above. only from bear perspective
        else if(priceData[0] < priceData[1]) {

          signedPriceDelta = priceData[1].sub(priceData[0]);
          signedPriceDelta = signedPriceDelta.mul(smallFactor);
          signedPriceDelta = signedPriceDelta.div(priceData[0]);
          pricedelta = uint256(signedPriceDelta);

          pricedelta = pricedelta.mul(multiplier.mul(bearKFactor)).div(uSmallFactor);
          pricedelta = pricedelta < lossLimit ? pricedelta : lossLimit;
          movement = bearEquity.mul(pricedelta);
          movement = movement.div(uSmallFactor);
          bullEquity = bullEquity.add(movement);
          bearEquity = totalEquity.sub(bullEquity);
        }
      }

      return(bullEquity, bearEquity);
  }

  function equityToReturnData(
    address bull,
    address bear,
    uint256 bullEquity,
    uint256 bearEquity,
    vaultInterface ivault
    )
    public
    view
    returns(uint256[6] memory)
  {
      uint256 bullPrice =
        bullEquity
        .mul(1 ether)
        .div(IERC20(bull).totalSupply().add(ivault.getLiqTokens(bull)));
      uint256 bearPrice =
        bearEquity
        .mul(1 ether)
        .div(IERC20(bear).totalSupply().add(ivault.getLiqTokens(bear)));
      uint256 bullTokenEquity =
        bullPrice
        .mul(IERC20(bull).totalSupply())
        .div(1 ether);
      uint256 bearTokenEquity =
        bearPrice
        .mul(IERC20(bear).totalSupply())
        .div(1 ether);

      return([
        bullPrice,
        bearPrice,
        bullEquity.sub(bullTokenEquity),
        bearEquity.sub(bearTokenEquity),
        bullTokenEquity,
        bearTokenEquity
      ]);
  }


  /*
   * @notice Calculates k factor of selected token. K factor is the multiplier
   * that adjusts the leverage level to maintain 100% liquidty at all times.
   * @dev K factor is scaled 10^9. A K factor of 1 represents a 1:1 ratio of
   * bull and bear equity.
   * @param targetEquity The total euqity of the target bull token
   * @param bullEquity The total equity bull tokens
   * @param bearEquity The total equity bear tokens
   * @param totalEquity The total equity of bull and bear tokens
   * @return K factor
   */
  function getKFactor(
    uint256 targetEquity,
    uint256 bullEquity,
    uint256 bearEquity,
    uint256 totalEquity
  )
  public
  view
  returns(uint256) {
    //If either token has 0 equity k value is 0
    if(bullEquity  == 0 || bearEquity == 0) {
      return(0);
    }
    else {
      //Avoids divides by 0 error
      targetEquity = targetEquity > 0 ? targetEquity : 1;
      uint256 kFactor =
        totalEquity.mul(10**9).div(targetEquity.mul(2)) < kControl ?
        totalEquity.mul(10**9).div(targetEquity.mul(2)): kControl;
      return(kFactor);
    }
  }

  ///////////////////
  //ADMIN FUNCTIONS//
  ///////////////////
  function setLossLimit(uint256 amount) public onlyOwner() {
    lossLimit = amount;
  }
  function setkControl(uint256 amount) public onlyOwner() {
    kControl = amount;
  }
  function proposeVaultPriceAggregator(address account) public onlyOwner() {
    priceAggregatorPropose = account;
    priceAggregatorProposeTimestamp = block.timestamp;
  }
  function updateVaultPriceAggregator() public onlyOwner() {
    require(priceAggregatorPropose != address(0));
    require(priceAggregatorProposeTimestamp + proposeDelay <= block.timestamp);
    priceAggregator = priceAggregatorInterface(priceAggregatorPropose);
    priceAggregatorPropose = address(0);
  }

  function proposeProposeDelay(uint256 delay) public onlyOwner() {
    proposeDelayPropose = delay;
    proposeDelayTimestamp = block.timestamp;
  }
  function updateProposeDelay() public onlyOwner() {
    require(proposeDelayPropose != 0);
    require(proposeDelayTimestamp + proposeDelay <= block.timestamp);
    proposeDelay = proposeDelayPropose;
    proposeDelayPropose = 0;
  }
}

