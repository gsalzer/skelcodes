// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./uniswap/IUniswapV2Router02.sol";

/*
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";
import "https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol";
*/

contract FundsRouter is Ownable {
    using SafeMath for uint256;

    uint8 public percentageComet = 56;
    uint8 public percentageTube = 14;
    uint8 public percentageCashBack = 30;

    IUniswapV2Router02 internal UniswapV2Router02;
    address internal _tube;
    address internal _must;
    address internal _cashback;
    address payable internal _cometGenerator;

    constructor(
        address router,
        address must,
        address tube,
        address cashback,
        address payable cometGenerator
    ) public Ownable() {
        _tube = tube;
        _must = must;
        _cashback = cashback;
        UniswapV2Router02 = IUniswapV2Router02(router);
        _cometGenerator = cometGenerator;
    }

    function updateTube(address tube) public onlyOwner {
        _tube = tube;
    }

    function updateMust(address must) public onlyOwner {
        _must = must;
    }

    function updateCometGenerator(address payable newCometGenerator)
        public
        onlyOwner
    {
        _cometGenerator = newCometGenerator;
    }

    function tube() public view returns (address) {
        return _tube;
    }

    function must() public view returns (address) {
        return _must;
    }

    function cashback() public view returns (address) {
        return _cashback;
    }

    function cometGenerator() public view returns (address) {
        return _cometGenerator;
    }

    function updatePercentage(
        uint8 newPercentageComet,
        uint8 newPercentageTube,
        uint8 newPercentageCashback
    ) public onlyOwner {
        require(
            (newPercentageComet + newPercentageTube + newPercentageCashback) ==
                100,
            "invalid percentage"
        );
        percentageComet = newPercentageComet;
        percentageTube = newPercentageTube;
        percentageCashBack = newPercentageCashback;
    }

    receive() external payable {
        uint256 _valueComet = msg.value.mul(percentageComet).div(100);
        uint256 _valueTube = msg.value.mul(percentageTube).div(100);
        uint256 _valueCashback = msg.value.mul(percentageCashBack).div(100);

        // Send to comet generator
        _cometGenerator.transfer(_valueComet);

        // Swap Eth to Must and send it to Tube
        address[] memory path = new address[](2);
        path[0] = UniswapV2Router02.WETH();

        path[1] = address(_must);
        UniswapV2Router02.swapExactETHForTokens{value: _valueTube}(
            0,
            path,
            address(_tube),
            block.timestamp
        );

        // Swap Eth to Must and send it to Cashback
        UniswapV2Router02.swapExactETHForTokens{value: _valueCashback}(
            0,
            path,
            address(_cashback),
            block.timestamp
        );
    }
}

