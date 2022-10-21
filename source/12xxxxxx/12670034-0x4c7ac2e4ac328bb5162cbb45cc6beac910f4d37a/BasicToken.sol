pragma solidity ^0.4.23;

import "./ERC20Basic.sol";
import "./SafeMath.sol";

/**
 * @title 实现ERC20基本合约的接口
 * @dev 基本的StandardToken，不包含allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    /**
     * @dev 返回存在的token总数
     */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
     * @dev 给特定的address转token
     * @param _to 要转账到的address
     * @param _value 要转账的金额
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        //做相关的合法验证
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        // msg.sender余额中减去额度，_to余额加上相应额度
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        //触发Transfer事件
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev 获取指定address的余额
     * @param _owner 查询余额的address.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
}

