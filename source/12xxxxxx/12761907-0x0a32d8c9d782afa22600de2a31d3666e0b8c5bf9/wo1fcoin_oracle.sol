// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract WFCSale_Oracle {
    uint256 public _tokenPrice;
    
    function setTokenPrice(uint256 _price) external {
        _tokenPrice = _price;
    }
    
    function getTokenPrice() external view returns(uint256) {
        return _tokenPrice;
    }
    
}

