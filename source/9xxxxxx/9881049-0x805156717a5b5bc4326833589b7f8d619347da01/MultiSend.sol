pragma solidity ^0.4.21;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/// @dev Beware that "send" may fail if the receiver is a contract.
contract MultiSend is Ownable {
  using SafeMath for uint;

  event Send(address _addr, uint _amount);
  event Fail(address _addr, uint _amount);

  // send _amount to each address
  function multiSend(address[] _addrs, uint _amount) external payable {
    require(_amount > 0);

    uint _totalToSend = _amount.mul(_addrs.length);
    require(msg.value >= _totalToSend);

    // try sending to multiple addresses
    uint _totalSent = 0;
    for (uint256 i = 0; i < _addrs.length; i++) {
      require(_addrs[i] != address(0));
      if (_addrs[i].send(_amount)) {
        _totalSent = _totalSent.add(_amount);
        // emit Send(_addrs[i], _amount);
      } else {
        emit Fail(_addrs[i], _amount);
      }
    }

    // refund unsent ether
    if (msg.value > _totalSent) {
      msg.sender.transfer(msg.value.sub(_totalSent));
      // emit Send(msg.sender, msg.value.sub(_totalSent));
    }
  }

  // split paid ether to addresses
  function splitSend(address[] _addrs) external payable {
    require(msg.value > 0);

    // try sending to multiple addresses
    uint _amount = msg.value.div(_addrs.length);
    uint _totalSent = 0;
    for (uint256 i = 0; i < _addrs.length; i++) {
      require(_addrs[i] != address(0));
      if (_addrs[i].send(_amount)) {
        _totalSent = _totalSent.add(_amount);
        // emit Send(_addrs[i], _amount);
      } else {
        emit Fail(_addrs[i], _amount);
      }
    }

    // refund unsent ether
    if (_totalSent != _amount.mul(_addrs.length)) {
      msg.sender.transfer(msg.value.sub(_totalSent));
      // emit Send(msg.sender, msg.value.sub(_totalSent));
    }
  }

  function ownerWithdraw() public onlyOwner {
    owner.transfer(address(this).balance);
  }
}
