pragma solidity =0.6.6;

import './OneDayWindowOracle.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IBackedPriceProvider.sol";

interface IERC20Extented is IERC20 {
    function decimals() external view returns (uint8);
}

contract BackedPriceProvider is IBackedPriceProvider  {

    address public immutable oracleA;
    address public immutable oracleB;
    address public immutable weth;


    constructor(address _oracleA, address _oracleB, address _weth) public {
       oracleA = _oracleA;
       oracleB = _oracleB;
       weth = _weth;
    }

    function update() external {
       OneDayWindowOracle(oracleA).update();
       OneDayWindowOracle(oracleB).update();
    }
    
    function getPrice(
        address base
    ) external override view returns (uint256 price) {
        require(base != weth, 'should not be crossToken');
        OneDayWindowOracle a = OneDayWindowOracle(oracleA);
        OneDayWindowOracle b = OneDayWindowOracle(oracleB);
        if(a.token0() == base || a.token1() == base){
            uint amount = a.consult(base, 10 ** uint256(IERC20Extented(base).decimals()));
            price = b.consult(weth, amount);
        }
        if(b.token0() == base || b.token1() == base){
            uint amount = b.consult(base, 10 ** uint256(IERC20Extented(base).decimals()));
            price = a.consult(weth, amount);
            return 1e18*1e6/price;
        }
    }
}
