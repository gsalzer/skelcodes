import "./ERC20.sol";
import "./set.sol";

abstract contract ERC20WithHoldersSet is ERC20 {
    using AddressSet for AddressSet.Set;

    AddressSet.Set holders;

    function checkRemove(address addr) private { if(_balances[addr] == 0) holders.remove(addr); }
    function checkAdd(address addr) private { if(_balances[addr] > 0) holders.insert(addr); }
    function _transfer(address sender, address recipient, uint256 amount) internal override virtual {
         ERC20._transfer(sender, recipient, amount);
         checkRemove(sender);
          checkAdd(recipient);
    }
    function _mint(address account, uint256 amount) internal override virtual {
        ERC20._mint(account, amount);
       checkAdd(account);
    }
    function _burn(address account, uint256 amount) internal override virtual {
        ERC20._burn(account, amount);
       checkRemove(account);
    }

    
}
