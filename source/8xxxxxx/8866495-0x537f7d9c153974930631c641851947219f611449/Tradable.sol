pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./AuthorizedInvestor.sol";

contract Tradable is ERC20, AuthorizedInvestor {
    using SafeMath for uint256;

    uint256 public decimals_t = 8;

    address[] public currentHolders;
    mapping (address => uint256) public lastUsed;
    mapping (address => uint256) public lastOxydation;
    event newHolder(address holder);

    enum ExchangeType { getToken, getEther }

    constructor() public {}

    function storeNewHolder(address _from, address _to) internal {
        bool foundFrom = false;
        bool foundTo = false;

        for(uint i = 0 ; i < currentHolders.length ; i++) {
            if(currentHolders[i] == _from) {
                foundFrom = true;
                if(ERC20.balanceOf(_from) == 0) {
                    remove(i);
                }
            }
            if(currentHolders[i] == _to) {
                foundTo = true;
                if(ERC20.balanceOf(_to) == 0) {
                    remove(i);
                }
            }
        }
        if(!foundFrom && ERC20.balanceOf(_from) > 0) {
            currentHolders.push(_from);
            emit newHolder(_from);
        }
        if(!foundTo && ERC20.balanceOf(_to) > 0) {
            currentHolders.push(_to);
            emit newHolder(_to);
        }
    }

    function storeLastUsed(address _from, address _to) internal {
        lastUsed[_from] = now;
        lastUsed[_to] = now;
        lastOxydation[_from] = 0;
        lastOxydation[_to] = 0;

    }

    function remove(uint index) private returns(address[] memory) {
        if (index >= currentHolders.length) return currentHolders;

        for (uint i = index; i<currentHolders.length-1; i++){
            currentHolders[i] = currentHolders[i+1];
        }
        delete currentHolders[currentHolders.length-1];
        currentHolders.length = currentHolders.length.sub(1);
        return currentHolders;
    }
}

