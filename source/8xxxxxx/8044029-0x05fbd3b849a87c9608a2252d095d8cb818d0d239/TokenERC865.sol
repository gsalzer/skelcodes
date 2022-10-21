pragma solidity ^0.4.25;

import "./TokenERC20.sol";

contract TokenERC865 is TokenERC20 {

    event TransferPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);
    event TransferPreSignedNotFeeToken(address indexed from, address indexed to, address indexed delegate, uint256 amount);

    function transferPreSigned(address _from, address _to, uint256 _value, uint256 _fee) onlyOwner public returns (bool) {
        require(_to != address(0));
        require(_from != address(0));
        require(balanceOf[_from] >= safeAdd(_value, _fee));
        balanceOf[_from] = safeSub(safeSub(balanceOf[_from], _value), _fee);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], _fee);
        emit Transfer(_from, _to, _value);
        emit Transfer(_from, msg.sender, _fee);
        emit TransferPreSigned(_from, _to, msg.sender, _value, _fee);
        return true;
    }

    function transferPreSignedNotFeeToken(address _from, address _to, uint256 _value) onlyOwner public returns (bool) {
        require(_to != address(0));
        require(_from != address(0));
        require(balanceOf[_from] >= _value);
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        emit Transfer(_from, _to, _value);
        emit TransferPreSignedNotFeeToken(_from, _to, msg.sender, _value);
        return true;
    }

}
