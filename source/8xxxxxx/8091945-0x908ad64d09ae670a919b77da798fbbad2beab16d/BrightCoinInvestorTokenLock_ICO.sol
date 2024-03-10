pragma solidity ^0.4.25;

import "./SafeMath.sol";
import "./BrightCoinTokenOwner_ICO.sol";



contract BrightCoinInvestorTokenLock is  BrightCoinTokenOwner
{

 /**
    * @dev Error messages for require statements
    */
   // string internal constant ALREADY_LOCKED = 'Tokens already locked';
   // string internal constant NOT_LOCKED = 'No tokens locked';
    //string internal constant AMOUNT_ZERO = 'Amount can not be 0';

enum BrightCoinLockType { Investor, Admin,Bounty }
      using SafeMath for uint;

    /**
     * @dev locked token structure
     */
    struct lockToken {
        uint256 amount;
        uint256 validity;
        bool exists;
        bool claimed;
 
    }

    /**
     * @dev Holds number & validity of tokens locked for a given reason for
     *      a specified address
     */

    mapping(address => lockToken)  locktokenDetails;

    /**
     * @dev Records data of all the tokens Locked
     */
    event Locked(
        address indexed _of,
        uint256 _amount,
        uint256 _validity
    );

    /**
     * @dev Records data of all the tokens unlocked
     */
    event Unlocked(
        address indexed _of,
        bytes32 indexed _reason,
        uint256 _amount
    );


   constructor() public 
   {
	
   }

    function tokensLocked(address _of)
        internal
        view
        returns (uint256 amount)
    {
        uint256 am = 0;
        lockToken storage AddrStruct =  locktokenDetails[_of];
        if (!AddrStruct.claimed)
            am = AddrStruct.amount;
      
            return am;
    }
    
    function isTokenLockExpire(address _of, uint256 _time)  view internal  returns(bool)
    {
        bool retVal = false;

       if(locktokenDetails[_of].validity < _time)
            return retVal = true;
      
            return retVal;
    }

    function getTokenLockExpiry(address _of)  view internal returns(uint256 )
    {
       return  locktokenDetails[_of].validity;
    }


    function isAddrExists(address _addr) view internal returns(bool)
    {
        
       lockToken storage lockBounty = locktokenDetails[_addr];
          return lockBounty.exists;
       
           
    }
    
    
    
     function SetTokenLock(address _of, uint256 _time, 
         uint256 _amount)  internal   
          {
              
               //uint256 validUntil = now.add(_time); //solhint-disable-line

                 require(_amount != 0);
                 require(_of != 0x0);

                 lockToken storage AddrStruct =  locktokenDetails[_of];
                 if(tokensLocked(_of) > 0)
                 {
                      
                        AddrStruct.amount = (AddrStruct.amount).add(_amount);
                        AddrStruct.validity = _time;
                 }
                 else
                 {
        
                        AddrStruct.amount = _amount;
                        AddrStruct.validity = _time;
                        AddrStruct.exists = true;
                        AddrStruct.claimed = false;
                 }
          }

          function IncreaseTokenAmount(address _addr, uint256 _validity,uint256 _amount)
         internal 
        returns (bool)
    {
       
        require(tokensLocked(_addr) > 0);
         lockToken storage AddrStruct =  locktokenDetails[_addr];
        AddrStruct.amount = (AddrStruct.amount).add(_amount);
        AddrStruct.validity = _validity;
       
       // emit Locked(msg.sender, _reason, locked[msg.sender][_reason].amount, locked[msg.sender][_reason].validity);
        return true;
        
    }



}


