pragma solidity ^0.5.8;

import "./ERC20Mintable.sol";
import "./ERC20Burnable.sol";
import "./ERC20Metadata.sol";
import "./ERC20Detailed.sol";


/**
 @title TokenTITANT - ERC20 Token Contract

 Developed by https://github.com/pironmind
 Powered by ILIK
 License: see https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/LICENSE
*/
contract TokenTITANT is
ERC20Detailed,
ERC20Burnable,
ERC20Mintable,
ERC20Metadata
{

    /**
    * Constructor
    */
    constructor(
        string  memory _name,
        string  memory _symbol,
        uint256 _supply,
        uint8   _decimals,
        address _owner,
        string  memory _website
    )
    public
    ERC20Detailed(_name, _symbol,_decimals)
    ERC20Metadata(_website)
    {
        if (_owner != address(0)) {
            mint(_owner, _supply * 10**uint256(decimals()));
            transferOwnership(_owner);
        } else {
            mint(owner(), _supply * 10**uint256(decimals()));
        }
    }
}

