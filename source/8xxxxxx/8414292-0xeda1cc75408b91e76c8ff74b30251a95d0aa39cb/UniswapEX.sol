/**
 *Submitted for verification at Etherscan.io on 2019-08-24
*/

// File: contracts/commons/SafeMath.sol

pragma solidity ^0.5.11;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/contracts@next`.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/contracts@next`.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/contracts@next`.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/interfaces/IERC20.sol

pragma solidity ^0.5.11;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/interfaces/UniswapExchange.sol

pragma solidity ^0.5.11;


contract UniswapExchange {
    // Address of ERC20 token sold on this exchange
    function tokenAddress() external view returns (address token);
    // Address of Uniswap Factory
    function factoryAddress() external view returns (address factory);
    // Provide Liquidity
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
    function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
    // Get Prices
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
    function getEthToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256 eth_sold);
    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought);
    function getTokenToEthOutputPrice(uint256 eth_bought) external view returns (uint256 tokens_sold);
    // Trade ETH to ERC20
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256  tokens_bought);
    function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns (uint256  tokens_bought);
    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns (uint256  eth_sold);
    function ethToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256  eth_sold);
    // Trade ERC20 to ETH
    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external returns (uint256  eth_bought);
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient) external returns (uint256  eth_bought);
    function tokenToEthSwapOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline) external returns (uint256  tokens_sold);
    function tokenToEthTransferOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline, address recipient) external returns (uint256  tokens_sold);
    // Trade ERC20 to ERC20
    function tokenToTokenSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address token_addr) external returns (uint256  tokens_sold);
    function tokenToTokenTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_sold);
    // Trade ERC20 to Custom Pool
    function tokenToExchangeSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address exchange_addr) external returns (uint256  tokens_sold);
    function tokenToExchangeTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_sold);
    // ERC20 comaptibility for liquidity tokens
    bytes32 public name;
    bytes32 public symbol;
    uint256 public decimals;
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    // Never use
    function setup(address token_addr) external;
}

// File: contracts/interfaces/UniswapFactory.sol

pragma solidity ^0.5.11;




contract UniswapFactory {
    // Public Variables
    address public exchangeTemplate;
    uint256 public tokenCount;
    // Create Exchange
    function createExchange(address token) external returns (address exchange);
    // Get Exchange and Token Info
    function getExchange(address token) external view returns (UniswapExchange exchange);
    function getToken(address exchange) external view returns (IERC20 token);
    function getTokenWithId(uint256 tokenId) external view returns (address token);
    // Never use
    function initializeFactory(address template) external;
}

// File: contracts/commons/Vault.sol

pragma solidity ^0.5.11;



contract Vault {
    function execute(IERC20 _token, address _to, uint256 _val) external payable {
        _token.transfer(_to, _val);
        // @TODO: maybe emit an event?
        selfdestruct(address(uint256(msg.sender))); //@TODO: revisit it
    }
}

// File: contracts/libs/Fabric.sol

pragma solidity ^0.5.11;




/**
 * @title Fabric
 * @dev Create deterministics vaults.
 */
library Fabric {
    /**
    * @dev Get a deterministics vault.
    */
    function getVault(bytes32 _key) internal view returns (address) {
        return address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        byte(0xff),
                        address(this),
                        _key,
                        keccak256(type(Vault).creationCode)
                    )
                )
            )
        );
    }

    /**
    * @dev Create deterministic vault.
    */
    function executeVault(bytes32 _key, IERC20 _token, address _to) internal returns (uint256 value) {
        address addr;
        bytes memory slotcode = type(Vault).creationCode;

        /* solium-disable-next-line */
        assembly{
          // Create the contract arguments for the constructor
          addr := create2(0, add(slotcode, 0x20), mload(slotcode), _key)
          if iszero(extcodesize(addr)) {
            revert(0, 0)
          }
        }

        value = _token.balanceOf(addr);
        Vault(addr).execute(_token, _to, value);
    }
}

// File: contracts/UniswapEX.sol

pragma solidity ^0.5.11;







contract UniswapEX {
    using SafeMath for uint256;
    using Fabric for bytes32;

    event DepositETH(
        uint256 _amount,
        bytes _data
    );

    event Executed(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _bought,
        uint256 _fee,
        address _owner,
        bytes32 _salt,
        address _relayer
    );

    address public constant ETH_ADDRESS = address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    uint256 private constant never = uint(-1);

    UniswapFactory public uniswapFactory;

    mapping(bytes32 => uint256) public ethDeposits;

    constructor(UniswapFactory _uniswapFactory) public {
        uniswapFactory = _uniswapFactory;
    }

    function _ethToToken(
        UniswapFactory _uniswapFactory,
        IERC20 _token,
        uint256 _amount,
        address _dest
    ) private returns (uint256) {
        UniswapExchange uniswap = _uniswapFactory.getExchange(address(_token));

        if (_dest != address(this)) {
            return uniswap.ethToTokenTransferInput.value(_amount)(1, never, _dest);
        } else {
            return uniswap.ethToTokenSwapInput.value(_amount)(1, never);
        }
    }

    function _tokenToEth(
        UniswapFactory _uniswapFactory,
        IERC20 _token,
        uint256 _amount,
        address _dest
    ) private returns (uint256) {
        UniswapExchange uniswap = _uniswapFactory.getExchange(address(_token));

        // Check if previues allowance is enought
        // and approve Uniswap if is not
        uint256 prevAllowance = _token.allowance(address(this), address(uniswap));
        if (prevAllowance < _amount) {
            if (prevAllowance != 0) {
                _token.approve(address(uniswap), 0);
            }

            _token.approve(address(uniswap), uint(-1));
        }

        // Execute the trade
        if (_dest != address(this)) {
            return uniswap.tokenToEthTransferInput(_amount, 1, never, _dest);
        } else {
            return uniswap.tokenToEthSwapInput(_amount, 1, never);
        }
    }

    function _pull(
        IERC20 _from,
        bytes32 _key
    ) private returns (uint256 amount) {
        if (address(_from) == ETH_ADDRESS) {
            amount = ethDeposits[_key];
            ethDeposits[_key] = 0;
        } else {
            amount = _key.executeVault(_from, address(this));
        }
    }

    function _keyOf(
        IERC20 _from,
        IERC20 _to,
        uint256 _return,
        uint256 _fee,
        address payable _owner,
        bytes32 _salt
    ) private pure returns (bytes32) {
        return keccak256(
            abi.encode(
                _from,
                _to,
                _return,
                _fee,
                _owner,
                _salt
            )
        );
    }

    function vaultOfOrder(
        IERC20 _from,
        IERC20 _to,
        uint256 _return,
        uint256 _fee,
        address payable _owner,
        bytes32 _salt
    ) public view returns (address) {
        return _keyOf(
            _from,
            _to,
            _return,
            _fee,
            _owner,
            _salt
        ).getVault();
    }

    function encodeTokenOrder(
        IERC20 _from,
        IERC20 _to,
        uint256 _amount,
        uint256 _return,
        uint256 _fee,
        address payable _owner,
        bytes32 _salt
    ) external view returns (bytes memory) {
        return abi.encodeWithSelector(
            _from.transfer.selector,
            vaultOfOrder(
                _from,
                _to,
                _return,
                _fee,
                _owner,
                _salt
            ),
            _amount,
            abi.encode(
                _from,
                _to,
                _return,
                _fee,
                _owner,
                _salt
            )
        );
    }

    function encode(
        address _from,
        address _to,
        uint256 _return,
        uint256 _fee,
        address payable _owner,
        bytes32 _salt
    ) external view returns (bytes memory) {
        return abi.encode(
            _from,
            _to,
            _return,
            _fee,
            _owner,
            _salt
        );
    }

    function decode(
        bytes calldata _data
    ) external view returns (
        address _from,
        address _to,
        uint256 _return,
        uint256 _fee,
        address payable _owner
    ) {
        (
            _from,
            _to,
            _return,
            _fee,
            _owner
        ) = abi.decode(
            _data,
            (address, address, uint256, uint256, address)
        );
    }

    function exists(
        IERC20 _from,
        IERC20 _to,
        uint256 _return,
        uint256 _fee,
        address payable _owner,
        bytes32 _salt
    ) external view returns (bool) {
        bytes32 key = _keyOf(
            _from,
            _to,
            _return,
            _fee,
            _owner,
            _salt
        );

        if (address(_from) == ETH_ADDRESS) {
            return ethDeposits[key] != 0;
        } else {
            return _from.balanceOf(key.getVault()) != 0;
        }
    }

    function canFill(
        IERC20 _from,
        IERC20 _to,
        uint256 _return,
        uint256 _fee,
        address payable _owner,
        bytes32 _salt
    ) external view returns (bool) {
        bytes32 key = _keyOf(
            _from,
            _to,
            _return,
            _fee,
            _owner,
            _salt
        );

        // Pull amount
        uint256 amount;
        if (address(_from) == ETH_ADDRESS) {
            amount = ethDeposits[key];
        } else {
            amount = _from.balanceOf(key.getVault());
        }

        uint256 bought;

        if (address(_from) == ETH_ADDRESS) {
            uint256 sell = amount.sub(_fee);
            bought = uniswapFactory.getExchange(address(_to)).getEthToTokenInputPrice(sell);
        } else if (address(_to) == ETH_ADDRESS) {
            bought = uniswapFactory.getExchange(address(_from)).getTokenToEthInputPrice(amount);
            bought = bought.sub(_fee);
        } else {
            uint256 boughtEth = uniswapFactory.getExchange(address(_from)).getTokenToEthInputPrice(amount);
            bought = uniswapFactory.getExchange(address(_to)).getEthToTokenInputPrice(boughtEth.sub(_fee));
        }

        return bought >= _return;
    }

    function depositETH(
        bytes calldata _data
    ) external payable {
        bytes32 key = keccak256(_data);
        ethDeposits[key] = ethDeposits[key].add(msg.value);
        emit DepositETH(msg.value, _data);
    }

    function cancel(
        IERC20 _from,
        IERC20 _to,
        uint256 _return,
        uint256 _fee,
        address payable _owner,
        bytes32 _salt
    ) external {
        require(msg.sender == _owner, "only owner can cancel");
        bytes32 key = _keyOf(
            _from,
            _to,
            _return,
            _fee,
            _owner,
            _salt
        );

        if (address(_from) == ETH_ADDRESS) {
            uint256 amount = ethDeposits[key];
            ethDeposits[key] = 0;
            msg.sender.transfer(amount);
        } else {
            key.executeVault(_from, msg.sender);
        }
    }

    function execute(
        IERC20 _from,
        IERC20 _to,
        uint256 _return,
        uint256 _fee,
        address payable _owner,
        bytes32 _salt
    ) external {
        bytes32 key = _keyOf(
            _from,
            _to,
            _return,
            _fee,
            _owner,
            _salt
        );

        // Pull amount
        uint256 amount = _pull(_from, key);
        require(amount > 0, "order does not exists");

        uint256 bought;

        if (address(_from) == ETH_ADDRESS) {
            // Keep some eth for paying the fee
            uint256 sell = amount.sub(_fee);
            bought = _ethToToken(uniswapFactory, _to, sell, _owner);
            msg.sender.transfer(_fee);
        } else if (address(_to) == ETH_ADDRESS) {
            // Convert
            bought = _tokenToEth(uniswapFactory, _from, amount, address(this));
            bought = bought.sub(_fee);

            // Send fee and amount bought
            msg.sender.transfer(_fee);
            _owner.transfer(bought);
        } else {
            // Convert from FromToken to ETH
            uint256 boughtEth = _tokenToEth(uniswapFactory, _from, amount, address(this));
            msg.sender.transfer(_fee);

            // Convert from ETH to ToToken
            bought = _ethToToken(uniswapFactory, _to, boughtEth.sub(_fee), _owner);
        }

        require(bought >= _return, "sell return is not enought");

        emit Executed(
            address(_from),
            address(_to),
            amount,
            bought,
            _fee,
            _owner,
            _salt,
            msg.sender
        );
    }

    function() external payable { }
}
