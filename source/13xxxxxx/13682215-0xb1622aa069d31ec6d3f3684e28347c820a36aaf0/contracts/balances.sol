// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

abstract contract ERC20 {
    function balanceOf(address account) public view virtual returns (uint256);
}

contract Balances {
    
    struct Balance {
        address user;
        address token;
        uint256 amount;
    }
    
    /* public functions */
    
    /* Check the ERC20 token balances of a wallet for multiple tokens and addresses.
     Returns array of token balances in wei units. */
    function tokenBalances(address[] calldata users,  address[] calldata tokens) external view returns (Balance[] memory balances) {
        balances = new Balance[](users.length * tokens.length);
        
        uint idx = 0;
        
        for(uint i = 0; i < tokens.length; i++) {
            
            for (uint j = 0; j < users.length; j++) {
                
                balances[idx].user = users[j];
                balances[idx].token = tokens[i];
                
                if(tokens[i] != address(0x0)) { 
                    balances[idx].amount = tokenBalance(users[j], tokens[i]); // check token balance and catch errors
                } else {
                    balances[idx].amount = users[j].balance; // ETH balance    
                }
                idx++;
            }
        }    
        return balances;
    }
    
    
    /* Private functions */
    
    
    /* Check the token balance of a wallet in a token contract.
    Returns 0 on a bad token contract   */
    function tokenBalance(address user, address token) internal view returns (uint) {
        if(isAContract(token)) {
            return ERC20(token).balanceOf(user);
        } else {
            return 0; // not a valid contract, return 0 instead of error
        }
    }
    
    // check if contract (token, exchange) is actually a smart contract and not a 'regular' address
    function isAContract(address contractAddr) internal view returns (bool) {
        uint256 codeSize;
        assembly { codeSize := extcodesize(contractAddr) } // contract code size
        return codeSize > 0;
        // Might not be 100% foolproof, but reliable enough for an early return in 'view' functions 
    }
}

