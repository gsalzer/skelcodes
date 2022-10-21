/*--------------------------------------------------------PRüF0.8.0
__/\\\\\\\\\\\\\ _____/\\\\\\\\\ _______/\\__/\\ ___/\\\\\\\\\\\\\\\        
 _\/\\\/////////\\\ _/\\\///////\\\ ____\//__\//____\/\\\///////////__       
  _\/\\\_______\/\\\_\/\\\_____\/\\\ ________________\/\\\ ____________      
   _\/\\\\\\\\\\\\\/__\/\\\\\\\\\\\/_____/\\\____/\\\_\/\\\\\\\\\\\ ____     
    _\/\\\/////////____\/\\\//////\\\ ___\/\\\___\/\\\_\/\\\///////______    
     _\/\\\ ____________\/\\\ ___\//\\\ __\/\\\___\/\\\_\/\\\ ____________   
      _\/\\\ ____________\/\\\ ____\//\\\ _\/\\\___\/\\\_\/\\\ ____________  
       _\/\\\ ____________\/\\\ _____\//\\\_\//\\\\\\\\\ _\/\\\ ____________ 
        _\/// _____________\/// _______\/// __\///////// __\/// _____________
         *-------------------------------------------------------------------*/

/*-----------------------------------------------------------------
 *  TO DO
 *
 *---------------------------------------------------------------*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

struct Record {
    uint8 assetStatus; // Status - Transferrable, locked, in transfer, stolen, lost, etc.
    uint8 modCount; // Number of times asset has been forceModded.
    uint8 currency; //currency for price information (0=not for sale, 1=ETH, 2=PRUF, 3=DAI, 4=WBTC.... )
    uint16 numberOfTransfers; //number of transfers and forcemods
    uint32 assetClass; // Type of asset
    uint32 countDown; // Variable that can only be dencreased from countDownStart
    uint32 countDownStart; // Starting point for countdown variable (set once)
    uint120 price; //price set for items offered for sale
    bytes32 Ipfs1a; // Publically viewable asset description
    bytes32 Ipfs2a; // Publically viewable immutable notes
    bytes32 Ipfs1b; // Publically viewable asset description
    bytes32 Ipfs2b; // Publically viewable immutable notes
    bytes32 rightsHolder; // KEK256 Registered owner
}

struct AC {
    //Struct for holding and manipulating assetClass data
    string name; // NameHash for assetClass
    uint32 assetClassRoot; // asset type root (bicyles - USA Bicycles)             //immutable
    uint8 custodyType; // custodial or noncustodial, special asset types       //immutable
    uint8 managementType; // type of management for asset creation, import, export //immutable
    uint8 storageProvider; // Storage Provider
    uint32 discount; // price sharing //internal admin                                      //immutable
    address referenceAddress; // Used with wrap / decorate
    uint8 switches; // bitwise Flags for AC control                          //immutable
    bytes32 IPFS; //IPFS data for defining idxHash creation attribute fields
}

struct ContractDataHash {
    //Struct for holding and manipulating contract authorization data
    uint8 contractType; // Auth Level / type
    bytes32 nameHash; // Contract Name hashed
}

struct DefaultContract {
    //Struct for holding and manipulating contract authorization data
    uint8 contractType; // Auth Level / type
    string name; // Contract name
}

struct escrowData {
    bytes32 controllingContractNameHash; //hash of the name of the controlling escrow contract
    bytes32 escrowOwnerAddressHash; //hash of an address designated as an executor for the escrow contract
    uint256 timelock;
}

struct escrowDataExtLight {
    //used only in recycle
    //1 slot
    uint8 escrowData; //used by recycle
    uint8 u8_1;
    uint8 u8_2;
    uint8 u8_3;
    uint16 u16_1;
    uint16 u16_2;
    uint32 u32_1;
    address addr_1; //used by recycle
}

struct escrowDataExtHeavy {
    //specific uses not defined
    // 5 slots
    uint32 u32_2;
    uint32 u32_3;
    uint32 u32_4;
    address addr_2;
    bytes32 b32_1;
    bytes32 b32_2;
    uint256 u256_1;
    uint256 u256_2;
}

struct Costs {
    //make these require full epoch to change???
    uint256 serviceCost; // Cost in the given item category
    address paymentAddress; // 2nd-party fee beneficiary address
}

struct Invoice {
    //invoice struct to facilitate payment messaging in-contract
    uint32 assetClass;
    address rootAddress;
    address ACTHaddress;
    uint256 rootPrice;
    uint256 ACTHprice;
}

struct ID {
    //ID struct for ID info
    uint256 trustLevel; //admin only
    bytes32 URI; //caller address match
    string userName; //admin only///caller address match can set
}

/*
 * @dev Interface for UTIL_TKN
 * INHERIANCE:
    import "./Imports/access/AccessControl.sol";
    import "./Imports/token/ERC20/ERC20.sol";
    import "./Imports/token/ERC20/ERC20Burnable.sol";
    import "./Imports/token/ERC20/ERC20Pausable.sol";
    import "./Imports/token/ERC20/ERC20Snapshot.sol";
 */
