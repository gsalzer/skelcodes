pragma solidity ^0.5.10;

import "./MoonGold.sol";

contract MoonGoldHodl { 
    using SafeMath for uint256;

    MoonGold moonGold;
    ERC20Interface MoondayToken;
    uint256 internal moondayTokenAmount = 0;
    uint256 internal moonGoldTokenAmount = 0;

    address payable public moonGoldAddress;

    constructor(
        address payable _moonGoldAddress,
        address _MoondayToken
        ) public {
        moonGold = MoonGold(_moonGoldAddress);
        MoondayToken = ERC20Interface(_MoondayToken);
        moonGoldAddress = _moonGoldAddress;
    }

    function buy()
        public
    {
        uint256 _moondayTokenAmount = MoondayToken.balanceOf(address(this));

        require(_moondayTokenAmount > 0, "Invalid Balance");
        MoondayToken.approve(moonGoldAddress, _moondayTokenAmount);
		moonGold.buy(_moondayTokenAmount, address(0));
    }

    function sell()
    public 
    {
        uint256 _moonGoldTokenAmount = moonGold.balanceOf(address(this));

        moonGold.sell(_moonGoldTokenAmount);
    }
}
