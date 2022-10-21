/**
 *Submitted for verification at Etherscan.io on 2019-12-17
*/

// File: contracts\utility\interfaces\IOwned.sol

pragma solidity 0.5.17;

/*
    Owned contract interface
*/
contract IOwned {
    // this function isn't abstract since the compiler emits automatically generated getter functions as external
    function owner() public view returns (address);

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

// File: contracts\utility\Owned.sol


/**
  * @dev Provides support and utilities for contract ownership
*/
contract Owned is IOwned {
    address private _owner;
    address public newOwner;
    
    function owner() public view returns (address) {
        return _owner;
    }

    /**
      * @dev triggered when the owner is updated
      * 
      * @param _prevOwner previous owner
      * @param _newOwner  new owner
    */
    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

    /**
      * @dev initializes a new Owned instance
    */
    constructor() public {
        _owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        require(msg.sender == _owner);
        _;
    }

    /**
      * @dev allows transferring the contract ownership
      * the new owner still needs to accept the transfer
      * can only be called by the contract owner
      * 
      * @param _newOwner    new contract owner
    */
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != _owner);
        newOwner = _newOwner;
    }

    /**
      * @dev used by a new owner to accept an ownership transfer
    */
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(_owner, newOwner);
        _owner = newOwner;
        newOwner = address(0);
    }
}

// File: contracts\utility\Utils.sol

/**
  * @dev Utilities & Common Modifiers
*/
contract Utils {
    /**
      * constructor
    */
    constructor() public {
    }

    // verifies that an amount is greater than zero
    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0);
        _;
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        require(_address != address(0));
        _;
    }

    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

}

// File: contracts\utility\interfaces\IContractRegistry.sol

/*
    Contract Registry interface
*/
contract IContractRegistry {
    function addressOf(bytes32 _contractName) public view returns (address);

    // deprecated, backward compatibility
    function getAddress(bytes32 _contractName) public view returns (address);
}

// File: contracts\utility\ContractRegistryClient.sol




/**
  * @dev Base contract for ContractRegistry clients
*/
contract ContractRegistryClient is Owned, Utils {
    bytes32 internal constant CONTRACT_FEATURES = "ContractFeatures";
    bytes32 internal constant CONTRACT_REGISTRY = "ContractRegistry";
    bytes32 internal constant NON_STANDARD_TOKEN_REGISTRY = "NonStandardTokenRegistry";
    bytes32 internal constant BANCOR_NETWORK = "BancorNetwork";
    bytes32 internal constant BANCOR_FORMULA = "BancorFormula";
    bytes32 internal constant BANCOR_GAS_PRICE_LIMIT = "BancorGasPriceLimit";
    bytes32 internal constant BANCOR_CONVERTER_FACTORY = "BancorConverterFactory";
    bytes32 internal constant BANCOR_CONVERTER_UPGRADER = "BancorConverterUpgrader";
    bytes32 internal constant BANCOR_CONVERTER_REGISTRY = "BancorConverterRegistry";
    bytes32 internal constant BANCOR_CONVERTER_REGISTRY_DATA = "BancorConverterRegistryData";
    bytes32 internal constant BNT_TOKEN = "BNTToken";
    bytes32 internal constant BANCOR_X = "BancorX";
    bytes32 internal constant BANCOR_X_UPGRADER = "BancorXUpgrader";

    IContractRegistry public registry;      // address of the current contract-registry
    IContractRegistry public prevRegistry;  // address of the previous contract-registry
    bool public adminOnly;                  // only an administrator can update the contract-registry

    /**
      * @dev verifies that the caller is mapped to the given contract name
      * 
      * @param _contractName    contract name
    */
    modifier only(bytes32 _contractName) {
        require(msg.sender == addressOf(_contractName));
        _;
    }

    /**
      * @dev initializes a new ContractRegistryClient instance
      * 
      * @param  _registry   address of a contract-registry contract
    */
    constructor(IContractRegistry _registry) internal validAddress(address(_registry)) {
        registry = IContractRegistry(_registry);
        prevRegistry = IContractRegistry(_registry);
    }

    /**
      * @dev updates to the new contract-registry
     */
    function updateRegistry() public {
        // verify that this function is permitted
        require(!adminOnly || isAdmin());

        // get the new contract-registry
        address newRegistry = addressOf(CONTRACT_REGISTRY);

        // verify that the new contract-registry is different and not zero
        require(newRegistry != address(registry) && newRegistry != address(0));

        // verify that the new contract-registry is pointing to a non-zero contract-registry
        require(IContractRegistry(newRegistry).addressOf(CONTRACT_REGISTRY) != address(0));

        // save a backup of the current contract-registry before replacing it
        prevRegistry = registry;

        // replace the current contract-registry with the new contract-registry
        registry = IContractRegistry(newRegistry);
    }

    /**
      * @dev restores the previous contract-registry
    */
    function restoreRegistry() public {
        // verify that this function is permitted
        require(isAdmin());

        // restore the previous contract-registry
        registry = prevRegistry;
    }

    /**
      * @dev restricts the permission to update the contract-registry
      * 
      * @param _adminOnly    indicates whether or not permission is restricted to administrator only
    */
    function restrictRegistryUpdate(bool _adminOnly) public {
        // verify that this function is permitted
        require(adminOnly != _adminOnly && isAdmin());

        // change the permission to update the contract-registry
        adminOnly = _adminOnly;
    }

    /**
      * @dev returns whether or not the caller is an administrator
     */
    function isAdmin() internal view returns (bool) {
        return msg.sender == owner();
    }

    /**
      * @dev returns the address associated with the given contract name
      * 
      * @param _contractName    contract name
      * 
      * @return contract address
    */
    function addressOf(bytes32 _contractName) internal view returns (address) {
        return registry.addressOf(_contractName);
    }
}