interface UTIL_TKN_Interface {
    /*
     * @dev PERMENANTLY !!!  Kill trusted agent and payable
     */
    function killTrustedAgent(uint256 _key) external;

    /*
     * @dev Set calling wallet to a "cold Wallet" that cannot be manipulated by TRUSTED_AGENT or PAYABLE permissioned functions
     */
    function setColdWallet() external;

    /*
     * @dev un-set calling wallet to a "cold Wallet", enabling manipulation by TRUSTED_AGENT and PAYABLE permissioned functions
     */
    function unSetColdWallet() external;

    /*
     * @dev return an adresses "cold wallet" status
     */
    function isColdWallet(address _addr) external returns (uint256);

    /*
     * @dev Set adress of payment contract
     */
    function AdminSetSharesAddress(address _paymentAddress) external;

    /*
     * @dev Deducts token payment from transaction
     * Requirements:
     * - the caller must have PAYABLE_ROLE.
     * - the caller must have a pruf token balance of at least `_rootPrice + _ACTHprice`.
     */
    // ---- NON-LEGACY
    // function payForService(address _senderAddress, Invoice calldata invoice)
    //     external;

    //---- LEGACY
    function payForService(
        address _senderAddress,
        address _rootAddress,
        uint256 _rootPrice,
        address _ACTHaddress,
        uint256 _ACTHprice
    ) external;

    /*
     * @dev arbitrary burn (requires TRUSTED_AGENT_ROLE)   ****USE WITH CAUTION
     */
    function trustedAgentBurn(address _addr, uint256 _amount) external;

    /*
     * @dev arbitrary transfer (requires TRUSTED_AGENT_ROLE)   ****USE WITH CAUTION
     */
    function trustedAgentTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    /*
     * @dev Take a balance snapshot, returns snapshot ID
     * - the caller must have the `SNAPSHOT_ROLE`.
     */
    function takeSnapshot() external returns (uint256);

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() external;

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() external;

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId)
        external
        returns (uint256);

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) external returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external;

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external;

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() external returns (uint256);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external returns (bool);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external returns (uint256);

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index)
        external
        returns (address);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

//------------------------------------------------------------------------------------------------
/*
 * @dev Interface for AC_TKN
 * INHERIANCE:
    import "./Imports/token/ERC721/ERC721.sol";
    import "./Imports/access/Ownable.sol";
    import "./Imports/utils/ReentrancyGuard.sol";
 */
interface AC_TKN_Interface {
    /*
     * @dev Set storage contract to interface with
     */
    function OO_setStorageContract(address _storageAddress) external;

    /*
     * @dev Address Setters
     */
    function Admin_resolveContractAddresses() external;

