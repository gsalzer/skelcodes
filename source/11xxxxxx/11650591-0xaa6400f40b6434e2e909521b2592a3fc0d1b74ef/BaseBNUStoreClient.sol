pragma solidity ^0.7.1;

import './Context.sol';
import './IBNUStore.sol';

interface IERC20Token{
    function burnTokenSale(address account, uint amount) external returns(bool);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

/**
@title Base contract for contract to interact with BNU Store contract
 */
contract BaseBNUStoreClient is Context{
    IBNUStore internal _bnuStoreContract;

    function setBNUStoreContract(address contractAddress) external onlyOwner contractActive{
        _setBNUStoreContract(contractAddress);
    }

    function _setBNUStoreContract(address contractAddress) internal{
        _bnuStoreContract = IBNUStore(contractAddress);
    }
}

// SPDX-License-Identifier: MIT
