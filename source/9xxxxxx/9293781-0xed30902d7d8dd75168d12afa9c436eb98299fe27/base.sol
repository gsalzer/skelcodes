/// base.sol -- basic ERC20 implementation

// Copyright (C) 2015, 2016, 2017  DappHub, LLC

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.4.23;

import "erc20.sol";
import "math.sol";

contract TokenBase is ERC20, DSMath {
    uint256                                            _supply;
    mapping (address => uint256)                       _balances;
    mapping (address => mapping (address => uint256))  _approvals;

    constructor(uint supply) public {
        _balances[msg.sender] = supply;
        _supply = supply;
    }

    function totalSupply() external view returns (uint) {
        return _supply;
    }
    function balanceOf(address src) external view returns (uint) {
        return _balances[src];
    }
    function allowance(address src, address guy) external view returns (uint) {
        return _approvals[src][guy];
    }

    function transfer(address dst, uint wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        if (src != msg.sender) {
            _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad); //Revert if funds insufficient. 
        }
        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);

        emit Transfer(src, dst, wad);

        return true;
    }

    function approve(address guy, uint wad) external returns (bool) {
        _approvals[msg.sender][guy] = wad;

        emit Approval(msg.sender, guy, wad);

        return true;
    }

    event Mint(address guy, uint wad);
    event Burn(address guy, uint wad);

    function mint(uint wad) internal { //Note: _supply constant
        _balances[msg.sender] = add(_balances[msg.sender], wad); 
        emit Mint(msg.sender, wad);
    }

    function burn(uint wad) internal { //Note: _supply constant
        _balances[msg.sender] = sub(_balances[msg.sender], wad); //Revert if funds insufficient.
        emit Burn(msg.sender, wad);
    }
    
}
