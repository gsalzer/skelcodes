pragma solidity 0.5.17;

import "./UpgradeableProxy.sol";

/**
 * @author Quant Network
 * @title FactoryAbstract
 * @dev Sets the main variables of a Treasury Factory contract and allows other contracts to easily interface with a Treasury Factory contract without knowing the whole code.
 */
contract FactoryBase is UpgradeableProxy {
    
    // stores the mapping of MAPP (multi-chain app) -> treasury payment channels
    bytes constant private mappChannels1 = '1.mappChannels';
    // stores the mapping of MAPP -> escrowed deposits contracts
    bytes constant private mappDeposits1 = '1.mappDeposits';
    //  stores the number of registered gateways
    bytes constant private mappCount1 = '1.mappCount';
    // stores the mapping of treasury -> gateway payment channels
    bytes constant private gatewayChannels1 = '1.gatewayChannels';
    //  stores the mapping of gateway -> escrowed deposits contracts
    bytes constant private gatewayDeposits1 = '1.gatewayDeposits';
    //  stores the number of registered gateways
    bytes constant private gatewayCount1 = '1.gatewayCount';
    
    /**
     * sets the payment channel for this mapp (multi-chain app)
     */
    function mappChannel(address mappOperator, address channel) internal {
        addressStorage[keccak256(abi.encodePacked(mappChannels1,mappOperator))] = channel;
    }
    
    /**
     * sets the escrowed deposit contract for this mapp
     */
    function mappDeposit(address mappOperator, address depositContract) internal {
        addressStorage[keccak256(abi.encodePacked(mappDeposits1,mappOperator))] = depositContract;
    }
    
    /**
     * sets the number of gateways
     */
    function mappCount(uint32 count) internal {
        uint32Storage[keccak256(abi.encodePacked(mappCount1))] = count;
    }
    
    /**
     * sets the payment channel for this gateway
     */
    function gatewayChannel(address gatewayOperator, address channel) internal {
        addressStorage[keccak256(abi.encodePacked(gatewayChannels1,gatewayOperator))] = channel;
    }
    
    /**
     * sets the escrowed deposit contract for this gateway
     */
    function gatewayDeposit(address gatewayOperator, address deposit) internal {
        addressStorage[keccak256(abi.encodePacked(gatewayDeposits1,gatewayOperator))] =  deposit;
    }
    
    /**
     * sets the number of gateways
     */
    function gatewayCount(uint32 count) internal {
        uint32Storage[keccak256(abi.encodePacked(gatewayCount1))] =  count;
    }

    /**
     * @return - the payment channel for this mapp (multi-chain app)
     */
    function mappChannel(address mappOperator) public view returns (address){
        return addressStorage[keccak256(abi.encodePacked(mappChannels1,mappOperator))];
    }
    
    /**
     * @return - the escrowed deposit for this mapp (multi-chain app)
     */
    function mappDeposit(address mappOperator) public view returns (address){
        return addressStorage[keccak256(abi.encodePacked(mappDeposits1,mappOperator))];
    }
    
    /**
     * @return - the number of mapps
     */
    function mappCount() public view returns (uint32) {
        return uint32Storage[keccak256(abi.encodePacked(mappCount1))];
    }
    
    /**
     * @return - the payment channel for this gateway
     */
    function gatewayChannel(address gatewayOperator) public view returns (address){
        return addressStorage[keccak256(abi.encodePacked(gatewayChannels1,gatewayOperator))];
    }
    
    /**
     * @return - the escrowed deposit for this gateway
     */
    function gatewayDeposit(address gatewayOperator) public view returns (address){
        return addressStorage[keccak256(abi.encodePacked(gatewayDeposits1,gatewayOperator))];
    }
    
    /**
     * @return - the number of gateways
     */
    function gatewayCount() public view returns (uint32) {
        return uint32Storage[keccak256(abi.encodePacked(gatewayCount1))];
    }
    
}

/**
 * @author Quant Network
 * @title Allows contracts to easily interface with an EscrowedDeposit contract without knowing the whole code
 */
contract EscrowedDepositAbstract {
    
    
    /**
     * The rule list contract can deduct QNT from this escrow and send it to the receiver (without closing the escrow)
     * @param tokenAmount - the amount to deduct
     * @param ruleAddress - the contract address detailing the specific rule that has been broken
     */
    function deductDeposit(uint256 tokenAmount, address ruleAddress) external;

}