    /*
     * @dev Mints assetClass token, must be isContractAdmin
     */
    function mintACToken(
        address _recipientAddress,
        uint256 tokenId,
        string calldata _tokenURI
    ) external returns (uint256);


    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * Requires the _msgSender() to be the owner, approved, or operator.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the _msgSender() to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the _msgSender() to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata _data
    ) external;

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId)
        external
        view
        returns (address tokenHolderAdress);

    /**
     * @dev Returns 170 if the specified token exists, otherwise zero
     *
     */
    function tokenExists(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external returns (uint256);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory tokenName);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory tokenSymbol);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId)
        external
        view
        returns (string memory URI);

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

//------------------------------------------------------------------------------------------------
/*
 * @dev Interface for A_TKN
 * INHERIANCE:
    import "./Imports/token/ERC721/ERC721.sol";
    import "./Imports/access/Ownable.sol";
    import "./Imports/utils/ReentrancyGuard.sol";
 */
interface A_TKN_Interface {
    /*
     * @dev Set storage contract to interface with
     */
    function OO_setStorageContract(address _storageAddress) external;

    /*
     * @dev Address Setters
     */
    function Admin_resolveContractAddresses() external;

    /*
     * @dev Mint new asset token
     */
    function mintAssetToken(
        address _recipientAddress,
        uint256 tokenId,
        string calldata _tokenURI
    ) external returns (uint256);


    /*
     * @dev Set new token URI String
     */
    function setURI(uint256 tokenId, string calldata _tokenURI)
        external
        returns (uint256);

    // /*
    //  * @dev Reassures user that token is minted in the PRUF system
    //  */
    // function validatePipToken(
    //     uint256 tokenId,
    //     uint32 _assetClass,
    //     string calldata _authCode
    // ) external view;

    /*
     * @dev See if token exists
     */
    function tokenExists(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * Requires the _msgSender() to be the owner, approved, or operator.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers the ownership of a given token ID to another address by a TRUSTED_AGENT.
     * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * Requires the _msgSender() to be the owner, approved, or operator.
     * @param _from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function trustedAgentTransferFrom(
        address _from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Burns a token
     */
    function trustedAgentBurn(uint256 tokenId) external;

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the _msgSender() to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the _msgSender() to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata _data
    ) external;

    /**
     * @dev Safely burns a token and sets the corresponding RGT to zero in storage.
     */
    function discard(uint256 tokenId) external;

    /**
     * @dev return an adresses "cold wallet" status
     * WALLET ADDRESSES SET TO "Cold" DO NOT WORK WITH TRUSTED_AGENT FUNCTIONS
     * @param _addr - address to check
     * returns 170 if adress is set to "cold wallet" status
     */
    function isColdWallet(address _addr) external returns (uint256);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId)
        external
        returns (address tokenHolderAdress);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external returns (uint256);

    /**
     * @dev Returns the name of the token.
     */
    function name() external returns (string memory tokenName);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external returns (string memory tokenSymbol);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external returns (string memory URI);

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external returns (uint256);
}

//------------------------------------------------------------------------------------------------
/*
 * @dev Interface for ID_TKN
 * INHERIANCE:
    import "./Imports/token/ERC721/ERC721.sol";
    import "./Imports/access/Ownable.sol";
    import "./Imports/utils/ReentrancyGuard.sol";
 */
interface ID_TKN_Interface {
    /*
     * @dev Mint new PRUF_ID token
     */
    function mintPRUF_IDToken(
        address _recipientAddress,
        uint256 _tokenId,
        string calldata _URI
    ) external returns (uint256);

    /*
     * @dev remint ID Token
     * must set a new and unuiqe rgtHash
     * burns old token
     * Sends new token to original Caller
     */
    function reMintPRUF_IDToken(address _recipientAddress, uint256 tokenId)
        external
        returns (uint256);

    /*
     * @dev See if token exists
     */
    function tokenExists(uint256 tokenId) external view returns (uint256);

