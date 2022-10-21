pragma solidity ^0.4.25;


interface CERC20 {
    function mint(uint mintAmount) returns (uint);
    function redeem(uint redeemTokens) returns (uint);
    function supplyRatePerBlock() returns (uint);
    function exchangeRateCurrent() returns (uint);
    function balanceOf(address _owner) public view returns (uint balance);
    function balanceOfUnderlying(address account) returns (uint);
}

interface CEther {
    function mint() payable;
    function redeem(uint redeemTokens) returns (uint);
    function supplyRatePerBlock() returns (uint);
    function balanceOf(address _owner) public view returns (uint balance);
    function balanceOfUnderlying(address account) returns (uint);
}
