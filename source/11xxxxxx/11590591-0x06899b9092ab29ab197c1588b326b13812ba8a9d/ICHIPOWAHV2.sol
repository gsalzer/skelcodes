// File: contracts/ichiPowahV2.sol

/**
 *Submitted for verification at Etherscan.io on 2020-09-12
*/

pragma solidity ^0.6.12;

library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

interface IPair {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function getReserves() external view returns (uint112, uint112, uint32);
}

interface IStake {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

interface IFarm {
    function userInfo(uint256 nr, address who) external view returns (uint256, uint256);
    function pendingIchi(uint256 nr, address who) external view returns (uint256);
    function pendingBonusIchi(uint256 _poolID, address _user) external view returns (uint256);
}

contract ICHIPOWAHV2 {
  using SafeMath for uint256;
  
  function name() public pure returns(string memory) { return "ICHIPOWAH"; }
  function symbol() public pure returns(string memory) { return "ICHIPOWAH"; }
  function decimals() public pure returns(uint8) { return 9; }  

  function totalSupply() public view returns (uint256) {
    IPair ichiETH_sushi = IPair(0x9cD028B1287803250B1e226F0180EB725428d069);
    IPair ichiETH_uni = IPair(0xd07D430Db20d2D7E0c4C11759256adBCC355B20C);

    IStake stake = IStake(0x70605a6457B0A8fBf1EEE896911895296eAB467E);
    IERC20 ichi = IERC20(0x903bEF1736CDdf2A537176cf3C64579C3867A881);
    
    (uint256 ichi1, , ) = ichiETH_uni.getReserves();
    (uint256 ichi2, , ) = ichiETH_sushi.getReserves();

    uint256 lp_totalIchi = ichi1.add(ichi2);

    uint256 xIchi_totalIchi = ichi.balanceOf(address(stake));

    return lp_totalIchi.mul(2).add(xIchi_totalIchi);
  }

  function getLpPowah(uint256 pid, IERC20 ichi, IPair pair, IFarm farm, address owner) public view returns (uint256) {
    uint256 lp_totalIchi = ichi.balanceOf(address(pair));
    uint256 lp_total = pair.totalSupply();
    uint256 lp_balance = pair.balanceOf(owner);

    // Add staked balance
    (uint256 lp_stakedBalance, ) = farm.userInfo(pid, owner);
    lp_balance = lp_balance.add(lp_stakedBalance);
    
    // LP voting power is 2x the users ICHI share in the pool.
    uint256 lp_powah = lp_totalIchi.mul(lp_balance).div(lp_total).mul(2);

    return lp_powah;
  }

  function balanceOf(address owner) public view returns (uint256) {
    IFarm farm = IFarm(0xcC50953A743B9CE382f423E37b07Efa6F9d9B000);

    IPair ichiETH_sushi = IPair(0x9cD028B1287803250B1e226F0180EB725428d069);
    IPair ichiETH_uni = IPair(0xd07D430Db20d2D7E0c4C11759256adBCC355B20C);

    IStake stake = IStake(0x70605a6457B0A8fBf1EEE896911895296eAB467E);
    IERC20 ichi = IERC20(0x903bEF1736CDdf2A537176cf3C64579C3867A881);

    uint256 one_lp_powah = getLpPowah(10, ichi, ichiETH_sushi, farm, owner);
    uint256 two_lp_powah = getLpPowah(5, ichi, ichiETH_uni, farm, owner);

    uint256 xIchi_totalIchi = ichi.balanceOf(address(stake));
    uint256 xIchi_balance = stake.balanceOf(owner);
    uint256 xIchi_total = stake.totalSupply();
    
    // xICHI voting power is the users ICHI share in the stake
    uint256 xIchi_powah = xIchi_totalIchi.mul(xIchi_balance).div(xIchi_total);
    
    uint256 lp_powah = one_lp_powah.add(two_lp_powah);

    return lp_powah.add(xIchi_powah);
  }

  function allowance(address, address) public pure returns (uint256) { return 0; }
  function transfer(address, uint256) public pure returns (bool) { return false; }
  function approve(address, uint256) public pure returns (bool) { return false; }
  function transferFrom(address, address, uint256) public pure returns (bool) { return false; }
}
