// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/math/Math.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import "./interfaces/IChainLinkFeed.sol";
import "./interfaces/IUniswapV2SlidingOracle.sol";
import "./interfaces/Keep3r/IKeep3rV1Mini.sol";

contract Keep3rV1HelperNewCustom is Ownable{
    using SafeMath for uint;

    IChainLinkFeed public constant FASTGAS = IChainLinkFeed(0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C);
    IKeep3rV1Mini public RLR = IKeep3rV1Mini(0x5b3F693EfD5710106eb2Eac839368364aCB5a70f);
    IUniswapV2SlidingOracle public UV2SO = IUniswapV2SlidingOracle(0xA54b8DFB9B14357BF9BF8209Cb4fCe74BFeC660F);
    address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    uint constant public MAX = 11;
    uint constant public BASE = 10;
    uint constant public SWAP = 300000;
    uint constant public TARGETBOND = 200e18;

    function quote(uint eth) public view returns (uint) {
        return UV2SO.current(address(WETH), eth, address(RLR));
    }

    function setOracle(address oracle) public onlyOwner {
        UV2SO = IUniswapV2SlidingOracle(oracle);
    }

    function setToken(address keepertoken) public onlyOwner{
        RLR = IKeep3rV1Mini(keepertoken);
    }

    function getFastGas() external view returns (uint) {
        return uint(FASTGAS.latestAnswer());
    }

    function bonds(address keeper) public view returns (uint) {
        return RLR.bonds(keeper, address(RLR)).add(RLR.votes(keeper));
    }

    function getQuoteLimitFor(address origin, uint gasUsed) public view returns (uint) {
        uint _min = quote((gasUsed.add(SWAP)).mul(uint(FASTGAS.latestAnswer())));
        uint _boost = _min.mul(MAX).div(BASE);
        uint _bond = Math.min(bonds(origin), TARGETBOND);
        return Math.max(_min, _boost.mul(_bond).div(TARGETBOND));
    }

    function getQuoteLimit(uint gasUsed) external view returns (uint) {
        return getQuoteLimitFor(tx.origin, gasUsed);
    }
}

