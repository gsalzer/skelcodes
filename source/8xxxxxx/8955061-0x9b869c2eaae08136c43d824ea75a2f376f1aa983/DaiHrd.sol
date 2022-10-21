pragma solidity 0.5.12;

import { Context } from "@openzeppelin/contracts/GSN/Context.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC777 } from "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import { IERC777Recipient } from "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import { IERC777Sender } from "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC1820Registry } from "@openzeppelin/contracts/introspection/IERC1820Registry.sol";
import { RuntimeConstants } from "./RuntimeConstants.sol";

// ERC777 is inlined because we need to change `_callTokensToSend` to protect against Uniswap replay attacks

/**
 * @dev Implementation of the {IERC777} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * Support for ERC20 is included in this contract, as specified by the EIP: both
 * the ERC777 and ERC20 interfaces can be safely used when interacting with it.
 * Both {IERC777-Sent} and {IERC20-Transfer} events are emitted on token
 * movements.
 *
 * Additionally, the {IERC777-granularity} value is hard-coded to `1`, meaning that there
 * are no special restrictions in the amount of tokens that created, moved, or
 * destroyed. This makes integration with ERC20 applications seamless.
 */
contract ERC777 is RuntimeConstants, Context, IERC777, IERC20 {
	using SafeMath for uint256;
	using Address for address;

	IERC1820Registry constant private _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

	mapping(address => uint256) private _balances;

	uint256 private _totalSupply;

	string private _name;
	string private _symbol;

	// We inline the result of the following hashes because Solidity doesn't resolve them at compile time.
	// See https://github.com/ethereum/solidity/issues/4024.

	// keccak256("ERC777TokensSender")
	bytes32 constant private TOKENS_SENDER_INTERFACE_HASH =
		0x29ddb589b1fb5fc7cf394961c1adf5f8c6454761adf795e67fe149f658abe895;

	// keccak256("ERC777TokensRecipient")
	bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH =
		0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;

	// This isn't ever read from - it's only used to respond to the defaultOperators query.
	address[] private _defaultOperatorsArray;

	// Immutable, but accounts may revoke them (tracked in __revokedDefaultOperators).
	mapping(address => bool) private _defaultOperators;

	// For each account, a mapping of its operators and revoked default operators.
	mapping(address => mapping(address => bool)) private _operators;
	mapping(address => mapping(address => bool)) private _revokedDefaultOperators;

	// ERC20-allowances
	mapping (address => mapping (address => uint256)) private _allowances;

	// KEYDONIX: Protect against Uniswap Exchange reentrancy bug: https://blog.openzeppelin.com/exploiting-uniswap-from-reentrancy-to-actual-profit/
	bool uniswapExchangeReentrancyGuard = false;

	/**
	 * @dev `defaultOperators` may be an empty array.
	 */
	constructor(string memory name, string memory symbol, address[] memory defaultOperators) public {
		_name = name;
		_symbol = symbol;

		_defaultOperatorsArray = defaultOperators;
		for (uint256 i = 0; i < _defaultOperatorsArray.length; i++) {
			_defaultOperators[_defaultOperatorsArray[i]] = true;
		}

		// register interfaces
		_erc1820.setInterfaceImplementer(address(this), keccak256("ERC777Token"), address(this));
		_erc1820.setInterfaceImplementer(address(this), keccak256("ERC20Token"), address(this));
	}

	/**
	 * @dev See {IERC777-name}.
	 */
	function name() public view returns (string memory) {
		return _name;
	}

	/**
	 * @dev See {IERC777-symbol}.
	 */
	function symbol() public view returns (string memory) {
		return _symbol;
	}

	/**
	 * @dev See {ERC20Detailed-decimals}.
	 *
	 * Always returns 18, as per the
	 * [ERC777 EIP](https://eips.ethereum.org/EIPS/eip-777#backward-compatibility).
	 */
	function decimals() public pure returns (uint8) {
		return 18;
	}

	/**
	 * @dev See {IERC777-granularity}.
	 *
	 * This implementation always returns `1`.
	 */
	function granularity() public view returns (uint256) {
		return 1;
	}

	/**
	 * @dev See {IERC777-totalSupply}.
	 */
	function totalSupply() public view returns (uint256) {
		return _totalSupply;
	}

	/**
	 * @dev Returns the amount of tokens owned by an account (`tokenHolder`).
	 */
	function balanceOf(address tokenHolder) public view returns (uint256) {
		return _balances[tokenHolder];
	}

	/**
	 * @dev See {IERC777-send}.
	 *
	 * Also emits a {Transfer} event for ERC20 compatibility.
	 */
	function send(address recipient, uint256 amount, bytes calldata data) external {
		_send(_msgSender(), _msgSender(), recipient, amount, data, "", true);
	}

	/**
	 * @dev See {IERC20-transfer}.
	 *
	 * Unlike `send`, `recipient` is _not_ required to implement the {IERC777Recipient}
	 * interface if it is a contract.
	 *
	 * Also emits a {Sent} event.
	 */
	function transfer(address recipient, uint256 amount) external returns (bool) {
		require(recipient != address(0), "ERC777: transfer to the zero address");

		address from = _msgSender();

		_callTokensToSend(from, from, recipient, amount, "", "");

		_move(from, from, recipient, amount, "", "");

		_callTokensReceived(from, from, recipient, amount, "", "", false);

		return true;
	}

	/**
	 * @dev See {IERC777-burn}.
	 *
	 * Also emits a {Transfer} event for ERC20 compatibility.
	 */
	function burn(uint256 amount, bytes calldata data) external {
		_burn(_msgSender(), _msgSender(), amount, data, "");
	}

	/**
	 * @dev See {IERC777-isOperatorFor}.
	 */
	function isOperatorFor(address operator, address tokenHolder) public view returns (bool) {
		return operator == tokenHolder ||
			(_defaultOperators[operator] && !_revokedDefaultOperators[tokenHolder][operator]) ||
			_operators[tokenHolder][operator];
	}

	/**
	 * @dev See {IERC777-authorizeOperator}.
	 */
	function authorizeOperator(address operator) external {
		require(_msgSender() != operator, "ERC777: authorizing self as operator");

		if (_defaultOperators[operator]) {
			delete _revokedDefaultOperators[_msgSender()][operator];
		} else {
			_operators[_msgSender()][operator] = true;
		}

		emit AuthorizedOperator(operator, _msgSender());
	}

	/**
	 * @dev See {IERC777-revokeOperator}.
	 */
	function revokeOperator(address operator) external {
		require(operator != _msgSender(), "ERC777: revoking self as operator");

		if (_defaultOperators[operator]) {
			_revokedDefaultOperators[_msgSender()][operator] = true;
		} else {
			delete _operators[_msgSender()][operator];
		}

		emit RevokedOperator(operator, _msgSender());
	}

	/**
	 * @dev See {IERC777-defaultOperators}.
	 */
	function defaultOperators() public view returns (address[] memory) {
		return _defaultOperatorsArray;
	}

	/**
	 * @dev See {IERC777-operatorSend}.
	 *
	 * Emits {Sent} and {Transfer} events.
	 */
	function operatorSend(address sender, address recipient, uint256 amount, bytes calldata data, bytes calldata operatorData) external {
		require(isOperatorFor(_msgSender(), sender), "ERC777: caller is not an operator for holder");
		_send(_msgSender(), sender, recipient, amount, data, operatorData, true);
	}

	/**
	 * @dev See {IERC777-operatorBurn}.
	 *
	 * Emits {Burned} and {Transfer} events.
	 */
	function operatorBurn(address account, uint256 amount, bytes calldata data, bytes calldata operatorData) external {
		require(isOperatorFor(_msgSender(), account), "ERC777: caller is not an operator for holder");
		_burn(_msgSender(), account, amount, data, operatorData);
	}

	/**
	 * @dev See {IERC20-allowance}.
	 *
	 * Note that operator and allowance concepts are orthogonal: operators may
	 * not have allowance, and accounts with allowance may not be operators
	 * themselves.
	 */
	function allowance(address holder, address spender) public view returns (uint256) {
		return _allowances[holder][spender];
	}

	/**
	 * @dev See {IERC20-approve}.
	 *
	 * Note that accounts cannot have allowance issued by their operators.
	 */
	function approve(address spender, uint256 value) external returns (bool) {
		address holder = _msgSender();
		_approve(holder, spender, value);
		return true;
	}

	/**
	 * @dev See {IERC20-transferFrom}.
	 *
	 * Note that operator and allowance concepts are orthogonal: operators cannot
	 * call `transferFrom` (unless they have allowance), and accounts with
	 * allowance cannot call `operatorSend` (unless they are operators).
	 *
	 * Emits {Sent}, {Transfer} and {Approval} events.
	 */
	function transferFrom(address holder, address recipient, uint256 amount) external returns (bool) {
		require(recipient != address(0), "ERC777: transfer to the zero address");
		require(holder != address(0), "ERC777: transfer from the zero address");

		address spender = _msgSender();

		// KEYDONIX: Block re-entrancy specifically for uniswap, which is vulnerable to ERC-777 tokens
		if (msg.sender == uniswapExchange) {
			require(!uniswapExchangeReentrancyGuard, "Attempted to execute a Uniswap exchange while in the middle of a Uniswap exchange");
			uniswapExchangeReentrancyGuard = true;
		}
		_callTokensToSend(spender, holder, recipient, amount, "", "");
		if (msg.sender == uniswapExchange) {
			uniswapExchangeReentrancyGuard = false;
		}

		_move(spender, holder, recipient, amount, "", "");
		_approve(holder, spender, _allowances[holder][spender].sub(amount, "ERC777: transfer amount exceeds allowance"));

		_callTokensReceived(spender, holder, recipient, amount, "", "", false);

		return true;
	}

	/**
	 * @dev Creates `amount` tokens and assigns them to `account`, increasing
	 * the total supply.
	 *
	 * If a send hook is registered for `account`, the corresponding function
	 * will be called with `operator`, `data` and `operatorData`.
	 *
	 * See {IERC777Sender} and {IERC777Recipient}.
	 *
	 * Emits {Minted} and {Transfer} events.
	 *
	 * Requirements
	 *
	 * - `account` cannot be the zero address.
	 * - if `account` is a contract, it must implement the {IERC777Recipient}
	 * interface.
	 */
	function _mint(address operator, address account, uint256 amount, bytes memory userData, bytes memory operatorData) internal {
		require(account != address(0), "ERC777: mint to the zero address");

		// Update state variables
		_totalSupply = _totalSupply.add(amount);
		_balances[account] = _balances[account].add(amount);

		_callTokensReceived(operator, address(0), account, amount, userData, operatorData, true);

		emit Minted(operator, account, amount, userData, operatorData);
		emit Transfer(address(0), account, amount);
	}

	// KEYDONIX: changed visibility from private to internal, we reference this function in derived contract
	/**
	 * @dev Send tokens
	 * @param operator address operator requesting the transfer
	 * @param from address token holder address
	 * @param to address recipient address
	 * @param amount uint256 amount of tokens to transfer
	 * @param userData bytes extra information provided by the token holder (if any)
	 * @param operatorData bytes extra information provided by the operator (if any)
	 * @param requireReceptionAck if true, contract recipients are required to implement ERC777TokensRecipient
	 */
	function _send(address operator, address from, address to, uint256 amount, bytes memory userData, bytes memory operatorData, bool requireReceptionAck) internal {
		require(from != address(0), "ERC777: send from the zero address");
		require(to != address(0), "ERC777: send to the zero address");

		_callTokensToSend(operator, from, to, amount, userData, operatorData);

		_move(operator, from, to, amount, userData, operatorData);

		_callTokensReceived(operator, from, to, amount, userData, operatorData, requireReceptionAck);
	}

	// KEYDONIX: changed visibility from private to internal, we reference this function in derived contract
	/**
	 * @dev Burn tokens
	 * @param operator address operator requesting the operation
	 * @param from address token holder address
	 * @param amount uint256 amount of tokens to burn
	 * @param data bytes extra information provided by the token holder
	 * @param operatorData bytes extra information provided by the operator (if any)
	 */

	function _burn(address operator, address from, uint256 amount, bytes memory data, bytes memory operatorData) internal {
		require(from != address(0), "ERC777: burn from the zero address");

		_callTokensToSend(operator, from, address(0), amount, data, operatorData);

		// Update state variables
		_balances[from] = _balances[from].sub(amount, "ERC777: burn amount exceeds balance");
		_totalSupply = _totalSupply.sub(amount);

		emit Burned(operator, from, amount, data, operatorData);
		emit Transfer(from, address(0), amount);
	}

	function _move(address operator, address from, address to, uint256 amount, bytes memory userData, bytes memory operatorData) private {
		_balances[from] = _balances[from].sub(amount, "ERC777: transfer amount exceeds balance");
		_balances[to] = _balances[to].add(amount);

		emit Sent(operator, from, to, amount, userData, operatorData);
		emit Transfer(from, to, amount);
	}

	function _approve(address holder, address spender, uint256 value) private {
		// TODO: restore this require statement if this function becomes internal, or is called at a new callsite. It is
		// currently unnecessary.
		//require(holder != address(0), "ERC777: approve from the zero address");
		require(spender != address(0), "ERC777: approve to the zero address");

		_allowances[holder][spender] = value;
		emit Approval(holder, spender, value);
	}

	/**
	 * @dev Call from.tokensToSend() if the interface is registered
	 * @param operator address operator requesting the transfer
	 * @param from address token holder address
	 * @param to address recipient address
	 * @param amount uint256 amount of tokens to transfer
	 * @param userData bytes extra information provided by the token holder (if any)
	 * @param operatorData bytes extra information provided by the operator (if any)
	 */
	function _callTokensToSend(address operator, address from, address to, uint256 amount, bytes memory userData, bytes memory operatorData) private {
		address implementer = _erc1820.getInterfaceImplementer(from, TOKENS_SENDER_INTERFACE_HASH);
		if (implementer != address(0)) {
			IERC777Sender(implementer).tokensToSend(operator, from, to, amount, userData, operatorData);
		}
	}

	/**
	 * @dev Call to.tokensReceived() if the interface is registered. Reverts if the recipient is a contract but
	 * tokensReceived() was not registered for the recipient
	 * @param operator address operator requesting the transfer
	 * @param from address token holder address
	 * @param to address recipient address
	 * @param amount uint256 amount of tokens to transfer
	 * @param userData bytes extra information provided by the token holder (if any)
	 * @param operatorData bytes extra information provided by the operator (if any)
	 * @param requireReceptionAck if true, contract recipients are required to implement ERC777TokensRecipient
	 */
	function _callTokensReceived(address operator, address from, address to, uint256 amount, bytes memory userData, bytes memory operatorData, bool requireReceptionAck) private {
		address implementer = _erc1820.getInterfaceImplementer(to, TOKENS_RECIPIENT_INTERFACE_HASH);
		if (implementer != address(0)) {
			IERC777Recipient(implementer).tokensReceived(operator, from, to, amount, userData, operatorData);
		} else if (requireReceptionAck) {
			require(!to.isContract(), "ERC777: token recipient contract has no implementer for ERC777TokensRecipient");
		}
	}
}

