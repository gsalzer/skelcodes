pragma solidity 0.5.8;

/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
contract Proxy {
    /**
    * @dev Tells the address of the implementation where every call will be delegated.
    * @return address of the implementation to which it will be delegated
    */
    function _implementation() internal view returns(address);

    /**
    * @dev Fallback function.
    * Implemented entirely in `_fallback`.
    */
    function _fallback() internal {
        _delegate(_implementation());
    }

    /**
    * @dev Fallback function allowing to perform a delegatecall to the given implementation.
    * This function will return whatever the implementation call returns
    */
    function _delegate(address implementation) internal {
        /*solium-disable-next-line security/no-inline-assembly*/
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize)
            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)
            // Copy the returned data.
            returndatacopy(0, 0, returndatasize)
            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize) }
            default { return(0, returndatasize) }
        }
    }

    function() external payable {
        _fallback();
    }
}

/**
 * @title Interface that every module contract should implement
 */
interface IModule {
    /**
     * @notice This function returns the signature of configure function
     */
    function getInitFunction() external pure returns(bytes4 initFunction);

    /**
     * @notice Return the permission flags that are associated with a module
     */
    function getPermissions() external view returns(bytes32[] memory permissions);

}

interface IDataStore {
    /**
     * @dev Changes security token atatched to this data store
     * @param _securityToken address of the security token
     */
    function setSecurityToken(address _securityToken) external;

    /**
     * @dev Stores a uint256 data against a key
     * @param _key Unique key to identify the data
     * @param _data Data to be stored against the key
     */
    function setUint256(bytes32 _key, uint256 _data) external;

    function setBytes32(bytes32 _key, bytes32 _data) external;

    function setAddress(bytes32 _key, address _data) external;

    function setString(bytes32 _key, string calldata _data) external;

    function setBytes(bytes32 _key, bytes calldata _data) external;

    function setBool(bytes32 _key, bool _data) external;

    /**
     * @dev Stores a uint256 array against a key
     * @param _key Unique key to identify the array
     * @param _data Array to be stored against the key
     */
    function setUint256Array(bytes32 _key, uint256[] calldata _data) external;

    function setBytes32Array(bytes32 _key, bytes32[] calldata _data) external ;

    function setAddressArray(bytes32 _key, address[] calldata _data) external;

    function setBoolArray(bytes32 _key, bool[] calldata _data) external;

    /**
     * @dev Inserts a uint256 element to the array identified by the key
     * @param _key Unique key to identify the array
     * @param _data Element to push into the array
     */
    function insertUint256(bytes32 _key, uint256 _data) external;

    function insertBytes32(bytes32 _key, bytes32 _data) external;

    function insertAddress(bytes32 _key, address _data) external;

    function insertBool(bytes32 _key, bool _data) external;

    /**
     * @dev Deletes an element from the array identified by the key.
     * When an element is deleted from an Array, last element of that array is moved to the index of deleted element.
     * @param _key Unique key to identify the array
     * @param _index Index of the element to delete
     */
    function deleteUint256(bytes32 _key, uint256 _index) external;

    function deleteBytes32(bytes32 _key, uint256 _index) external;

    function deleteAddress(bytes32 _key, uint256 _index) external;

    function deleteBool(bytes32 _key, uint256 _index) external;

    /**
     * @dev Stores multiple uint256 data against respective keys
     * @param _keys Array of keys to identify the data
     * @param _data Array of data to be stored against the respective keys
     */
    function setUint256Multi(bytes32[] calldata _keys, uint256[] calldata _data) external;

    function setBytes32Multi(bytes32[] calldata _keys, bytes32[] calldata _data) external;

    function setAddressMulti(bytes32[] calldata _keys, address[] calldata _data) external;

    function setBoolMulti(bytes32[] calldata _keys, bool[] calldata _data) external;

    /**
     * @dev Inserts multiple uint256 elements to the array identified by the respective keys
     * @param _keys Array of keys to identify the data
     * @param _data Array of data to be inserted in arrays of the respective keys
     */
    function insertUint256Multi(bytes32[] calldata _keys, uint256[] calldata _data) external;

    function insertBytes32Multi(bytes32[] calldata _keys, bytes32[] calldata _data) external;

    function insertAddressMulti(bytes32[] calldata _keys, address[] calldata _data) external;

    function insertBoolMulti(bytes32[] calldata _keys, bool[] calldata _data) external;

    function getUint256(bytes32 _key) external view returns(uint256);

    function getBytes32(bytes32 _key) external view returns(bytes32);

    function getAddress(bytes32 _key) external view returns(address);

    function getString(bytes32 _key) external view returns(string memory);

    function getBytes(bytes32 _key) external view returns(bytes memory);

    function getBool(bytes32 _key) external view returns(bool);

    function getUint256Array(bytes32 _key) external view returns(uint256[] memory);

    function getBytes32Array(bytes32 _key) external view returns(bytes32[] memory);

    function getAddressArray(bytes32 _key) external view returns(address[] memory);

    function getBoolArray(bytes32 _key) external view returns(bool[] memory);

    function getUint256ArrayLength(bytes32 _key) external view returns(uint256);

    function getBytes32ArrayLength(bytes32 _key) external view returns(uint256);

    function getAddressArrayLength(bytes32 _key) external view returns(uint256);

    function getBoolArrayLength(bytes32 _key) external view returns(uint256);

    function getUint256ArrayElement(bytes32 _key, uint256 _index) external view returns(uint256);

    function getBytes32ArrayElement(bytes32 _key, uint256 _index) external view returns(bytes32);

    function getAddressArrayElement(bytes32 _key, uint256 _index) external view returns(address);

    function getBoolArrayElement(bytes32 _key, uint256 _index) external view returns(bool);

    function getUint256ArrayElements(bytes32 _key, uint256 _startIndex, uint256 _endIndex) external view returns(uint256[] memory);

    function getBytes32ArrayElements(bytes32 _key, uint256 _startIndex, uint256 _endIndex) external view returns(bytes32[] memory);

    function getAddressArrayElements(bytes32 _key, uint256 _startIndex, uint256 _endIndex) external view returns(address[] memory);

    function getBoolArrayElements(bytes32 _key, uint256 _startIndex, uint256 _endIndex) external view returns(bool[] memory);
}

/**
 * @title Interface for the Polymath Module Registry contract
 */
interface IModuleRegistry {

    ///////////
    // Events
    //////////

    // Emit when network becomes paused
    event Pause(address account);
    // Emit when network becomes unpaused
    event Unpause(address account);
    // Emit when Module is used by the SecurityToken
    event ModuleUsed(address indexed _moduleFactory, address indexed _securityToken);
    // Emit when the Module Factory gets registered on the ModuleRegistry contract
    event ModuleRegistered(address indexed _moduleFactory, address indexed _owner);
    // Emit when the module gets verified by Polymath
    event ModuleVerified(address indexed _moduleFactory);
    // Emit when the module gets unverified by Polymath or the factory owner
    event ModuleUnverified(address indexed _moduleFactory);
    // Emit when a ModuleFactory is removed by Polymath
    event ModuleRemoved(address indexed _moduleFactory, address indexed _decisionMaker);
    // Emit when ownership gets transferred
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @notice Called by a security token (2.x) to notify the registry it is using a module
     * @param _moduleFactory is the address of the relevant module factory
     */
    function useModule(address _moduleFactory) external;

    /**
     * @notice Called by a security token to notify the registry it is using a module
     * @param _moduleFactory is the address of the relevant module factory
     * @param _isUpgrade whether the use is part of an existing module upgrade
     */
    function useModule(address _moduleFactory, bool _isUpgrade) external;

    /**
     * @notice Called by the ModuleFactory owner to register new modules for SecurityToken to use
     * @param _moduleFactory is the address of the module factory to be registered
     */
    function registerModule(address _moduleFactory) external;

    /**
     * @notice Called by the ModuleFactory owner or registry curator to delete a ModuleFactory
     * @param _moduleFactory is the address of the module factory to be deleted
     */
    function removeModule(address _moduleFactory) external;

    /**
     * @notice Check that a module and its factory are compatible
     * @param _moduleFactory is the address of the relevant module factory
     * @param _securityToken is the address of the relevant security token
     * @return bool whether module and token are compatible
     */
    function isCompatibleModule(address _moduleFactory, address _securityToken) external view returns(bool isCompatible);

    /**
    * @notice Called by Polymath to verify modules for SecurityToken to use.
    * @notice A module can not be used by an ST unless first approved/verified by Polymath
    * @notice (The only exception to this is that the author of the module is the owner of the ST - Only if enabled by the FeatureRegistry)
    * @param _moduleFactory is the address of the module factory to be registered
    */
    function verifyModule(address _moduleFactory) external;

    /**
    * @notice Called by Polymath to unverify modules for SecurityToken to use.
    * @notice A module can not be used by an ST unless first approved/verified by Polymath
    * @notice (The only exception to this is that the author of the module is the owner of the ST - Only if enabled by the FeatureRegistry)
    * @param _moduleFactory is the address of the module factory to be registered
    */
    function unverifyModule(address _moduleFactory) external;

    /**
     * @notice Returns the verified status, and reputation of the entered Module Factory
     * @param _factoryAddress is the address of the module factory
     * @return bool indicating whether module factory is verified
     * @return address of the factory owner
     * @return address array which contains the list of securityTokens that use that module factory
     */
    function getFactoryDetails(address _factoryAddress) external view returns(bool isVerified, address factoryOwner, address[] memory usingTokens);

    /**
     * @notice Returns all the tags related to the a module type which are valid for the given token
     * @param _moduleType is the module type
     * @param _securityToken is the token
     * @return list of tags
     * @return corresponding list of module factories
     */
    function getTagsByTypeAndToken(uint8 _moduleType, address _securityToken) external view returns(bytes32[] memory tags, address[] memory factories);

    /**
     * @notice Returns all the tags related to the a module type which are valid for the given token
     * @param _moduleType is the module type
     * @return list of tags
     * @return corresponding list of module factories
     */
    function getTagsByType(uint8 _moduleType) external view returns(bytes32[] memory tags, address[] memory factories);

    /**
     * @notice Returns the list of addresses of all Module Factory of a particular type
     * @param _moduleType Type of Module
     * @return address array that contains the list of addresses of module factory contracts.
     */
    function getAllModulesByType(uint8 _moduleType) external view returns(address[] memory factories);
    /**
     * @notice Returns the list of addresses of Module Factory of a particular type
     * @param _moduleType Type of Module
     * @return address array that contains the list of addresses of module factory contracts.
     */
    function getModulesByType(uint8 _moduleType) external view returns(address[] memory factories);

    /**
     * @notice Returns the list of available Module factory addresses of a particular type for a given token.
     * @param _moduleType is the module type to look for
     * @param _securityToken is the address of SecurityToken
     * @return address array that contains the list of available addresses of module factory contracts.
     */
    function getModulesByTypeAndToken(uint8 _moduleType, address _securityToken) external view returns(address[] memory factories);

    /**
     * @notice Use to get the latest contract address of the regstries
     */
    function updateFromRegistry() external;

    /**
     * @notice Get the owner of the contract
     * @return address owner
     */
    function owner() external view returns(address ownerAddress);

    /**
     * @notice Check whether the contract operations is paused or not
     * @return bool
     */
    function isPaused() external view returns(bool paused);

    /**
     * @notice Reclaims all ERC20Basic compatible tokens
     * @param _tokenContract The address of the token contract
     */
    function reclaimERC20(address _tokenContract) external;

    /**
     * @notice Called by the owner to pause, triggers stopped state
     */
    function pause() external;

    /**
     * @notice Called by the owner to unpause, returns to normal state
     */
    function unpause() external;

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) external;

}

interface IPolymathRegistry {

    event ChangeAddress(string _nameKey, address indexed _oldAddress, address indexed _newAddress);
    
    /**
     * @notice Returns the contract address
     * @param _nameKey is the key for the contract address mapping
     * @return address
     */
    function getAddress(string calldata _nameKey) external view returns(address registryAddress);

    /**
     * @notice Changes the contract address
     * @param _nameKey is the key for the contract address mapping
     * @param _newAddress is the new contract address
     */
    function changeAddress(string calldata _nameKey, address _newAddress) external;

}

/**
 * @title Interface for the Polymath Security Token Registry contract
 */
interface ISecurityTokenRegistry {

    // Emit when network becomes paused
    event Pause(address account);
    // Emit when network becomes unpaused
    event Unpause(address account);
    // Emit when the ticker is removed from the registry
    event TickerRemoved(string _ticker, address _removedBy);
    // Emit when the token ticker expiry is changed
    event ChangeExpiryLimit(uint256 _oldExpiry, uint256 _newExpiry);
    // Emit when changeSecurityLaunchFee is called
    event ChangeSecurityLaunchFee(uint256 _oldFee, uint256 _newFee);
    // Emit when changeTickerRegistrationFee is called
    event ChangeTickerRegistrationFee(uint256 _oldFee, uint256 _newFee);
    // Emit when Fee currency is changed
    event ChangeFeeCurrency(bool _isFeeInPoly);
    // Emit when ownership gets transferred
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    // Emit when ownership of the ticker gets changed
    event ChangeTickerOwnership(string _ticker, address indexed _oldOwner, address indexed _newOwner);
    // Emit at the time of launching a new security token of version 3.0+
    event NewSecurityToken(
        string _ticker,
        string _name,
        address indexed _securityTokenAddress,
        address indexed _owner,
        uint256 _addedAt,
        address _registrant,
        bool _fromAdmin,
        uint256 _usdFee,
        uint256 _polyFee,
        uint256 _protocolVersion
    );
    // Emit at the time of launching a new security token v2.0.
    // _registrationFee is in poly
    event NewSecurityToken(
        string _ticker,
        string _name,
        address indexed _securityTokenAddress,
        address indexed _owner,
        uint256 _addedAt,
        address _registrant,
        bool _fromAdmin,
        uint256 _registrationFee
    );
    // Emit when new ticker get registers
    event RegisterTicker(
        address indexed _owner,
        string _ticker,
        uint256 indexed _registrationDate,
        uint256 indexed _expiryDate,
        bool _fromAdmin,
        uint256 _registrationFeePoly,
        uint256 _registrationFeeUsd
    );
    // Emit after ticker registration
    // _registrationFee is in poly
    // fee in usd is not being emitted to maintain backwards compatibility
    event RegisterTicker(
        address indexed _owner,
        string _ticker,
        string _name,
        uint256 indexed _registrationDate,
        uint256 indexed _expiryDate,
        bool _fromAdmin,
        uint256 _registrationFee
    );
    // Emit at when issuer refreshes exisiting token
    event SecurityTokenRefreshed(
        string _ticker,
        string _name,
        address indexed _securityTokenAddress,
        address indexed _owner,
        uint256 _addedAt,
        address _registrant,
        uint256 _protocolVersion
    );
    event ProtocolFactorySet(address indexed _STFactory, uint8 _major, uint8 _minor, uint8 _patch);
    event LatestVersionSet(uint8 _major, uint8 _minor, uint8 _patch);
    event ProtocolFactoryRemoved(address indexed _STFactory, uint8 _major, uint8 _minor, uint8 _patch);

    /**
     * @notice Deploys an instance of a new Security Token of version 2.0 and records it to the registry
     * @dev this function is for backwards compatibilty with 2.0 dApp.
     * @param _name is the name of the token
     * @param _ticker is the ticker symbol of the security token
     * @param _tokenDetails is the off-chain details of the token
     * @param _divisible is whether or not the token is divisible
     */
    function generateSecurityToken(
        string calldata _name,
        string calldata _ticker,
        string calldata _tokenDetails,
        bool _divisible
    )
        external;

