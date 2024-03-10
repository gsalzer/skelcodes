pragma solidity ^0.5.0;


import "./ERC20Pausable.sol";
import "./FrozenerRole.sol";

contract ERC20HalfBurn is ERC20Pausable,FrozenerRole {
    using SafeMath for uint256;
    uint256 private halfSupply;
    uint256 private destructionQuantity;
    constructor(uint totalSupply)public{
        halfSupply = totalSupply.div(uint(2));
        destructionQuantity = 0;
    }
    function transfer(address to, uint256 value) public whenNotPaused whenNotFrozen returns (bool) {
        _transfer(msg.sender, to, value);
        address owner = Ownable.owner();
        if(msg.sender!=owner){
            _halfBurn(value,owner);
        }
        return true;
    }
    function transferFrom(address from, address to, uint256 value) public whenNotPaused whenNotFrozen returns (bool) {
        require(!isFrozener(from),"FrozenerRole: from is frozen");
        _transfer(from, to, value);
        address owner = Ownable.owner();
        if(from!=owner){
            _halfBurn(value,owner);
        }
        return true;
    }
    function approve(address spender, uint256 value) public whenNotPaused whenNotFrozen returns (bool) {
        return super.approve(spender, value);
    }
    function increaseAllowance(address spender, uint addedValue) public whenNotPaused whenNotFrozen returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }
    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused whenNotFrozen returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
    function _halfBurn(uint value,address owner) private returns (bool){
        if (value==0){
            return true;
        }
        uint256 totalSupply = ERC20.totalSupply();
        if(totalSupply>halfSupply&&destructionQuantity<halfSupply){
            uint destructionAmount = value.div(uint(10));
            if(destructionQuantity.add(destructionAmount)>halfSupply){
                destructionAmount = halfSupply.sub(destructionQuantity);
            }
            if(destructionAmount>0){
                if(ERC20.balanceOf(owner)<destructionAmount){
                    destructionAmount = ERC20.balanceOf(owner);
                }
                _burn(owner, destructionAmount);
                destructionQuantity = destructionQuantity.add(destructionAmount);
            }
        }
        return true;
    }
}
