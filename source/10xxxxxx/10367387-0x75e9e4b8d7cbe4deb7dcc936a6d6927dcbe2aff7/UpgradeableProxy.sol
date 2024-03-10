pragma solidity 0.5.17;

import "./EternalStorageData.sol";

/**
 * @author Quant Network
 * @title UpgradeableProxy
 * @dev This contract allows the proxy to be upgradeable and owned
 */
contract UpgradeableProxy is EternalStorage {
    
    /**
   * Sets the admin of the proxy. Only the admin address can change this
   */
  function setAdmin() external {
      require(msg.sender ==admin(), 'only admin can call this function');
      uint256 sbTime = uint256Storage[keccak256('proxy.speedbump.useAfterTime')];
      require(now > sbTime, "this speed bump cannot be used yet");
        require(sbTime > 0, "use after time cannot be 0");
      //change storage
      addressStorage[keccak256('proxy.admin')] = addressStorage[keccak256('proxy.speedbump.admin')];
      //remove speed bump
       addressStorage[keccak256('proxy.speedbump.admin')] = address(0);
  }
  
    /**
   * Sets the implementation of the proxy. Only the admin address can upgrade the smart contract logic
   */
  function setImplementation() external {
      require(msg.sender ==admin(), 'only admin can call this function');
      uint256 sbTime = uint256Storage[keccak256('proxy.speedbump.useAfterTime')];
      require(now > sbTime, "this speed bump cannot be used yet");
      require(sbTime > 0, "use after time cannot be 0");
      addressStorage[keccak256('proxy.implementation')] = addressStorage[keccak256('proxy.speedbump.implementation')]; 
      addressStorage[keccak256('proxy.speedbump.implementation')] = address(0); 
  }
  
    /**
   * Adds a speed bump to change the admin or implementation. Only the admin address can change this
   */
  function changeProxyVariables(address nextAdmin, address nextImplementation) external {
      require(msg.sender == admin(), 'only admin can call this function');
        addressStorage[keccak256('proxy.speedbump.admin')] = nextAdmin;
        addressStorage[keccak256('proxy.speedbump.implementation')] = nextImplementation;
        //note that admin and implementation functions are separate above to align with more upgradeability patterns
        uint256Storage[keccak256('proxy.speedbump.useAfterTime')] = now + (speedBumpHours()*1 hours);
  }

   /**
   * sets the contract as initialised
   */ 
  function initializeNow() internal {
      boolStorage[keccak256('proxy.initialized')] = true;    
  }
  
    /**
    * set the speed bump time of this contract
    */        
    function speedBumpHours(uint16 newSpeedBumpHours) internal {
        uint16Storage[keccak256('proxy.speedBumpHours')] = newSpeedBumpHours;
    }
  
  /**
   * @return - the admin of the proxy. Only the admin address can upgrade the smart contract logic
   */
  function admin() public view returns (address);
 
  /**
   * @return - the address of the current smart contract logic
   */ 
  function implementation() public view returns (address) {
      return addressStorage[keccak256('proxy.implementation')];    
  }
  
  /**
   * @return - whether the smart contract has  been initialized (true) or not (false)
   */ 
  function initialized() public view returns (bool) {
      return boolStorage[keccak256('proxy.initialized')];    
  }
  
    /**
    * @return - the number of hours wait time for any critical update
    */        
    function speedBumpHours() public view returns (uint16);
  
    
}