    /**
     * @notice Deploys an instance of a new Security Token and records it to the registry
     * @param _name is the name of the token
     * @param _ticker is the ticker symbol of the security token
     * @param _tokenDetails is the off-chain details of the token
     * @param _divisible is whether or not the token is divisible
     * @param _treasuryWallet Ethereum address which will holds the STs.
     * @param _protocolVersion Version of securityToken contract
     * - `_protocolVersion` is the packed value of uin8[3] array (it will be calculated offchain)
     * - if _protocolVersion == 0 then latest version of securityToken will be generated
     */
    function generateNewSecurityToken(
        string calldata _name,
        string calldata _ticker,
        string calldata _tokenDetails,
        bool _divisible,
        address _treasuryWallet,
        uint256 _protocolVersion
    )
        external;

    /**
     * @notice Deploys an instance of a new Security Token and replaces the old one in the registry
     * This can be used to upgrade from version 2.0 of ST to 3.0 or in case something goes wrong with earlier ST
     * @dev This function needs to be in STR 3.0. Defined public to avoid stack overflow
     * @param _name is the name of the token
     * @param _ticker is the ticker symbol of the security token
     * @param _tokenDetails is the off-chain details of the token
     * @param _divisible is whether or not the token is divisible
     */
    function refreshSecurityToken(
        string calldata _name,
        string calldata _ticker,
        string calldata _tokenDetails,
        bool _divisible,
        address _treasuryWallet
    )
        external returns (address securityToken);

    /**
     * @notice Adds a new custom Security Token and saves it to the registry. (Token should follow the ISecurityToken interface)
     * @param _name Name of the token
     * @param _ticker Ticker of the security token
     * @param _owner Owner of the token
     * @param _securityToken Address of the securityToken
     * @param _tokenDetails Off-chain details of the token
     * @param _deployedAt Timestamp at which security token comes deployed on the ethereum blockchain
     */
    function modifySecurityToken(
        string calldata _name,
        string calldata _ticker,
        address _owner,
        address _securityToken,
        string calldata _tokenDetails,
        uint256 _deployedAt
    )
    external;

    /**
     * @notice Adds a new custom Security Token and saves it to the registry. (Token should follow the ISecurityToken interface)
     * @param _ticker is the ticker symbol of the security token
     * @param _owner is the owner of the token
     * @param _securityToken is the address of the securityToken
     * @param _tokenDetails is the off-chain details of the token
     * @param _deployedAt is the timestamp at which the security token is deployed
     */
    function modifyExistingSecurityToken(
        string calldata _ticker,
        address _owner,
        address _securityToken,
        string calldata _tokenDetails,
        uint256 _deployedAt
    )
        external;

    /**
     * @notice Modifies the ticker details. Only Polymath has the ability to do so.
     * @notice Only allowed to modify the tickers which are not yet deployed.
     * @param _owner is the owner of the token
     * @param _ticker is the token ticker
     * @param _registrationDate is the date at which ticker is registered
     * @param _expiryDate is the expiry date for the ticker
     * @param _status is the token deployment status
     */
    function modifyExistingTicker(
        address _owner,
        string calldata _ticker,
        uint256 _registrationDate,
        uint256 _expiryDate,
        bool _status
    )
        external;

    /**
     * @notice Registers the token ticker for its particular owner
     * @notice once the token ticker is registered to its owner then no other issuer can claim
     * @notice its ownership. If the ticker expires and its issuer hasn't used it, then someone else can take it.
     * @param _owner Address of the owner of the token
     * @param _ticker Token ticker
     * @param _tokenName Name of the token
     */
    function registerTicker(address _owner, string calldata _ticker, string calldata _tokenName) external;

    /**
     * @notice Registers the token ticker to the selected owner
     * @notice Once the token ticker is registered to its owner then no other issuer can claim
     * @notice its ownership. If the ticker expires and its issuer hasn't used it, then someone else can take it.
     * @param _owner is address of the owner of the token
     * @param _ticker is unique token ticker
     */
    function registerNewTicker(address _owner, string calldata _ticker) external;

