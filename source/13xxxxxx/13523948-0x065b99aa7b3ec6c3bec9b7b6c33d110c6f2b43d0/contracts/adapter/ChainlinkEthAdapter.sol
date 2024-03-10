// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@mochifi/library/contracts/Float.sol";
import "../interfaces/IGovernanceOwned.sol";
import "../interfaces/ICSSRAdapter.sol";
import "../interfaces/ICSSRRouter.sol";

contract ChainlinkEthAdapter is ICSSRAdapter {
    IGovernanceOwned public immutable owned;
    ICSSRRouter public immutable cssrRouter;
    address public immutable weth;

    mapping(address => AggregatorV3Interface) public feed;

    modifier onlyGov() {
        require(msg.sender == owned.governance(), "!gov");
        _;
    }

    constructor(address _owned, address _cssr, address _weth) {
        owned = IGovernanceOwned(_owned);
        cssrRouter = ICSSRRouter(_cssr);
        weth = _weth;
    }

    function update(address _asset, bytes calldata _data)
        external
        override
        returns (float memory)
    {
        return getPrice(_asset);
    }

    function setFeed(address[] calldata _assets, address[] calldata _feeds) external onlyGov {
        for(uint256 i = 0; i<_assets.length; i++) {
            feed[_assets[i]] = AggregatorV3Interface(_feeds[i]);
        }
    }

    function support(address _asset) external view override returns (bool) {
        return address(feed[_asset]) != address(0);
    }

    function getPrice(address _asset)
        public
        view
        override
        returns (float memory)
    {
        float memory ethPrice = cssrRouter.getPrice(weth);
        (, int256 price, , , ) = feed[_asset].latestRoundData();
        uint256 decimalSum = feed[_asset].decimals() +
            IERC20Metadata(_asset).decimals();
        if (decimalSum > 18) {
            return
                float({
                    numerator: uint256(price)* ethPrice.numerator,
                    denominator: (ethPrice.denominator) * 10**(decimalSum - 18)
                });
        } else {
            return
                float({
                    numerator: (uint256(price) *ethPrice.numerator) * 10**(18 - decimalSum),
                    denominator: ethPrice.denominator
                });
        }
    }

    function getLiquidity(address _asset)
        external
        view
        override
        returns (uint256)
    {
        revert("chainlink adapter does not support liquidity");
    }
}

