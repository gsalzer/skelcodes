pragma solidity 0.5.11;


interface IERC20 {
  function balanceOf(address) external view returns (uint256);
}


contract DepositChecker {
  IERC20 internal constant _DAI = IERC20(
    0x6B175474E89094C44Da98b954EedeAC495271d0F // mainnet
  );

  IERC20 internal constant _USDC = IERC20(
    0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 // mainnet
  );
  
  function balancesOf(
    address[] calldata relays
  ) external view returns (
    uint256[] memory daiBalances,
    uint256[] memory usdcBalances
  ) {
    daiBalances = new uint256[](relays.length);
    usdcBalances = new uint256[](relays.length);
    for (uint256 i = 0; i < relays.length; i++) {
      address relay = relays[i];
      daiBalances[i] = _DAI.balanceOf(relay);
      usdcBalances[i] = _USDC.balanceOf(relay);
    }
  }
}
