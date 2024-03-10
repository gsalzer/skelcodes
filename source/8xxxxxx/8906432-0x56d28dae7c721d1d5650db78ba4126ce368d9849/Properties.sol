/**
 *Submitted for verification at Etherscan.io on 2019-10-01
*/

// File: contracts/Math/SafeMath.sol

pragma solidity ^0.5.7;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
  * @dev Multiplies two numbers, throws on overflow.
  */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
  * @dev Adds two numbers, throws on overflow.
  */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

// File: contracts/Properties/IProperties.sol

pragma solidity ^0.5.7;

/**
@title IProperties
@dev This contract represents properties contract interface */
contract IProperties {
    /**
    @notice fired when owner is changed
     */
    event OwnerChanged(address newOwner);

    /**
    @notice fired when a manager's status is set
     */
    event ManagerSet(address manager, bool status);

    /**
    @notice fired when a new property is created
     */
    event PropertyCreated(
        uint256 propertyId,
        uint256 allocationCapacity,
        string title,
        string location,
        uint256 marketValue,
        uint256 maxInvestedATperInvestor,
        uint256 totalAllowedATinvestments,
        address AT,
        uint256 dateAdded
    );

    /**
    @notice fired when the status of a property is updated
     */
    event PropertyStatusUpdated(uint256 propertyId, uint256 status);

    /**
    @notice fired when a property is invested in
     */
    event PropertyInvested(uint256 propertyId, uint256 tokens);

    /**
    @dev fired when investment contract's status is set
    */
    event InvestmentContractStatusSet(address investmentContract, bool status);

    /**
    @dev fired when a property is updated
    s */
    event PropertyUpdated(uint256 propertyId);

    /**
    @dev function to change the owner
    @param newOwner the address of new owner
     */
    function changeOwner(address newOwner) external;

    /**
    @dev function to set the status of manager
    @param manager address of manager
    @param status the status to set
     */
    function setManager(address manager, bool status) external;

    /**
    @dev function to create a new property
    @param  allocationCapacity refers to the number of ATs allocated to a property
    @param title title of property
    @param location location of property
    @param marketValue market value of property in USD
    @param maxInvestedATperInvestor absolute amount of shares that could be allocated per person
    @param totalAllowedATinvestments absolute amount of shares to be issued
    @param AT address of AT contract
    */
    function createProperty(
        uint256 allocationCapacity,
        string memory title,
        string memory location,
        uint256 marketValue,
        uint256 maxInvestedATperInvestor,
        uint256 totalAllowedATinvestments,
        address AT
    ) public returns (bool);

    /**
    @notice function is called to update a property's status
    @param propertyId ID of the property
    @param status status of the property
     */
    function updatePropertyStatus(uint256 propertyId, uint256 status) external;

    /**
    @notice function is called to invest in the property
    @param investor the address of the investor
    @param propertyId the ID of the property to invest in
    @param shares the amount of shares being invested
     */
    function invest(address investor, uint256 propertyId, uint256 shares)
        public
        returns (bool);

    /**
    @dev this function is called to set the status of an investment contract
    @param investmentContract the address of investment contract
    @param status status of the investment smart contact
     */
    function setInvestmentContractStatus(
        address investmentContract,
        bool status
    ) external;

    /**
    @notice the function returns the paramters of a property
    @param propertyId the ID of the property to get
     */
    function getProperty(uint256 propertyId)
        public
        view
        returns (
            uint256,
            uint256,
            string memory,
            string memory,
            uint256,
            uint256,
            uint256,
            address,
            uint256,
            uint8
        );

    /**
    @notice function returns the list of property investors
    @param from the starting number . minimum = 0
    @param to the ending number
     */
    function getPropertyInvestors(uint256 propertyId, uint256 from, uint256 to)
        public
        view
        returns (address[] memory);

    /**
    @notice Called to get the total amount of investment and investment for a specific holder for a property
    @param propertyId The ID of the property
    @param holder The address of the holder
    @return The total amount of investment
    @return The amount of shares owned by the holder */
    function getTotalAndHolderShares(uint256 propertyId, address holder)
        public
        view
        returns (uint256 totalShares, uint256 holderShares);
}

// File: contracts/Properties/Properties.sol

pragma solidity ^0.5.7;



/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract IERC721Receiver {
    /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   * after a `safeTransfer`. This function MUST return the function selector,
   * otherwise the caller will revert the transaction. The selector to be
   * returned can be obtained as `this.onERC721Received.selector`. This
   * function MAY throw to revert and reject the transfer.
   * Note: the ERC721 contract address is always the message sender.
   * @param operator The address which called `safeTransferFrom` function
   * @param from The address which previously owned the token
   * @param tokenId The NFT identifier which is being transferred
   * @param data Additional data with no specified format
   * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
   */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public returns (bytes4);
}

