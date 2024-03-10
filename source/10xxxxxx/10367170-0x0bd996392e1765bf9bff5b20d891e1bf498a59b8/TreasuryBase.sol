pragma solidity 0.5.17;

import "./UpgradeableProxy.sol";

/**
 * @author Quant Network
 * @title TreasuryAbstract
 * @dev Sets the main variables of a Treasury contract and allows other contracts to easily interface with a Treasury contract without knowing the whole code. 
 */
contract TreasuryBase is UpgradeableProxy {
    
        // the connected factory of this treasury
        bytes constant private treasurysFactory1 = '1.treasurysFactory';
        // the connected rulelist of this treasury
        bytes constant private treasurysRuleList1 = '1.treasurysRuleList';
        // the treasury's escrowed deposit
        bytes constant private treasurysDeposit1 = '1.treasuryDeposit';
        // the QNT address of this treasury (possible cold wallet)   
        bytes constant private QNTAddress1 = '1.QNTAddress';
        // the operator address of this treasury, which can call other smart contract functions on behalf of the treasury
        bytes constant private operatorAddress1 = '1.operatorAddress';
        // whether this treasury is currently paused (true) or active (false)
        bytes constant private circuitBreakerOn1 = '1.circuitBreakerOn';
        // the fee the MAPP has to pay for any dispute raised per gateway
        bytes constant private mappDisputeFeeMultipler1 = '1.mappDisputeFeeMultipler';
        // the commission divider charged for every mapp to gateway transaction. 
        // The divider is used with the original fee of the function.
        // I.e a commission divider of 2 is equal to 50% commission
        bytes constant private commissionDivider1 = '1.commissionDivider';
        // the penalty multiplier the treasury has to pay if it has been found in breach of 
        // one of its verification rules. The mulitipication is used with the original fee of the function.
        // I.e. a treasuryPenalty of 10 is equal to a 10x penalty
        bytes constant private  treasuryPenaltyMultipler1 = '1.treasuryPenaltyMultipler';
        // the penalty multiplier a gateway has to pay if it has be found in breach of
        // one of its verification rules. The mulitipication is used with the original fee of the function
        // I.e. a gatewayPenalty of 5 is equal to a 5x penalty.
        bytes constant private gatewayPenaltyMultipler1 = '1.gatewayPenaltyMultipler';

        /**
         * set a new factory for this treasury
         */        
        function treasurysFactory(address newTreasurysFactory) internal {
            addressStorage[keccak256(treasurysFactory1)] = newTreasurysFactory;
        } 
        
        
        /**
         * set a new rulelist for this treasury
         */        
        function treasurysRuleList(address newTreasurysRuleList) internal {
            addressStorage[keccak256(treasurysRuleList1)] = newTreasurysRuleList;
        } 

        /**
         * set a new treasury deposit 
         */        
        function treasurysDeposit(address newTreasuryDeposit) internal {
            addressStorage[keccak256(treasurysDeposit1)] = newTreasuryDeposit;
        }
        
        /**
         * set a new QNTAddress for this treasury
         */        
        function QNTAddress(address newQNTAddress) internal {
            addressStorage[keccak256(QNTAddress1)] = newQNTAddress;
        }
        
        /**
         * set a new operator for this treasury
         */        
        function operatorAddress(address newOperator) internal {
            addressStorage[keccak256(operatorAddress1)] = newOperator;
        }
        
        /**
         * set the circuitbreaker of this treasury
         */        
        function circuitBreakerOn(bool newCircuitBreakerOn) internal {
            boolStorage[keccak256(circuitBreakerOn1)] = newCircuitBreakerOn;
        }
        
        /**
         * set the mapp dispute fee multiplier
         */        
        function mappDisputeFeeMultipler(uint16 newMappDisputeFeeMultipler) internal {
            uint16Storage[keccak256(mappDisputeFeeMultipler1)] = newMappDisputeFeeMultipler;
        }
        
 
        /**
         * set the commission divider
         */        
        function commissionDivider(uint16 neCommissionDivider) internal {
            uint16Storage[keccak256(commissionDivider1)] = neCommissionDivider;
        }

        /**
         * set the treasury dispute multiplier
         */        
        function treasuryPenaltyMultipler(uint16 newTreasuryPenaltyMultipler) internal {
            uint16Storage[keccak256(treasuryPenaltyMultipler1)] = newTreasuryPenaltyMultipler;
        }

        /**
         * set the gateway dispute multiplier
         */        
        function gatewayPenaltyMultipler(uint16 newGatewayPenaltyMultipler) internal {
            uint16Storage[keccak256(gatewayPenaltyMultipler1)] = newGatewayPenaltyMultipler;
        }

      /**
       * @return - the admin of the proxy. Only the admin address can upgrade the smart contract logic
       */
      function admin() public view returns (address) {
          return addressStorage[keccak256('proxy.admin')];   
      }
    
        /**
        * @return - the number of hours wait time for any critical update
        */        
        function speedBumpHours() public view returns (uint16){
            return uint16Storage[keccak256('proxy.speedBumpHours')];
        }
     
        /**
         * @return - the connected factory of this treasury
         */        
        function treasurysFactory() public view returns (address){
            return addressStorage[keccak256(treasurysFactory1)];
        } 
        
        /**
         * @return - the connected rulelist of this treasury
         */        
        function treasurysRuleList() public view returns (address){
            return addressStorage[keccak256(treasurysRuleList1)];
        } 


        /**
         * @return - the treasury's escrowed deposit
         */        
        function treasurysDeposit() public view returns (address){
            return addressStorage[keccak256(treasurysDeposit1)];
        }
        
        /**
         * @return - the withdrawal address of this treasury
         */        
        function QNTAddress() public view returns (address){
            return addressStorage[keccak256(QNTAddress1)];
        }
        
        /**
         * @return - the operator of this treasury
         */        
        function operatorAddress() public view returns (address){
            return addressStorage[keccak256(operatorAddress1)];
        }
        
        /**
         * @return - whether this treasury is currently active or not
         */        
        function circuitBreakerOn() public view returns (bool){
            return boolStorage[keccak256(circuitBreakerOn1)];
        }
        
        /**
         * @return - the fee the mapp has to pay for any dispute raised per gateway
         */        
        function mappDisputeFeeMultipler() public view returns (uint16){
            return uint16Storage[keccak256(mappDisputeFeeMultipler1)];
        }
        
 
        /**
         * @return the commission divider charged for every mapp to gateway transaction.
         * The divider is used with the original fee of the function.
         * I.e a commission divider of 2 is equal to 50% commission
         */        
        function commissionDivider() public view returns (uint16){
            return uint16Storage[keccak256(commissionDivider1)];
        }

        /**
         * @return - the penalty multiplier for the treasury has to pay if it has been found in breach of
         * one of its verification rules. The mulitipication is used with the original fee of the function.
         * I.e. a treasuryPenalty of 10 is equal to a 10x penalty
         */        
        function treasuryPenaltyMultipler() public view returns (uint16){
            return uint16Storage[keccak256(treasuryPenaltyMultipler1)];
        }

        /**
         * @return - the penalty multiplier a gateway has to pay if it has be found in breach of
         * one of its verification rules. The mulitipication is used with the original fee of the function
         * I.e. a gatewayPenalty of 5 is equal to a 5x penalty.
         */        
        function gatewayPenaltyMultipler() public view returns (uint16){
            return uint16Storage[keccak256(gatewayPenaltyMultipler1)];
        }
    
}
