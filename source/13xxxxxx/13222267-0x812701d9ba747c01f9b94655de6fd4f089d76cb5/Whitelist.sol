pragma solidity ^0.7.0;
import "./Ownable.sol";

contract Whitelist is Ownable {
    mapping(address => bool) whitelist;
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    /// constructor called at deploy time
    constructor(address[] memory wl_addrs) {
        //wlcount = wl_addrs.length;

        for (uint i = 0; i < wl_addrs.length; i++) {
            // loop over wl_addrs and update set of whitelisted accounts
            address _address = wl_addrs[i];
            whitelist[_address] = true;
        }
    }

    function add(address _address) public onlyOwner {
        whitelist[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function remove(address _address) public onlyOwner {
        whitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function isWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address];
    }
}
