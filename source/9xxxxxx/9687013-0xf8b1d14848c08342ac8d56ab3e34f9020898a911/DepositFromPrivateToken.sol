pragma solidity ^0.4.24;
import "./PrivateToken.sol";
import "./StandardToken.sol";

/**
 * @title Lock Token
 *
 * Token would be locked for thirty days after ICO.  During this period
 * new buyer could still trade their tokens.
 */

 contract DepositFromPrivateToken is StandardToken {
   using SafeMath for uint256;

   PrivateToken public privateToken; // Storage slot 3

   modifier onlyPrivateToken() {
     require(msg.sender == address(privateToken));
     _;
   }

   /**
   * @dev Deposit is the function should only be called from PrivateToken
   * When the user wants to deposit their private Token to Origin Token. They should
   * let the Private Token invoke this function.
   * @param _depositor address. The person who wants to deposit.
   */

   function deposit(address _depositor, uint256 _value) public onlyPrivateToken returns(bool){
     require(_value != 0);
     balances[_depositor] = balances[_depositor].add(_value);
     emit Transfer(privateToken, _depositor, _value);
     return true;
   }
 }

