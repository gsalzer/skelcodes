// @author Unstoppable Domains, Inc.
// @date June 16th, 2021

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

abstract contract CapperRole is AccessControlUpgradeable {
    bytes32 public constant CAPPER_ROLE = keccak256('CAPPER_ROLE');

    modifier onlyCapper() {
        require(isCapper(_msgSender()), 'CapperRole: CALLER_IS_NOT_CAPPER');
        _;
    }

    function isCapper(address account) public view returns (bool) {
        return hasRole(CAPPER_ROLE, account);
    }

    function addCapper(address account) public onlyCapper {
        _addCapper(account);
    }

    function renounceCapper() public {
        _removeCapper(_msgSender());
    }

    function _addCapper(address account) internal {
        _setupRole(CAPPER_ROLE, account);
    }

    function _removeCapper(address account) internal {
        renounceRole(CAPPER_ROLE, account);
    }
}

