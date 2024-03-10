pragma solidity ^0.5.13;
pragma experimental ABIEncoderV2;

import "./MultiOwned.sol";
import "./ERC20.sol";
import "./BurnerRole.sol";

contract ERC20Burnable is MultiOwned, ERC20, BurnerRole {
    function addBurner(address _addr)
        public
        onlySelf
    {
        _addBurner(_addr);
    }

    function burn(uint256 _amount)
        public
        onlyBurner
        returns (bool success)
    {
        _burn(msg.sender, _amount);
        return true;
    }

    function burnFrom(address _from, uint256 _amount)
        public
        ifBurner(_from)
        returns (bool success)
    {
        _burn(_from, _amount);
        _approve(_from, msg.sender, allowed[_from][msg.sender].sub(_amount));
        return true;
    }

    function removeBurner(address _addr)
        public
        onlySelf
    {
        _removeBurner(_addr);
    }

    function _burn(address _from, uint256 _amount)
        internal
    {
        balances[_from] = balances[_from].sub(_amount);
        if (balances[_from] == 0) holders.remove(_from);
        tokenTotalSupply = tokenTotalSupply.sub(_amount);

        emit Transfer(_from, address(0), _amount);
        emit Burn(_from, _amount);
    }
}