    /**
     * @dev @dev Blocks the transfer of a given token ID to another address
     * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * Requires the _msgSender() to be the owner, approved, or operator.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Safely blocks the transfer of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the _msgSender() to be the owner, approved, or operator
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Safely blocks the transfer of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the _msgSender() to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata _data
    ) external;

    /*
     * @dev Set new ID data fields
     */
    function setTrustLevel(uint256 _tokenId, uint256 _trustLevel) external;

    /*
     * @dev get ID data
     */
    function IdData(uint256 _tokenId) external view returns (ID memory);

    /*
     * @dev get ID trustLevel
     */
    function trustedLevel(uint256 _tokenId) external view returns (uint256);

    /*
     * @dev get ID trustLevel by address (token 0 at address)
     */
    function trustedLevelByAddress(address _addr)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId)
        external
        view
        returns (address tokenHolderAdress);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external returns (uint256);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory tokenName);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory tokenSymbol);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId)
        external
        view
        returns (string memory URI);

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

//------------------------------------------------------------------------------------------------
/*
 * @dev Interface for AC_MGR
 * INHERIANCE:
    import "./PRUF_BASIC.sol";
     
 */
interface AC_MGR_Interface {
    /*
     * @dev Set pricing
     */
    function OO_SetACpricing(uint256 _L1) external;

    /*
     * @dev Tincreases (but cannot decrease) price share for a given AC
     * !! to be used with great caution
     * This breaks decentralization and must eventually be given over to some kind of governance contract.
     */
    function adminIncreaseShare(uint32 _assetClass, uint32 _newDiscount)
        external;

    /*
     * @dev Transfers a name from one asset class to another
     * !! -------- to be used with great caution and only as a result of community governance action -----------
     * Designed to remedy brand infringement issues. This breaks decentralization and must eventually be given
     * over to some kind of governance contract.
     * Destination AC must have IPFS Set to 0xFFF.....
     *
     */
    function transferName(
        uint32 _assetClass_source,
        uint32 _assetClass_dest,
        string calldata _name
    ) external;

    /*
     * @dev Modifies an asset class with minimal controls
     *--------DPS TEST ---- NEW args, order
     */
    function AdminModAssetClass(
        uint32 _assetClass,
        uint32 _assetClassRoot,
        uint8 _custodyType,
        uint8 _managementType,
        uint8 _storageProvider,
        uint32 _discount,
        address _refAddress,
        uint8 _switches,
        bytes32 _IPFS
    ) external;

    /*
     * @dev Mints asset class token and creates an assetClass. Mints to @address
     * Requires that:
     *  name is unuiqe
     *  AC is not provisioned with a root (proxy for not yet registered)
     *  that ACtoken does not exist
     *  _discount 10000 = 100 percent price share , cannot exceed
     */
    function createAssetClass(
        uint32 _assetClass,
        string calldata _name,
        uint32 _assetClassRoot,
        uint8 _custodyType,
        uint8 _managementType,
        uint32 _discount,
        bytes32 _IPFS,
        address _recipientAddress
    ) external;

    /**
     * @dev Burns (amount) tokens and mints a new asset class token to the caller address
     *
     * Requirements:
     * - the caller must have a balance of at least `amount`.
     */
    function purchaseACnode(
        string calldata _name,
        uint32 _assetClassRoot,
        uint8 _custodyType,
        bytes32 _IPFS
    ) external returns (uint256);

    /*
     * @dev Authorize / Deauthorize / Authorize users for an address be permitted to make record modifications
     */
    function addUser(
        uint32 _assetClass,
        bytes32 _addrHash,
        uint8 _userType
    ) external;

    /*
     * @dev Modifies an assetClass
     * Sets a new AC name. Asset Classes cannot be moved to a new root or custody type.
     * Requires that:
     *  caller holds ACtoken
     *  name is unuiqe or same as old name
     */
    function updateACname(uint32 _assetClass, string calldata _name) external;

    /*
     * @dev Modifies an assetClass
     * Sets a new AC IPFS Address. Asset Classes cannot be moved to a new root or custody type.
     * Requires that:
     *  caller holds ACtoken
     */
    function updateACipfs(uint32 _assetClass, bytes32 _IPFS) external;

