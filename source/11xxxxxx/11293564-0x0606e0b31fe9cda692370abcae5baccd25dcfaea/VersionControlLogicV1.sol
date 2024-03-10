// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

import "./VCProxy.sol";
import "./VersionControlV1.sol";
import "./SenateLogicV1.sol";

/// @author Guillaume Gonnaud 2019
/// @title Logic code smart contract for proper versioning of proxies. Logic code, to be casted on the proxy.
contract VersionControlLogicV1 is VCProxyData, VersionControlHeaderV1, VersionControlStoragePublicV1  {

    /// @notice Generic constructor, empty
    /// @dev This contract is meant to be used in a delegatecall and hence its memory state is irrelevant
    constructor() public {
        //Memory state for logic smart contract is irrelevant
    }

    //Modifier for functions that requires to be called only by the controller of the version control
    modifier restrictedToController(){
        require(msg.sender == controller, "Only the controller can call this function");
        _;
    }

    /// @notice Set the code address of a specific version to the new specified code address
    /// @dev To be overhauled with voting in the future
    /// @param _version The version that is stored by the smart contract you want to change the logic code of
    /// @param _code The new code address
    function setVersion(uint256 _version, address _code) public restrictedToController(){ //Need to be restricted to PA only
        bool authorization = senate == address(0x0); //We check if the senate is set
        if(!authorization){ //If the senate is set, ask for authorization
            authorization = SenateLogicV1(senate).isAddressAllowed(_code);
        }
        require(authorization, "The senate -voting smart contract- did not allow this address to be used");
        emit VCChangedVersion(_version, code[_version], _code);
        code[_version] = _code;
    }

    /// @notice Push a new address in the versioning Ledger
    /// @dev Must be approved by the senate
    /// @param _code The new code address
    /// @return The number of Cryptographs owned by `_owner`, possibly zero
    function pushVersion(address _code) public restrictedToController() returns (uint256){ //Need to be restricted to PA only
        bool authorization = senate == address(0x0); //We check if the senate is set
        if(!authorization){ //If the senate is set, ask for authorization
            authorization = SenateLogicV1(senate).isAddressAllowed(_code);
        }
        require(authorization, "The senate -voting smart contract- did not allow this address to be pushed");
        code.push(_code);
        uint256 index = code.length - 1;
        emit VCCAddedVersion(index, _code);
        return index;
    }

    /// @notice Expose the length of the code array
    /// @dev Useful to know the index of the last inserted code element
    /// @return The lenght of the code array
    function codeLength() external view returns (uint256){
        return code.length;
    }

    /// @notice Push a new address in the versioning Ledger
    /// @dev Can be set up once only
    /// @param _senate The new code address
    function setSenate (address _senate) public restrictedToController(){
        require(senate == address(0x0), "The senate address has already been set");
        senate = _senate;
    }

}
