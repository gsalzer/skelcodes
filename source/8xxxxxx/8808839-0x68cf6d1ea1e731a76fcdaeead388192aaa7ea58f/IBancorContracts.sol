pragma solidity 0.5.11;


import "./ERC20InterfaceV5.sol";


/**
    Id definitions for bancor contracts

    Can be used in conjunction with the contract registry to get contract addresses
*/
contract ContractIds {
    // generic
    bytes32 public constant CONTRACT_REGISTRY = "ContractRegistry";

    // bancor logic
    bytes32 public constant BANCOR_NETWORK = "BancorNetwork";
    bytes32 public constant BANCOR_FORMULA = "BancorFormula";
    bytes32 public constant BANCOR_NETWORK_PATH_FINDER = "BancorNetworkPathFinder";

    // Ids of BNT converter and BNT token
    bytes32 public constant BNT_TOKEN = "BNTToken";
    bytes32 public constant BNT_CONVERTER = "BNTConverter";

    // Id of BancorX contract
    bytes32 public constant BANCOR_X = "BancorX";
}

contract IBancorNetworkPathFinder {
    function get(ERC20 srcToken, ERC20 destToken, address[] memory converterRegistries) public view returns (address[] memory);
}

// File: contracts/utility/interfaces/IContractRegistry.sol

/*
    Contract Registry interface
*/
contract IContractRegistry {
    function addressOf(bytes32 _contractName) public view returns (address);

    // deprecated, backward compatibility
    function getAddress(bytes32 _contractName) public view returns (address);
}


// File: contracts/converter/interfaces/IBancorConverter.sol

/*
    Bancor Converter interface
*/
contract IBancorNetwork {
    function getReturnByPath(ERC20[] calldata _path, uint256 _amount) external view returns (uint256, uint256);
    function convert2(
        ERC20[] calldata _path,
        uint256 _amount,
        uint256 _minReturn,
        address _affiliateAccount,
        uint256 _affiliateFee
    ) external payable returns (uint256);
}

