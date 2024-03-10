// SPDX-License-Identifier: DOGE WORLD
pragma solidity ^0.8.0;

import "../SafelyOwned.sol";
import "../EnumerableSet.sol";
import "./IDogey.sol";
import "../IERC20.sol";

contract Dogey is SafelyOwned, IDogey
{
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet doges;

    function doge(uint256 _index) public override view returns (IERC20) { return IERC20(doges.at(_index)); }
    function isDogey(IERC20 _doge) public override view returns (bool) { return doges.contains(address(_doge)); }
    function dogeCount() public override view returns (uint256) { return doges.length(); }
    
    function dogeify(IERC20 _doge, bool _isDogey) public ownerOnly()
    {
        if (_isDogey && !doges.add(address(_doge))) { return; }
        if (!_isDogey && !doges.remove(address(_doge))) { return; }        
        emit Dogeification(_doge, _isDogey);
    }
}
