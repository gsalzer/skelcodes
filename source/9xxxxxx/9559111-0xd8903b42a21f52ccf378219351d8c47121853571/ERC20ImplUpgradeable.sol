pragma solidity ^0.4.24;

import "IERC20ImplUpgradeable.sol";
import "ERC20Impl.sol";
import "ERC20MintBurn.sol";
import "Authorization.sol";

contract ERC20ImplUpgradeable is IERC20ImplUpgradeable, Authorization {

    ERC20Impl public erc20Impl;
    ERC20MintBurn public erc20MintBurn;

    event UpdateImpl(address _old, address _new);
    event UpdateMintBurn(address _old, address _new);

    modifier onlyImpl {
        require(this.isImplAddress(msg.sender), "Only Impl can call");
        _;
    }

    constructor(address _proxy) public Authorization(_proxy) {
    }

    function isImplAddress(address sender) view external returns(bool) {
        return sender == address(erc20Impl) || sender == address(erc20MintBurn);
    }

    function updateImpl(address _erc20Impl) external onlyAdmin(msg.sender) {
        require(_erc20Impl != 0x0, "address is zero"); 

        address _old = erc20Impl;
        erc20Impl = ERC20Impl(_erc20Impl);
        emit UpdateImpl(_old, _erc20Impl);
    }

    function getImplAddress() view external returns(address) {
        return erc20Impl;
    }

    function updateMintBurn(address _erc20Impl) external onlyAdmin(msg.sender) {
        require(_erc20Impl != 0x0, "address is zero"); 
        
        address _old = erc20MintBurn;
        erc20MintBurn = ERC20MintBurn(_erc20Impl);
        emit UpdateMintBurn(_old, _erc20Impl);
    }

    function getMintBurnAddress() view external returns(address) {
        return erc20MintBurn;
    }
    
}
