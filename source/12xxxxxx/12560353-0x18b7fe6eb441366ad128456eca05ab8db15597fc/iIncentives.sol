pragma solidity ^0.7.6;
// "SPDX-License-Identifier: MIT"

interface IIncentives {
    
    event IncentivesTokenCreated(string indexed symbol, address indexed contractAddress);
    /**
    * Put governance tokens into this contract
    * Store token amount in the contract and register it for the user.
    */
    function putGovernance(uint256 amount) external; 
    
    /**
     * Withdraw Governance tokens.
     * Withdraw amount of gov. tokens registered for the user and not blocked by withdrawan incentives tokens.
     */
     function withdrawGovernance(uint amount) external;
    
    /**
     * Withdraw some amount of specific incentives token.
     * @param tokenAddress address of incentives token user wants to withdraw.
     * Every user can withdraw amount of incentives tokens of all available types equal to amount of his Gov. tokens stored in the contract.
    */
    function withdrawIncentives(address tokenAddress, uint amount) external;
    
    /**
     * Return incentives tokens to the contract.
     * @param tokenAddress address of the incentives token which user plans to return to the contract.
     */
     function putIncentivesTokens(address tokenAddress, uint amount) external;
     
     /**
      * Create new incentives token.
      * Function called by the contract owner to add new type of incentives token to the contract.
      */
     function createnNewIncentivesToken(string memory name, string memory symbol) external;
     
     /**
      * Switch to the new contract owner.
      */
      function switchOwner(address newOwner) external;

     /**
      * function returns user tokens state. how many different tokens contract holds
      * for the user including Governance tokens.
      * @return list of token addresses and their respective amounts list including governance token.
      */
      function userState(address _user) view external returns(address[] memory, uint256[] memory);
      
       /**
      * function returns all available tokens on the contract
      * @return list of token addresses and their respective amounts list including governance token.
      */
      function availableTokens() view external returns(address[] memory, uint256[] memory);
      
      /**
       * Function returns count of unique users with governance tokens in the contract.
       */
       function userscount() view external returns(uint256);
       /**
       * Compute the address of the contract to be deployed.
       */
       function getAddress(string memory name, string memory symbol) view external returns (address);

       function getMaxBorrowed(address user) view external returns(uint256);
       function getGovBalances(address user) view external returns(uint256);
       function setCrowdsale(address crowdsale) external;
       function lockIncentives(address lockContract,address incentivesToken,uint256 amount,uint256 unlock_time) external;
    
}

