pragma solidity 0.5.8;

import "./ERC20.sol";

contract ERC20Whitelisted is ERC20 {

    mapping(address => bool) internal _isWhitelisted;
    mapping(address => string) internal iso;

    address[] internal whitelistedAddresses;

    function isWhitelisted(address _account) public view returns(bool, string memory) {
        return (_isWhitelisted[_account], iso[_account]);
    }

    function addWhitelisted(address _account, string memory _iso) public {
        require(_isWhitelisted[_account] == false, 'account already whitelisted');
        _isWhitelisted[_account] = true;
        iso[_account] = _iso;

        whitelistedAddresses.push(_account);
    }

    function removeWhitelisted(address _account) public {
        _isWhitelisted[_account] = false;
    }

    function getWhitelistedAddresses() public view returns(address[] memory) {
        return whitelistedAddresses;
    }

}
