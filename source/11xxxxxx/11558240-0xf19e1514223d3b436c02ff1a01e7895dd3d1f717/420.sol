// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./Aml.sol";

contract Juicy420 is ERC20, Ownable, ERC20Burnable, Aml {

	constructor() ERC20("Juicy420", "420", 0) {
        _mint(msg.sender, 23809523);
    }

    function transfer (address _to, uint256 _value)
          public
          override
          notRestricted(_to)
          returns (bool success)
      {
        success = super.transfer(_to, _value);
      }

      function transferFrom (address _from, address _to, uint256 _value)
          public
          override
          notRestricted(_to)
          returns (bool success)
      {
        success = super.transferFrom(_from, _to, _value);
      }
}
