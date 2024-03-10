pragma solidity ^0.4.24;
import { Proxy } from "Proxy.sol";
import { StorageModule } from "StorageModule.sol";
import { AuthModule } from "AuthModule.sol";
import "ItMapUintAddress.sol";
import "IERC20.sol";
import "IERC20Mintable.sol";
import "IERC20Burnable.sol";
import "IERC20ImplUpgradeable.sol";
import "Authorization.sol";

contract TokenModule is Authorization {
    
    using ItMapUintAddress for ItMapUintAddress.MapUintAddress;

    ItMapUintAddress.MapUintAddress tokenMap;

    event UpdateToken(uint _tag, address _old, address _new);

    constructor(address _proxy) public Authorization(_proxy) {
       
    }

    function addToken(uint _tag, address _token) external whenNotPaused onlyAdmin(msg.sender) {
        require(tokenMap.data[_tag].value == address(0), "Token already exists");
        tokenMap.add(_tag, _token);
        emit UpdateToken(_tag, address(0), _token);
    }

    function updateToken(uint _tag, address _token) external whenNotPaused onlyAdmin(msg.sender) {
        require(tokenMap.data[_tag].value != address(0), "Token not exists");
        address _old = tokenMap.data[_tag].value;
        tokenMap.add(_tag, _token);
        emit UpdateToken(_tag, _old, _token);
    }

    function getToken(uint _tag) external view returns (address) {
        return tokenMap.getByKey(_tag);
    }

    function balanceOf(address _from) external view returns (uint256 sum) {
        for(uint i = tokenMap.startIndex(); tokenMap.validIndex(i); i = tokenMap.nextIndex(i)) {
            IERC20 _token = IERC20(tokenMap.getByIndex(i));
            if(_token != address(0))
                sum += _token.balanceOf(_from);
        }
    }

    function mint(uint _tokenTag, address[] _investors, uint[] _balances, uint[] _timestamps, bool _originals) external whenNotPaused onlyIssuer(msg.sender) {
        IERC20ImplUpgradeable token = IERC20ImplUpgradeable(tokenMap.getByKey(_tokenTag));
        IERC20Mintable impl = IERC20Mintable(token.getMintBurnAddress());
        require(impl != address(0), "mint impl require not 0");

        impl.mint(_investors, _balances, _timestamps);

        StorageModule sm = StorageModule(proxy.getModule("StorageModule"));
        sm.initShareholders(_investors, _originals);
    }

    function burn(uint _tokenTag, address[] _investors, uint256[] _values, uint256[] _timestamps) external whenNotPaused onlyIssuer(msg.sender) {
        IERC20ImplUpgradeable token = IERC20ImplUpgradeable(tokenMap.getByKey(_tokenTag));
        IERC20Burnable impl = IERC20Burnable(token.getMintBurnAddress());
        require(impl != address(0), "burn impl require not 0");
        impl.burn(_investors, _values, _timestamps);
    }

    function burnAll(uint _tokenTag, address[] _investors) external whenNotPaused onlyIssuer(msg.sender) {
        IERC20ImplUpgradeable token = IERC20ImplUpgradeable(tokenMap.getByKey(_tokenTag));
        IERC20Burnable impl = IERC20Burnable(token.getMintBurnAddress());
        require(impl != address(0), "burn impl require not 0");
        impl.burnAll(_investors);
    }

    function getTokenTags() external view returns(uint[] tags){
        tags = new uint[](tokenMap.size);
        uint j = 0;
        for(uint i = tokenMap.startIndex(); tokenMap.validIndex(i); i = tokenMap.nextIndex(i)) {
            tags[j] = tokenMap.keys[i].key;
            ++j;
        }
    }
}

