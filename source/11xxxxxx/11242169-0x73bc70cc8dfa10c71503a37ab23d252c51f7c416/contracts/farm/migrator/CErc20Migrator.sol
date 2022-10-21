// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./CTokenInterface.sol";
import "../../token/PERC20.sol";

//第一次进行cERC20迁移
contract CErc20Migrator {

    address public breeder;
    uint256 public notBeforeBlock;
    address targetToken;

    constructor(address _breeder, uint256 _notBeforeBlock, address _targetToken) public {
        breeder = _breeder;
        notBeforeBlock = _notBeforeBlock;
        targetToken = _targetToken;
    }


    function replaceMigrate(CTokenInterface oldLpToken) external returns (PERC20, uint){

        require(msg.sender == breeder, "not from breeder");
        require(block.number >= notBeforeBlock, "too early to migrate");

        PERC20 newLpToken = PERC20(targetToken);
        require(oldLpToken.underlying() == newLpToken.underlying(), "not match");

        address sender = msg.sender;
        uint256 lp = oldLpToken.balanceOf(sender);

        if (lp == 0) {
            return (newLpToken, 0);
        }

        // 从cToken中赎回相应的代币
        oldLpToken.transferFrom(sender, address(this), lp);
        oldLpToken.redeem(lp);

        //获得赎回了多少代币
        uint redeemBal = 0;
        address underlying = oldLpToken.underlying();

        IERC20 token = IERC20(underlying);
        redeemBal = token.balanceOf(address(this));

        // 将赎回的代币，抵押到wePiggy中，生成pToken
        token.approve(address(newLpToken), redeemBal);
        newLpToken.mintForMigrate(redeemBal, lp);

        // 获得抵押生成的pToken有多少
        uint mintBal = newLpToken.balanceOf(address(this));

        //将余额转到挖矿合约
        newLpToken.transferFrom(address(this), sender, mintBal);

        //返回占比
        return (newLpToken, mintBal);
    }

    function migrate(CTokenInterface oldLpToken) external returns (PERC20, uint){

        require(msg.sender == breeder, "not from breeder");
        require(block.number >= notBeforeBlock, "too early to migrate");

        PERC20 newLpToken = PERC20(targetToken);
        require(oldLpToken.underlying() == newLpToken.underlying(), "not match");

        address sender = msg.sender;
        uint256 lp = oldLpToken.balanceOf(sender);

        if (lp == 0) {
            return (newLpToken, 0);
        }

        // 从cToken中赎回相应的代币
        oldLpToken.transferFrom(sender, address(this), lp);
        oldLpToken.redeem(lp);

        //获得赎回了多少代币
        uint redeemBal = 0;
        address underlying = oldLpToken.underlying();

        IERC20 token = IERC20(underlying);
        redeemBal = token.balanceOf(address(this));

        // 将赎回的代币，抵押到wePiggy中，生成pToken
        token.approve(address(newLpToken), redeemBal);
        newLpToken.mint(redeemBal);

        // 获得抵押生成的pToken有多少
        uint mintBal = newLpToken.balanceOf(address(this));

        //将余额转到挖矿合约
        newLpToken.transferFrom(address(this), sender, mintBal);

        //返回占比
        return (newLpToken, mintBal);
    }
}




