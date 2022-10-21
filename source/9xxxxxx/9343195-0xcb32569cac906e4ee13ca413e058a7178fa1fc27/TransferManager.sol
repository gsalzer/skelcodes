pragma solidity ^0.5.10;

import "./Identity.sol";
import "./IClaimTopicsRegistry.sol";
import "./IIdentityRegistry.sol";
import "./ICompliance.sol";
// import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./ERC20.sol";
import "./AgentRole.sol";

import "./Roles.sol";

contract Pausable is AgentRole, ERC20 {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyAgent whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyAgent whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}


contract TransferManager is Pausable {

    mapping(address => uint256) private holderIndices;
    mapping(address => address) private cancellations;
    mapping (address => bool) frozen;
    mapping (address => Identity)  _identity;
    mapping (address => uint256) public freezedTokens;

    mapping(uint16 => uint256) countryShareHolders;

	uint8 public decimals = 6;
	uint256 public maxTokenSupply = 100000000 * (10 ** uint256(decimals));
	
    address[] private shareholders;
    bytes32[] public claimsNotInNewAddress;

    IIdentityRegistry public identityRegistry;

    ICompliance public compliance;

    event IdentityRegistryAdded(address indexed _identityRegistry);

    event ComplianceAdded(address indexed _compliance);

    event VerifiedAddressSuperseded(
        address indexed original,
        address indexed replacement,
        address indexed sender
    );

    event AddressFrozen(
        address indexed addr,
        bool indexed isFrozen,
        address indexed owner
    );

    event recoverySuccess(
        address wallet_lostAddress,
        address wallet_newAddress,
        address onchainID
    );

    event recoveryFails(
        address wallet_lostAddress,
        address wallet_newAddress,
        address onchainID
    );

    event TokensFreezed(address indexed addr, uint256 amount);
    
    event TokensUnfreezed(address indexed addr, uint256 amount);
    
    constructor (
        address _identityRegistry,
        address _compliance
    ) public {
        identityRegistry = IIdentityRegistry(_identityRegistry);
        emit IdentityRegistryAdded(_identityRegistry);
        compliance = ICompliance(_compliance);
        emit ComplianceAdded(_compliance);
    }

    /**
    * @notice ERC-20 overridden function that include logic to check for trade validity.
    *  Require that the msg.sender and to addresses are not frozen.
    *  Require that the value should not exceed available balance .
    *  Require that the to address is a verified address,
    *  If the `to` address is not currently a shareholder then it MUST become one.
    *  If the transfer will reduce `msg.sender`'s balance to 0 then that address
    *  MUST be removed from the list of shareholders.
    *
    * @param _to The address of the receiver
    * @param _value The number of tokens to transfer
    *
    * @return `true` if successful and revert if unsuccessful
    */
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(!frozen[_to] && !frozen[msg.sender]);
        require(_value <=  balanceOf(msg.sender).sub(freezedTokens[msg.sender]), "Insufficient Balance" );
        if(identityRegistry.isVerified(_to) && compliance.canTransfer(msg.sender, _to, _value)){
            updateShareholders(_to);
            pruneShareholders(msg.sender, _value);
            return super.transfer(_to, _value);
        }

        revert("Transfer not possible");
    }

    /**
    * @notice ERC-20 overridden function that include logic to check for trade validity.
    *  Require that the from and to addresses are not frozen.
    *  Require that the value should not exceed available balance .
    *  Require that the to address is a verified address,
    *  If the `to` address is not currently a shareholder then it MUST become one.
    *  If the transfer will reduce `from`'s balance to 0 then that address
    *  MUST be removed from the list of shareholders.
    *
    * @param _from The address of the sender
    * @param _to The address of the receiver
    * @param _value The number of tokens to transfer
    *
    * @return `true` if successful and revert if unsuccessful
    */
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(!frozen[_to] && !frozen[_from]);
        require(_value <=  balanceOf(_from).sub(freezedTokens[_from]), "Insufficient Balance" );
        if(identityRegistry.isVerified(_to) && compliance.canTransfer(_from, _to, _value)){
            updateShareholders(_to);
            pruneShareholders(_from, _value);
            return super.transferFrom(_from, _to, _value);
        }

        revert("Transfer not possible");
    }

    /**
     * Holder count simply returns the total number of token holder addresses.
     */
    function holderCount()
        public
        view
        returns (uint)
    {
        return shareholders.length;
    }

    /**
     *  By counting the number of token holders using `holderCount`
     *  you can retrieve the complete list of token holders, one at a time.
     *  It MUST throw if `index >= holderCount()`.
     *  @param index The zero-based index of the holder.
     *  @return the address of the token holder with the given index.
     */
    function holderAt(uint256 index)
        public
        onlyOwner
        view
        returns (address)
    {
        require(index < shareholders.length);
        return shareholders[index];
    }


    /**
     *  If the address is not in the `shareholders` array then push it
     *  and update the `holderIndices` mapping.
     *  @param addr The address to add as a shareholder if it's not already.
     */
    function updateShareholders(address addr)
        internal
    {
        if (holderIndices[addr] == 0) {
            holderIndices[addr] = shareholders.push(addr);
            uint16 country = identityRegistry.investorCountry(addr);
            countryShareHolders[country]++;
        }
    }

    /**
     *  If the address is in the `shareholders` array and the forthcoming
     *  transfer or transferFrom will reduce their balance to 0, then
     *  we need to remove them from the shareholders array.
     *  @param addr The address to prune if their balance will be reduced to 0.
     @  @dev see https://ethereum.stackexchange.com/a/39311
     */
    function pruneShareholders(address addr, uint256 value)
        internal
    {
        uint256 balance = balanceOf(addr) - value;
        // uint256 balance = balanceOf(addr)
        if (balance > 0) {
            return;
        }
        uint256 holderIndex = holderIndices[addr] - 1;
        uint256 lastIndex = shareholders.length - 1;
        address lastHolder = shareholders[lastIndex];
        // overwrite the addr's slot with the last shareholder
        shareholders[holderIndex] = lastHolder;
        // also copy over the index
        holderIndices[lastHolder] = holderIndices[addr];
        // trim the shareholders array (which drops the last entry)
        shareholders.length--;
        // and zero out the index for addr
        holderIndices[addr] = 0;
        //Decrease the country count
        uint16 country = identityRegistry.investorCountry(addr);
        countryShareHolders[country]--;
    }

    function getShareholderCountByCountry(uint16 index) public view returns (uint) {
        return countryShareHolders[index];
    }

    /**
     *  Checks to see if the supplied address was superseded.
     *  @param addr The address to check
     *  @return true if the supplied address was superseded by another address.
     */
    function isSuperseded(address addr)
        public
        view
        onlyOwner
        returns (bool)
    {
        return cancellations[addr] != address(0);
    }

    /**
     *  Gets the most recent address, given a superseded one.
     *  Addresses may be superseded multiple times, so this function needs to
     *  follow the chain of addresses until it reaches the final, verified address.
     *  @param addr The superseded address.
     *  @return the verified address that ultimately holds the share.
     */
    function getCurrentFor(address addr)
        public
        view
        onlyOwner
        returns (address)
    {
        return findCurrentFor(addr);
    }

    /**
     *  Recursively find the most recent address given a superseded one.
     *  @param addr The superseded address.
     *  @return the verified address that ultimately holds the share.
     */
    function findCurrentFor(address addr)
        internal
        view
        returns (address)
    {
        address candidate = cancellations[addr];
        if (candidate == address(0)) {
            return addr;
        }
        return findCurrentFor(candidate);
    }

    /**
     *  Sets an address frozen status for this token.
     *  @param addr The address for which to update frozen status
     *  @param freeze Frozen status of the address
     */
    function setAddressFrozen(address addr, bool freeze)
    external
    onlyAgent {
        frozen[addr] = freeze;

        emit AddressFrozen(addr, freeze, msg.sender);
    }

    /**
     *  Freezes token amount specified for given address.
     *  @param addr The address for which to update freezed tokens
     *  @param amount Amount of Tokens to be freezed
     */
    function freezePartialTokens(address addr, uint256 amount)
        onlyAgent
        external
    {
        uint256 balance = balanceOf(addr);
        require(balance >= freezedTokens[addr]+amount, 'Amount exceeds available balance');
        freezedTokens[addr] += amount;
        emit TokensFreezed(addr, amount);
    }
    
    /**
     *  Unfreezes token amount specified for given address
     *  @param addr The address for which to update freezed tokens
     *  @param amount Amount of Tokens to be unfreezed
     */
    function unfreezePartialTokens(address addr, uint256 amount)
        onlyAgent
        external
    {
        require(freezedTokens[addr] >= amount, 'Amount should be less than or equal to freezed tokens');
        freezedTokens[addr] -= amount;
        emit TokensUnfreezed(addr, amount);
    }

    //Identity registry setter.
    function setIdentityRegistry(address _identityRegistry) public onlyOwner {
        identityRegistry = IIdentityRegistry(_identityRegistry);
        emit IdentityRegistryAdded(_identityRegistry);
    }

    function setCompliance(address _compliance) public onlyOwner {
        compliance = ICompliance(_compliance);
        emit ComplianceAdded(_compliance);
    }

    uint256[]  claimTopics;
    bytes32[]  lostAddressClaimIds;
    bytes32[]  newAddressClaimIds;
    uint256 foundClaimTopic;
    uint256 scheme;
    address issuer;
    bytes  sig;
    bytes  data;

    function recoveryAddress(address wallet_lostAddress, address wallet_newAddress, address onchainID) public onlyAgent {
        require(holderIndices[wallet_lostAddress] != 0 && holderIndices[wallet_newAddress] == 0);
        require(identityRegistry.contains(wallet_lostAddress), "wallet should be in the registry");

        Identity _onchainID = Identity(onchainID);

        // Check if the token issuer/Tokeny has the management key to the onchainID
        bytes32 _key = keccak256(abi.encode(msg.sender));

        if(_onchainID.keyHasPurpose(_key, 1)) {
            // Burn tokens on the lost wallet
            uint investorTokens = balanceOf(wallet_lostAddress);
            _burn(wallet_lostAddress, investorTokens);

            // Remove lost wallet management key from the onchainID
            bytes32 lostWalletkey = keccak256(abi.encode(wallet_lostAddress));
            if (_onchainID.keyHasPurpose(lostWalletkey, 1)) {
                uint256[] memory purposes = _onchainID.getKeyPurposes(lostWalletkey);
                for(uint _purpose = 0; _purpose <= purposes.length; _purpose++){
                    if(_purpose != 0)
                        _onchainID.removeKey(lostWalletkey, _purpose);
                }
                // _onchainID.removeKey(lostWalletkey);
            }

            // Add new wallet to the identity registry and link it with the onchainID
            identityRegistry.registerIdentity(wallet_newAddress, _onchainID, identityRegistry.investorCountry(wallet_lostAddress));

            // Remove lost wallet from the identity registry
            identityRegistry.deleteIdentity(wallet_lostAddress);

            cancellations[wallet_lostAddress] = wallet_newAddress;
        	uint256 holderIndex = holderIndices[wallet_lostAddress] - 1;
        	shareholders[holderIndex] = wallet_newAddress;
        	holderIndices[wallet_newAddress] = holderIndices[wallet_lostAddress];
        	holderIndices[wallet_lostAddress] = 0;

            // Mint equivalent token amount on the new wallet
            _mint(wallet_newAddress, investorTokens);

            emit recoverySuccess(wallet_lostAddress, wallet_newAddress, onchainID);

        }
        else {
            emit recoveryFails(wallet_lostAddress, wallet_newAddress, onchainID);
        }
    }
}

