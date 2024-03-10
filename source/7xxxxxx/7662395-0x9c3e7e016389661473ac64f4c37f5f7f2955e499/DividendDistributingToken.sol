pragma solidity 0.5.7;

import "./SafeMath.sol";
import "./ERC20.sol";

import "./LoanEscrow.sol";

/**
 * @title DividendDistributingToken
 * @dev An ERC20-compliant token that distributes any Dai it receives to its token holders proportionate to their share.
 *
 * Implementation based on: https://blog.pennyether.com/posts/realtime-dividend-token.html#the-token
 *
 * The user is responsible for when they transact tokens (transacting before a dividend payout is probably not ideal).
 *
 * `TokenizedProperty` inherits from `this` and is the front-facing contract representing the rights / ownership to a property.
 *
 * NOTE: if the owner(s) of a `TokenizedProperty` wish to update `LoanEscrow` behavior (i.e. changing the ERC20 token funds are raised in, or changing loan behavior),
 * some options are: (a) `untokenize` and re-deploy the updated `TokenizedProperty`, or (b) deploy an independent contract acting as the updated dividend distribution vehicle.
 */
contract DividendDistributingToken is ERC20, LoanEscrow {
  using SafeMath for uint256;

  uint256 public constant POINTS_PER_DAI = uint256(10) ** 32;

  uint256 public pointsPerToken = 0;
  mapping(address => uint256) public credits;
  mapping(address => uint256) public lastPointsPerToken;

  event DividendsCollected(address indexed collector, uint256 amount);
  event DividendsDeposited(address indexed depositor, uint256 amount);

  function collectOwedDividends(address _account) public {
    creditAccount(_account);

    uint256 _dai = credits[_account].div(POINTS_PER_DAI);
    credits[_account] = 0;

    pull(_account, _dai, false);
    emit DividendsCollected(_account, _dai);
  }

  function depositDividends() public {  // dividends
    uint256 amount = dai.allowance(msg.sender, address(this));

    uint256 fee = amount.div(100);
    dai.safeTransferFrom(msg.sender, blockimmo(), fee);

    deposit(msg.sender, amount.sub(fee));

    // partially tokenized properties store the "non-tokenized" part in `this` contract, dividends not disrupted
    uint256 issued = totalSupply().sub(unissued());
    pointsPerToken = pointsPerToken.add(amount.sub(fee).mul(POINTS_PER_DAI).div(issued));

    emit DividendsDeposited(msg.sender, amount);
  }

  function unissued() public view returns (uint256) {
    return balanceOf(address(this));
  }

  function creditAccount(address _account) internal {
    uint256 amount = balanceOf(_account).mul(pointsPerToken.sub(lastPointsPerToken[_account]));

    uint256 _credits = credits[_account].add(amount);
    if (credits[_account] != _credits)
      credits[_account] = _credits;

    if (lastPointsPerToken[_account] != pointsPerToken)
      lastPointsPerToken[_account] = pointsPerToken;
  }
}

