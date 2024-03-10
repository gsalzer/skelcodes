pragma solidity ^0.4.24;

import "ERC20ImplUpgradeable.sol";
import "IERC20.sol";

contract ERC20Proxy is IERC20, ERC20ImplUpgradeable {
   
    string public name;    
    string public symbol;
    uint8 public decimals;
    string public tokenDetails;

    event UpdateTokenDetails(string _oldDetails, string _newDetails);
    event RevertTransfer(uint _tx);

    constructor(
        string _name,
        string _symbol,
        uint8 _decimals,
        string _tokenDetails,
        address _proxy
    )
        public 
        ERC20ImplUpgradeable(_proxy) 
    {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        tokenDetails = _tokenDetails;
    }

    function totalSupply() public view returns (uint256) {
        return erc20Impl.totalSupply();
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return erc20Impl.balanceOf(_owner);
    }

    function balanceOfLock(address _owner) public view returns (uint256[] lockBalanceTimestamps, uint256[] lockBalanceValues) {
        return erc20Impl.balanceOfLock(_owner);
    }
    
    function emitTransfer(address _from, address _to, uint256 _value) public onlyImpl {
        emit Transfer(_from, _to, _value);
    }
    
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool success) {
        return erc20Impl.transferWithSender(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool success) {
        return erc20Impl.transferFromWithSender(msg.sender, _from, _to, _value);
    }
    
    function emitApproval(address _owner, address _spender, uint256 _value) public onlyImpl {
        emit Approval(_owner, _spender, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool success) {
        return erc20Impl.approveWithSender(msg.sender, _spender, _value);
    }

    function increaseApproval(address _spender, uint256 _addedValue) whenNotPaused public returns (bool success) {
        return erc20Impl.increaseApprovalWithSender(msg.sender, _spender, _addedValue);
    }
    
    function decreaseApproval(address _spender, uint256 _subtractedValue) public whenNotPaused returns (bool success) {
        return erc20Impl.decreaseApprovalWithSender(msg.sender, _spender, _subtractedValue);
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return erc20Impl.allowance(_owner, _spender);
    }

    function revertTransfer
    (
        uint _tx,
        address _from,
        address _to,
        uint _value
    ) 
        public 
        whenNotPaused
        onlyIssuer(msg.sender)
    {
        erc20Impl.revertTransfer(_tx, _from, _to, _value);
    }

    function emitRevertTransfer(uint _tx) public onlyImpl {
        emit RevertTransfer(_tx);
    }

    function updateTokenDetails(string _newTokenDetails) public whenNotPaused onlyIssuer(msg.sender) {
        emit UpdateTokenDetails(tokenDetails, _newTokenDetails);
        tokenDetails = _newTokenDetails;
    }

}
