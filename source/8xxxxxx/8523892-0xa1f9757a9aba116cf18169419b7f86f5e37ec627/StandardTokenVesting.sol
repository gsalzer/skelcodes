pragma solidity 0.4.24;

import "./FLXCToken.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

/** @title StandardTokenVesting
  * @dev A token holder contract that can release its token balance gradually like a
  * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the owner.
  */
contract StandardTokenVesting is Ownable {
  using SafeMath for uint256;

  event Released(uint256 amount);
  event Revoked();

  // beneficiary of tokens after they are released
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;


  /** @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _start the time (as Unix time) at which point vesting starts
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _revocable whether the vesting is revocable or not
   */
  constructor(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) public {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    owner = msg.sender;
    cliff = _start.add(_cliff);
    start = _start;
  }

  /** @notice Transfers vested tokens to beneficiary.
    * @param token ERC20 token which is being vested
    */
  function release(FLXCToken token) public returns (bool){
    uint256 unreleased = releasableAmount(token);
    require(unreleased > 0);
    released[token] = released[token].add(unreleased);

    token.transfer(beneficiary, unreleased);
    emit Released(unreleased);
    return true;
  }

  /** @notice Allows the owner to revoke the vesting. Tokens already vested
    * remain in the contract, the rest are returned to the owner.
    * @param token ERC20 token which is being vested
    */
  function revoke(FLXCToken token) public onlyOwner returns(bool) {
    require(revocable);
    require(!revoked[token]);
    uint256 balance = token.balanceOf(this);
    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;
    token.transfer(owner, refund);
    emit Revoked();

    return true;
  }

  /** @dev Calculates the amount that has already vested but hasn't been released yet.
    * @param token ERC20 token which is being vested
    */
  function releasableAmount(FLXCToken token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

  /** @dev Calculates the amount that has already vested.
    * @param token FLXC Token which is being vested
    */
  function vestedAmount(FLXCToken token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (block.timestamp < cliff) {
      return 0;
    } else if (block.timestamp >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(block.timestamp.sub(start)).div(duration);
    }
  }
}

