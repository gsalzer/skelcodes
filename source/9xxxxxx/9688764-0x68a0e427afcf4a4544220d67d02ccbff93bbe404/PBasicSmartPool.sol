// Sources flattened with buidler v1.2.0 https://buidler.dev

// File contracts/interfaces/IBPool.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is disstributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.6.2;

interface IBPool {
    function isBound(address token) external view returns(bool);
    function getBalance(address token) external view returns (uint);
    function rebind(address token, uint balance, uint denorm) external;
    function setSwapFee(uint swapFee) external;
    function bind(address token, uint balance, uint denorm) external;
    function unbind(address token) external;
    function getDenormalizedWeight(address token) external view returns (uint);
    function getTotalDenormalizedWeight() external view returns (uint);
    function getCurrentTokens() external view returns(address[] memory);
    function setController(address manager) external;

    function calcPoolOutGivenSingleIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountIn,
        uint swapFee
    )
        external pure
        returns (uint poolAmountOut);

    function calcSingleInGivenPoolOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountOut,
        uint swapFee
    )
        external pure
        returns (uint tokenAmountIn);

    function calcSingleOutGivenPoolIn(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountIn,
        uint swapFee
    )
        external pure
        returns (uint tokenAmountOut);

    function calcPoolInGivenSingleOut(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountOut,
        uint swapFee
    )
        external pure
        returns (uint poolAmountIn);
}


// File contracts/interfaces/IPSmartPool.sol

pragma solidity ^0.6.2;


// Based on the liquidity bootstrapping pool by Balancer
interface IPSmartPool {
    function joinPool(uint256 _amount) external;
    function exitPool(uint256 _amount) external;
}


// File contracts/PCToken.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.6.2;


// Highly opinionated token implementation
// Based on the balancer Implementation

interface IERC20 {
    event Approval(address indexed _src, address indexed _dst, uint _amount);
    event Transfer(address indexed _src, address indexed _dst, uint _amount);

    function totalSupply() external view returns (uint);
    function balanceOf(address _whom) external view returns (uint);
    function allowance(address _src, address _dst) external view returns (uint);

    function approve(address _dst, uint _amount) external returns (bool);
    function transfer(address _dst, uint _amount) external returns (bool);
    function transferFrom(
        address _src, address _dst, uint _amount
    ) external returns (bool);
}

