pragma solidity ^0.5.10;

import "./MintableAndBurnable.sol";
import "./IToken.sol";

contract Token is IToken, MintableAndBurnable {
    string public name = "ENEGRA";
    string public symbol = "EGX";
    string public version = "1.2";
    address public onchainID = 0x0000000000000000000000000000000000000000;

    constructor(
        address _identityRegistry,
        address _compliance
		)
        public
		TransferManager(_identityRegistry, _compliance)
    {}

    /**
    * Owner can update token information here
    */
    function setTokenInformation(
		string calldata _name,
		string calldata _symbol,
		uint8 _decimals,
		string calldata _version,
		address _onchainID,
		uint256 _maxTokenSupply
		) external onlyOwner {

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        version = _version;
		onchainID = _onchainID;
		maxTokenSupply = _maxTokenSupply * (10 ** uint256(decimals));

        emit UpdatedTokenInformation(name, symbol, decimals, version, onchainID, _maxTokenSupply);
    }
}