contract MakerFunctions {
	// KEYDONIX: Renamed from `rmul` for clarity
	// KEYDONIX: Changed ONE to 10**27 for clarity
	function safeMul27(uint x, uint y) internal pure returns (uint z) {
		z = safeMul(x, y) / 10 ** 27;
	}

	function rpow(uint x, uint n, uint base) internal pure returns (uint z) {
		assembly {
			switch x case 0 {switch n case 0 {z := base} default {z := 0}}
			default {
				switch mod(n, 2) case 0 { z := base } default { z := x }
				let half := div(base, 2)  // for rounding.
				for { n := div(n, 2) } n { n := div(n,2) } {
				let xx := mul(x, x)
				if iszero(eq(div(xx, x), x)) { revert(0,0) }
				let xxRound := add(xx, half)
				if lt(xxRound, xx) { revert(0,0) }
				x := div(xxRound, base)
				if mod(n,2) {
					let zx := mul(z, x)
					if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
					let zxRound := add(zx, half)
					if lt(zxRound, zx) { revert(0,0) }
					z := div(zxRound, base)
				}
			}
			}
		}
	}

	// KEYDONIX: Renamed from `mul` due to shadowing warning from Solidity
	function safeMul(uint x, uint y) internal pure returns (uint z) {
		require(y == 0 || (z = x * y) / y == x);
	}
}

