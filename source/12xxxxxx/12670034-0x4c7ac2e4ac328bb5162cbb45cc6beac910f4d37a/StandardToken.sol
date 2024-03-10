pragma solidity ^0.4.23;

import "./BasicToken.sol";
import "./ERC20.sol";

/**
 * @title 标准 ERC20 token
 *
 * @dev 实现基础的标准token
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {
    mapping(address => mapping(address => uint256)) internal allowed;

    /**
     * @dev 从一个地址向另外一个地址转token
     * @param _from 转账的from地址
     * @param _to address 转账的to地址
     * @param _value uint256 转账token数量
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        // 做合法性检查
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        //_from余额减去相应的金额
        //_to余额加上相应的金额
        //msg.sender可以从账户_from中转出的数量减少_value
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        // 触发Transfer事件
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev 批准传递的address以代表msg.sender花费指定数量的token
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender 花费资金的地址
     * @param _value 可以被花费的token数量
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        //记录msg.sender允许_spender动用的token
        allowed[msg.sender][_spender] = _value;
        //触发Approval事件
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev 函数检查所有者允许的_spender花费的token数量
     * @param _owner address 资金所有者地址.
     * @param _spender address 花费资金的spender的地址.
     * @return A uint256 指定_spender仍可用token的数量。
     */
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        //允许_spender从_owner中转出的token数
        return allowed[_owner][_spender];
    }

    /**
     * @dev 增加所有者允许_spender花费代币的数量。
     *
     * allowed[_spender] == 0时approve应该被调用. 增加allowed值最好使用此函数避免2此调用（等待知道第一笔交易被挖出）
     * From MonolithDAO Token.sol
     * @param _spender 花费资金的地址
     * @param _addedValue 用于增加允许动用的token牌数量
     */
    function increaseApproval(address _spender, uint256 _addedValue)
        public
        returns (bool)
    {
        //在之前允许的数量上增加_addedValue
        allowed[msg.sender][_spender] = (
            allowed[msg.sender][_spender].add(_addedValue)
        );
        //触发Approval事件
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev 减少所有者允许_spender花费代币的数量
     *
     * allowed[_spender] == 0时approve应该被调用. 减少allowed值最好使用此函数避免2此调用（等待知道第一笔交易被挖出）
     * From MonolithDAO Token.sol
     * @param _spender  花费资金的地址
     * @param _subtractedValue 用于减少允许动用的token牌数量
     */
    function decreaseApproval(address _spender, uint256 _subtractedValue)
        public
        returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            //减少的数量少于之前允许的数量，则清零
            allowed[msg.sender][_spender] = 0;
        } else {
            //减少对应的_subtractedValue数量
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        //触发Approval事件
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