// File: contracts\token\interfaces\IERC20Token.sol

/*
    ERC20 Standard Token interface
*/
contract IERC20Token {
    // these functions aren't abstract since the compiler emits automatically generated getter functions as external
    function name() public view returns (string memory) {this;}
    function symbol() public view returns (string memory) {this;}
    function decimals() public view returns (uint8) {this;}
    function totalSupply() public view returns (uint256) {this;}
    function balanceOf(address _owner) public view returns (uint256) {_owner; this;}
    function allowance(address _owner, address _spender) public view returns (uint256) {_owner; _spender; this;}

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

// File: contracts\utility\interfaces\IWhitelist.sol

/*
    Whitelist interface
*/
contract IWhitelist {
    function isWhitelisted(address _address) public view returns (bool);
}

// File: contracts\converter\interfaces\IBancorConverter.sol



/*
    Bancor Converter interface
*/
contract IBancorConverter {
    function getReturn(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount) public view returns (uint256, uint256);
    function convert2(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn, address _affiliateAccount, uint256 _affiliateFee) public returns (uint256);
    function quickConvert2(IERC20Token[] memory _path, uint256 _amount, uint256 _minReturn, address _affiliateAccount, uint256 _affiliateFee) public payable returns (uint256);
    function conversionsEnabled() public view returns (bool) {this;}
    function conversionWhitelist() public view returns (IWhitelist) {this;}
    function conversionFee() public view returns (uint32) {this;}
    function reserves(address _address) public view returns (uint256, uint32, bool, bool, bool) {_address; this;}
    function getReserveBalance(IERC20Token _reserveToken) public view returns (uint256);
    function reserveTokens(uint256 _index) public view returns (IERC20Token) {_index; this;}
    // deprecated, backward compatibility
    function change(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256);
    function convert(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256);
    function quickConvert(IERC20Token[] memory _path, uint256 _amount, uint256 _minReturn) public payable returns (uint256);
    function connectors(address _address) public view returns (uint256, uint32, bool, bool, bool);
    function getConnectorBalance(IERC20Token _connectorToken) public view returns (uint256);
    function connectorTokens(uint256 _index) public view returns (IERC20Token);
    function connectorTokenCount() public view returns (uint16);
}

// File: contracts\converter\interfaces\IBancorConverterRegistry.sol


interface IBancorConverterRegistry {
    function addConverter(IBancorConverter _converter) external;
    function removeConverter(IBancorConverter _converter) external;
    function getSmartTokenCount() external view returns (uint);
    function getSmartTokens() external view returns (address[] memory);
    function getSmartToken(uint _index) external view returns (address);
    function isSmartToken(address _value) external view returns (bool);
    function getLiquidityPoolCount() external view returns (uint);
    function getLiquidityPools() external view returns (address[] memory);
    function getLiquidityPool(uint _index) external view returns (address);
    function isLiquidityPool(address _value) external view returns (bool);
    function getConvertibleTokenCount() external view returns (uint);
    function getConvertibleTokens() external view returns (address[] memory);
    function getConvertibleToken(uint _index) external view returns (address);
    function isConvertibleToken(address _value) external view returns (bool);
    function getConvertibleTokenSmartTokenCount(address _convertibleToken) external view returns (uint);
    function getConvertibleTokenSmartTokens(address _convertibleToken) external view returns (address[] memory);
    function getConvertibleTokenSmartToken(address _convertibleToken, uint _index) external view returns (address);
    function isConvertibleTokenSmartToken(address _convertibleToken, address _value) external view returns (bool);
}

// File: contracts\token\interfaces\ISmartToken.sol



/*
    Smart Token interface
*/
contract ISmartToken is IOwned, IERC20Token {
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}

// File: contracts\BancorNetworkPathFinder.sol





/**
  * @dev The BancorNetworkPathFinder contract allows generating a conversion path between any token pair in the Bancor Network.
  * The path can then be used in various functions in the BancorNetwork contract.
  *
  * See the BancorNetwork contract for conversion path format.
*/
contract BancorNetworkPathFinder is ContractRegistryClient {
    address[] public anchorTokens;
    IBancorConverterRegistry public converterRegistry;

    /**
      * @dev initializes a new BancorNetworkPathFinder instance
      * 
      * @param _registry address of a contract registry contract
    */
    constructor(IContractRegistry _registry) ContractRegistryClient(_registry) public {
    }

    /**
      * @dev updates the anchor token
      * 
      * @param _anchorTokens addresses of the anchor tokens
    */
    function setAnchorTokens(address[] memory _anchorTokens) public ownerOnly {
        anchorTokens = _anchorTokens;
    }
    
    function updateConverterRegistry() public ownerOnly {
        converterRegistry = IBancorConverterRegistry(addressOf(BANCOR_CONVERTER_REGISTRY));
    }

    /**
      * @dev generates and returns the conversion path between a given token pair in the Bancor Network
      * 
      * @param _sourceToken address of the source token
      * @param _targetToken address of the target token
      * 
      * @return path from the source token to the target token
    */
    function generatePath(address _sourceToken, address _targetToken) public view returns (address[] memory) {
        uint256 bestPathWeight = 0;
        address[] memory bestPath = new address[](0);
        for (uint i = 0; i < anchorTokens.length; i++) {
            address[] memory sourcePath = getPathForAnchor(2, anchorTokens[i], _sourceToken);
            address[] memory targetPath = getPathForAnchor(2, anchorTokens[i], _targetToken);
            address[] memory path = getShortestPath(sourcePath, targetPath);
            uint256 pathWeight = weightOf(path);
            if (pathWeight >= bestPathWeight) {
                bestPathWeight = pathWeight;
                bestPath = path;
            }
        }
        
        return bestPath;
    }
    
    function weightOf(address[] memory path) public view returns(uint256) {
        return weightOf(path, IERC20Token(path[0]).balanceOf(IOwned(path[1]).owner()));
    }
    
    function weightOf(address[] memory path, uint256 preWeight) public view returns(uint256) {
        return preWeight * IERC20Token(path[path.length - 1]).balanceOf(IOwned(path[path.length - 2]).owner());
    }

    /**
      * @dev generates and returns the conversion path between a given token and the anchor token
      * 
      * @param _token               address of the token
      * 
      * @return path from the input token to the anchor token
    */
    function getPathForAnchor(uint256 maxDepth, address anchorToken, address _token) public view returns (address[] memory) {
        if (_token == anchorToken)
            return getInitialArray(_token);

        address[] memory smartTokens;
        if (converterRegistry.isSmartToken(_token))
            smartTokens = getInitialArray(_token);
        else
            smartTokens = converterRegistry.getConvertibleTokenSmartTokens(_token);

        uint256 bestPathWeight = 0;
        address[] memory bestPath = new address[](0);
        for (uint256 n = 0; n < smartTokens.length && maxDepth > 0; n++) {
            IBancorConverter converter = IBancorConverter(ISmartToken(smartTokens[n]).owner());
            uint256 connectorTokenCount = converter.connectorTokenCount();
            uint256 preWeight = IERC20Token(_token).balanceOf(IOwned(smartTokens[n]).owner());
            for (uint256 i = 0; i < connectorTokenCount; i++) {
                address connectorToken = address(converter.connectorTokens(i));
                if (connectorToken != _token) {
                    address[] memory path = getPathForAnchor(maxDepth - 1, anchorToken, connectorToken);
                    
                    if (path.length > 0) {
                        address[] memory extendedPath = getExtendedArray(_token, smartTokens[n], path);
                        uint256 pathWeight = weightOf(extendedPath, preWeight);
                        if (pathWeight >= bestPathWeight) {
                            bestPathWeight = pathWeight;
                            bestPath = extendedPath;
                        }
                    }
                }
            }
        }

        return bestPath;
    }

    /**
      * @dev merges two paths with a common suffix into one
      * 
      * @param _sourcePath address of the source path
      * @param _targetPath address of the target path
      * 
      * @return merged path
    */
    function getShortestPath(address[] memory _sourcePath, address[] memory _targetPath) private pure returns (address[] memory) {
        if (_sourcePath.length > 0 && _targetPath.length > 0) {
            uint256 i = _sourcePath.length;
            uint256 j = _targetPath.length;
            while (i > 0 && j > 0 && _sourcePath[i - 1] == _targetPath[j - 1]) {
                i--;
                j--;
            }

            address[] memory path = new address[](i + j + 1);
            for (uint256 m = 0; m <= i; m++)
                path[m] = _sourcePath[m];
            for (uint256 n = j; n > 0; n--)
                path[path.length - n] = _targetPath[n - 1];

            uint256 length = 0;
            for (uint256 p = 0; p < path.length; p += 1) {
                for (uint256 q = p + 2; q < path.length - p % 2; q += 2) {
                    if (path[p] == path[q])
                        p = q;
                }
                path[length++] = path[p];
            }

            return getPartialArray(path, length);
        }

        return new address[](0);
    }

    /**
      * @dev creates a new array containing a single item
      * 
      * @param _item item
      * 
      * @return initial array
    */
    function getInitialArray(address _item) private pure returns (address[] memory) {
        address[] memory array = new address[](1);
        array[0] = _item;
        return array;
    }

    /**
      * @dev prepends two items to the beginning of an array
      * 
      * @param _item0 first item
      * @param _item1 second item
      * @param _array initial array
      * 
      * @return extended array
    */
    function getExtendedArray(address _item0, address _item1, address[] memory _array) private pure returns (address[] memory) {
        address[] memory array = new address[](2 + _array.length);
        array[0] = _item0;
        array[1] = _item1;
        for (uint256 i = 0; i < _array.length; i++)
            array[2 + i] = _array[i];
        return array;
    }

    /**
      * @dev extracts the prefix of a given array
      * 
      * @param _array given array
      * @param _length prefix length
      * 
      * @return partial array
    */
    function getPartialArray(address[] memory _array, uint256 _length) private pure returns (address[] memory) {
        address[] memory array = new address[](_length);
        for (uint256 i = 0; i < _length; i++)
            array[i] = _array[i];
        return array;
    }
}

contract A {
    function generatePath(address _sourceToken, address _targetToken) public returns (address[] memory);
}