    /**
    * @notice Check that Security Token is registered
    * @param _securityToken Address of the Scurity token
    * @return bool
    */
    function isSecurityToken(address _securityToken) external view returns(bool isValid);

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) external;

    /**
     * @notice Get security token address by ticker name
     * @param _ticker Symbol of the Scurity token
     * @return address
     */
    function getSecurityTokenAddress(string calldata _ticker) external view returns(address tokenAddress);

    /**
    * @notice Returns the security token data by address
    * @param _securityToken is the address of the security token.
    * @return string is the ticker of the security Token.
    * @return address is the issuer of the security Token.
    * @return string is the details of the security token.
    * @return uint256 is the timestamp at which security Token was deployed.
    */
    function getSecurityTokenData(address _securityToken) external view returns (
        string memory tokenSymbol,
        address tokenAddress,
        string memory tokenDetails,
        uint256 tokenTime
    );

    /**
     * @notice Get the current STFactory Address
     */
    function getSTFactoryAddress() external view returns(address stFactoryAddress);

    /**
     * @notice Returns the STFactory Address of a particular version
     * @param _protocolVersion Packed protocol version
     */
    function getSTFactoryAddressOfVersion(uint256 _protocolVersion) external view returns(address stFactory);

    /**
     * @notice Get Protocol version
     */
    function getLatestProtocolVersion() external view returns(uint8[] memory protocolVersion);

    /**
     * @notice Used to get the ticker list as per the owner
     * @param _owner Address which owns the list of tickers
     */
    function getTickersByOwner(address _owner) external view returns(bytes32[] memory tickers);

    /**
     * @notice Returns the list of tokens owned by the selected address
     * @param _owner is the address which owns the list of tickers
     * @dev Intention is that this is called off-chain so block gas limit is not relevant
     */
    function getTokensByOwner(address _owner) external view returns(address[] memory tokens);

    /**
     * @notice Returns the list of all tokens
     * @dev Intention is that this is called off-chain so block gas limit is not relevant
     */
    function getTokens() external view returns(address[] memory tokens);

    /**
     * @notice Returns the owner and timestamp for a given ticker
     * @param _ticker ticker
     * @return address
     * @return uint256
     * @return uint256
     * @return string
     * @return bool
     */
    function getTickerDetails(string calldata _ticker) external view returns(address tickerOwner, uint256 tickerRegistration, uint256 tickerExpiry, string memory tokenName, bool tickerStatus);

    /**
     * @notice Modifies the ticker details. Only polymath account has the ability
     * to do so. Only allowed to modify the tickers which are not yet deployed
     * @param _owner Owner of the token
     * @param _ticker Token ticker
     * @param _tokenName Name of the token
     * @param _registrationDate Date on which ticker get registered
     * @param _expiryDate Expiry date of the ticker
     * @param _status Token deployed status
     */
    function modifyTicker(
        address _owner,
        string calldata _ticker,
        string calldata _tokenName,
        uint256 _registrationDate,
        uint256 _expiryDate,
        bool _status
    )
    external;

    /**
     * @notice Removes the ticker details and associated ownership & security token mapping
     * @param _ticker Token ticker
     */
    function removeTicker(string calldata _ticker) external;

    /**
     * @notice Transfers the ownership of the ticker
     * @dev _newOwner Address whom ownership to transfer
     * @dev _ticker Ticker
     */
    function transferTickerOwnership(address _newOwner, string calldata _ticker) external;

    /**
     * @notice Changes the expiry time for the token ticker
     * @param _newExpiry New time period for token ticker expiry
     */
    function changeExpiryLimit(uint256 _newExpiry) external;

   /**
    * @notice Sets the ticker registration fee in USD tokens. Only Polymath.
    * @param _tickerRegFee is the registration fee in USD tokens (base 18 decimals)
    */
    function changeTickerRegistrationFee(uint256 _tickerRegFee) external;

    /**
    * @notice Sets the ticker registration fee in USD tokens. Only Polymath.
    * @param _stLaunchFee is the registration fee in USD tokens (base 18 decimals)
    */
    function changeSecurityLaunchFee(uint256 _stLaunchFee) external;

    /**
    * @notice Sets the ticker registration and ST launch fee amount and currency
    * @param _tickerRegFee is the ticker registration fee (base 18 decimals)
    * @param _stLaunchFee is the st generation fee (base 18 decimals)
    * @param _isFeeInPoly defines if the fee is in poly or usd
    */
    function changeFeesAmountAndCurrency(uint256 _tickerRegFee, uint256 _stLaunchFee, bool _isFeeInPoly) external;

    /**
    * @notice Changes the SecurityToken contract for a particular factory version
    * @notice Used only by Polymath to upgrade the SecurityToken contract and add more functionalities to future versions
    * @notice Changing versions does not affect existing tokens.
    * @param _STFactoryAddress is the address of the proxy.
    * @param _major Major version of the proxy.
    * @param _minor Minor version of the proxy.
    * @param _patch Patch version of the proxy
    */
    function setProtocolFactory(address _STFactoryAddress, uint8 _major, uint8 _minor, uint8 _patch) external;

    /**
    * @notice Removes a STFactory
    * @param _major Major version of the proxy.
    * @param _minor Minor version of the proxy.
    * @param _patch Patch version of the proxy
    */
    function removeProtocolFactory(uint8 _major, uint8 _minor, uint8 _patch) external;

    /**
    * @notice Changes the default protocol version
    * @notice Used only by Polymath to upgrade the SecurityToken contract and add more functionalities to future versions
    * @notice Changing versions does not affect existing tokens.
    * @param _major Major version of the proxy.
    * @param _minor Minor version of the proxy.
    * @param _patch Patch version of the proxy
    */
    function setLatestVersion(uint8 _major, uint8 _minor, uint8 _patch) external;

    /**
     * @notice Changes the PolyToken address. Only Polymath.
     * @param _newAddress is the address of the polytoken.
     */
    function updatePolyTokenAddress(address _newAddress) external;

    /**
     * @notice Used to update the polyToken contract address
     */
    function updateFromRegistry() external;

    /**
     * @notice Gets the security token launch fee
     * @return Fee amount
     */
    function getSecurityTokenLaunchFee() external returns(uint256 fee);

    /**
     * @notice Gets the ticker registration fee
     * @return Fee amount
     */
    function getTickerRegistrationFee() external returns(uint256 fee);

    /**
     * @notice Set the getter contract address
     * @param _getterContract Address of the contract
     */
    function setGetterRegistry(address _getterContract) external;

    /**
     * @notice Returns the usd & poly fee for a particular feetype
     * @param _feeType Key corresponding to fee type
     */
    function getFees(bytes32 _feeType) external returns (uint256 usdFee, uint256 polyFee);

    /**
     * @notice Returns the list of tokens to which the delegate has some access
     * @param _delegate is the address for the delegate
     * @dev Intention is that this is called off-chain so block gas limit is not relevant
     */
    function getTokensByDelegate(address _delegate) external view returns(address[] memory tokens);

    /**
     * @notice Gets the expiry limit
     * @return Expiry limit
     */
    function getExpiryLimit() external view returns(uint256 expiry);

    /**
     * @notice Gets the status of the ticker
     * @param _ticker Ticker whose status need to determine
     * @return bool
     */
    function getTickerStatus(string calldata _ticker) external view returns(bool status);

    /**
     * @notice Gets the fee currency
     * @return true = poly, false = usd
     */
    function getIsFeeInPoly() external view returns(bool isInPoly);

    /**
     * @notice Gets the owner of the ticker
     * @param _ticker Ticker whose owner need to determine
     * @return address Address of the owner
     */
    function getTickerOwner(string calldata _ticker) external view returns(address owner);

    /**
     * @notice Checks whether the registry is paused or not
     * @return bool
     */
    function isPaused() external view returns(bool paused);

    /**
    * @notice Called by the owner to pause, triggers stopped state
    */
    function pause() external;

    /**
     * @notice Called by the owner to unpause, returns to normal state
     */
    function unpause() external;

    /**
     * @notice Reclaims all ERC20Basic compatible tokens
     * @param _tokenContract is the address of the token contract
     */
    function reclaimERC20(address _tokenContract) external;

    /**
     * @notice Gets the owner of the contract
     * @return address owner
     */
    function owner() external view returns(address ownerAddress);

    /**
     * @notice Checks if the entered ticker is registered and has not expired
     * @param _ticker is the token ticker
     * @return bool
     */
    function tickerAvailable(string calldata _ticker) external view returns(bool);

}

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SecurityTokenStorage {

    uint8 internal constant PERMISSION_KEY = 1;
    uint8 internal constant TRANSFER_KEY = 2;
    uint8 internal constant MINT_KEY = 3;
    uint8 internal constant CHECKPOINT_KEY = 4;
    uint8 internal constant BURN_KEY = 5;
    uint8 internal constant DATA_KEY = 6;
    uint8 internal constant WALLET_KEY = 7;

    bytes32 internal constant INVESTORSKEY = 0xdf3a8dd24acdd05addfc6aeffef7574d2de3f844535ec91e8e0f3e45dba96731; //keccak256(abi.encodePacked("INVESTORS"))
    bytes32 internal constant TREASURY = 0xaae8817359f3dcb67d050f44f3e49f982e0359d90ca4b5f18569926304aaece6; //keccak256(abi.encodePacked("TREASURY_WALLET"))
    bytes32 internal constant LOCKED = "LOCKED";
    bytes32 internal constant UNLOCKED = "UNLOCKED";

    //////////////////////////
    /// Document datastructure
    //////////////////////////

    struct Document {
        bytes32 docHash; // Hash of the document
        uint256 lastModified; // Timestamp at which document details was last modified
        string uri; // URI of the document that exist off-chain
    }

    // Used to hold the semantic version data
    struct SemanticVersion {
        uint8 major;
        uint8 minor;
        uint8 patch;
    }

    // Struct for module data
    struct ModuleData {
        bytes32 name;
        address module;
        address moduleFactory;
        bool isArchived;
        uint8[] moduleTypes;
        uint256[] moduleIndexes;
        uint256 nameIndex;
        bytes32 label;
    }

    // Structures to maintain checkpoints of balances for governance / dividends
    struct Checkpoint {
        uint256 checkpointId;
        uint256 value;
    }

    //Naming scheme to match Ownable
    address internal _owner;
    address public tokenFactory;
    bool public initialized;

    // ERC20 Details
    string public name;
    string public symbol;
    uint8 public decimals;

    // Address of the controller which is a delegated entity
    // set by the issuer/owner of the token
    address public controller;

    IPolymathRegistry public polymathRegistry;
    IModuleRegistry public moduleRegistry;
    ISecurityTokenRegistry public securityTokenRegistry;
    IERC20 public polyToken;
    address public getterDelegate;
    // Address of the data store used to store shared data
    IDataStore public dataStore;

    uint256 public granularity;

    // Value of current checkpoint
    uint256 public currentCheckpointId;

    // off-chain data
    string public tokenDetails;

    // Used to permanently halt controller actions
    bool public controllerDisabled = false;

    // Used to temporarily halt all transactions
    bool public transfersFrozen;

    // Number of investors with non-zero balance
    uint256 public holderCount;

    // Variable which tells whether issuance is ON or OFF forever
    // Implementers need to implement one more function to reset the value of `issuance` variable
    // to false. That function is not a part of the standard (EIP-1594) as it is depend on the various factors
    // issuer, followed compliance rules etc. So issuers have the choice how they want to close the issuance.
    bool internal issuance = true;

    // Array use to store all the document name present in the contracts
    bytes32[] _docNames;

    // Times at which each checkpoint was created
    uint256[] checkpointTimes;

    SemanticVersion securityTokenVersion;

    // Records added modules - module list should be order agnostic!
    mapping(uint8 => address[]) modules;

    // Records information about the module
    mapping(address => ModuleData) modulesToData;

    // Records added module names - module list should be order agnostic!
    mapping(bytes32 => address[]) names;

    // Mapping of checkpoints that relate to total supply
    mapping (uint256 => uint256) checkpointTotalSupply;

    // Map each investor to a series of checkpoints
    mapping(address => Checkpoint[]) checkpointBalances;

    // mapping to store the documents details in the document
    mapping(bytes32 => Document) internal _documents;
    // mapping to store the document name indexes
    mapping(bytes32 => uint256) internal _docIndexes;
    // Mapping from (investor, partition, operator) to approved status
    mapping (address => mapping (bytes32 => mapping (address => bool))) partitionApprovals;

}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IPoly {
    function decimals() external view returns(uint8);
    function totalSupply() external view returns(uint256);
    function balanceOf(address _owner) external view returns(uint256);
    function allowance(address _owner, address _spender) external view returns(uint256);
    function transfer(address _to, uint256 _value) external returns(bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns(bool);
    function approve(address _spender, uint256 _value) external returns(bool);
    function decreaseApproval(address _spender, uint _subtractedValue) external returns(bool);
    function increaseApproval(address _spender, uint _addedValue) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library StatusCodes {

    // ERC1400 status code inspired from ERC1066
    enum Status {
        TransferFailure,
        TransferSuccess,
        InsufficientBalance,
        InsufficientAllowance,
        TransfersHalted,
        FundsLocked,
        InvalidSender,
        InvalidReceiver,
        InvalidOperator
    }

    function code(Status _status) internal pure returns (byte) {
        return byte(uint8(0x50) + (uint8(_status)));
    }
}

/**
 * @title Helper library use to compare or validate the semantic versions
 */

library VersionUtils {

    function lessThanOrEqual(uint8[] memory _current, uint8[] memory _new) internal pure returns(bool) {
        require(_current.length == 3);
        require(_new.length == 3);
        uint8 i = 0;
        for (i = 0; i < _current.length; i++) {
            if (_current[i] == _new[i]) continue;
            if (_current[i] < _new[i]) return true;
            if (_current[i] > _new[i]) return false;
        }
        return true;
    }

    function greaterThanOrEqual(uint8[] memory _current, uint8[] memory _new) internal pure returns(bool) {
        require(_current.length == 3);
        require(_new.length == 3);
        uint8 i = 0;
        for (i = 0; i < _current.length; i++) {
            if (_current[i] == _new[i]) continue;
            if (_current[i] > _new[i]) return true;
            if (_current[i] < _new[i]) return false;
        }
        return true;
    }

    /**
     * @notice Used to pack the uint8[] array data into uint24 value
     * @param _major Major version
     * @param _minor Minor version
     * @param _patch Patch version
     */
    function pack(uint8 _major, uint8 _minor, uint8 _patch) internal pure returns(uint24) {
        return (uint24(_major) << 16) | (uint24(_minor) << 8) | uint24(_patch);
    }

    /**
     * @notice Used to convert packed data into uint8 array
     * @param _packedVersion Packed data
     */
    function unpack(uint24 _packedVersion) internal pure returns(uint8[] memory) {
        uint8[] memory _unpackVersion = new uint8[](3);
        _unpackVersion[0] = uint8(_packedVersion >> 16);
        _unpackVersion[1] = uint8(_packedVersion >> 8);
        _unpackVersion[2] = uint8(_packedVersion);
        return _unpackVersion;
    }


    /**
     * @notice Used to packed the KYC data
     */
    function packKYC(uint64 _a, uint64 _b, uint64 _c, uint8 _d) internal pure returns(uint256) {
        // this function packs 3 uint64 and a uint8 together in a uint256 to save storage cost
        // a is rotated left by 136 bits, b is rotated left by 72 bits and c is rotated left by 8 bits.
        // rotation pads empty bits with zeroes so now we can safely do a bitwise OR operation to pack
        // all the variables together.
        return (uint256(_a) << 136) | (uint256(_b) << 72) | (uint256(_c) << 8) | uint256(_d);
    }

    /**
     * @notice Used to convert packed data into KYC data
     * @param _packedVersion Packed data
     */
    function unpackKYC(uint256 _packedVersion) internal pure returns(uint64 canSendAfter, uint64 canReceiveAfter, uint64 expiryTime, uint8 added) {
        canSendAfter = uint64(_packedVersion >> 136);
        canReceiveAfter = uint64(_packedVersion >> 72);
        expiryTime = uint64(_packedVersion >> 8);
        added = uint8(_packedVersion);
    }
}

/**
 * @title Utility contract for reusable code
 */
library Util {
    /**
    * @notice Changes a string to upper case
    * @param _base String to change
    */
    function upper(string memory _base) internal pure returns(string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            bytes1 b1 = _baseBytes[i];
            if (b1 >= 0x61 && b1 <= 0x7A) {
                b1 = bytes1(uint8(b1) - 32);
            }
            _baseBytes[i] = b1;
        }
        return string(_baseBytes);
    }

    /**
     * @notice Changes the string into bytes32
     * @param _source String that need to convert into bytes32
     */
    /// Notice - Maximum Length for _source will be 32 chars otherwise returned bytes32 value will have lossy value.
    function stringToBytes32(string memory _source) internal pure returns(bytes32) {
        return bytesToBytes32(bytes(_source), 0);
    }

    /**
     * @notice Changes bytes into bytes32
     * @param _b Bytes that need to convert into bytes32
     * @param _offset Offset from which to begin conversion
     */
    /// Notice - Maximum length for _source will be 32 chars otherwise returned bytes32 value will have lossy value.
    function bytesToBytes32(bytes memory _b, uint _offset) internal pure returns(bytes32) {
        bytes32 result;

        for (uint i = 0; i < _b.length; i++) {
            result |= bytes32(_b[_offset + i] & 0xFF) >> (i * 8);
        }
        return result;
    }

    /**
     * @notice Changes the bytes32 into string
     * @param _source that need to convert into string
     */
    function bytes32ToString(bytes32 _source) internal pure returns(string memory) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        uint j = 0;
        for (j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(_source) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    /**
     * @notice Gets function signature from _data
     * @param _data Passed data
     * @return bytes4 sig
     */
    function getSig(bytes memory _data) internal pure returns(bytes4 sig) {
        uint len = _data.length < 4 ? _data.length : 4;
        for (uint256 i = 0; i < len; i++) {
          sig |= bytes4(_data[i] & 0xFF) >> (i * 8);
        }
        return sig;
    }
}

interface IOracle {
    /**
    * @notice Returns address of oracle currency (0x0 for ETH)
    */
    function getCurrencyAddress() external view returns(address currency);

    /**
    * @notice Returns symbol of oracle currency (0x0 for ETH)
    */
    function getCurrencySymbol() external view returns(bytes32 symbol);

    /**
    * @notice Returns denomination of price
    */
    function getCurrencyDenominated() external view returns(bytes32 denominatedCurrency);

    /**
    * @notice Returns price - should throw if not valid
    */
    function getPrice() external returns(uint256 price);

}

/**
 * @title Interface that every module factory contract should implement
 */
interface IModuleFactory {
    event ChangeSetupCost(uint256 _oldSetupCost, uint256 _newSetupCost);
    event ChangeCostType(bool _isOldCostInPoly, bool _isNewCostInPoly);
    event GenerateModuleFromFactory(
        address _module,
        bytes32 indexed _moduleName,
        address indexed _moduleFactory,
        address _creator,
        uint256 _setupCost,
        uint256 _setupCostInPoly
    );
    event ChangeSTVersionBound(string _boundType, uint8 _major, uint8 _minor, uint8 _patch);

    //Should create an instance of the Module, or throw
    function deploy(bytes calldata _data) external returns(address moduleAddress);

    /**
     * @notice Get the tags related to the module factory
     */
    function version() external view returns(string memory moduleVersion);

    /**
     * @notice Get the tags related to the module factory
     */
    function name() external view returns(bytes32 moduleName);

    /**
     * @notice Returns the title associated with the module
     */
    function title() external view returns(string memory moduleTitle);

    /**
     * @notice Returns the description associated with the module
     */
    function description() external view returns(string memory moduleDescription);

    /**
     * @notice Get the setup cost of the module in USD
     */
    function setupCost() external returns(uint256 usdSetupCost);

    /**
     * @notice Type of the Module factory
     */
    function getTypes() external view returns(uint8[] memory moduleTypes);

    /**
     * @notice Get the tags related to the module factory
     */
    function getTags() external view returns(bytes32[] memory moduleTags);

    /**
     * @notice Used to change the setup fee
     * @param _newSetupCost New setup fee
     */
    function changeSetupCost(uint256 _newSetupCost) external;

    /**
     * @notice Used to change the currency and amount setup cost
     * @param _setupCost new setup cost
     * @param _isCostInPoly new setup cost currency. USD or POLY
     */
    function changeCostAndType(uint256 _setupCost, bool _isCostInPoly) external;

    /**
     * @notice Function use to change the lower and upper bound of the compatible version st
     * @param _boundType Type of bound
     * @param _newVersion New version array
     */
    function changeSTVersionBounds(string calldata _boundType, uint8[] calldata _newVersion) external;

    /**
     * @notice Get the setup cost of the module
     */
    function setupCostInPoly() external returns (uint256 polySetupCost);

    /**
     * @notice Used to get the lower bound
     * @return Lower bound
     */
    function getLowerSTVersionBounds() external view returns(uint8[] memory lowerBounds);

    /**
     * @notice Used to get the upper bound
     * @return Upper bound
     */
    function getUpperSTVersionBounds() external view returns(uint8[] memory upperBounds);

    /**
     * @notice Updates the tags of the ModuleFactory
     * @param _tagsData New list of tags
     */
    function changeTags(bytes32[] calldata _tagsData) external;

    /**
     * @notice Updates the name of the ModuleFactory
     * @param _name New name that will replace the old one.
     */
    function changeName(bytes32 _name) external;

    /**
     * @notice Updates the description of the ModuleFactory
     * @param _description New description that will replace the old one.
     */
    function changeDescription(string calldata _description) external;

    /**
     * @notice Updates the title of the ModuleFactory
     * @param _title New Title that will replace the old one.
     */
    function changeTitle(string calldata _title) external;

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

library DecimalMath {
    using SafeMath for uint256;

    uint256 internal constant e18 = uint256(10) ** uint256(18);

    /**
     * @notice This function multiplies two decimals represented as (decimal * 10**DECIMALS)
     * @return uint256 Result of multiplication represented as (decimal * 10**DECIMALS)
     */
    function mul(uint256 x, uint256 y) internal pure returns(uint256 z) {
        z = SafeMath.add(SafeMath.mul(x, y), (e18) / 2) / (e18);
    }

    /**
     * @notice This function divides two decimals represented as (decimal * 10**DECIMALS)
     * @return uint256 Result of division represented as (decimal * 10**DECIMALS)
     */
    function div(uint256 x, uint256 y) internal pure returns(uint256 z) {
        z = SafeMath.add(SafeMath.mul(x, (e18)), y / 2) / y;
    }

}

/**
 * @title Interface that any module factory contract should implement
 * @notice Contract is abstract
 */
contract ModuleFactory is IModuleFactory, Ownable {

    IPolymathRegistry public polymathRegistry;

    string initialVersion;
    bytes32 public name;
    string public title;
    string public description;

    uint8[] typesData;
    bytes32[] tagsData;

    bool public isCostInPoly;
    uint256 public setupCost;

    string constant POLY_ORACLE = "StablePolyUsdOracle";

    // @notice Allow only two variables to be stored
    // 1. lowerBound
    // 2. upperBound
    // @dev (0.0.0 will act as the wildcard)
    // @dev uint24 consists packed value of uint8 _major, uint8 _minor, uint8 _patch
    mapping(string => uint24) compatibleSTVersionRange;

    /**
     * @notice Constructor
     */
    constructor(uint256 _setupCost, address _polymathRegistry, bool _isCostInPoly) public {
        setupCost = _setupCost;
        polymathRegistry = IPolymathRegistry(_polymathRegistry);
        isCostInPoly = _isCostInPoly;
    }

    /**
     * @notice Type of the Module factory
     */
    function getTypes() external view returns(uint8[] memory) {
        return typesData;
    }

    /**
     * @notice Get the tags related to the module factory
     */
    function getTags() external view returns(bytes32[] memory) {
        return tagsData;
    }

    /**
     * @notice Get the version related to the module factory
     */
    function version() external view returns(string memory) {
        return initialVersion;
    }

    /**
     * @notice Used to change the fee of the setup cost
     * @param _setupCost new setup cost
     */
    function changeSetupCost(uint256 _setupCost) public onlyOwner {
        emit ChangeSetupCost(setupCost, _setupCost);
        setupCost = _setupCost;
    }

    /**
     * @notice Used to change the currency and amount of setup cost
     * @param _setupCost new setup cost
     * @param _isCostInPoly new setup cost currency. USD or POLY
     */
    function changeCostAndType(uint256 _setupCost, bool _isCostInPoly) public onlyOwner {
        emit ChangeSetupCost(setupCost, _setupCost);
        emit ChangeCostType(isCostInPoly, _isCostInPoly);
        setupCost = _setupCost;
        isCostInPoly = _isCostInPoly;
    }

    /**
     * @notice Updates the title of the ModuleFactory
     * @param _title New Title that will replace the old one.
     */
    function changeTitle(string memory _title) public onlyOwner {
        require(bytes(_title).length > 0, "Invalid text");
        title = _title;
    }

    /**
     * @notice Updates the description of the ModuleFactory
     * @param _description New description that will replace the old one.
     */
    function changeDescription(string memory _description) public onlyOwner {
        require(bytes(_description).length > 0, "Invalid text");
        description = _description;
    }

    /**
     * @notice Updates the name of the ModuleFactory
     * @param _name New name that will replace the old one.
     */
    function changeName(bytes32 _name) public onlyOwner {
        require(_name != bytes32(0), "Invalid text");
        name = _name;
    }

    /**
     * @notice Updates the tags of the ModuleFactory
     * @param _tagsData New list of tags
     */
    function changeTags(bytes32[] memory _tagsData) public onlyOwner {
        require(_tagsData.length > 0, "Invalid text");
        tagsData = _tagsData;
    }

    /**
     * @notice Function use to change the lower and upper bound of the compatible version st
     * @param _boundType Type of bound
     * @param _newVersion new version array
     */
    function changeSTVersionBounds(string calldata _boundType, uint8[] calldata _newVersion) external onlyOwner {
        require(
            keccak256(abi.encodePacked(_boundType)) == keccak256(abi.encodePacked("lowerBound")) || keccak256(
                abi.encodePacked(_boundType)
            ) == keccak256(abi.encodePacked("upperBound")),
            "Invalid bound type"
        );
        require(_newVersion.length == 3, "Invalid version");
        if (compatibleSTVersionRange[_boundType] != uint24(0)) {
            uint8[] memory _currentVersion = VersionUtils.unpack(compatibleSTVersionRange[_boundType]);
            if (keccak256(abi.encodePacked(_boundType)) == keccak256(abi.encodePacked("lowerBound"))) {
                require(VersionUtils.lessThanOrEqual(_newVersion, _currentVersion), "Invalid version");
            } else {
                require(VersionUtils.greaterThanOrEqual(_newVersion, _currentVersion), "Invalid version");
            }
        }
        compatibleSTVersionRange[_boundType] = VersionUtils.pack(_newVersion[0], _newVersion[1], _newVersion[2]);
        emit ChangeSTVersionBound(_boundType, _newVersion[0], _newVersion[1], _newVersion[2]);
    }

    /**
     * @notice Used to get the lower bound
     * @return lower bound
     */
    function getLowerSTVersionBounds() external view returns(uint8[] memory) {
        return VersionUtils.unpack(compatibleSTVersionRange["lowerBound"]);
    }

    /**
     * @notice Used to get the upper bound
     * @return upper bound
     */
    function getUpperSTVersionBounds() external view returns(uint8[] memory) {
        return VersionUtils.unpack(compatibleSTVersionRange["upperBound"]);
    }

    /**
     * @notice Get the setup cost of the module
     */
    function setupCostInPoly() public returns (uint256) {
        if (isCostInPoly)
            return setupCost;
        uint256 polyRate = IOracle(polymathRegistry.getAddress(POLY_ORACLE)).getPrice();
        return DecimalMath.div(setupCost, polyRate);
    }

    /**
     * @notice Calculates fee in POLY
     */
    function _takeFee() internal returns(uint256) {
        uint256 polySetupCost = setupCostInPoly();
        address polyToken = polymathRegistry.getAddress("PolyToken");
        if (polySetupCost > 0) {
            require(IERC20(polyToken).transferFrom(msg.sender, owner(), polySetupCost), "Insufficient allowance for module fee");
        }
        return polySetupCost;
    }

    /**
     * @notice Used to initialize the module
     * @param _module Address of module
     * @param _data Data used for the intialization of the module factory variables
     */
    function _initializeModule(address _module, bytes memory _data) internal {
        uint256 polySetupCost = _takeFee();
        bytes4 initFunction = IModule(_module).getInitFunction();
        if (initFunction != bytes4(0)) {
            require(Util.getSig(_data) == initFunction, "Provided data is not valid");
            /*solium-disable-next-line security/no-low-level-calls*/
            (bool success, ) = _module.call(_data);
            require(success, "Unsuccessful initialization");
        }
        /*solium-disable-next-line security/no-block-members*/
        emit GenerateModuleFromFactory(_module, name, address(this), msg.sender, setupCost, polySetupCost);
    }

}

/**
 * Utility library of inline functions on addresses
 */
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

/**
 * @title UpgradeabilityProxy
 * @dev This contract represents a proxy where the implementation address to which it will delegate can be upgraded
 */
contract UpgradeabilityProxy is Proxy {
    // Version name of the current implementation
    string internal __version;

    // Address of the current implementation
    address internal __implementation;

    /**
    * @dev This event will be emitted every time the implementation gets upgraded
    * @param _newVersion representing the version name of the upgraded implementation
    * @param _newImplementation representing the address of the upgraded implementation
    */
    event Upgraded(string _newVersion, address indexed _newImplementation);

    /**
    * @dev Upgrades the implementation address
    * @param _newVersion representing the version name of the new implementation to be set
    * @param _newImplementation representing the address of the new implementation to be set
    */
    function _upgradeTo(string memory _newVersion, address _newImplementation) internal {
        require(
            __implementation != _newImplementation && _newImplementation != address(0),
            "Old address is not allowed and implementation address should not be 0x"
        );
        require(Address.isContract(_newImplementation), "Cannot set a proxy implementation to a non-contract address");
        require(bytes(_newVersion).length > 0, "Version should not be empty string");
        require(keccak256(abi.encodePacked(__version)) != keccak256(abi.encodePacked(_newVersion)), "New version equals to current");
        __version = _newVersion;
        __implementation = _newImplementation;
        emit Upgraded(_newVersion, _newImplementation);
    }

}

/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradeabilityProxy is UpgradeabilityProxy {
    // Owner of the contract
    address private __upgradeabilityOwner;

    /**
    * @dev Event to show ownership has been transferred
    * @param _previousOwner representing the address of the previous owner
    * @param _newOwner representing the address of the new owner
    */
    event ProxyOwnershipTransferred(address _previousOwner, address _newOwner);

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier ifOwner() {
        if (msg.sender == _upgradeabilityOwner()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
    * @dev the constructor sets the original owner of the contract to the sender account.
    */
    constructor() public {
        _setUpgradeabilityOwner(msg.sender);
    }

    /**
    * @dev Tells the address of the owner
    * @return the address of the owner
    */
    function _upgradeabilityOwner() internal view returns(address) {
        return __upgradeabilityOwner;
    }

    /**
    * @dev Sets the address of the owner
    */
    function _setUpgradeabilityOwner(address _newUpgradeabilityOwner) internal {
        require(_newUpgradeabilityOwner != address(0), "Address should not be 0x");
        __upgradeabilityOwner = _newUpgradeabilityOwner;
    }

    /**
    * @notice Internal function to provide the address of the implementation contract
    */
    function _implementation() internal view returns(address) {
        return __implementation;
    }

    /**
    * @dev Tells the address of the proxy owner
    * @return the address of the proxy owner
    */
    function proxyOwner() external ifOwner returns(address) {
        return _upgradeabilityOwner();
    }

    /**
    * @dev Tells the version name of the current implementation
    * @return string representing the name of the current version
    */
    function version() external ifOwner returns(string memory) {
        return __version;
    }

    /**
    * @dev Tells the address of the current implementation
    * @return address of the current implementation
    */
    function implementation() external ifOwner returns(address) {
        return _implementation();
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferProxyOwnership(address _newOwner) external ifOwner {
        require(_newOwner != address(0), "Address should not be 0x");
        emit ProxyOwnershipTransferred(_upgradeabilityOwner(), _newOwner);
        _setUpgradeabilityOwner(_newOwner);
    }

    /**
    * @dev Allows the upgradeability owner to upgrade the current version of the proxy.
    * @param _newVersion representing the version name of the new implementation to be set.
    * @param _newImplementation representing the address of the new implementation to be set.
    */
    function upgradeTo(string calldata _newVersion, address _newImplementation) external ifOwner {
        _upgradeTo(_newVersion, _newImplementation);
    }

    /**
    * @dev Allows the upgradeability owner to upgrade the current version of the proxy and call the new implementation
    * to initialize whatever is needed through a low level call.
    * @param _newVersion representing the version name of the new implementation to be set.
    * @param _newImplementation representing the address of the new implementation to be set.
    * @param _data represents the msg.data to bet sent in the low level call. This parameter may include the function
    * signature of the implementation to be called with the needed payload
    */
    function upgradeToAndCall(string calldata _newVersion, address _newImplementation, bytes calldata _data) external payable ifOwner {
        _upgradeToAndCall(_newVersion, _newImplementation, _data);
    }

    function _upgradeToAndCall(string memory _newVersion, address _newImplementation, bytes memory _data) internal {
        _upgradeTo(_newVersion, _newImplementation);
        bool success;
        /*solium-disable-next-line security/no-call-value*/
        (success, ) = address(this).call.value(msg.value)(_data);
        require(success, "Fail in executing the function of implementation contract");
    }

}

/**
 * @title Factory for deploying upgradable modules
 */
contract UpgradableModuleFactory is ModuleFactory {

    event LogicContractSet(string _version, uint256 _upgrade, address _logicContract, bytes _upgradeData);

    event ModuleUpgraded(
        address indexed _module,
        address indexed _securityToken,
        uint256 indexed _version
    );

    struct LogicContract {
        string version;
        address logicContract;
        bytes upgradeData;
    }

    // Mapping from version to logic contract
    mapping (uint256 => LogicContract) public logicContracts;

    // Mapping from Security Token address, to deployed proxy module address, to module version
    mapping (address => mapping (address => uint256)) public modules;

    // Mapping of which security token owns a given module
    mapping (address => address) public moduleToSecurityToken;

    // Current version
    uint256 public latestUpgrade;

    /**
     * @notice Constructor
     * @param _setupCost Setup cost of the module
      * @param _logicContract Contract address that contains the logic related to `description`
     * @param _polymathRegistry Address of the Polymath registry
     * @param _isCostInPoly true = cost in Poly, false = USD
     */
    constructor(
        string memory _version,
        uint256 _setupCost,
        address _logicContract,
        address _polymathRegistry,
        bool _isCostInPoly
    )
        public ModuleFactory(_setupCost, _polymathRegistry, _isCostInPoly)
    {
        require(_logicContract != address(0), "Invalid address");
        logicContracts[latestUpgrade].logicContract = _logicContract;
        logicContracts[latestUpgrade].version = _version;
    }

    /**
     * @notice Used to upgrade the module factory
     * @param _version Version of upgraded module
     * @param _logicContract Address of deployed module logic contract referenced from proxy
     * @param _upgradeData Data to be passed in call to upgradeToAndCall when a token upgrades its module
     */
    function setLogicContract(string calldata _version, address _logicContract, bytes calldata _upgradeData) external onlyOwner {
        require(keccak256(abi.encodePacked(_version)) != keccak256(abi.encodePacked(logicContracts[latestUpgrade].version)), "Same version");
        require(_logicContract != logicContracts[latestUpgrade].logicContract, "Same version");
        require(_logicContract != address(0), "Invalid address");
        latestUpgrade++;
        _modifyLogicContract(latestUpgrade, _version, _logicContract, _upgradeData);
    }

    /**
     * @notice Used to update an existing token logic contract
     * @param _upgrade logic contract to upgrade
     * @param _version Version of upgraded module
     * @param _logicContract Address of deployed module logic contract referenced from proxy
     * @param _upgradeData Data to be passed in call to upgradeToAndCall when a token upgrades its module
     */
    function updateLogicContract(uint256 _upgrade, string calldata _version, address _logicContract, bytes calldata _upgradeData) external onlyOwner {
        require(_upgrade <= latestUpgrade, "Invalid upgrade");
        // version & contract must differ from previous version, otherwise upgrade proxy will fail
        if (_upgrade > 0) {
          require(keccak256(abi.encodePacked(_version)) != keccak256(abi.encodePacked(logicContracts[_upgrade - 1].version)), "Same version");
          require(_logicContract != logicContracts[_upgrade - 1].logicContract, "Same version");
        }
        require(_logicContract != address(0), "Invalid address");
        require(_upgradeData.length > 4, "Invalid Upgrade");
        _modifyLogicContract(_upgrade, _version, _logicContract, _upgradeData);
    }

    function _modifyLogicContract(uint256 _upgrade, string memory _version, address _logicContract, bytes memory _upgradeData) internal {
        logicContracts[_upgrade].version = _version;
        logicContracts[_upgrade].logicContract = _logicContract;
        logicContracts[_upgrade].upgradeData = _upgradeData;
        IModuleRegistry moduleRegistry = IModuleRegistry(polymathRegistry.getAddress("ModuleRegistry"));
        moduleRegistry.unverifyModule(address(this));
        emit LogicContractSet(_version, _upgrade, _logicContract, _upgradeData);
    }

    /**
     * @notice Used by a security token to upgrade a given module
     * @param _module Address of (proxy) module to be upgraded
     */
    function upgrade(address _module) external {
        // Only allow the owner of a module to upgrade it
        require(moduleToSecurityToken[_module] == msg.sender, "Incorrect caller");
        // Only allow issuers to upgrade in single step verisons to preserve upgradeToAndCall semantics
        uint256 newVersion = modules[msg.sender][_module] + 1;
        require(newVersion <= latestUpgrade, "Incorrect version");
        OwnedUpgradeabilityProxy(address(uint160(_module))).upgradeToAndCall(logicContracts[newVersion].version, logicContracts[newVersion].logicContract, logicContracts[newVersion].upgradeData);
        modules[msg.sender][_module] = newVersion;
        emit ModuleUpgraded(
            _module,
            msg.sender,
            newVersion
        );
    }

    /**
     * @notice Used to initialize the module
     * @param _module Address of module
     * @param _data Data used for the intialization of the module factory variables
     */
    function _initializeModule(address _module, bytes memory _data) internal {
        super._initializeModule(_module, _data);
        moduleToSecurityToken[_module] = msg.sender;
        modules[msg.sender][_module] = latestUpgrade;
    }

    /**
     * @notice Get the version related to the module factory
     */
    function version() external view returns(string memory) {
        return logicContracts[latestUpgrade].version;
    }

}

/**
 * @title Interface to be implemented by all Transfer Manager modules
 */
interface ITransferManager {
    //  If verifyTransfer returns:
    //  FORCE_VALID, the transaction will always be valid, regardless of other TM results
    //  INVALID, then the transfer should not be allowed regardless of other TM results
    //  VALID, then the transfer is valid for this TM
    //  NA, then the result from this TM is ignored
    enum Result {INVALID, NA, VALID, FORCE_VALID}

    /**
     * @notice Determines if the transfer between these two accounts can happen
     */
    function executeTransfer(address _from, address _to, uint256 _amount, bytes calldata _data) external returns(Result result);

    function verifyTransfer(address _from, address _to, uint256 _amount, bytes calldata _data) external view returns(Result result, bytes32 partition);

    /**
     * @notice return the amount of tokens for a given user as per the partition
     * @param _partition Identifier
     * @param _tokenHolder Whom token amount need to query
     * @param _additionalBalance It is the `_value` that transfer during transfer/transferFrom function call
     */
    function getTokensByPartition(bytes32 _partition, address _tokenHolder, uint256 _additionalBalance) external view returns(uint256 amount);

}

/**
 * @title Interface to be implemented by all permission manager modules
 */
interface IPermissionManager {
    /**
    * @notice Used to check the permission on delegate corresponds to module contract address
    * @param _delegate Ethereum address of the delegate
    * @param _module Ethereum contract address of the module
    * @param _perm Permission flag
    * @return bool
    */
    function checkPermission(address _delegate, address _module, bytes32 _perm) external view returns(bool);

    /**
    * @notice Used to add a delegate
    * @param _delegate Ethereum address of the delegate
    * @param _details Details about the delegate i.e `Belongs to financial firm`
    */
    function addDelegate(address _delegate, bytes32 _details) external;

    /**
    * @notice Used to delete a delegate
    * @param _delegate Ethereum address of the delegate
    */
    function deleteDelegate(address _delegate) external;

    /**
    * @notice Used to check if an address is a delegate or not
    * @param _potentialDelegate the address of potential delegate
    * @return bool
    */
    function checkDelegate(address _potentialDelegate) external view returns(bool);

    /**
    * @notice Used to provide/change the permission to the delegate corresponds to the module contract
    * @param _delegate Ethereum address of the delegate
    * @param _module Ethereum contract address of the module
    * @param _perm Permission flag
    * @param _valid Bool flag use to switch on/off the permission
    * @return bool
    */
    function changePermission(address _delegate, address _module, bytes32 _perm, bool _valid) external;

    /**
    * @notice Used to change one or more permissions for a single delegate at once
    * @param _delegate Ethereum address of the delegate
    * @param _modules Multiple module matching the multiperms, needs to be same length
    * @param _perms Multiple permission flag needs to be changed
    * @param _valids Bool array consist the flag to switch on/off the permission
    * @return nothing
    */
    function changePermissionMulti(
        address _delegate,
        address[] calldata _modules,
        bytes32[] calldata _perms,
        bool[] calldata _valids
    ) external;

    /**
    * @notice Used to return all delegates with a given permission and module
    * @param _module Ethereum contract address of the module
    * @param _perm Permission flag
    * @return address[]
    */
    function getAllDelegatesWithPerm(address _module, bytes32 _perm) external view returns(address[] memory);

    /**
    * @notice Used to return all permission of a single or multiple module
    * @dev possible that function get out of gas is there are lot of modules and perm related to them
    * @param _delegate Ethereum address of the delegate
    * @param _types uint8[] of types
    * @return address[] the address array of Modules this delegate has permission
    * @return bytes32[] the permission array of the corresponding Modules
    */
    function getAllModulesAndPermsFromTypes(address _delegate, uint8[] calldata _types) external view returns(
        address[] memory,
        bytes32[] memory
    );

    /**
    * @notice Used to get the Permission flag related the `this` contract
    * @return Array of permission flags
    */
    function getPermissions() external view returns(bytes32[] memory);

    /**
    * @notice Used to get all delegates
    * @return address[]
    */
    function getAllDelegates() external view returns(address[] memory);

}

library TokenLib {

    using SafeMath for uint256;

    struct EIP712Domain {
        string  name;
        uint256 chainId;
        address verifyingContract;
    }

    struct Acknowledgment {
        string text;
    }

    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
    );

    bytes32 constant ACK_TYPEHASH = keccak256(
        "Acknowledgment(string text)"
    );

    bytes32 internal constant WHITELIST = "WHITELIST";
    bytes32 internal constant INVESTORSKEY = 0xdf3a8dd24acdd05addfc6aeffef7574d2de3f844535ec91e8e0f3e45dba96731; //keccak256(abi.encodePacked("INVESTORS"))

    // Emit when Module get upgraded from the securityToken
    event ModuleUpgraded(uint8[] _types, address _module);
    // Emit when Module is archived from the SecurityToken
    event ModuleArchived(uint8[] _types, address _module);
    // Emit when Module is unarchived from the SecurityToken
    event ModuleUnarchived(uint8[] _types, address _module);
    // Emit when Module get removed from the securityToken
    event ModuleRemoved(uint8[] _types, address _module);
    // Emit when the budget allocated to a module is changed
    event ModuleBudgetChanged(uint8[] _moduleTypes, address _module, uint256 _oldBudget, uint256 _budget);
    // Emit when document is added/removed
    event DocumentUpdated(bytes32 indexed _name, string _uri, bytes32 _documentHash);
    event DocumentRemoved(bytes32 indexed _name, string _uri, bytes32 _documentHash);

    function hash(EIP712Domain memory _eip712Domain) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256(bytes(_eip712Domain.name)),
                _eip712Domain.chainId,
                _eip712Domain.verifyingContract
            )
        );
    }

    function hash(Acknowledgment memory _ack) internal pure returns (bytes32) {
        return keccak256(abi.encode(ACK_TYPEHASH, keccak256(bytes(_ack.text))));
    }

    function recoverFreezeIssuanceAckSigner(bytes calldata _signature) external view returns (address) {
        Acknowledgment memory ack = Acknowledgment("I acknowledge that freezing Issuance is a permanent and irrevocable change");
        return extractSigner(ack, _signature);
    }

    function recoverDisableControllerAckSigner(bytes calldata _signature) external view returns (address) {
        Acknowledgment memory ack = Acknowledgment("I acknowledge that disabling controller is a permanent and irrevocable change");
        return extractSigner(ack, _signature);
    }

    function extractSigner(Acknowledgment memory _ack, bytes memory _signature) internal view returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (_signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        }

        bytes32 DOMAIN_SEPARATOR = hash(
            EIP712Domain(
                {
                    name: "Polymath",
                    chainId: 1,
                    verifyingContract: address(this)
                }
            )
        );

        // Note: we need to use `encodePacked` here instead of `encode`.
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            hash(_ack)
        ));
        return ecrecover(digest, v, r, s);
    }

    /**
    * @notice Archives a module attached to the SecurityToken
    * @param _moduleData Storage data
    */
    function archiveModule(SecurityTokenStorage.ModuleData storage _moduleData) external {
        require(!_moduleData.isArchived, "Module archived");
        require(_moduleData.module != address(0), "Module missing");
        /*solium-disable-next-line security/no-block-members*/
        emit ModuleArchived(_moduleData.moduleTypes, _moduleData.module);
        _moduleData.isArchived = true;
    }

    /**
    * @notice Unarchives a module attached to the SecurityToken
    * @param _moduleData Storage data
    */
    function unarchiveModule(IModuleRegistry _moduleRegistry, SecurityTokenStorage.ModuleData storage _moduleData) external {
        require(_moduleData.isArchived, "Module unarchived");
        /*solium-disable-next-line security/no-block-members*/
        // Check the version is still valid - can only be false if token was upgraded between unarchive / archive
        _moduleRegistry.useModule(_moduleData.moduleFactory, true);
        emit ModuleUnarchived(_moduleData.moduleTypes, _moduleData.module);
        _moduleData.isArchived = false;
    }

    /**
    * @notice Upgrades a module attached to the SecurityToken
    * @param _moduleData Storage data
    */
    function upgradeModule(IModuleRegistry _moduleRegistry, SecurityTokenStorage.ModuleData storage _moduleData) external {
        require(_moduleData.module != address(0), "Module missing");
        //Check module is verified and within version bounds
        _moduleRegistry.useModule(_moduleData.moduleFactory, true);
        // Will revert if module isn't upgradable
        UpgradableModuleFactory(_moduleData.moduleFactory).upgrade(_moduleData.module);
        emit ModuleUpgraded(_moduleData.moduleTypes, _moduleData.module);
    }

    /**
    * @notice Removes a module attached to the SecurityToken
    * @param _module address of module to unarchive
    */
    function removeModule(
        address _module,
        mapping(uint8 => address[]) storage _modules,
        mapping(address => SecurityTokenStorage.ModuleData) storage _modulesToData,
        mapping(bytes32 => address[]) storage _names
    )
        external
    {
        require(_modulesToData[_module].isArchived, "Not archived");
        require(_modulesToData[_module].module != address(0), "Module missing");
        /*solium-disable-next-line security/no-block-members*/
        emit ModuleRemoved(_modulesToData[_module].moduleTypes, _module);
        // Remove from module type list
        uint8[] memory moduleTypes = _modulesToData[_module].moduleTypes;
        for (uint256 i = 0; i < moduleTypes.length; i++) {
            _removeModuleWithIndex(moduleTypes[i], _modulesToData[_module].moduleIndexes[i], _modules, _modulesToData);
            /* modulesToData[_module].moduleType[moduleTypes[i]] = false; */
        }
        // Remove from module names list
        uint256 index = _modulesToData[_module].nameIndex;
        bytes32 name = _modulesToData[_module].name;
        uint256 length = _names[name].length;
        _names[name][index] = _names[name][length - 1];
        _names[name].length = length - 1;
        if ((length - 1) != index) {
            _modulesToData[_names[name][index]].nameIndex = index;
        }
        // Remove from modulesToData
        delete _modulesToData[_module];
    }

    /**
    * @notice Internal - Removes a module attached to the SecurityToken by index
    */
    function _removeModuleWithIndex(
        uint8 _type,
        uint256 _index,
        mapping(uint8 => address[]) storage _modules,
        mapping(address => SecurityTokenStorage.ModuleData) storage _modulesToData
    )
        internal
    {
        uint256 length = _modules[_type].length;
        _modules[_type][_index] = _modules[_type][length - 1];
        _modules[_type].length = length - 1;

        if ((length - 1) != _index) {
            //Need to find index of _type in moduleTypes of module we are moving
            uint8[] memory newTypes = _modulesToData[_modules[_type][_index]].moduleTypes;
            for (uint256 i = 0; i < newTypes.length; i++) {
                if (newTypes[i] == _type) {
                    _modulesToData[_modules[_type][_index]].moduleIndexes[i] = _index;
                }
            }
        }
    }

    /**
    * @notice allows owner to increase/decrease POLY approval of one of the modules
    * @param _module module address
    * @param _change change in allowance
    * @param _increase true if budget has to be increased, false if decrease
    */
    function changeModuleBudget(
        address _module,
        uint256 _change,
        bool _increase,
        IERC20 _polyToken,
        mapping(address => SecurityTokenStorage.ModuleData) storage _modulesToData
    )
        external
    {
        require(_modulesToData[_module].module != address(0), "Module missing");
        uint256 currentAllowance = _polyToken.allowance(address(this), _module);
        uint256 newAllowance;
        if (_increase) {
            require(IPoly(address(_polyToken)).increaseApproval(_module, _change), "IncreaseApproval fail");
            newAllowance = currentAllowance.add(_change);
        } else {
            require(IPoly(address(_polyToken)).decreaseApproval(_module, _change), "Insufficient allowance");
            newAllowance = currentAllowance.sub(_change);
        }
        emit ModuleBudgetChanged(_modulesToData[_module].moduleTypes, _module, currentAllowance, newAllowance);
    }

    /**
     * @notice Queries a value at a defined checkpoint
     * @param _checkpoints is array of Checkpoint objects
     * @param _checkpointId is the Checkpoint ID to query
     * @param _currentValue is the Current value of checkpoint
     * @return uint256
     */
    function getValueAt(SecurityTokenStorage.Checkpoint[] storage _checkpoints, uint256 _checkpointId, uint256 _currentValue) external view returns(uint256) {
        //Checkpoint id 0 is when the token is first created - everyone has a zero balance
        if (_checkpointId == 0) {
            return 0;
        }
        if (_checkpoints.length == 0) {
            return _currentValue;
        }
        if (_checkpoints[0].checkpointId >= _checkpointId) {
            return _checkpoints[0].value;
        }
        if (_checkpoints[_checkpoints.length - 1].checkpointId < _checkpointId) {
            return _currentValue;
        }
        if (_checkpoints[_checkpoints.length - 1].checkpointId == _checkpointId) {
            return _checkpoints[_checkpoints.length - 1].value;
        }
        uint256 min = 0;
        uint256 max = _checkpoints.length - 1;
        while (max > min) {
            uint256 mid = (max + min) / 2;
            if (_checkpoints[mid].checkpointId == _checkpointId) {
                max = mid;
                break;
            }
            if (_checkpoints[mid].checkpointId < _checkpointId) {
                min = mid + 1;
            } else {
                max = mid;
            }
        }
        return _checkpoints[max].value;
    }

    /**
     * @notice Stores the changes to the checkpoint objects
     * @param _checkpoints is the affected checkpoint object array
     * @param _newValue is the new value that needs to be stored
     */
    function adjustCheckpoints(SecurityTokenStorage.Checkpoint[] storage _checkpoints, uint256 _newValue, uint256 _currentCheckpointId) external {
        //No checkpoints set yet
        if (_currentCheckpointId == 0) {
            return;
        }
        //No new checkpoints since last update
        if ((_checkpoints.length > 0) && (_checkpoints[_checkpoints.length - 1].checkpointId == _currentCheckpointId)) {
            return;
        }
        //New checkpoint, so record balance
        _checkpoints.push(SecurityTokenStorage.Checkpoint({checkpointId: _currentCheckpointId, value: _newValue}));
    }

    /**
    * @notice Keeps track of the number of non-zero token holders
    * @param _holderCount Number of current token holders
    * @param _from Sender of transfer
    * @param _to Receiver of transfer
    * @param _value Value of transfer
    * @param _balanceTo Balance of the _to address
    * @param _balanceFrom Balance of the _from address
    * @param _dataStore address of data store
    */
    function adjustInvestorCount(
        uint256 _holderCount,
        address _from,
        address _to,
        uint256 _value,
        uint256 _balanceTo,
        uint256 _balanceFrom,
        IDataStore _dataStore
    )
        external
        returns(uint256)
    {
        uint256 holderCount = _holderCount;
        if ((_value == 0) || (_from == _to)) {
            return holderCount;
        }
        // Check whether receiver is a new token holder
        if ((_balanceTo == 0) && (_to != address(0))) {
            holderCount = holderCount.add(1);
            if (!_isExistingInvestor(_to, _dataStore)) {
                _dataStore.insertAddress(INVESTORSKEY, _to);
                //KYC data can not be present if added is false and hence we can set packed KYC as uint256(1) to set added as true
                _dataStore.setUint256(_getKey(WHITELIST, _to), uint256(1));
            }
        }
        // Check whether sender is moving all of their tokens
        if (_value == _balanceFrom) {
            holderCount = holderCount.sub(1);
        }

        return holderCount;
    }

    /**
     * @notice Used to attach a new document to the contract, or update the URI or hash of an existing attached document
     * @param name Name of the document. It should be unique always
     * @param uri Off-chain uri of the document from where it is accessible to investors/advisors to read.
     * @param documentHash hash (of the contents) of the document.
     */
    function setDocument(
        mapping(bytes32 => SecurityTokenStorage.Document) storage document,
        bytes32[] storage docNames,
        mapping(bytes32 => uint256) storage docIndexes,
        bytes32 name,
        string calldata uri,
        bytes32 documentHash
    )
        external
    {
        require(name != bytes32(0), "Bad name");
        require(bytes(uri).length > 0, "Bad uri");
        if (document[name].lastModified == uint256(0)) {
            docNames.push(name);
            docIndexes[name] = docNames.length;
        }
        document[name] = SecurityTokenStorage.Document(documentHash, now, uri);
        emit DocumentUpdated(name, uri, documentHash);
    }

    /**
     * @notice Used to remove an existing document from the contract by giving the name of the document.
     * @dev Can only be executed by the owner of the contract.
     * @param name Name of the document. It should be unique always
     */
    function removeDocument(
        mapping(bytes32 => SecurityTokenStorage.Document) storage document,
        bytes32[] storage docNames,
        mapping(bytes32 => uint256) storage docIndexes,
        bytes32 name
    )
        external
    {
        require(document[name].lastModified != uint256(0), "Not existed");
        uint256 index = docIndexes[name] - 1;
        if (index != docNames.length - 1) {
            docNames[index] = docNames[docNames.length - 1];
            docIndexes[docNames[index]] = index + 1;
        }
        docNames.length--;
        emit DocumentRemoved(name, document[name].uri, document[name].docHash);
        delete document[name];
    }

    /**
     * @notice Validate transfer with TransferManager module if it exists
     * @dev TransferManager module has a key of 2
     * @param modules Array of addresses for transfer managers
     * @param modulesToData Mapping of the modules details
     * @param from sender of transfer
     * @param to receiver of transfer
     * @param value value of transfer
     * @param data data to indicate validation
     * @param transfersFrozen whether the transfer are frozen or not.
     * @return bool
     */
    function verifyTransfer(
        address[] storage modules,
        mapping(address => SecurityTokenStorage.ModuleData) storage modulesToData,
        address from,
        address to,
        uint256 value,
        bytes memory data,
        bool transfersFrozen
    )
        public //Marked public to avoid stack too deep error
        view
        returns(bool, bytes32)
    {
        if (!transfersFrozen) {
            bool isInvalid = false;
            bool isValid = false;
            bool isForceValid = false;
            // Use the local variables to avoid the stack too deep error
            bytes32 appCode;
            for (uint256 i = 0; i < modules.length; i++) {
                if (!modulesToData[modules[i]].isArchived) {
                    (ITransferManager.Result valid, bytes32 reason) = ITransferManager(modules[i]).verifyTransfer(from, to, value, data);
                    if (valid == ITransferManager.Result.INVALID) {
                        isInvalid = true;
                        appCode = reason;
                    } else if (valid == ITransferManager.Result.VALID) {
                        isValid = true;
                    } else if (valid == ITransferManager.Result.FORCE_VALID) {
                        isForceValid = true;
                    }
                }
            }
            // Use the local variables to avoid the stack too deep error
            isValid = isForceValid ? true : (isInvalid ? false : isValid);
            return (isValid, isValid ? bytes32(StatusCodes.code(StatusCodes.Status.TransferSuccess)): appCode);
        }
        return (false, bytes32(StatusCodes.code(StatusCodes.Status.TransfersHalted)));
    }

    function canTransfer(
        bool success,
        bytes32 appCode,
        address to,
        uint256 value,
        uint256 balanceOfFrom
    )
        external
        pure
        returns (byte, bytes32)
    {
        if (!success)
            return (StatusCodes.code(StatusCodes.Status.TransferFailure), appCode);

        if (balanceOfFrom < value)
            return (StatusCodes.code(StatusCodes.Status.InsufficientBalance), bytes32(0));

        if (to == address(0))
            return (StatusCodes.code(StatusCodes.Status.InvalidReceiver), bytes32(0));

        // Balance overflow can never happen due to totalsupply being a uint256 as well
        // else if (!KindMath.checkAdd(balanceOf(_to), _value))
        //     return (0x50, bytes32(0));

        return (StatusCodes.code(StatusCodes.Status.TransferSuccess), bytes32(0));
    }

    function _getKey(bytes32 _key1, address _key2) internal pure returns(bytes32) {
        return bytes32(keccak256(abi.encodePacked(_key1, _key2)));
    }

    function _isExistingInvestor(address _investor, IDataStore dataStore) internal view returns(bool) {
        uint256 data = dataStore.getUint256(_getKey(WHITELIST, _investor));
        //extracts `added` from packed `whitelistData`
        return uint8(data) == 0 ? false : true;
    }

}

