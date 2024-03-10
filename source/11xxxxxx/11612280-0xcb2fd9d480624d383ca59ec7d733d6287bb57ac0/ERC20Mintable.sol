pragma solidity ^0.5.0;

import "./ERC20Ownable.sol";
import "./ERC20.sol";

contract ERC20Mintable is ERC20, ERC20Ownable {

    using SafeMath for uint256;

    event Mint(address indexed to, uint256 value);

    event Redeem(address indexed account, uint256 value);

    /**
     * @dev Mint a specific amount of tokens.
     * @param value The amount of token to be mint.
     */
    function mint(address account, uint256 value) public onlyOwner {
        _mint(account, value);
    }

    /**
     * @dev redeem a specific amount of tokens.
     * @param value The amount of token to be redeem.
     */
    function redeem(uint256 value) public onlyOwner {
        _redeem(value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Mint(account, value);
    }

    /**
     * @dev Internal function that redeem an amount of an account
     * @param value The amount that will be redeem.
     */
    function _redeem(uint256 value) internal {
        _totalSupply = _totalSupply.sub(value);
        _balances[msg.sender] = _balances[msg.sender].sub(value);
        emit Redeem(msg.sender, value);
    }

}