    /*
     * @dev Set function costs and payment address per asset class, in Wei
     */
    function ACTH_setCosts(
        uint32 _assetClass,
        uint16 _service,
        uint256 _serviceCost,
        address _paymentAddress
    ) external;

    /*
     * @dev Modifies an assetClass
     * Sets the immutable data on an ACNode
     * Requires that:
     * caller holds ACtoken
     * ACnode is managementType 255 (unconfigured)
     */
    function updateACImmutable(
        uint32 _assetClass,
        uint8 _managementType,
        uint8 _storageProvider,
        address _refAddress
    ) external;

    //-------------------------------------------Read-only functions ----------------------------------------------
    /*
     * @dev get a User Record
     */
    function getUserType(bytes32 _userHash, uint32 _assetClass)
        external
        view
        returns (uint8);

    /*
     * @dev get the authorization status of a management type 0 = not allowed  DPS:TEST -- NEW
     */
    function getManagementTypeStatus(uint8 _managementType)
        external
        view
        returns (uint8);

    /*
     * @dev get the authorization status of a storage type 0 = not allowed   DPS:TEST -- NEW
     */
    function getStorageProviderStatus(uint8 _storageProvider)
        external
        view
        returns (uint8);

    /*
     * @dev get the authorization status of a custody type 0 = not allowed   DPS:TEST -- NEW
     */
    function getCustodyTypeStatus(uint8 _custodyType)
        external
        view
        returns (uint8);

    /*
     * @dev Retrieve AC_data @ _assetClass
     */
    function getAC_data(uint32 _assetClass)
        external
        returns (
            uint32,
            uint8,
            uint8,
            uint32,
            address
        );

    /* CAN'T RETURN A STRUCT WITH A STRING WITHOUT WIERDNESS-0.8.1
     * @dev Retrieve AC_data @ _assetClass
     */
    function getExtAC_data(uint32 _assetClass)
        external
        view
        returns (AC memory);

    /* CAN'T RETURN A STRUCT WITH A STRING WITHOUT WIERDNESS-0.8.1
     * @dev Retrieve AC_data @ _assetClass
     */
    function getExtAC_data_nostruct(uint32 _assetClass)
        external
        view
        returns (
            uint8,
            address,
            uint8,
            bytes32
        );

    /*
     * @dev compare the root of two asset classes
     */
    function isSameRootAC(uint32 _assetClass1, uint32 _assetClass2)
        external
        view
        returns (uint8);

    /*
     * @dev Retrieve AC_name @ _tokenId
     */
    function getAC_name(uint32 _tokenId) external view returns (string memory);

    /*
     * @dev Retrieve AC_number @ AC_name
     */
    function resolveAssetClass(string calldata _name)
        external
        view
        returns (uint32);

    /*
     * @dev return current AC token index pointer
     */
    function currentACpricingInfo() external view returns (uint256, uint256);

    /*
     * @dev get bit (1/0) from .switches at specified position
     */
    function getSwitchAt(uint32 _assetClass, uint8 _position)
        external
        view
        returns (uint256);

    /*
     * @dev Retrieve function costs per asset class, per service type, in Wei
     */
    function getServiceCosts(uint32 _assetClass, uint16 _service)
        external
        view
        returns (Invoice memory);

    /*
     * @dev Retrieve AC_discount @ _assetClass, in percent ACTH share, * 100 (9000 = 90%)
     */
    function getAC_discount(uint32 _assetClass) external view returns (uint32);
}

//------------------------------------------------------------------------------------------------
/*
 * @dev Interface for STOR
 * INHERIANCE:
    import "./Imports/access/Ownable.sol";
    import "./Imports/utils/Pausable.sol";
     
    import "./Imports/utils/ReentrancyGuard.sol";
 */
interface STOR_Interface {
    /*
     * @dev Triggers stopped state. (pausable)
     */
    function pause() external;