library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

}

/**
 * @title IERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {
    /**
   * @notice Query if a contract implements an interface
   * @param interfaceId The interface identifier, as specified in ERC-165
   * @dev Interface identification is specified in ERC-165. This function
   * uses less than 30,000 gas.
   */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
/**
 * @title ERC165
 * @author Matt Condon (@shrugs)
 * @dev Implements ERC165 using a lookup table.
 */
contract ERC165 is IERC165 {
    bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
    /**
   * 0x01ffc9a7 ===
   *   bytes4(keccak256('supportsInterface(bytes4)'))
   */

    /**
   * @dev a mapping of interface id to whether or not it's supported
   */
    mapping(bytes4 => bool) internal _supportedInterfaces;

    /**
   * @dev A contract implementing SupportsInterfaceWithLookup
   * implement ERC165 itself
   */
    constructor() public {
        _registerInterface(_InterfaceId_ERC165);
    }

    /**
   * @dev implement supportsInterface(bytes4) using a lookup table
   */
    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool)
    {
        return _supportedInterfaces[interfaceId];
    }

    /**
   * @dev private method for registering an interface
   */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}
contract IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);

    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId)
        public
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator)
        public
        view
        returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public;
}
contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from token ID to owner
    mapping(uint256 => address) private _tokenOwner;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to number of owned token
    mapping(address => uint256) private _ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    bytes4 private constant _InterfaceId_ERC721 = 0x80ac58cd;
    /*
   * 0x80ac58cd ===
   *   bytes4(keccak256('balanceOf(address)')) ^
   *   bytes4(keccak256('ownerOf(uint256)')) ^
   *   bytes4(keccak256('approve(address,uint256)')) ^
   *   bytes4(keccak256('getApproved(uint256)')) ^
   *   bytes4(keccak256('setApprovalForAll(address,bool)')) ^
   *   bytes4(keccak256('isApprovedForAll(address,address)')) ^
   *   bytes4(keccak256('transferFrom(address,address,uint256)')) ^
   *   bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
   *   bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'))
   */

    constructor() public {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_InterfaceId_ERC721);
    }

    /**
   * @dev Gets the balance of the specified address
   * @param owner address to query the balance of
   * @return uint256 representing the amount owned by the passed address
   */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0));
        return _ownedTokensCount[owner];
    }

    /**
   * @dev Gets the owner of the specified token ID
   * @param tokenId uint256 ID of the token to query the owner of
   * @return owner address currently marked as the owner of the given token ID
   */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0));
        return owner;
    }

    /**
   * @dev Approves another address to transfer the given token ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per token at a given time.
   * Can only be called by the token owner or an approved operator.
   * @param to address to be approved for the given token ID
   * @param tokenId uint256 ID of the token to be approved
   */
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * Reverts if the token ID does not exist.
   * @param tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for the given token ID
   */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId));
        return _tokenApprovals[tokenId];
    }

    /**
   * @dev Sets or unsets the approval of a given operator
   * An operator is allowed to transfer all tokens of the sender on their behalf
   * @param to operator address to set the approval
   * @param approved representing the status of the approval to be set
   */
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender);
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    /**
   * @dev Tells whether an operator is approved by a given owner
   * @param owner owner address which you want to query the approval of
   * @param operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
    function isApprovedForAll(address owner, address operator)
        public
        view
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
   * @dev Transfers the ownership of a given token ID to another address
   * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
   * Requires the msg sender to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
  */
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId));
        require(to != address(0));

        _clearApproval(from, tokenId);
        _removeTokenFrom(from, tokenId);
        _addTokenTo(to, tokenId);

        emit Transfer(from, to, tokenId);
    }

    /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   *
   * Requires the msg sender to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
  */
    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
    {
        // solium-disable-next-line arg-overflow
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg sender to be the owner, approved, or operator
   * @param from current owner of the token
   * @param to address to receive the ownership of the given token ID
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes data to send along with a safe transfer check
   */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public {
        transferFrom(from, to, tokenId);
        // solium-disable-next-line arg-overflow
        require(_checkAndCallSafeTransfer(from, to, tokenId, _data));
    }

    /**
   * @dev Returns whether the specified token exists
   * @param tokenId uint256 ID of the token to query the existence of
   * @return whether the token exists
   */
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    /**
   * @dev Returns whether the given spender can transfer a given token ID
   * @param spender address of the spender to query
   * @param tokenId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   *  is an operator of the owner, or is the owner of the token
   */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        address owner = ownerOf(tokenId);
        // Disable solium check because of
        // https://github.com/duaraghav8/Solium/issues/175
        // solium-disable-next-line operator-whitespace
        return (
            spender == owner ||
                getApproved(tokenId) == spender ||
                isApprovedForAll(owner, spender)
        );
    }

    /**
   * @dev Internal function to mint a new token
   * Reverts if the given token ID already exists
   * @param to The address that will own the minted token
   * @param tokenId uint256 ID of the token to be minted by the msg.sender
   */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0));
        _addTokenTo(to, tokenId);
        emit Transfer(address(0), to, tokenId);
    }

    /**
   * @dev Internal function to burn a specific token
   * Reverts if the token does not exist
   * @param tokenId uint256 ID of the token being burned by the msg.sender
   */
    function _burn(address owner, uint256 tokenId) internal {
        _clearApproval(owner, tokenId);
        _removeTokenFrom(owner, tokenId);
        emit Transfer(owner, address(0), tokenId);
    }

    /**
   * @dev Internal function to clear current approval of a given token ID
   * Reverts if the given address is not indeed the owner of the token
   * @param owner owner of the token
   * @param tokenId uint256 ID of the token to be transferred
   */
    function _clearApproval(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner);
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }

    /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param to address representing the new owner of the given token ID
   * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
    function _addTokenTo(address to, uint256 tokenId) internal {
        require(_tokenOwner[tokenId] == address(0));
        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);
    }

    /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param from address representing the previous owner of the given token ID
   * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
    function _removeTokenFrom(address from, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from);
        _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
        _tokenOwner[tokenId] = address(0);
    }

    /**
   * @dev Internal function to invoke `onERC721Received` on a target address
   * The call is not executed if the target address is not a contract
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return whether the call correctly returned the expected magic value
   */
    function _checkAndCallSafeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }
        bytes4 retval = IERC721Receiver(to).onERC721Received(
            msg.sender,
            from,
            tokenId,
            _data
        );
        return (retval == _ERC721_RECEIVED);
    }
}
/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */

