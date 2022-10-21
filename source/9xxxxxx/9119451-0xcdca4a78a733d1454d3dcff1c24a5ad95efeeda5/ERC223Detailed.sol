pragma solidity ^0.5.0;

import './SafeMath.sol';
import './Context.sol';
import "./ERC223.sol";


/**
 * @dev Optional functions from the ERC223 standard.
 */
contract ERC223Detailed is Context, IERC223, ERC223 {
    using SafeMath for uint256;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     *
     *  note : [(final)totalSupply] >> claimAmount * 10 ** decimals
     *  example : args << "The Kh Token No.X", "ABC", "10000000000", "18"
    */
    constructor (
        string memory token_name,
        string memory symbol,
        uint256 claimAmount,
        uint8 decimals
    ) public {
        _name = token_name;
        _symbol = symbol;
        _decimals = decimals;

        _totalSupply = claimAmount.mul(10 ** uint256(_decimals));
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply, "");
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

