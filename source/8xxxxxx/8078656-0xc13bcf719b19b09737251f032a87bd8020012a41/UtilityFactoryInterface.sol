pragma solidity ^0.4.25;

import "./FactoryInterface.sol";

/**
 * @title TokenReserve interface
 */
contract UtilityFactoryInterface is FactoryInterface {

    event Issued(address indexed _issuer, string _symbol, string _name, uint256 _initialSupply, uint8 _decimals);

    /**
    * @dev Function to release token
    * @param _symbol Symbol of the new token.
    * @param _name Name of the new token.
    * @param _initialSupply Supply of the utility token.
    * @param _decimals number of decimals of the utility token.
    * @param _mintable sets the token as mintable
    * @param _burnable sets the token as burnable
    */
    function createToken(string _symbol, string _name, uint256 _initialSupply, uint8 _decimals, bool _mintable, bool _burnable) external;
}