contract Properties is IProperties, ERC721 {
    enum Status {INVESTABLE, UNINVESTABLE} // enum representing state of a property

    mapping(address => bool) public managers; // mapping of managers
    mapping(address => bool) public investmentContracts; // mapping of investment contracts

    /**
    @dev A struct representing property
     */
    struct Property {
        uint256 id; // ID of the property
        uint256 currentAllocation; // refers to the number of ATs allocated to a property
        string title; // title of property
        string location; // location of property
        uint256 marketValue; // market value of property in USD
        uint256 maxInvestedATperInvestor; //absolute amount of shares that could be allocated per person
        uint256 allocationCapacity; //absolute amount of shares to be issued
        address AT; // address of AT contract
        uint256 dateAdded; // date of property
        Status status; // status of property ( Investable/ Uninvestable )
        address[] investors; // list of investors.
        mapping(address => uint256) investments; // mapping from investor to its investments
    }

    mapping(uint256 => Property) public properties; // mapping of properties
    uint256 propertyCount = 0; // count of properties

    address public owner; // address of owner

    /**
    @notice constructor of Properties contract
     */
    constructor() public {
        owner = msg.sender; // The Sender is the Owner; Ethereum Address of the Owner
    }

    /**
    @notice only owner can pass through this modifier
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner can call this function");
        _;
    }

    /**
    @notice only manager can pass through this modifier
     */
    modifier onlyManager() {
        require(managers[msg.sender], "Only managers can call this function.");
        _;
    }

    /**
    @notice only investment contract can pass through this modifier
     */
    modifier onlyInvestmentContracts() {
        require(
            investmentContracts[msg.sender],
            "Only investment contracts are allowed to call this function."
        );
        _;
    }

    /**
    @dev function to change the owner
    @param newOwner the address of new owner
     */
    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0x0), "Owner address is invalid.");
        owner = newOwner;

        emit OwnerChanged(newOwner);
    }

    /**
    @dev function to set the status of manager
    @param manager address of manager
    @param status the status to set
     */
    function setManager(address manager, bool status) external onlyOwner {
        require(manager != address(0x0), "Manager address is invalid.");
        require(managers[manager] != status, "Provided status is already set.");

        managers[manager] = status;

        emit ManagerSet(manager, status);
    }

    /**
    @dev function to create a new property
    @param  currentAllocation refers to the number of ATs allocated to a property
    @param title title of property
    @param location location of property
    @param marketValue market value of property in USD
    @param maxInvestedATperInvestor absolute amount of shares that could be allocated per person
    @param allocationCapacity absolute amount of shares to be issued
    @param AT address of AT contract
    */
    function createProperty(
        uint256 currentAllocation,
        string memory title,
        string memory location,
        uint256 marketValue,
        uint256 maxInvestedATperInvestor,
        uint256 allocationCapacity,
        address AT
    ) public onlyManager returns (bool) {
        propertyCount = propertyCount + 1;

        Property memory newProperty = Property(
            propertyCount,
            currentAllocation,
            title,
            location,
            marketValue,
            maxInvestedATperInvestor,
            allocationCapacity,
            AT,
            now,
            Status.INVESTABLE,
            new address[](0)
        );

        properties[propertyCount] = newProperty;

        emit PropertyCreated(
            propertyCount,
            currentAllocation,
            title,
            location,
            marketValue,
            maxInvestedATperInvestor,
            allocationCapacity,
            AT,
            now
        );

        return true;
    }

    /**
    @notice function is called to update property
    @param propertyId ID of the property
    @param marketValue USD value of the market
    @param AT address of the AT token for the given property
     */
    function updateProperty(uint256 propertyId, uint256 marketValue, address AT)
        public
        onlyManager
        returns (bool)
    {
        require(propertyId >= 0, "Property ID is invalid.");

        Property storage property = properties[propertyId];
        property.marketValue = marketValue;
        property.AT = AT;

        emit PropertyUpdated(propertyId);
    }

    /**
    @notice function is called to update a property's status
    @param propertyId ID of the property
    @param status status of the property
     */
    function updatePropertyStatus(uint256 propertyId, uint256 status)
        external
        onlyManager
    {
        require(propertyId >= 0, "Property ID is invalid.");
        require(
            properties[propertyId].status != Status(status),
            "This status is already set."
        );

        properties[propertyId].status = Status(status);

        emit PropertyStatusUpdated(propertyId, status);
    }

    /**
    @notice function is called to invest in the property
    @param investor the address of the investor
    @param propertyId the ID of the property to invest in
    @param shares the amount of shares being invested
     */
    function invest(address investor, uint256 propertyId, uint256 shares)
        public
        onlyInvestmentContracts
        returns (bool)
    {
        require(propertyId >= 0, "Property ID is invalid.");

        Property storage property = properties[propertyId];

        require(uint8(property.status) == 0, "property is not investable");

        require(
            property.investments[investor].add(shares) <=
                property.maxInvestedATperInvestor,
            "Amount of shares exceed the maximum allowed limit per investor."
        );
        require(
            shares.add(property.currentAllocation) <=
                property.allocationCapacity,
            "Amount of shares exceed the maximum allowed capacity."
        );

        property.currentAllocation = property.currentAllocation.add(shares);

        if (property.investments[investor] == 0) {
            property.investors.push(investor);
        }

        property.investments[investor] = property.investments[investor].add(
            shares
        );

        emit PropertyInvested(propertyId, shares);

        return true;

    }

    /**
    @dev this function is called to set the status of an investment contract
    @param investmentContract the address of investment contract
    @param status status of the investment smart contact
     */
    function setInvestmentContractStatus(
        address investmentContract,
        bool status
    ) external onlyManager {
        require(
            investmentContract != address(0),
            "investmentContract address cannot be zero address."
        );
        require(
            investmentContracts[investmentContract] != status,
            "the status is already set."
        );

        investmentContracts[investmentContract] = status;

        emit InvestmentContractStatusSet(investmentContract, status);
    }

    /**
    @notice the function returns the paramters of a property
    @param propertyId the ID of the property to get
     */
    function getProperty(uint256 propertyId)
        public
        view
        returns (
            uint256,
            uint256,
            string memory,
            string memory,
            uint256,
            uint256,
            uint256,
            address,
            uint256,
            uint8
        )
    {
        require(propertyId >= 0, "Property ID is invalid.");

        Property memory property = properties[propertyId];

        return (
            property.id,
            property.currentAllocation,
            property.title,
            property.location,
            property.marketValue,
            property.maxInvestedATperInvestor,
            property.allocationCapacity,
            property.AT,
            property.dateAdded,
            uint8(property.status)
        );
    }

    /**
    @notice function returns the list of property investors
    @param from the starting number . minimum = 0
    @param to the ending number
     */
    function getPropertyInvestors(uint256 propertyId, uint256 from, uint256 to)
        public
        view
        returns (address[] memory)
    {
        require(propertyId >= 0, "Property ID is invalid.");

        Property memory property = properties[propertyId];

        uint256 length = to - from;

        address[] memory investors = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            investors[i] = property.investors[from + i];
        }

        return investors;
    }

    /**
    @notice Called to get the total amount of investment and investment for a specific holder for a property
    @param propertyId The ID of the property
    @param holder The address of the holder
    @return The total amount of investment
    @return The amount of shares owned by the holder */
    function getTotalAndHolderShares(uint256 propertyId, address holder)
        public
        view
        returns (uint256 totalShares, uint256 holderShares)
    {
        require(propertyId >= 0, "Property ID is invalid.");

        Property storage property = properties[propertyId];

        totalShares = property.allocationCapacity;
        holderShares = property.investments[holder];
    }

}
