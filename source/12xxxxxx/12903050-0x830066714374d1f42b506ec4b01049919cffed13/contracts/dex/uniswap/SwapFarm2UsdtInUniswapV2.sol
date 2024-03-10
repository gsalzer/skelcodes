pragma solidity >=0.5.17 <=0.8.0;


import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './SwapInUniswapV2.sol';

interface ISwapFarm2UsdtInUniswapV2 {
    function swapFarm2UsdtInUniswapV2(
        uint256 _amount,
        uint256 _minReturn,
        uint256 _timeout
    ) external returns (uint256[] memory);
}

contract SwapFarm2UsdtInUniswapV2 is SwapInUniswapV2 {
    address private FARM_ADDRESS = address(0xa0246c9032bC3A600820415aE600c6388619A14D);
    address private WETH_ADDRESS = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address private USDT_ADDRESS = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    /**
     * farm => usdt
     */
    function swapFarm2UsdtInUniswapV2(
        uint256 _amount,
        uint256 _minReturn,
        uint256 _timeout
    ) internal returns (uint256[] memory) {
        require(_amount > 0, '_amount>0');
        require(_minReturn >= 0, '_minReturn>=0');
        address[] memory _path = new address[](3);
        _path[0] = FARM_ADDRESS;
        _path[1] = WETH_ADDRESS;
        _path[2] = USDT_ADDRESS;
        return this.swap(FARM_ADDRESS, _amount, _minReturn, _path, address(this), _timeout);
    }
}

