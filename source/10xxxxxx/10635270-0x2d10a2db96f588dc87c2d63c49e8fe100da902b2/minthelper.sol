pragma solidity ^0.4.26;
// Minthelper contract customized for solo mining in COSMiC
//
// THANKS:
//  - Original `Minthelper` contract by Mikers (https://github.com/snissn)
//  - additional Thanks to 0x1d00ffff (https://github.com/0x1d00ffff)
//

library SafeMath
{
    
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }

}

contract Ownable
{
  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
    constructor() public
    {
        owner = msg.sender;
    }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public
  {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
    
  }

}


contract ERC20Interface
{
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ERC918Interface
{
  function totalSupply() public constant returns (uint);
  function getMiningDifficulty() public constant returns (uint);
  function getMiningTarget() public constant returns (uint);
  function getMiningReward() public constant returns (uint);
  function balanceOf(address tokenOwner) public constant returns (uint balance);
  function merge() public returns (bool success);
// uint public lastRewardAmount;

  function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success);

  event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);

}

/*
The owner (or anyone) will deposit tokens in here
The owner calls the multisend method to send out payments
*/
contract MintHelper is Ownable {

  using SafeMath for uint;

//  address public mintableToken;
    address public payoutsWallet;
    address public minterWallet;

//  uint public minterFeePercent;


    constructor(address pWallet, address mWallet) public
    {
      payoutsWallet = pWallet;
      minterWallet = mWallet;
//    minterFeePercent = 2;
    }
    
/*
function setPayoutsWallet(address pWallet)
    public onlyOwner
    returns (bool)
    {
      payoutsWallet = pWallet;
      return true;
    }
*/

/*
    function setMinterWallet(address mWallet)
    public onlyOwner
    returns (bool)
    {
      minterWallet = mWallet;
      return true;
    }
*/

    function proxyMint( uint256 nonce, bytes32 challenge_digest, address mintableToken )
    public /* onlyOwner */
    returns (bool)
    {
      //identify the rewards that will be won and how to split them up
      //uint donatePercent = 2;
      uint totalReward = ERC918Interface(mintableToken).getMiningReward();      // get current reward in tokens
      
      //uint minterReward = totalReward.mul(donatePercent).div(100);          // developer gets 2% auto-donation
      uint minterReward = totalReward.mul(2).div(100);
      
      uint payoutReward = totalReward.sub(minterReward);                    // the miner gets 98% !

      // call mint() in selected erc918 token contract with solution nonce and its keccak256 digest. get paid in new tokens.
      require(ERC918Interface(mintableToken).mint(nonce, challenge_digest ));

      //transfer the tokens to the correct wallets.
      require(ERC20Interface(mintableToken).transfer(minterWallet, minterReward));
      require(ERC20Interface(mintableToken).transfer(payoutsWallet, payoutReward));

      return true;
    }

    //withdraw any eth inside
    function withdraw()
    public onlyOwner
    {
        msg.sender.transfer(address(this).balance);      
    }

    //send tokens out
    function send(address _tokenAddr, address dest, uint value)
    public onlyOwner
    returns (bool)
    {
        return ERC20Interface(_tokenAddr).transfer(dest, value);
    }

}

