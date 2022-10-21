pragma solidity ^0.5.3;

import { Owned } from "./Ownable.sol";

contract Whitelist is Owned{
    
    bool public whitelistToggle = false;
    
    mapping(address => bool) whitelistedAccounts;
    
    modifier onlyWhitelisted(address from, address to) {
        if(whitelistToggle){
            require(whitelistedAccounts[from], "Sender account is not whitelisted");
            require(whitelistedAccounts[to], "Receiver account is not whitelisted");
        }
        _;
    }
    
    event Whitelisted(address account);
    event UnWhitelisted(address account);
    
    event ToggleWhitelist(address sender, uint timestamp);
    event UntoggleWhitelist(address sender, uint timestamp);
    
    function addWhitelist(address account) public onlyOwner returns(bool) {
        whitelistedAccounts[account] = true;
        emit Whitelisted(account);
    }
        
    function removeWhitelist(address account) public onlyOwner returns(bool) {
        whitelistedAccounts[account] = false;
        emit UnWhitelisted(account);
    }
    
    function toggle() external onlyOwner {
        whitelistToggle = true;
        emit ToggleWhitelist(msg.sender, now);
    }
    
    function untoggle() external onlyOwner {
        whitelistToggle = false;
        emit UntoggleWhitelist(msg.sender, now);
    }
    
    function isWhiteListed(address account) public view returns(bool){
        return whitelistedAccounts[account];
    }
    
}

