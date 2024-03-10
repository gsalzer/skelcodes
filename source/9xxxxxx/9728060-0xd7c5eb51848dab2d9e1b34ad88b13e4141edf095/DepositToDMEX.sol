pragma solidity >0.4.99 <0.6.0;

// https://theethereum.wiki/w/index.php/ERC20_Token_Standard
contract ERC20Interface {
    function approve(address spender, uint tokens) public returns (bool success);
    function balanceOf(address tokenOwner) public view returns (uint balance);
}

contract DMEXBaseInterface {
    function depositTokenForUser(address token, uint128 amount, address user) public;
}

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    /**
     * @dev Sets the `implementer` contract as `account`'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(address account, bytes32 interfaceHash, address implementer) external;
}

contract DepositToDMEX { 
    address public owner;
    address public dmex_contract;


    constructor(address owner_, address dmex_contract_, address token) public {
        owner = owner_;
        dmex_contract = dmex_contract_;
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24).setInterfaceImplementer(address(this), keccak256("ERC777TokensRecipient"), address(this));
        sendTokensToDMEX(token);
    }
    
    function sendTokensToDMEX(address token) public
    {
        uint256 availableBalance = ERC20Interface(token).balanceOf(address(this));
        uint128 shortAvailableBalance = uint128(availableBalance);
        ERC20Interface(token).approve(dmex_contract, availableBalance);
        DMEXBaseInterface(dmex_contract).depositTokenForUser(token, shortAvailableBalance, owner);
    }

    function tokensReceived(address operator, address from, address to, uint256 amount, bytes memory userData, bytes memory operatorData) public
    {
        sendTokensToDMEX(msg.sender);
    }


}