contract PCToken is IERC20 {
    string public name     = "Balancer Smart Pool";
    string public symbol   = "BSP";
    uint8 public constant decimals = 18;

    uint internal totalSupplyInternal;

    mapping(address => uint)                   internal balance;
    mapping(address => mapping(address=>uint)) internal allowanceInternal;

    event Approval(address indexed _src, address indexed _dst, uint _amount);
    event Transfer(address indexed _src, address indexed _dst, uint _amount);

    uint public constant BONE              = 10**18;

    uint public constant MAX_BOUND_TOKENS  = 8;

    uint public constant MIN_WEIGHT        = BONE;
    uint public constant MAX_WEIGHT        = BONE * 50;
    uint public constant MAX_TOTAL_WEIGHT  = BONE * 50;
    uint public constant MIN_BALANCE       = BONE / 10**6;
    uint public constant MAX_BALANCE       = BONE * 10**12;

    uint public constant MIN_POOL_SUPPLY   = BONE;

    function badd(uint a, uint b)
        internal pure
        returns (uint)
    {
        uint c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    function bsub(uint a, uint b)
        internal pure
        returns (uint)
    {
        (uint c, bool flag) = bsubSign(a, b);
        require(!flag, "ERR_SUB_UNDERFLOW");
        return c;
    }

    function bsubSign(uint a, uint b)
        internal pure
        returns (uint, bool)
    {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    function bmul(uint a, uint b)
        internal pure
        returns (uint)
    {
        uint c0 = a * b;
        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
        uint c1 = c0 + (BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint c2 = c1 / BONE;
        return c2;
    }

    function bdiv(uint a, uint b)
        internal pure
        returns (uint)
    {
        require(b != 0, "ERR_DIV_ZERO");
        uint c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL"); // bmul overflow
        uint c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
        uint c2 = c1 / b;
        return c2;
    }

    function _mint(uint _amount) internal {
        balance[address(this)] = badd(balance[address(this)], _amount);
        totalSupplyInternal = badd(totalSupplyInternal, _amount);
        emit Transfer(address(0), address(this), _amount);
    }

    function _burn(uint _amount) internal {
        require(balance[address(this)] >= _amount, "ERR_INSUFFICIENT_BAL");
        balance[address(this)] = bsub(balance[address(this)], _amount);
        totalSupplyInternal = bsub(totalSupplyInternal, _amount);
        emit Transfer(address(this), address(0), _amount);
    }

    function _move(address _src, address _dst, uint _amount) internal {
        require(balance[_src] >= _amount, "ERR_INSUFFICIENT_BAL");
        balance[_src] = bsub(balance[_src], _amount);
        balance[_dst] = badd(balance[_dst], _amount);
        emit Transfer(_src, _dst, _amount);
    }

    function _push(address _to, uint _amount) internal {
        _move(address(this), _to, _amount);
    }

    function _pull(address _from, uint _amount) internal {
        _move(_from, address(this), _amount);
    }

    function allowance(address _src, address _dst) external view override returns (uint) {
        return allowanceInternal[_src][_dst];
    }

    function balanceOf(address _whom) external view override returns (uint) {
        return balance[_whom];
    }

    function totalSupply() public view override returns (uint) {
        return totalSupplyInternal;
    }

    function approve(address _dst, uint _amount) external override returns (bool) {
        allowanceInternal[msg.sender][_dst] = _amount;
        emit Approval(msg.sender, _dst, _amount);
        return true;
    }

    function increaseApproval(address _dst, uint _amount) external returns (bool) {
        allowanceInternal[msg.sender][_dst] = badd(allowanceInternal[msg.sender][_dst], _amount);
        emit Approval(msg.sender, _dst, allowanceInternal[msg.sender][_dst]);
        return true;
    }

    function decreaseApproval(address _dst, uint _amount) external returns (bool) {
        uint oldValue = allowanceInternal[msg.sender][_dst];
        if (_amount > oldValue) {
            allowanceInternal[msg.sender][_dst] = 0;
        } else {
            allowanceInternal[msg.sender][_dst] = bsub(oldValue, _amount);
        }
        emit Approval(msg.sender, _dst, allowanceInternal[msg.sender][_dst]);
        return true;
    }

    function transfer(address _dst, uint _amount) external override returns (bool) {
        _move(msg.sender, _dst, _amount);
        return true;
    }

    function transferFrom(address _src, address _dst, uint _amount) external override returns (bool) {
        require(msg.sender == _src || _amount <= allowanceInternal[_src][msg.sender], "ERR_PCTOKEN_BAD_CALLER");
        _move(_src, _dst, _amount);
        if (msg.sender != _src && allowanceInternal[_src][msg.sender] != uint256(-1)) {
            allowanceInternal[_src][msg.sender] = bsub(allowanceInternal[_src][msg.sender], _amount);
            emit Approval(msg.sender, _dst, allowanceInternal[_src][msg.sender]);
        }
        return true;
    }
}


// File contracts/smart-pools/PBasicSmartPool.sol

pragma solidity ^0.6.2;




contract PBasicSmartPool is IPSmartPool, PCToken {
    
    IBPool public bPool;

    modifier ready() {
        require(address(bPool) != address(0), "PBasicSmartPool.ready: not ready");
        _;
    }   

     event LOG_JOIN(
        address indexed caller,
        address indexed tokenIn,
        uint256 tokenAmountIn
    );

    event LOG_EXIT(
        address indexed caller,
        address indexed tokenOut,
        uint256 tokenAmountOut
    );

    constructor() public {
        
    }

    // Seperated initializer for easier use with proxies
    function init(address _bPool, string memory _name, string memory _symbol, uint256 _initialSupply) public {
        require(address(bPool) == address(0), "PBasicSmartPool.init: already initialised");
        bPool = IBPool(_bPool);
        name = _name;
        symbol = _symbol;
        _mintPoolShare(_initialSupply);
        _pushPoolShare(msg.sender, _initialSupply);
    }

    function joinPool(uint256 _amount) external override ready {
        uint poolTotal = totalSupply();

        uint ratio = bdiv(_amount, poolTotal);
        require(ratio != 0);

        address[] memory tokens = bPool.getCurrentTokens();

        for (uint i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint bal = bPool.getBalance(t);
            uint tokenAmountIn = bmul(ratio, bal);
            emit LOG_JOIN(msg.sender, t, tokenAmountIn);
            _pullUnderlying(t, msg.sender, tokenAmountIn);
        }
        _mintPoolShare(_amount);
        _pushPoolShare(msg.sender, _amount);
    }

    function exitPool(uint256 _amount) external override ready {

        uint poolTotal = totalSupply();
        uint ratio = bdiv(_amount, poolTotal);
        require(ratio != 0);

        _pullPoolShare(msg.sender, _amount);
        _burnPoolShare(_amount);

        address[] memory tokens = bPool.getCurrentTokens();

        for (uint i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint bal = bPool.getBalance(t);
            uint tAo = bmul(ratio, bal);
            emit LOG_EXIT(msg.sender, t, tAo);  
            _pushUnderlying(t, msg.sender, tAo);
        }
    }

    // Pull tokens from address and rebind BPool
    function _pullUnderlying(address _token, address _from, uint _amount)
        internal
    {
        // Gets current Balance of token i, Bi, and weight of token i, Wi, from BPool.
        uint tokenBalance = bPool.getBalance(_token);
        uint tokenWeight = bPool.getDenormalizedWeight(_token);

        bool xfer = IERC20(_token).transferFrom(_from, address(this), _amount);
        IERC20(_token).approve(address(bPool), _amount);
        require(xfer, "ERR_ERC20_FALSE");
        bPool.rebind(_token, badd(tokenBalance, _amount), tokenWeight);
    }

    // Rebind BPool and push tokens to address
    function _pushUnderlying(address _token, address _to, uint _amount)
        internal
    {
        // Gets current Balance of token i, Bi, and weight of token i, Wi, from BPool.
        uint tokenBalance = bPool.getBalance(_token);
        uint tokenWeight = bPool.getDenormalizedWeight(_token);
        bPool.rebind(_token, bsub(tokenBalance, _amount), tokenWeight);

        bool xfer = IERC20(_token).transfer(_to, _amount);
        require(xfer, "ERR_ERC20_FALSE");
    }
    function _pullPoolShare(address _from, uint _amount)
        internal
    {
        _pull(_from, _amount);
    }

    function _burnPoolShare(uint _amount)
        internal
    {
        _burn(_amount);
    }

    function _mintPoolShare(uint _amount)
        internal
    {
        _mint(_amount);
    }

    function _pushPoolShare(address _to, uint _amount)
        internal
    {
        _push(_to, _amount);
    }

}


// File contracts/interfaces/IBFactory.sol

pragma solidity ^0.6.2;

interface IBFactory {
    function newBPool() external returns (address);
}
