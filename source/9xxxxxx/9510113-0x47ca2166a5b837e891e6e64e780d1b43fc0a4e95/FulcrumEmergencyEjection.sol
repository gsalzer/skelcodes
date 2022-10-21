pragma solidity ^0.5.16;

contract Erc20 {
    function transferFrom(address from, address to, uint256 value) external returns(bool);
}

contract iErc20 is Erc20 {
    function tokenPrice() view external returns(uint256);
    function totalAssetBorrow() view external returns(uint256);
    function totalAssetSupply() view external returns(uint256);
    function burn(address receiver, uint256 burnAmount) external returns(uint256);
}

contract FulcrumEmergencyEjection {
    iErc20 constant iDAI = iErc20(0x493C57C4763932315A328269E1ADaD09653B9081);

    function corona(uint256 dustAmount, uint256 userBalance) external returns(uint256 outAmount) {
        uint256 DAIAmount = iDAI.totalAssetSupply() - iDAI.totalAssetBorrow();
        if (DAIAmount > dustAmount) {
            uint256 iDAITokenPrice = iDAI.tokenPrice();
            uint256 availableBurnAmount = DAIAmount * 1e18 / iDAITokenPrice;
            availableBurnAmount = userBalance < availableBurnAmount ? userBalance : availableBurnAmount;
            iDAI.transferFrom(msg.sender, address(this), availableBurnAmount);
            return iDAI.burn(msg.sender, availableBurnAmount);
        }
        return 0;
    }
}
