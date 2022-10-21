pragma solidity ^0.7.1;

import './Context.sol';

interface IERC20Token{
    function transfer(address recipient, uint amount) external returns (bool);
}

/**
@title Token sale store
@dev Store BNU token for token sale
 */
contract BNUStore is Context{
    address public _shareTokenSaleContractAddress;
    address public _publicTokenSaleContractAddress;
    address public _vestingContractAddress;

    modifier onlyAllowedContracts{
        require(
            _msgSender() == _shareTokenSaleContractAddress || 
            _msgSender() == _publicTokenSaleContractAddress ||
            _msgSender() == _vestingContractAddress, "Fobidden");
        _;
    }

    /**
    @dev BNU token contrat address
     */
    IERC20Token internal _bnxTokenContract;

    function setBnuTokenContract(address contractAddress) external onlyOwner contractActive{
        _setBnuTokenContract(contractAddress);
    }
  
    function setPublicTokenSaleContractAddress(address contractAddress) external onlyOwner contractActive{
        _publicTokenSaleContractAddress = contractAddress;
    }

    function setShareTokenSaleContractAddress(address contractAddress) external onlyOwner contractActive{
        _shareTokenSaleContractAddress = contractAddress;
    }

    function setVestingContractAddress(address contractAddress) external onlyOwner contractActive{
        _vestingContractAddress = contractAddress;
    }

    function transfer(address recipient, uint amount) external onlyAllowedContracts contractActive returns(bool){
        require(_bnxTokenContract.transfer(recipient, amount),"Can not transfer BNU");
        return true;
    }

    function _setBnuTokenContract(address contractAddress) internal{
        _bnxTokenContract = IERC20Token(contractAddress);
    }
}

// SPDX-License-Identifier: MIT
