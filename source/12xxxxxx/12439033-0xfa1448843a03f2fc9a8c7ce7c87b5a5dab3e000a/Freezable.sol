pragma solidity 0.5.17;

import "./Ownership.sol";

contract Freezable is Ownership {
    
    mapping (address => bool) frozen;
    bool public emergencyFreeze = false;

    event Freezed(address targetAddress, bool frozen);
    event EmerygencyFreezed(bool emergencyFreezeStatus);

    modifier unfreezed(address _account) { 
        require(!frozen[_account]);
        _;  
    }
    
    modifier noEmergencyFreeze() { 
        require(!emergencyFreeze);
        _; 
    }

    // ------------------------------------------------------------------------
    // Freeze account - onlyOwner
    // ------------------------------------------------------------------------
    function freezeAccount (address _target, bool _freeze) public onlyOwner returns(bool) {
        frozen[_target] = _freeze;
        emit Freezed(_target, _freeze);
        return true;
    }

    // ------------------------------------------------------------------------
    // Emerygency freeze - onlyOwner
    // ------------------------------------------------------------------------
    function emergencyFreezeAllAccounts (bool _freeze) public onlyOwner returns(bool) {
        emergencyFreeze = _freeze;
        emit EmerygencyFreezed(_freeze);
        return true;
    }

    // ------------------------------------------------------------------------
    // Get Freeze Status : Constant
    // ------------------------------------------------------------------------
    function isFreezed(address _targetAddress) public view returns (bool) {
        return frozen[_targetAddress]; 
    }

}