    /*
     * @dev Returns to normal state. (pausable)
     */
    function unpause() external;

    /*
     * @dev Authorize / Deauthorize / Authorize ADRESSES permitted to make record modifications, per AssetClass
     * populates contract name resolution and data mappings
     */
    function OO_addContract(
        string calldata _name,
        address _addr,
        uint32 _assetClass,
        uint8 _contractAuthLevel
    ) external;

    /*
     * @dev ASet the default 11 authorized contracts
     */
    function enableDefaultContractsForAC(uint32 _assetClass) external;

    /*
     * @dev Authorize / Deauthorize / Authorize contract NAMES permitted to make record modifications, per AssetClass
     * allows ACtokenHolder to auithorize or deauthorize specific contracts to work within their asset class
     */
    function enableContractForAC(
        string calldata _name,
        uint32 _assetClass,
        uint8 _contractAuthLevel
    ) external;

    /*
     * @dev Make a new record, writing to the 'database' mapping with basic initial asset data
     */
    function newRecord(
        bytes32 _idxHash,
        bytes32 _rgtHash,
        uint32 _assetClass,
        uint32 _countDownStart
    ) external;

    /*
     * @dev Modify a record, writing to the 'database' mapping with updates to multiple fields
     */
    function modifyRecord(
        bytes32 _idxHash,
        bytes32 _rgtHash,
        uint8 _newAssetStatus,
        uint32 _countDown,
        uint256 _incrementForceModCount,
        uint256 _incrementNumberOfTransfers
    ) external;

    /*
     * @dev Change asset class of an asset - writes to assetClass in the 'Record' struct of the 'database' at _idxHash
     */
    function changeAC(bytes32 _idxHash, uint32 _newAssetClass) external;

    /*
     * @dev Set an asset to stolen or lost. Allows narrow modification of status 6/12 assets, normally locked
     */
    function setLostOrStolen(bytes32 _idxHash, uint8 _newAssetStatus) external;

    /*
     * @dev Set an asset to escrow locked status (6/50/56).
     */
    function setEscrow(bytes32 _idxHash, uint8 _newAssetStatus) external;

    /*
     * @dev remove an asset from escrow status. Implicitly trusts escrowManager ECR_MGR contract
     */
    function endEscrow(bytes32 _idxHash) external;

    /*
     * @dev Modify record sale price and currency data
     */
    function setPrice(
        bytes32 _idxHash,
        uint120 _price,
        uint8 _currency
    ) external;

    /*
     * @dev set record sale price and currency data to zero
     */
    function clearPrice(bytes32 _idxHash) external;

    /*
     * @dev Modify record Ipfs1a data
     */
    function modifyIpfs1(
        bytes32 _idxHash,
        bytes32 _Ipfs1a,
        bytes32 _Ipfs1b
    ) external;

    /*
     * @dev Write record Ipfs2 data
     */
    function modifyIpfs2(
        bytes32 _idxHash,
        bytes32 _Ipfs2a,
        bytes32 _Ipfs2b
    ) external;

    /*
     * @dev return a record from the database, including rgt
     */
    function retrieveRecord(bytes32 _idxHash) external returns (Record memory);

    // function retrieveRecord(bytes32 _idxHash)
    //     external
    //     view
    //     returns (
    //         bytes32,
    //         uint8,
    //         uint32,
    //         uint32,
    //         uint32,
    //         bytes32,
    //         bytes32
    //     );

    /*
     * @dev return a record from the database w/o rgt
     */
    function retrieveShortRecord(
        bytes32 _idxHash //CTS:EXAMINE, doesn't return same number of params as STOR
    )
        external
        view
        returns (
            uint8,
            uint8,
            uint32,
            uint32,
            uint32,
            bytes32,
            bytes32,
            uint16
        );

    /*
     * @dev return the pricing and currency data from a record
     */
    function getPriceData(bytes32 _idxHash)
        external
        view
        returns (uint120, uint8);