/**
 * @title Interface to be implemented by upgradable token factories
 */
interface IUpgradableTokenFactory {

  /**
   * @notice Used to upgrade a token
   * @param _maxModuleType maximum module type enumeration
   */
  function upgradeToken(uint8 _maxModuleType) external;

}

interface IERC1410 {

    // Token Information
    function balanceOfByPartition(bytes32 _partition, address _tokenHolder) external view returns (uint256);
    //function partitionsOf(address _tokenHolder) external view returns (bytes32[] memory);

    // Token Transfers
    function transferByPartition(bytes32 _partition, address _to, uint256 _value, bytes calldata _data) external returns (bytes32);
    function operatorTransferByPartition(bytes32 _partition, address _from, address _to, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external returns (bytes32);
    function canTransferByPartition(address _from, address _to, bytes32 _partition, uint256 _value, bytes calldata _data) external view returns (byte, bytes32, bytes32);

    // Operator Information
    // These functions are present in the STGetter
    // function isOperator(address _operator, address _tokenHolder) external view returns (bool);
    // function isOperatorForPartition(bytes32 _partition, address _operator, address _tokenHolder) external view returns (bool);

    // Operator Management
    function authorizeOperator(address _operator) external;
    function revokeOperator(address _operator) external;
    function authorizeOperatorByPartition(bytes32 _partition, address _operator) external;
    function revokeOperatorByPartition(bytes32 _partition, address _operator) external;

    // Issuance / Redemption
    function issueByPartition(bytes32 _partition, address _tokenHolder, uint256 _value, bytes calldata _data) external;
    function redeemByPartition(bytes32 _partition, uint256 _value, bytes calldata _data) external;
    function operatorRedeemByPartition(bytes32 _partition, address _tokenHolder, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external;

    // Transfer Events
    event TransferByPartition(
        bytes32 indexed _fromPartition,
        address _operator,
        address indexed _from,
        address indexed _to,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    // Operator Events
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);
    event AuthorizedOperatorByPartition(bytes32 indexed partition, address indexed operator, address indexed tokenHolder);
    event RevokedOperatorByPartition(bytes32 indexed partition, address indexed operator, address indexed tokenHolder);

    // Issuance / Redemption Events
    event IssuedByPartition(bytes32 indexed partition, address indexed to, uint256 value, bytes data);
    event RedeemedByPartition(bytes32 indexed partition, address indexed operator, address indexed from, uint256 value, bytes data, bytes operatorData);

}

/**
 * @title Standard Interface of ERC1594
 */
interface IERC1594 {

    // Transfers
    function transferWithData(address _to, uint256 _value, bytes calldata _data) external;
    function transferFromWithData(address _from, address _to, uint256 _value, bytes calldata _data) external;

    // Token Issuance
    // Present in the STGetter.sol
    //function isIssuable() external view returns (bool);
    function issue(address _tokenHolder, uint256 _value, bytes calldata _data) external;

    // Token Redemption
    function redeem(uint256 _value, bytes calldata _data) external;
    function redeemFrom(address _tokenHolder, uint256 _value, bytes calldata _data) external;

    // Transfer Validity
    function canTransfer(address _to, uint256 _value, bytes calldata _data) external view returns (byte, bytes32);
    function canTransferFrom(address _from, address _to, uint256 _value, bytes calldata _data) external view returns (byte, bytes32);

    // Issuance / Redemption Events
    event Issued(address indexed _operator, address indexed _to, uint256 _value, bytes _data);
    event Redeemed(address indexed _operator, address indexed _from, uint256 _value, bytes _data);

}

// @title IERC1643 Document Management (part of the ERC1400 Security Token Standards)
/// @dev See https://github.com/SecurityTokenStandard/EIP-Spec

interface IERC1643 {

    // Document Management
    //-- Included in interface but commented because getDocuement() & getAllDocuments() body is provided in the STGetter
    // function getDocument(bytes32 _name) external view returns (string memory, bytes32, uint256);
    // function getAllDocuments() external view returns (bytes32[] memory);
    function setDocument(bytes32 _name, string calldata _uri, bytes32 _documentHash) external;
    function removeDocument(bytes32 _name) external;

    // Document Events
    event DocumentRemoved(bytes32 indexed _name, string _uri, bytes32 _documentHash);
    event DocumentUpdated(bytes32 indexed _name, string _uri, bytes32 _documentHash);

}

interface IERC1644 {

    // Controller Operation
    function isControllable() external view returns (bool);
    function controllerTransfer(address _from, address _to, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external;
    function controllerRedeem(address _tokenHolder, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external;

    // Controller Events
    event ControllerTransfer(
        address _controller,
        address indexed _from,
        address indexed _to,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    event ControllerRedemption(
        address _controller,
        address indexed _tokenHolder,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

}

/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <remco@2π.com>, Eenae <alexey@mixbytes.io>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://eips.ethereum.org/EIPS/eip-20
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer token to a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
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
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}

/**
 * @title Security Token contract
 * @notice SecurityToken is an ERC1400 token with added capabilities:
 * @notice - Implements the ERC1400 Interface
 * @notice - Transfers are restricted
 * @notice - Modules can be attached to it to control its behaviour
 * @notice - ST should not be deployed directly, but rather the SecurityTokenRegistry should be used
 * @notice - ST does not inherit from ISecurityToken due to:
 * @notice - https://github.com/ethereum/solidity/issues/4847
 */
contract SecurityToken is ERC20, ReentrancyGuard, SecurityTokenStorage, IERC1594, IERC1643, IERC1644, IERC1410, Proxy {

    using SafeMath for uint256;

    // Emit at the time when module get added
    event ModuleAdded(
        uint8[] _types,
        bytes32 indexed _name,
        address indexed _moduleFactory,
        address _module,
        uint256 _moduleCost,
        uint256 _budget,
        bytes32 _label,
        bool _archived
    );
    // Emit when Module get upgraded from the securityToken
    event ModuleUpgraded(uint8[] _types, address _module);
    // Emit when the token details get updated
    event UpdateTokenDetails(string _oldDetails, string _newDetails);
    // Emit when the token name get updated
    event UpdateTokenName(string _oldName, string _newName);
    // Emit when the granularity get changed
    event GranularityChanged(uint256 _oldGranularity, uint256 _newGranularity);
    // Emit when is permanently frozen by the issuer
    event FreezeIssuance();
    // Emit when transfers are frozen or unfrozen
    event FreezeTransfers(bool _status);
    // Emit when new checkpoint created
    event CheckpointCreated(uint256 indexed _checkpointId, uint256 _investorLength);
    // Events to log controller actions
    event SetController(address indexed _oldController, address indexed _newController);
    //Event emit when the global treasury wallet address get changed
    event TreasuryWalletChanged(address _oldTreasuryWallet, address _newTreasuryWallet);
    event DisableController();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TokenUpgraded(uint8 _major, uint8 _minor, uint8 _patch);

    // Emit when Module get archived from the securityToken
    event ModuleArchived(uint8[] _types, address _module); //Event emitted by the tokenLib.
    // Emit when Module get unarchived from the securityToken
    event ModuleUnarchived(uint8[] _types, address _module); //Event emitted by the tokenLib.
    // Emit when Module get removed from the securityToken
    event ModuleRemoved(uint8[] _types, address _module); //Event emitted by the tokenLib.
    // Emit when the budget allocated to a module is changed
    event ModuleBudgetChanged(uint8[] _moduleTypes, address _module, uint256 _oldBudget, uint256 _budget); //Event emitted by the tokenLib.

    // Constructor
    constructor() public {
        initialized = true;
    }

    /**
     * @notice Initialization function
     * @dev Expected to be called atomically with the proxy being created, by the owner of the token
     * @dev Can only be called once
     */
    function initialize(address _getterDelegate) public {
        //Expected to be called atomically with the proxy being created
        require(!initialized, "Already initialized");
        getterDelegate = _getterDelegate;
        securityTokenVersion = SemanticVersion(3, 0, 0);
        updateFromRegistry();
        tokenFactory = msg.sender;
        initialized = true;
    }

    /**
     * @notice Checks if an address is a module of certain type
     * @param _module Address to check
     * @param _type type to check against
     */
    function isModule(address _module, uint8 _type) public view returns(bool) {
        if (modulesToData[_module].module != _module || modulesToData[_module].isArchived)
            return false;
        for (uint256 i = 0; i < modulesToData[_module].moduleTypes.length; i++) {
            if (modulesToData[_module].moduleTypes[i] == _type) {
                return true;
            }
        }
        return false;
    }

    // Require msg.sender to be the specified module type or the owner of the token
    function _onlyModuleOrOwner(uint8 _type) internal view {
        if (msg.sender != owner())
            require(isModule(msg.sender, _type));
    }

    function _isValidPartition(bytes32 _partition) internal pure {
        require(_partition == UNLOCKED, "Invalid partition");
    }

    function _isValidOperator(address _from, address _operator, bytes32 _partition) internal view {
        _isAuthorised(
            allowance(_from, _operator) == uint(-1) || partitionApprovals[_from][_partition][_operator]
        );
    }

    function _zeroAddressCheck(address _entity) internal pure {
        require(_entity != address(0), "Invalid address");
    }

    function _isValidTransfer(bool _isTransfer) internal pure {
        require(_isTransfer, "Transfer Invalid");
    }

    function _isValidRedeem(bool _isRedeem) internal pure {
        require(_isRedeem, "Invalid redeem");
    }

    function _isSignedByOwner(bool _signed) internal pure {
        require(_signed, "Owner did not sign");
    }

    function _isIssuanceAllowed() internal view {
        require(issuance, "Issuance frozen");
    }

    // Function to check whether the msg.sender is authorised or not
    function _onlyController() internal view {
        _isAuthorised(msg.sender == controller && isControllable());
    }

    function _isAuthorised(bool _authorised) internal pure {
        require(_authorised, "Not Authorised");
    }

    /**
     * @dev Throws if called by any account other than the owner.
     * @dev using the internal function instead of modifier to save the code size
     */
    function _onlyOwner() internal view {
        require(isOwner());
    }

    /**
     * @dev Require msg.sender to be the specified module type
     */
    function _onlyModule(uint8 _type) internal view {
        require(isModule(msg.sender, _type));
    }

    modifier checkGranularity(uint256 _value) {
        require(_value % granularity == 0, "Invalid granularity");
        _;
    }

    /**
      * @notice Attachs a module to the SecurityToken
      * @dev  E.G.: On deployment (through the STR) ST gets a TransferManager module attached to it
      * @dev to control restrictions on transfers.
      * @param _moduleFactory is the address of the module factory to be added
      * @param _data is data packed into bytes used to further configure the module (See STO usage)
      * @param _maxCost max amount of POLY willing to pay to the module.
      * @param _budget max amount of ongoing POLY willing to assign to the module.
      * @param _label custom module label.
      */
    function addModuleWithLabel(
        address _moduleFactory,
        bytes memory _data,
        uint256 _maxCost,
        uint256 _budget,
        bytes32 _label,
        bool _archived
    )
        public
        nonReentrant
    {
        _onlyOwner();
        //Check that the module factory exists in the ModuleRegistry - will throw otherwise
        moduleRegistry.useModule(_moduleFactory, false);
        IModuleFactory moduleFactory = IModuleFactory(_moduleFactory);
        uint8[] memory moduleTypes = moduleFactory.getTypes();
        uint256 moduleCost = moduleFactory.setupCostInPoly();
        require(moduleCost <= _maxCost, "Invalid cost");
        //Approve fee for module
        polyToken.approve(_moduleFactory, moduleCost);
        //Creates instance of module from factory
        address module = moduleFactory.deploy(_data);
        require(modulesToData[module].module == address(0), "Module exists");
        //Approve ongoing budget
        polyToken.approve(module, _budget);
        _addModuleData(moduleTypes, _moduleFactory, module, moduleCost, _budget, _label, _archived);
    }

    function _addModuleData(
        uint8[] memory _moduleTypes,
        address _moduleFactory,
        address _module,
        uint256 _moduleCost,
        uint256 _budget,
        bytes32 _label,
        bool _archived
    ) internal {
        bytes32 moduleName = IModuleFactory(_moduleFactory).name();
        uint256[] memory moduleIndexes = new uint256[](_moduleTypes.length);
        uint256 i;
        for (i = 0; i < _moduleTypes.length; i++) {
            moduleIndexes[i] = modules[_moduleTypes[i]].length;
            modules[_moduleTypes[i]].push(_module);
        }
        modulesToData[_module] = ModuleData(
            moduleName,
            _module,
            _moduleFactory,
            _archived,
            _moduleTypes,
            moduleIndexes,
            names[moduleName].length,
            _label
        );
        names[moduleName].push(_module);
        emit ModuleAdded(_moduleTypes, moduleName, _moduleFactory, _module, _moduleCost, _budget, _label, _archived);
    }

    /**
    * @notice addModule function will call addModuleWithLabel() with an empty label for backward compatible
    */
    function addModule(address _moduleFactory, bytes calldata _data, uint256 _maxCost, uint256 _budget, bool _archived) external {
        addModuleWithLabel(_moduleFactory, _data, _maxCost, _budget, "", _archived);
    }

    /**
    * @notice Archives a module attached to the SecurityToken
    * @param _module address of module to archive
    */
    function archiveModule(address _module) external {
        _onlyOwner();
        TokenLib.archiveModule(modulesToData[_module]);
    }

    /**
    * @notice Upgrades a module attached to the SecurityToken
    * @param _module address of module to archive
    */
    function upgradeModule(address _module) external {
        _onlyOwner();
        TokenLib.upgradeModule(moduleRegistry, modulesToData[_module]);
    }

    /**
    * @notice Upgrades security token
    */
    function upgradeToken() external {
        _onlyOwner();
        // 10 is the number of module types to check for incompatibilities before upgrading.
        // The number is hard coded and kept low to keep usage low.
        // We currently have 7 module types. If we ever create more than 3 new module types,
        // We will upgrade the implementation accordinly. We understand the limitations of this approach.
        IUpgradableTokenFactory(tokenFactory).upgradeToken(10);
        emit TokenUpgraded(securityTokenVersion.major, securityTokenVersion.minor, securityTokenVersion.patch);
    }

    /**
    * @notice Unarchives a module attached to the SecurityToken
    * @param _module address of module to unarchive
    */
    function unarchiveModule(address _module) external {
        _onlyOwner();
        TokenLib.unarchiveModule(moduleRegistry, modulesToData[_module]);
    }

    /**
    * @notice Removes a module attached to the SecurityToken
    * @param _module address of module to unarchive
    */
    function removeModule(address _module) external {
        _onlyOwner();
        TokenLib.removeModule(_module, modules, modulesToData, names);
    }

    /**
    * @notice Allows the owner to withdraw unspent POLY stored by them on the ST or any ERC20 token.
    * @dev Owner can transfer POLY to the ST which will be used to pay for modules that require a POLY fee.
    * @param _tokenContract Address of the ERC20Basic compliance token
    * @param _value amount of POLY to withdraw
    */
    function withdrawERC20(address _tokenContract, uint256 _value) external {
        _onlyOwner();
        IERC20 token = IERC20(_tokenContract);
        require(token.transfer(owner(), _value));
    }

    /**
    * @notice allows owner to increase/decrease POLY approval of one of the modules
    * @param _module module address
    * @param _change change in allowance
    * @param _increase true if budget has to be increased, false if decrease
    */
    function changeModuleBudget(address _module, uint256 _change, bool _increase) external {
        _onlyOwner();
        TokenLib.changeModuleBudget(_module, _change, _increase, polyToken, modulesToData);
    }

    /**
     * @notice updates the tokenDetails associated with the token
     * @param _newTokenDetails New token details
     */
    function updateTokenDetails(string calldata _newTokenDetails) external {
        _onlyOwner();
        emit UpdateTokenDetails(tokenDetails, _newTokenDetails);
        tokenDetails = _newTokenDetails;
    }

    /**
    * @notice Allows owner to change token granularity
    * @param _granularity granularity level of the token
    */
    function changeGranularity(uint256 _granularity) external {
        _onlyOwner();
        require(_granularity != 0, "Invalid granularity");
        emit GranularityChanged(granularity, _granularity);
        granularity = _granularity;
    }

    /**
    * @notice Allows owner to change data store
    * @param _dataStore Address of the token data store
    */
    function changeDataStore(address _dataStore) external {
        _onlyOwner();
        _zeroAddressCheck(_dataStore);
        dataStore = IDataStore(_dataStore);
    }

    /**
    * @notice Allows owner to change token name
    * @param _name new name of the token
    */
    function changeName(string calldata _name) external {
        _onlyOwner();
        require(bytes(_name).length > 0);
        emit UpdateTokenName(name, _name);
        name = _name;
    }

    /**
     * @notice Allows to change the treasury wallet address
     * @param _wallet Ethereum address of the treasury wallet
     */
    function changeTreasuryWallet(address _wallet) external {
        _onlyOwner();
        _zeroAddressCheck(_wallet);
        emit TreasuryWalletChanged(dataStore.getAddress(TREASURY), _wallet);
        dataStore.setAddress(TREASURY, _wallet);
    }

    /**
    * @notice Keeps track of the number of non-zero token holders
    * @param _from sender of transfer
    * @param _to receiver of transfer
    * @param _value value of transfer
    */
    function _adjustInvestorCount(address _from, address _to, uint256 _value) internal {
        holderCount = TokenLib.adjustInvestorCount(holderCount, _from, _to, _value, balanceOf(_to), balanceOf(_from), dataStore);
    }

    /**
     * @notice freezes transfers
     */
    function freezeTransfers() external {
        _onlyOwner();
        require(!transfersFrozen);
        transfersFrozen = true;
        /*solium-disable-next-line security/no-block-members*/
        emit FreezeTransfers(true);
    }

    /**
     * @notice Unfreeze transfers
     */
    function unfreezeTransfers() external {
        _onlyOwner();
        require(transfersFrozen);
        transfersFrozen = false;
        /*solium-disable-next-line security/no-block-members*/
        emit FreezeTransfers(false);
    }

    /**
     * @notice Internal - adjusts token holder balance at checkpoint before a token transfer
     * @param _investor address of the token holder affected
     */
    function _adjustBalanceCheckpoints(address _investor) internal {
        TokenLib.adjustCheckpoints(checkpointBalances[_investor], balanceOf(_investor), currentCheckpointId);
    }

    /**
     * @notice Overloaded version of the transfer function
     * @param _to receiver of transfer
     * @param _value value of transfer
     * @return bool success
     */
    function transfer(address _to, uint256 _value) public returns(bool success) {
        _transferWithData(msg.sender, _to, _value, "");
        return true;
    }

    /**
     * @notice Transfer restrictions can take many forms and typically involve on-chain rules or whitelists.
     * However for many types of approved transfers, maintaining an on-chain list of approved transfers can be
     * cumbersome and expensive. An alternative is the co-signing approach, where in addition to the token holder
     * approving a token transfer, and authorised entity provides signed data which further validates the transfer.
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @param _data The `bytes _data` allows arbitrary data to be submitted alongside the transfer.
     * for the token contract to interpret or record. This could be signed data authorising the transfer
     * (e.g. a dynamic whitelist) but is flexible enough to accomadate other use-cases.
     */
    function transferWithData(address _to, uint256 _value, bytes memory _data) public {
        _transferWithData(msg.sender, _to, _value, _data);
    }

    function _transferWithData(address _from, address _to, uint256 _value, bytes memory _data) internal {
        _isValidTransfer(_updateTransfer(_from, _to, _value, _data));
        // Using the internal function instead of super.transfer() in the favour of reducing the code size
        _transfer(_from, _to, _value);
    }

    /**
     * @notice Overloaded version of the transferFrom function
     * @param _from sender of transfer
     * @param _to receiver of transfer
     * @param _value value of transfer
     * @return bool success
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        transferFromWithData(_from, _to, _value, "");
        return true;
    }

    /**
     * @notice Transfer restrictions can take many forms and typically involve on-chain rules or whitelists.
     * However for many types of approved transfers, maintaining an on-chain list of approved transfers can be
     * cumbersome and expensive. An alternative is the co-signing approach, where in addition to the token holder
     * approving a token transfer, and authorised entity provides signed data which further validates the transfer.
     * @dev `msg.sender` MUST have a sufficient `allowance` set and this `allowance` must be debited by the `_value`.
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @param _data The `bytes _data` allows arbitrary data to be submitted alongside the transfer.
     * for the token contract to interpret or record. This could be signed data authorising the transfer
     * (e.g. a dynamic whitelist) but is flexible enough to accomadate other use-cases.
     */
    function transferFromWithData(address _from, address _to, uint256 _value, bytes memory _data) public {
        _isValidTransfer(_updateTransfer(_from, _to, _value, _data));
        require(super.transferFrom(_from, _to, _value));
    }

    /**
     * @notice Get the balance according to the provided partitions
     * @param _partition Partition which differentiate the tokens.
     * @param _tokenHolder Whom balance need to queried
     * @return Amount of tokens as per the given partitions
     */
    function balanceOfByPartition(bytes32 _partition, address _tokenHolder) public view returns(uint256) {
        return _balanceOfByPartition(_partition, _tokenHolder, 0);
    }

    function _balanceOfByPartition(bytes32 _partition, address _tokenHolder, uint256 _additionalBalance) internal view returns(uint256 partitionBalance) {
        address[] memory tms = modules[TRANSFER_KEY];
        uint256 amount;
        for (uint256 i = 0; i < tms.length; i++) {
            amount = ITransferManager(tms[i]).getTokensByPartition(_partition, _tokenHolder, _additionalBalance);
            // In UNLOCKED partition we are returning the minimum of all the unlocked balances
            if (_partition == UNLOCKED) {
                if (amount < partitionBalance || i == 0)
                    partitionBalance = amount;
            }
            // In locked partition we are returning the maximum of all the Locked balances
            else {
                if (partitionBalance < amount)
                    partitionBalance = amount;
            }
        }
    }

    /**
     * @notice Transfers the ownership of tokens from a specified partition from one address to another address
     * @param _partition The partition from which to transfer tokens
     * @param _to The address to which to transfer tokens to
     * @param _value The amount of tokens to transfer from `_partition`
     * @param _data Additional data attached to the transfer of tokens
     * @return The partition to which the transferred tokens were allocated for the _to address
     */
    function transferByPartition(bytes32 _partition, address _to, uint256 _value, bytes memory _data) public returns (bytes32) {
        return _transferByPartition(msg.sender, _to, _value, _partition, _data, address(0), "");
    }

    function _transferByPartition(
        address _from,
        address _to,
        uint256 _value,
        bytes32 _partition,
        bytes memory _data,
        address _operator,
        bytes memory _operatorData
    )
        internal
        returns(bytes32 toPartition)
    {
        _isValidPartition(_partition);
        // Avoiding to add this check
        // require(balanceOfByPartition(_partition, msg.sender) >= _value);
        // NB - Above condition will be automatically checked using the executeTransfer() function execution.
        // NB - passing `_additionalBalance` value is 0 because accessing the balance before transfer
        uint256 lockedBalanceBeforeTransfer = _balanceOfByPartition(LOCKED, _to, 0);
        _transferWithData(_from, _to, _value, _data);
        // NB - passing `_additonalBalance` valie is 0 because balance of `_to` was updated in the transfer call
        uint256 lockedBalanceAfterTransfer = _balanceOfByPartition(LOCKED, _to, 0);
        toPartition =  _returnPartition(lockedBalanceBeforeTransfer, lockedBalanceAfterTransfer, _value);
        emit TransferByPartition(_partition, _operator, _from, _to, _value, _data, _operatorData);
    }

    function _returnPartition(uint256 _beforeBalance, uint256 _afterBalance, uint256 _value) internal pure returns(bytes32 toPartition) {
        // return LOCKED only when the transaction `_value` should be equal to the change in the LOCKED partition
        // balance otherwise return UNLOCKED
        toPartition = _afterBalance.sub(_beforeBalance) == _value ? LOCKED : UNLOCKED; // Returning the same partition UNLOCKED
    }

    ///////////////////////
    /// Operator Management
    ///////////////////////

    /**
     * @notice Authorises an operator for all partitions of `msg.sender`.
     * NB - Allowing investors to authorize an investor to be an operator of all partitions
     * but it doesn't mean we operator is allowed to transfer the LOCKED partition values.
     * Logic for this restriction is written in `operatorTransferByPartition()` function.
     * @param _operator An address which is being authorised.
     */
    function authorizeOperator(address _operator) public {
        _approve(msg.sender, _operator, uint(-1));
        emit AuthorizedOperator(_operator, msg.sender);
    }

    /**
     * @notice Revokes authorisation of an operator previously given for all partitions of `msg.sender`.
     * NB - Allowing investors to authorize an investor to be an operator of all partitions
     * but it doesn't mean we operator is allowed to transfer the LOCKED partition values.
     * Logic for this restriction is written in `operatorTransferByPartition()` function.
     * @param _operator An address which is being de-authorised
     */
    function revokeOperator(address _operator) public {
        _approve(msg.sender, _operator, 0);
        emit RevokedOperator(_operator, msg.sender);
    }

    /**
     * @notice Authorises an operator for a given partition of `msg.sender`
     * @param _partition The partition to which the operator is authorised
     * @param _operator An address which is being authorised
     */
    function authorizeOperatorByPartition(bytes32 _partition, address _operator) public {
        _isValidPartition(_partition);
        partitionApprovals[msg.sender][_partition][_operator] = true;
        emit AuthorizedOperatorByPartition(_partition, _operator, msg.sender);
    }

    /**
     * @notice Revokes authorisation of an operator previously given for a specified partition of `msg.sender`
     * @param _partition The partition to which the operator is de-authorised
     * @param _operator An address which is being de-authorised
     */
    function revokeOperatorByPartition(bytes32 _partition, address _operator) public {
        _isValidPartition(_partition);
        partitionApprovals[msg.sender][_partition][_operator] = false;
        emit RevokedOperatorByPartition(_partition, _operator, msg.sender);
    }

    /**
     * @notice Transfers the ownership of tokens from a specified partition from one address to another address
     * @param _partition The partition from which to transfer tokens.
     * @param _from The address from which to transfer tokens from
     * @param _to The address to which to transfer tokens to
     * @param _value The amount of tokens to transfer from `_partition`
     * @param _data Additional data attached to the transfer of tokens
     * @param _operatorData Additional data attached to the transfer of tokens by the operator
     * @return The partition to which the transferred tokens were allocated for the _to address
     */
    function operatorTransferByPartition(
        bytes32 _partition,
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    )
        external
        returns (bytes32)
    {
        // For the current release we are only allowing UNLOCKED partition tokens to transact
        _validateOperatorAndPartition(_partition, _from, msg.sender);
        require(_operatorData[0] != 0);
        return _transferByPartition(_from, _to, _value, _partition, _data, msg.sender, _operatorData);
    }

    function _validateOperatorAndPartition(bytes32 _partition, address _from, address _operator) internal view {
        _isValidPartition(_partition);
        _isValidOperator(_from, _operator, _partition);
    }

    /**
     * @notice Updates internal variables when performing a transfer
     * @param _from sender of transfer
     * @param _to receiver of transfer
     * @param _value value of transfer
     * @param _data data to indicate validation
     * @return bool success
     */
    function _updateTransfer(address _from, address _to, uint256 _value, bytes memory _data) internal nonReentrant returns(bool verified) {
        // NB - the ordering in this function implies the following:
        //  - investor counts are updated before transfer managers are called - i.e. transfer managers will see
        //investor counts including the current transfer.
        //  - checkpoints are updated after the transfer managers are called. This allows TMs to create
        //checkpoints as though they have been created before the current transactions,
        //  - to avoid the situation where a transfer manager transfers tokens, and this function is called recursively,
        //the function is marked as nonReentrant. This means that no TM can transfer (or mint / burn) tokens in the execute transfer function.
        _adjustInvestorCount(_from, _to, _value);
        verified = _executeTransfer(_from, _to, _value, _data);
        _adjustBalanceCheckpoints(_from);
        _adjustBalanceCheckpoints(_to);
    }

    /**
     * @notice Validate transfer with TransferManager module if it exists
     * @dev TransferManager module has a key of 2
     * function (no change in the state).
     * @param _from sender of transfer
     * @param _to receiver of transfer
     * @param _value value of transfer
     * @param _data data to indicate validation
     * @return bool
     */
    function _executeTransfer(
        address _from,
        address _to,
        uint256 _value,
        bytes memory _data
    )
        internal
        checkGranularity(_value)
        returns(bool)
    {
        if (!transfersFrozen) {
            bool isInvalid;
            bool isValid;
            bool isForceValid;
            address module;
            uint256 tmLength = modules[TRANSFER_KEY].length;
            for (uint256 i = 0; i < tmLength; i++) {
                module = modules[TRANSFER_KEY][i];
                if (!modulesToData[module].isArchived) {
                    // refer to https://github.com/PolymathNetwork/polymath-core/wiki/Transfer-manager-results
                    // for understanding what these results mean
                    ITransferManager.Result valid = ITransferManager(module).executeTransfer(_from, _to, _value, _data);
                    if (valid == ITransferManager.Result.INVALID) {
                        isInvalid = true;
                    } else if (valid == ITransferManager.Result.VALID) {
                        isValid = true;
                    } else if (valid == ITransferManager.Result.FORCE_VALID) {
                        isForceValid = true;
                    }
                }
            }
            return isForceValid ? true : (isInvalid ? false : isValid);
        }
        return false;
    }

    /**
     * @notice Permanently freeze issuance of this security token.
     * @dev It MUST NOT be possible to increase `totalSuppy` after this function is called.
     */
    function freezeIssuance(bytes calldata _signature) external {
        _onlyOwner();
        _isIssuanceAllowed();
        _isSignedByOwner(owner() == TokenLib.recoverFreezeIssuanceAckSigner(_signature));
        issuance = false;
        /*solium-disable-next-line security/no-block-members*/
        emit FreezeIssuance();
    }

    /**
     * @notice This function must be called to increase the total supply (Corresponds to mint function of ERC20).
     * @dev It only be called by the token issuer or the operator defined by the issuer. ERC1594 doesn't have
     * have the any logic related to operator but its superset ERC1400 have the operator logic and this function
     * is allowed to call by the operator.
     * @param _tokenHolder The account that will receive the created tokens (account should be whitelisted or KYCed).
     * @param _value The amount of tokens need to be issued
     * @param _data The `bytes _data` allows arbitrary data to be submitted alongside the transfer.
     */
    function issue(
        address _tokenHolder,
        uint256 _value,
        bytes memory _data
    )
        public // changed to public to save the code size and reuse the function
    {
        _isIssuanceAllowed();
        _onlyModuleOrOwner(MINT_KEY);
        _issue(_tokenHolder, _value, _data);
    }

    function _issue(
        address _tokenHolder,
        uint256 _value,
        bytes memory _data
    )
        internal
    {
        // Add a function to validate the `_data` parameter
        _isValidTransfer(_updateTransfer(address(0), _tokenHolder, _value, _data));
        _mint(_tokenHolder, _value);
        emit Issued(msg.sender, _tokenHolder, _value, _data);
    }

    /**
     * @notice issue new tokens and assigns them to the target _tokenHolder.
     * @dev Can only be called by the issuer or STO attached to the token.
     * @param _tokenHolders A list of addresses to whom the minted tokens will be dilivered
     * @param _values A list of number of tokens get minted and transfer to corresponding address of the investor from _tokenHolders[] list
     * @return success
     */
    function issueMulti(address[] memory _tokenHolders, uint256[] memory _values) public {
        _isIssuanceAllowed();
        _onlyModuleOrOwner(MINT_KEY);
        // Remove reason string to reduce the code size
        require(_tokenHolders.length == _values.length);
        for (uint256 i = 0; i < _tokenHolders.length; i++) {
            _issue(_tokenHolders[i], _values[i], "");
        }
    }

    /**
     * @notice Increases totalSupply and the corresponding amount of the specified owners partition
     * @param _partition The partition to allocate the increase in balance
     * @param _tokenHolder The token holder whose balance should be increased
     * @param _value The amount by which to increase the balance
     * @param _data Additional data attached to the minting of tokens
     */
    function issueByPartition(bytes32 _partition, address _tokenHolder, uint256 _value, bytes calldata _data) external {
        _isValidPartition(_partition);
        //Use issue instead of _issue function in the favour to saving code size
        issue(_tokenHolder, _value, _data);
        emit IssuedByPartition(_partition, _tokenHolder, _value, _data);
    }

    /**
     * @notice This function redeem an amount of the token of a msg.sender. For doing so msg.sender may incentivize
     * using different ways that could be implemented with in the `redeem` function definition. But those implementations
     * are out of the scope of the ERC1594.
     * @param _value The amount of tokens need to be redeemed
     * @param _data The `bytes _data` it can be used in the token contract to authenticate the redemption.
     */
    function redeem(uint256 _value, bytes calldata _data) external {
        _onlyModule(BURN_KEY);
        _redeem(msg.sender, _value, _data);
    }

    function _redeem(address _from, uint256 _value, bytes memory _data) internal {
        // Add a function to validate the `_data` parameter
        _isValidRedeem(_checkAndBurn(_from, _value, _data));
    }

    /**
     * @notice Decreases totalSupply and the corresponding amount of the specified partition of msg.sender
     * @param _partition The partition to allocate the decrease in balance
     * @param _value The amount by which to decrease the balance
     * @param _data Additional data attached to the burning of tokens
     */
    function redeemByPartition(bytes32 _partition, uint256 _value, bytes calldata _data) external {
        _onlyModule(BURN_KEY);
        _isValidPartition(_partition);
        _redeemByPartition(_partition, msg.sender, _value, address(0), _data, "");
    }

    function _redeemByPartition(
        bytes32 _partition,
        address _from,
        uint256 _value,
        address _operator,
        bytes memory _data,
        bytes memory _operatorData
    )
        internal
    {
        _redeem(_from, _value, _data);
        emit RedeemedByPartition(_partition, _operator, _from, _value, _data, _operatorData);
    }

    /**
     * @notice Decreases totalSupply and the corresponding amount of the specified partition of tokenHolder
     * @dev This function can only be called by the authorised operator.
     * @param _partition The partition to allocate the decrease in balance.
     * @param _tokenHolder The token holder whose balance should be decreased
     * @param _value The amount by which to decrease the balance
     * @param _data Additional data attached to the burning of tokens
     * @param _operatorData Additional data attached to the transfer of tokens by the operator
     */
    function operatorRedeemByPartition(
        bytes32 _partition,
        address _tokenHolder,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    )
        external
    {
        _onlyModule(BURN_KEY);
        require(_operatorData[0] != 0);
        _zeroAddressCheck(_tokenHolder);
        _validateOperatorAndPartition(_partition, _tokenHolder, msg.sender);
        _redeemByPartition(_partition, _tokenHolder, _value, msg.sender, _data, _operatorData);
    }

    function _checkAndBurn(address _from, uint256 _value, bytes memory _data) internal returns(bool verified) {
        verified = _updateTransfer(_from, address(0), _value, _data);
        _burn(_from, _value);
        emit Redeemed(address(0), msg.sender, _value, _data);
    }

    /**
     * @notice This function redeem an amount of the token of a msg.sender. For doing so msg.sender may incentivize
     * using different ways that could be implemented with in the `redeem` function definition. But those implementations
     * are out of the scope of the ERC1594.
     * @dev It is analogy to `transferFrom`
     * @param _tokenHolder The account whose tokens gets redeemed.
     * @param _value The amount of tokens need to be redeemed
     * @param _data The `bytes _data` it can be used in the token contract to authenticate the redemption.
     */
    function redeemFrom(address _tokenHolder, uint256 _value, bytes calldata _data) external {
        _onlyModule(BURN_KEY);
        // Add a function to validate the `_data` parameter
        _isValidRedeem(_updateTransfer(_tokenHolder, address(0), _value, _data));
        _burnFrom(_tokenHolder, _value);
        emit Redeemed(msg.sender, _tokenHolder, _value, _data);
    }

    /**
     * @notice Creates a checkpoint that can be used to query historical balances / totalSuppy
     * @return uint256
     */
    function createCheckpoint() external returns(uint256) {
        _onlyModuleOrOwner(CHECKPOINT_KEY);
        // currentCheckpointId can only be incremented by 1 and hence it can not be overflowed
        currentCheckpointId = currentCheckpointId + 1;
        /*solium-disable-next-line security/no-block-members*/
        checkpointTimes.push(now);
        checkpointTotalSupply[currentCheckpointId] = totalSupply();
        emit CheckpointCreated(currentCheckpointId, dataStore.getAddressArrayLength(INVESTORSKEY));
        return currentCheckpointId;
    }

    /**
     * @notice Used by the issuer to set the controller addresses
     * @param _controller address of the controller
     */
    function setController(address _controller) external {
        _onlyOwner();
        require(isControllable());
        emit SetController(controller, _controller);
        controller = _controller;
    }

    /**
     * @notice Used by the issuer to permanently disable controller functionality
     * @dev enabled via feature switch "disableControllerAllowed"
     */
    function disableController(bytes calldata _signature) external {
        _onlyOwner();
        _isSignedByOwner(owner() == TokenLib.recoverDisableControllerAckSigner(_signature));
        require(isControllable());
        controllerDisabled = true;
        delete controller;
        emit DisableController();
    }

    /**
     * @notice Transfers of securities may fail for a number of reasons. So this function will used to understand the
     * cause of failure by getting the byte value. Which will be the ESC that follows the EIP 1066. ESC can be mapped
     * with a reson string to understand the failure cause, table of Ethereum status code will always reside off-chain
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @param _data The `bytes _data` allows arbitrary data to be submitted alongside the transfer.
     * @return byte Ethereum status code (ESC)
     * @return bytes32 Application specific reason code
     */
    function canTransfer(address _to, uint256 _value, bytes calldata _data) external view returns (byte, bytes32) {
        return _canTransfer(msg.sender, _to, _value, _data);
    }

    /**
     * @notice Transfers of securities may fail for a number of reasons. So this function will used to understand the
     * cause of failure by getting the byte value. Which will be the ESC that follows the EIP 1066. ESC can be mapped
     * with a reson string to understand the failure cause, table of Ethereum status code will always reside off-chain
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @param _data The `bytes _data` allows arbitrary data to be submitted alongside the transfer.
     * @return byte Ethereum status code (ESC)
     * @return bytes32 Application specific reason code
     */
    function canTransferFrom(address _from, address _to, uint256 _value, bytes calldata _data) external view returns (byte reasonCode, bytes32 appCode) {
        (reasonCode, appCode) = _canTransfer(_from, _to, _value, _data);
        if (_isSuccess(reasonCode) && _value > allowance(_from, msg.sender)) {
            return (StatusCodes.code(StatusCodes.Status.InsufficientAllowance), bytes32(0));
        }
    }

    function _canTransfer(address _from, address _to, uint256 _value, bytes memory _data) internal view returns (byte, bytes32) {
        bytes32 appCode;
        bool success;
        if (_value % granularity != 0) {
            return (StatusCodes.code(StatusCodes.Status.TransferFailure), bytes32(0));
        }
        (success, appCode) = TokenLib.verifyTransfer(modules[TRANSFER_KEY], modulesToData, _from, _to, _value, _data, transfersFrozen);
        return TokenLib.canTransfer(success, appCode, _to, _value, balanceOf(_from));
    }

    /**
     * @notice The standard provides an on-chain function to determine whether a transfer will succeed,
     * and return details indicating the reason if the transfer is not valid.
     * @param _from The address from whom the tokens get transferred.
     * @param _to The address to which to transfer tokens to.
     * @param _partition The partition from which to transfer tokens
     * @param _value The amount of tokens to transfer from `_partition`
     * @param _data Additional data attached to the transfer of tokens
     * @return ESC (Ethereum Status Code) following the EIP-1066 standard
     * @return Application specific reason codes with additional details
     * @return The partition to which the transferred tokens were allocated for the _to address
     */
    function canTransferByPartition(
        address _from,
        address _to,
        bytes32 _partition,
        uint256 _value,
        bytes calldata _data
    )
        external
        view
        returns (byte reasonCode, bytes32 appStatusCode, bytes32 toPartition)
    {
        if (_partition == UNLOCKED) {
            (reasonCode, appStatusCode) = _canTransfer(_from, _to, _value, _data);
            if (_isSuccess(reasonCode)) {
                uint256 beforeBalance = _balanceOfByPartition(LOCKED, _to, 0);
                uint256 afterbalance = _balanceOfByPartition(LOCKED, _to, _value);
                toPartition = _returnPartition(beforeBalance, afterbalance, _value);
            }
            return (reasonCode, appStatusCode, toPartition);
        }
        return (StatusCodes.code(StatusCodes.Status.TransferFailure), bytes32(0), bytes32(0));
    }

    /**
     * @notice Used to attach a new document to the contract, or update the URI or hash of an existing attached document
     * @dev Can only be executed by the owner of the contract.
     * @param _name Name of the document. It should be unique always
     * @param _uri Off-chain uri of the document from where it is accessible to investors/advisors to read.
     * @param _documentHash hash (of the contents) of the document.
     */
    function setDocument(bytes32 _name, string calldata _uri, bytes32 _documentHash) external {
        _onlyOwner();
        TokenLib.setDocument(_documents, _docNames, _docIndexes, _name, _uri, _documentHash);
    }

    /**
     * @notice Used to remove an existing document from the contract by giving the name of the document.
     * @dev Can only be executed by the owner of the contract.
     * @param _name Name of the document. It should be unique always
     */
    function removeDocument(bytes32 _name) external {
        _onlyOwner();
        TokenLib.removeDocument(_documents, _docNames, _docIndexes, _name);
    }

    /**
     * @notice In order to provide transparency over whether `controllerTransfer` / `controllerRedeem` are useable
     * or not `isControllable` function will be used.
     * @dev If `isControllable` returns `false` then it always return `false` and
     * `controllerTransfer` / `controllerRedeem` will always revert.
     * @return bool `true` when controller address is non-zero otherwise return `false`.
     */
    function isControllable() public view returns (bool) {
        return !controllerDisabled;
    }

    /**
     * @notice This function allows an authorised address to transfer tokens between any two token holders.
     * The transfer must still respect the balances of the token holders (so the transfer must be for at most
     * `balanceOf(_from)` tokens) and potentially also need to respect other transfer restrictions.
     * @dev This function can only be executed by the `controller` address.
     * @param _from Address The address which you want to send tokens from
     * @param _to Address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @param _data data to validate the transfer. (It is not used in this reference implementation
     * because use of `_data` parameter is implementation specific).
     * @param _operatorData data attached to the transfer by controller to emit in event. (It is more like a reason string
     * for calling this function (aka force transfer) which provides the transparency on-chain).
     */
    function controllerTransfer(address _from, address _to, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external {
        _onlyController();
        _updateTransfer(_from, _to, _value, _data);
        _transfer(_from, _to, _value);
        emit ControllerTransfer(msg.sender, _from, _to, _value, _data, _operatorData);
    }

    /**
     * @notice This function allows an authorised address to redeem tokens for any token holder.
     * The redemption must still respect the balances of the token holder (so the redemption must be for at most
     * `balanceOf(_tokenHolder)` tokens) and potentially also need to respect other transfer restrictions.
     * @dev This function can only be executed by the `controller` address.
     * @param _tokenHolder The account whose tokens will be redeemed.
     * @param _value uint256 the amount of tokens need to be redeemed.
     * @param _data data to validate the transfer. (It is not used in this reference implementation
     * because use of `_data` parameter is implementation specific).
     * @param _operatorData data attached to the transfer by controller to emit in event. (It is more like a reason string
     * for calling this function (aka force transfer) which provides the transparency on-chain).
     */
    function controllerRedeem(address _tokenHolder, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external {
        _onlyController();
        _checkAndBurn(_tokenHolder, _value, _data);
        emit ControllerRedemption(msg.sender, _tokenHolder, _value, _data, _operatorData);
    }

    function _implementation() internal view returns(address) {
        return getterDelegate;
    }

    function updateFromRegistry() public {
        _onlyOwner();
        moduleRegistry = IModuleRegistry(polymathRegistry.getAddress("ModuleRegistry"));
        securityTokenRegistry = ISecurityTokenRegistry(polymathRegistry.getAddress("SecurityTokenRegistry"));
        polyToken = IERC20(polymathRegistry.getAddress("PolyToken"));
    }

    //Ownable Functions

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) external {
        _onlyOwner();
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
    * @dev Check if a status code represents success (ie: 0x*1)
    * @param status Binary ERC-1066 status code
    * @return successful A boolean representing if the status code represents success
    */
    function _isSuccess(byte status) internal pure returns (bool successful) {
        return (status & 0x0F) == 0x01;
    }
}
