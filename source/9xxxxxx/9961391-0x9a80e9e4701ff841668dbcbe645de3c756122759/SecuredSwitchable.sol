pragma solidity 0.5.0;

import "./Secured.sol";

contract SecuredSwitchable is Secured {

    bool private _isEnabled;

    modifier onlyEnabled() {
        require(_isEnabled);
        _;
    }

    function isEnabled() public view returns (bool) {
        return _isEnabled;
    }

    function setEnabled() public onlyAdmin {
        require(!_isEnabled);
        _isEnabled = true;
    }

    function setDisabled() public onlyAdmin {
        require(_isEnabled);
        _isEnabled = false;
    }
}

