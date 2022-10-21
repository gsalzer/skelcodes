pragma solidity 0.5.11;
interface ERC20Interface {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}
interface CurveInterface {
    function exchange(int128, int128, uint256, uint256, uint256) external;
}
contract CurveSwapperPOC {
  ERC20Interface internal constant _CDAI = ERC20Interface(
    0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643
  );
  ERC20Interface internal constant _CUSDC = ERC20Interface(
    0x39AA39c021dfbaE8faC545936693aC917d5E7563
  );
  CurveInterface internal constant _CURVE = CurveInterface(
    0x2e60CF74d81ac34eB21eEff58Db4D385920ef419
  );
  constructor() public {
    require(_CUSDC.approve(address(_CURVE), uint256(-1)));
  }
  function swap() external {
    uint256 cUSDCBalance = _CUSDC.balanceOf(msg.sender);
    require(_CUSDC.transferFrom(msg.sender, address(this), cUSDCBalance));
    _CURVE.exchange(1, 0, cUSDCBalance, cUSDCBalance, now + 1);
    uint256 cDaiBalance = _CDAI.balanceOf(address(this));
    require(_CDAI.transfer(msg.sender, cDaiBalance));
  }
}
