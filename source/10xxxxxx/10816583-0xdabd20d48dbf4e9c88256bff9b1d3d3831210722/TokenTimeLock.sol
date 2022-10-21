pragma solidity ^0.5.0;

import './ERC20Interface.sol';
import './SafeMath.sol';
/**
 * @title SimpleTimelock
 * @dev SimpleTimelock is an ETH holder contract that will allow a
 * beneficiary to receive the ETH after a given release time.
 */
contract TokenTimeLock {

    using SafeMath for uint256;
    // beneficiary of ETH after it is released
    address public beneficiary;

    // start time of Locked Token
     uint256 startTime;

     uint256 counter; 
     
     address owner;
    
    //Release Amount
    uint256  releaseAmount;
    uint256 public totalTokenLocked;
    //Token initializer
    ERC20Interface token;
    
    constructor(address _owner)public{
        owner = _owner;
    }

    function lockedToken(address _beneficiary,  uint256 _amount, address _token) public {
        token = ERC20Interface(_token);
        require(msg.sender == owner, "Only owner locked token");
        require(beneficiary == address(0),"Already Add token by beneficiary");
        require(token.balanceOf(msg.sender) >= _amount, "You have not enough Balance to Loked");
       token.transferFrom(msg.sender, address(this), _amount);
        beneficiary = _beneficiary;
        startTime = block.timestamp;
        totalTokenLocked = _amount;

    }

    // transfers ETH held by timelock to beneficiary.
    function withdrawToken(uint256 _amount) public {
        //set only That benificiary will release token
        require(msg.sender == beneficiary, "Only benificiary can unlock token");
        if(block.timestamp > (counter.mul(30 days)).add(startTime) )
           counter++;
        uint256 amount = (token.balanceOf(address(this)));
        require(amount > 0, "no Token to release");

        require(releaseAmount.add(_amount) <= counter.mul(20950), "Not enough Balance left to Withdraw this month");
        releaseAmount = releaseAmount.add(_amount);

        token.transfer(beneficiary, _amount);
    }
    // Change Ownership Of Beneficiary
    function changeBeneficiary(address _beni) public {
        require(msg.sender == beneficiary,"Un authorize call only Beneficiary change Ownership");
        beneficiary = _beni;
    }
    
    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function tokenLeft() public view returns (uint256 balance) {
        require(msg.sender == owner ||msg.sender == beneficiary,"Only Owner or beneficiary Call");
        return  totalTokenLocked.sub(releaseAmount);
    }

}