contract ReverseRegistrar {
	function setName(string memory name) public returns (bytes32 node);
}

contract DaiHrd is ERC777, MakerFunctions {
	event Deposit(address indexed from, uint256 depositedAttodai, uint256 mintedAttodaiHrd);
	event Withdrawal(address indexed from, address indexed to, uint256 withdrawnAttodai, uint256 burnedAttodaiHrd);
	event DepositVatDai(address indexed account, uint256 depositedAttorontodai, uint256 mintedAttodaiHrd);
	event WithdrawalVatDai(address indexed from, address indexed to, uint256 withdrawnAttorontodai, uint256 burnedAttodaiHrd);

	// uses this super constructor syntax instead of the preferred alternative syntax because my editor doesn't like the class syntax
	constructor(ReverseRegistrar reverseRegistrar) ERC777("DAI-HRD", "DAI-HRD", new address[](0)) public {
		dai.approve(address(daiJoin), uint(-1));
		vat.hope(address(pot));
		vat.hope(address(daiJoin));
		if (reverseRegistrar != ReverseRegistrar(0)) {
			reverseRegistrar.setName("dai-hrd.eth");
		}
	}

	function deposit(uint256 attodai) external returns(uint256 attodaiHrd) {
		dai.transferFrom(msg.sender, address(this), attodai);
		daiJoin.join(address(this), dai.balanceOf(address(this)));
		uint256 depositedAttopot = depositVatDaiForAccount(msg.sender);
		emit Deposit(msg.sender, attodai, depositedAttopot);
		return depositedAttopot;
	}

	// If the user has vat dai directly (after performing vault actions, for instance), they don't need to create the DAI ERC20 just so we can burn it, we'll accept vat dai
	function depositVatDai(uint256 attorontovatDai) external returns(uint256 attodaiHrd) {
		vat.move(msg.sender, address(this), attorontovatDai);
		uint256 depositedAttopot = depositVatDaiForAccount(msg.sender);
		emit DepositVatDai(msg.sender, attorontovatDai, depositedAttopot);
		return depositedAttopot;
	}

	function withdrawTo(address recipient, uint256 attodaiHrd) external returns(uint256 attodai) {
		// Don't need rontodaiPerPot, so we don't call updateAndFetchChi
		if (pot.rho() != now) pot.drip();
		return withdraw(recipient, attodaiHrd);
	}

	function withdrawToDenominatedInDai(address recipient, uint256 attodai) external returns(uint256 attodaiHrd) {
		uint256 rontodaiPerPot = updateAndFetchChi();
		attodaiHrd = convertAttodaiToAttodaiHrd(attodai, rontodaiPerPot);
		uint256 attodaiWithdrawn = withdraw(recipient, attodaiHrd);
		require(attodaiWithdrawn >= attodai, "DaiHrd/withdrawToDenominatedInDai: Not withdrawing enough DAI to cover request");
		return attodaiHrd;
	}

	function withdrawVatDai(address recipient, uint256 attodaiHrd) external returns(uint256 attorontodai) {
		require(recipient != address(0) && recipient != address(this), "DaiHrd/withdrawVatDai: Invalid recipient");
		// Don't need rontodaiPerPot, so we don't call updateAndFetchChi
		if (pot.rho() != now) pot.drip();
		_burn(address(0), msg.sender, attodaiHrd, new bytes(0), new bytes(0));
		pot.exit(attodaiHrd);
		attorontodai = vat.dai(address(this));
		vat.move(address(this), recipient, attorontodai);
		emit WithdrawalVatDai(msg.sender, recipient, attorontodai, attodaiHrd);
		return attorontodai;
	}

	// Dai specific functions. These functions all behave similar to standard ERC777 functions with input or output denominated in Dai instead of DaiHrd
	function balanceOfDenominatedInDai(address tokenHolder) external view returns(uint256 attodai) {
		uint256 rontodaiPerPot = calculatedChi();
		uint256 attodaiHrd = balanceOf(tokenHolder);
		return convertAttodaiHrdToAttodai(attodaiHrd, rontodaiPerPot);
	}

	function totalSupplyDenominatedInDai() external view returns(uint256 attodai) {
		uint256 rontodaiPerPot = calculatedChi();
		return convertAttodaiHrdToAttodai(totalSupply(), rontodaiPerPot);
	}

	function sendDenominatedInDai(address recipient, uint256 attodai, bytes calldata data) external {
		uint256 rontodaiPerPot = calculatedChi();
		uint256 attodaiHrd = convertAttodaiToAttodaiHrd(attodai, rontodaiPerPot);
		_send(_msgSender(), _msgSender(), recipient, attodaiHrd, data, "", true);
	}

	function burnDenominatedInDai(uint256 attodai, bytes calldata data) external {
		uint256 rontodaiPerPot = calculatedChi();
		uint256 attodaiHrd = convertAttodaiToAttodaiHrd(attodai, rontodaiPerPot);
		_burn(_msgSender(), _msgSender(), attodaiHrd, data, "");
	}

	function operatorSendDenominatedInDai(address sender, address recipient, uint256 attodai, bytes calldata data, bytes calldata operatorData) external {
		require(isOperatorFor(_msgSender(), sender), "ERC777: caller is not an operator for holder");

		uint256 rontodaiPerPot = calculatedChi();
		uint256 attodaiHrd = convertAttodaiToAttodaiHrd(attodai, rontodaiPerPot);
		_send(_msgSender(), sender, recipient, attodaiHrd, data, operatorData, true);
	}

	function operatorBurnDenominatedInDai(address account, uint256 attodai, bytes calldata data, bytes calldata operatorData) external {
		require(isOperatorFor(_msgSender(), account), "ERC777: caller is not an operator for holder");

		uint256 rontodaiPerPot = calculatedChi();
		uint256 attodaiHrd = convertAttodaiToAttodaiHrd(attodai, rontodaiPerPot);
		_burn(_msgSender(), account, attodaiHrd, data, operatorData);
	}

	// Utility Functions
	function calculatedChi() public view returns (uint256 rontodaiPerPot) {
		// mirrors Maker's calculation: rmul(rpow(dsr, now - rho, ONE), chi);
		return safeMul27(rpow(pot.dsr(), now - pot.rho(), 10 ** 27), pot.chi());
	}

	function convertAttodaiToAttodaiHrd(uint256 attodai, uint256 rontodaiPerPot ) private pure returns (uint256 attodaiHrd) {
		// + 1 is to compensate rounding? since attodaiHrd is rounded down
		return attodai.mul(10 ** 27).add(rontodaiPerPot - 1).div(rontodaiPerPot);
	}

	function convertAttodaiHrdToAttodai(uint256 attodaiHrd, uint256 rontodaiPerPot ) private pure returns (uint256 attodai) {
		return attodaiHrd.mul(rontodaiPerPot).div(10 ** 27);
	}

	function updateAndFetchChi() private returns (uint256 rontodaiPerPot) {
		return (pot.rho() == now) ? pot.chi() : pot.drip();
	}

	// Takes whatever vat dai has already been transferred to DaiHrd, gives to pot (DSR) and mints tokens for user
	function depositVatDaiForAccount(address account) private returns (uint256 attopotDeposited) {
		uint256 rontodaiPerPot = updateAndFetchChi();
		uint256 attopotToDeposit = vat.dai(address(this)) / rontodaiPerPot;
		pot.join(attopotToDeposit);
		_mint(address(0), account, attopotToDeposit, new bytes(0), new bytes(0));
		return attopotToDeposit;
	}

	// Internal implementations of functions with multiple entrypoints. drip() should be called prior to this call
	function withdraw(address recipient, uint256 attodaiHrd) private returns(uint256 attodaiWithdrawn) {
		require(recipient != address(0) && recipient != address(this), "DaiHrd/withdraw: Invalid recipient");
		_burn(address(0), msg.sender, attodaiHrd, new bytes(0), new bytes(0));
		pot.exit(attodaiHrd);
		daiJoin.exit(address(this), vat.dai(address(this)) / 10**27);
		uint256 attodai = dai.balanceOf(address(this));
		dai.transfer(recipient, attodai);
		emit Withdrawal(msg.sender, recipient, attodai, attodaiHrd);
		return attodai;
	}
}