    /*
     * @dev Compare record.rightsholder with supplied bytes32 rightsholder
     * return 170 if matches, 0 if not
     */
    function _verifyRightsHolder(bytes32 _idxHash, bytes32 _rgtHash)
        external
        view
        returns (uint256);

    /*
     * @dev Compare record.rightsholder with supplied bytes32 rightsholder (writes an emit in blockchain for independant verification)
     */
    function blockchainVerifyRightsHolder(bytes32 _idxHash, bytes32 _rgtHash)
        external
        returns (uint8);

    /*
     * @dev //returns the address of a contract with name _name. This is for web3 implementations to find the right contract to interact with
     * example :  Frontend = ****** so web 3 first asks storage where to find frontend, then calls for frontend functions.
     */
    function resolveContractAddress(string calldata _name)
        external
        view
        returns (address);

    /*
     * @dev //returns the contract type of a contract with address _addr.
     */
    function ContractInfoHash(address _addr, uint32 _assetClass)
        external
        view
        returns (uint8, bytes32);
}

//------------------------------------------------------------------------------------------------
/*
 * @dev Interface for ECR_MGR
 * INHERIANCE:
    import "./PRUF_BASIC.sol";
     
 */
interface ECR_MGR_Interface {
    /*
     * @dev Set an asset to escrow status (6/50/56). Sets timelock for unix timestamp of escrow end.
     */
    function setEscrow(
        bytes32 _idxHash,
        uint8 _newAssetStatus,
        bytes32 _escrowOwnerAddressHash,
        uint256 _timelock
    ) external;

    /*
     * @dev remove an asset from escrow status
     */
    function endEscrow(bytes32 _idxHash) external;

    /*
     * @dev Set data in EDL mapping
     * Must be setter contract
     * Must be in  escrow
     */
    function setEscrowDataLight(
        bytes32 _idxHash,
        escrowDataExtLight calldata _escrowDataLight
    ) external;

    /*
     * @dev Set data in EDL mapping
     * Must be setter contract
     * Must be in  escrow
     */
    function setEscrowDataHeavy(
        bytes32 _idxHash,
        escrowDataExtHeavy calldata escrowDataHeavy
    ) external;

    /*
     * @dev Permissive removal of asset from escrow status after time-out
     */
    function permissiveEndEscrow(bytes32 _idxHash) external;

    /*
     * @dev return escrow OwnerHash
     */
    function retrieveEscrowOwner(bytes32 _idxHash)
        external
        returns (bytes32 hashOfEscrowOwnerAdress);

    /*
     * @dev return escrow data @ IDX
     */
    function retrieveEscrowData(bytes32 _idxHash)
        external
        returns (escrowData memory);

    /*
     * @dev return EscrowDataLight @ IDX
     */
    function retrieveEscrowDataLight(bytes32 _idxHash)
        external
        view
        returns (escrowDataExtLight memory);

    /*
     * @dev return EscrowDataHeavy @ IDX
     */
    function retrieveEscrowDataHeavy(bytes32 _idxHash)
        external
        view
        returns (escrowDataExtHeavy memory);
}

//------------------------------------------------------------------------------------------------
/*
 * @dev Interface for RCLR
 * INHERIANCE:
    import "./PRUF_ECR_CORE.sol";
    import "./PRUF_CORE.sol";
 */
interface RCLR_Interface {
    function discard(bytes32 _idxHash, address _sender) external;

    function recycle(bytes32 _idxHash) external;
}

//------------------------------------------------------------------------------------------------
/*
 * @dev Interface for APP
 * INHERIANCE:
    import "./PRUF_CORE.sol";
 */
interface APP_Interface {
    function transferAssetToken(address _to, bytes32 _idxHash) external;
}

//------------------------------------------------------------------------------------------------
/*
 * @dev Interface for APP_NC
 * INHERIANCE:
    import "./PRUF_CORE.sol";
 */
interface APP_NC_Interface {
    function transferAssetToken(address _to, bytes32 _idxHash) external;
}

