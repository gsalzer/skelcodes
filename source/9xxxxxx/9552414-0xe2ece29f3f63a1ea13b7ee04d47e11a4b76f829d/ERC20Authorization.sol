pragma solidity ^0.4.24;
import "ComplianceModule.sol";
import "StorageModule.sol";
import "Authorization.sol";

contract ERC20Authorization is Authorization{
    
    constructor(address _proxy) public Authorization(_proxy) {

    }

    modifier onlyTxCheck(address _from, address _to, uint256 _amount) {
        ComplianceModule comp = ComplianceModule(proxy.getModule("ComplianceModule"));
        require(comp.txCheck(_from, _to, _amount), "Need to be txCheck");
        _;
    }

    modifier onlyMintCheck(address[] _to, uint256[] _amounts) {
        require(ComplianceModule(proxy.getModule("ComplianceModule")).mintCheck(_to, _amounts), "Need to be mintCheck");
        _;
    }

    function updateShareholders(address _from, address _to) internal {
        StorageModule stor = StorageModule(proxy.getModule("StorageModule"));
        stor.updateShareholders(_from, _to);
    }

}
