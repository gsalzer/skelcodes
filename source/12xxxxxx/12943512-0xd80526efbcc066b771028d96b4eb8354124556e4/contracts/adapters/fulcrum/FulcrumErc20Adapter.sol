// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "../../interfaces/ITokenAdapter.sol";
import "../../interfaces/FulcrumInterfaces.sol";
import "../../interfaces/IERC20Metadata.sol";
import "../../interfaces/IERC20.sol";
import "../../libraries/LowGasSafeMath.sol";
import "../../libraries/TransferHelper.sol";
import "../../libraries/SymbolHelper.sol";
import "../../libraries/MinimalSignedMath.sol";


contract FulcrumErc20Adapter is IErc20Adapter {
  using MinimalSignedMath for uint256;
  using LowGasSafeMath for uint256;
  using TransferHelper for address;
  using SymbolHelper for address;

/* ========== Constants ========== */

  IBZX internal constant bzx = IBZX(0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f);
  uint256 internal constant weiPercentPrecision = 1e20;

/* ========== Storage ========== */

  address public override underlying;

  address public override token;

/* ========== Initializer ========== */

  function initialize(address _underlying, address _token) public virtual {
    require(underlying == address(0) && token == address(0), "initialized");
    require(_underlying != address(0) && _token != address(0), "bad address");
    underlying = _underlying;
    token = _token;
    _underlying.safeApproveMax(token);
  }

/* ========== Metadata ========== */

  function name() external view override returns (string memory) {
    return string(abi.encodePacked(
      "Fulcrum ",
      underlying.getSymbol(),
      " Adapter"
    ));
  }

  function availableLiquidity() public view override returns (uint256) {
    (,,,uint256 interestUnPaid, uint256 interestFeePercent,) = bzx.getLenderInterestData(
      token,
      underlying
    );

    interestUnPaid = interestUnPaid
      .mul(weiPercentPrecision.sub(interestFeePercent))
      / weiPercentPrecision;
    return IERC20(underlying).balanceOf(token).add(interestUnPaid);
  }

/* ========== Conversion Queries ========== */

  function toUnderlyingAmount(uint256 tokenAmount) public view override returns (uint256) {
    return tokenAmount.mul(IToken(token).tokenPrice()) / uint256(1e18);
  }

  function toWrappedAmount(uint256 underlyingAmount) public view override returns (uint256) {
    return underlyingAmount.mul(1e18) / IToken(token).tokenPrice();
  }

/* ========== Performance Queries ========== */

  function getAPR() public view virtual override returns (uint256 apr) {
    return IToken(token).supplyInterestRate() / 100;
  }

  function getHypotheticalAPR(int256 liquidityDelta) external view virtual override returns (uint256 apr) {
    IToken iToken = IToken(token);
    return iToken.totalSupplyInterestRate(
      iToken.totalAssetSupply().add(liquidityDelta)
    ) / 100;
  }

  function getRevenueBreakdown()
    external
    view
    override
    returns (
      address[] memory assets,
      uint256[] memory aprs
    )
  {
    assets = new address[](1);
    aprs = new uint256[](1);
    assets[0] = underlying;
    aprs[0] = getAPR();
  }

/* ========== Caller Balance Queries ========== */

  function balanceWrapped() external view virtual override returns (uint256) {
    return IERC20(token).balanceOf(msg.sender);
  }

  function balanceUnderlying() external view virtual override returns (uint256) {
    return IToken(token).assetBalanceOf(msg.sender);
  }

/* ========== Token Actions ========== */

  function deposit(uint256 amountUnderlying) external virtual override returns (uint256 amountMinted) {
    underlying.safeTransferFrom(msg.sender, address(this), amountUnderlying);
    amountMinted = IToken(token).mint(msg.sender, amountUnderlying);
    require(amountMinted > 0, "IToken: Mint failed");
  }

  function withdraw(uint256 amountToken) external virtual override returns (uint256 amountReceived) {
    address _token = token;
    _token.safeTransferFrom(msg.sender, address(this), amountToken);
    amountReceived = IToken(_token).burn(msg.sender, amountToken);
    require(amountReceived > 0, "IToken: Burn failed");
  }

  function withdrawAll() external virtual override returns (uint256 amountReceived) {
    address _token = token;
    uint256 amountToken = IERC20(_token).balanceOf(msg.sender);
    _token.safeTransferFrom(msg.sender, address(this), amountToken);
    amountReceived = IToken(_token).burn(msg.sender, amountToken);
    require(amountReceived > 0, "IToken: Burn failed");
  }

  function withdrawUnderlying(uint256 amountUnderlying) external virtual override returns (uint256 amountBurned) {
    amountBurned = amountUnderlying.mul(1e18).divCeil(IToken(token).tokenPrice());
    token.safeTransferFrom(msg.sender, address(this), amountBurned);
    require(IToken(token).burn(msg.sender, amountBurned) > 0, "IToken: Burn failed");
  }

  function withdrawUnderlyingUpTo(uint256 amountUnderlying) external virtual override returns (uint256 amountReceived) {
    uint256 amountAvailable = availableLiquidity();
    amountReceived = amountAvailable < amountUnderlying ? amountAvailable : amountUnderlying;
    uint256 amountBurned = amountReceived.mul(1e18) / IToken(token).tokenPrice();
    token.safeTransferFrom(msg.sender, address(this), amountBurned);
    require(IToken(token).burn(msg.sender, amountBurned) > 0, "IToken: Burn failed");
  }
}
