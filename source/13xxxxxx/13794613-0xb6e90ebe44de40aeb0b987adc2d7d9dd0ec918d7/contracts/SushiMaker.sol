// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./WethMaker.sol";

/// @notice Contract for selling weth to sushi. Deploy on mainnet.
contract SushiMaker is WethMaker {

    event Serve(uint256 amount);

    address public immutable sushi;
    address public immutable xSushi;

    constructor(
        address _owner,
        address _user,
        address _factory,
        address _weth,
        address _sushi,
        address _xSushi
    ) WethMaker(_owner, _user, _factory, _weth) {
        sushi = _sushi;
        xSushi = _xSushi;
    }

    function buySushi(uint256 amountIn, uint256 minOutAmount) external onlyTrusted returns (uint256 amountOut) {
        amountOut = _swap(weth, sushi, amountIn, xSushi);
        if (amountOut < minOutAmount) revert SlippageProtection();
        emit Serve(amountOut);
    }

    function sweep(uint256 amount) external onlyTrusted {
        IERC20(sushi).transfer(xSushi, amount);
        emit Serve(amount);
    }

    // Don't allow direct withdrawals on mainnet.
    function withdraw(address, address, uint256) external pure override {
        revert();
    }

    // In case we receive any unwrapped ethereum we can call this.
    function wrapEth() external {
        weth.call{value: address(this).balance}("");
    }

}

