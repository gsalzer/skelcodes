pragma solidity ^0.4.24;

import "ERC20Proxy.sol";
import "ERC20Store.sol";
import "ERC20Authorization.sol";

contract ERC20MintBurn is ERC20Authorization, IERC20Mintable, IERC20Burnable {

    ERC20Proxy public erc20Proxy;
    ERC20Store public erc20Store;

    event Mint(address[] _investors, uint256[] _values, uint256[] _timestamps);

    constructor (
        address _erc20Proxy, 
        address _erc20Store, 
        address _proxy
    ) 
        public 
        ERC20Authorization(_proxy) 
    {
        erc20Proxy = ERC20Proxy(_erc20Proxy);
        erc20Store = ERC20Store(_erc20Store);
    }

    function mint(
        address[] _receivers, 
        uint256[] _values, 
        uint256[] _timestamps
    ) 
        external 
        whenNotPaused
        onlyTokenModule(msg.sender)
        onlyMintCheck(_receivers, _values)
    {
        require (_receivers.length == _values.length && _values.length == _timestamps.length, "param arrays length not equal");
        
        uint256 oldSupply;
        uint256 newSupply = erc20Store.totalSupply();

        for(uint i = 0; i < _receivers.length; ++i) {
            oldSupply = newSupply;
            newSupply = oldSupply + _values[i];
            require (newSupply >= oldSupply, "uint overflow");
            if(_timestamps[i] > 0)
                erc20Store.addLockBalance(_receivers[i], _values[i], _timestamps[i]);
            else 
                erc20Store.addBalance(_receivers[i], _values[i]);
            erc20Proxy.emitTransfer(address(0), _receivers[i], _values[i]);
        }
        erc20Store.setTotalSupply(newSupply);
        emit Mint(_receivers, _values, _timestamps);
    }

    function burn(
        address[] _owners, 
        uint256[] _values,
        uint256[] _timestamps
    ) 
        external 
        whenNotPaused
        onlyTokenModule(msg.sender)
    {
        require ((_owners.length == _values.length) && (_owners.length == _timestamps.length), "param arrays length not equal");
        uint256 balanceOfOwner = 0;
        for(uint i = 0; i < _owners.length; ++i) {
            if(_timestamps[i] == 0 || now >= _timestamps[i]) {
                erc20Store.adjustLockBalance(_owners[i]);
                balanceOfOwner = erc20Store.balances(_owners[i]);
                require(_values[i] <= balanceOfOwner, "burn vale should less equal balance");
                erc20Store.setBalance(_owners[i], balanceOfOwner - _values[i]);
            } else {
                balanceOfOwner = erc20Store.getLockBalance(_owners[i], _timestamps[i]);
                require(_values[i] <= balanceOfOwner, "burn vale should less equal balance");
                erc20Store.setLockBalance(_owners[i], _timestamps[i], balanceOfOwner - _values[i]);
            }
            erc20Store.setTotalSupply(erc20Store.totalSupply() - _values[i]);
            erc20Proxy.emitTransfer(_owners[i], address(0), _values[i]);
        }
    }

    function burnAll(address[] _owners) external whenNotPaused onlyTokenModule(msg.sender) {
        require (_owners.length != 0, "param _owners is null");
        uint balanceOfOwner;
        for(uint i = 0; i < _owners.length; ++i) {
            balanceOfOwner = erc20Store.sweep(_owners[i]);
            if(balanceOfOwner != 0) {
              erc20Store.setTotalSupply(erc20Store.totalSupply() - balanceOfOwner);
              erc20Proxy.emitTransfer(_owners[i], address(0), balanceOfOwner);
            }
        }
    }
}

