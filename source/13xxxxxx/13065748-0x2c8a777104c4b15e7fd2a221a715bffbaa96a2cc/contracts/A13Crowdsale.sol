pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract A13Crowdsale {
  using SafeMath for uint256;

  address public owner;
  address public contractAddress;
  ERC20 public tokenToBuy;

  constructor () {
    require(msg.sender != address(0));

    owner = msg.sender;
    tokenToBuy = ERC20(address(0));
    contractAddress = address(this);
  }

  modifier onlyOwner {
    require(msg.sender == owner, "Only the owner can call this function.");
    _;
  }

  function getOwner() public view returns (address) {
    return owner;
  }

  function setTokenToBuy (address _token) public onlyOwner {
    require(tokenToBuy == ERC20(address(0)), "ERC20 cannot be set more than once.");
    tokenToBuy = ERC20(_token);
  }

  function getPricePerToken() public pure returns (uint256) {
      // this is 2 decimals over from ETH's placement
      // basically, if rate is 1, then the price per token will be 0.01ETH which is the intention
      return 10 ** 16;
  }

  function buyA13TokenInWholeUnits(uint256 numberOfTokens) public payable {
    require(tokenToBuy != ERC20(address(0)), "ERC20 token variable not set.");
    require(msg.value > 0, "Cannot send 0 Ether.");
    require(numberOfTokens > 0, "It would waste gas to try and buy 0 tokens.");
    require(numberOfTokens <= tokenToBuy.balanceOf(contractAddress), "Cannot buy more tokens than contract holds.");
    require(SafeMath.mul(getPricePerToken(), numberOfTokens) == msg.value, "Incorrect amount of Ether sent.");

    // Send A13 tokens to the caller of the function
    tokenToBuy.transfer(msg.sender, numberOfTokens);
  }

  function getBalanceOfToken() public view returns (uint) {
    return tokenToBuy.balanceOf(contractAddress);
  }

  function getBalanceOfETH() public view returns (uint) {
    return contractAddress.balance;
  }

  function withdrawERC20Tokens(address _token) onlyOwner public {
    ERC20(_token).transfer(msg.sender, ERC20(_token).balanceOf(contractAddress));
  }

  function withdrawA13Tokens(uint _amount) onlyOwner public {
    require(tokenToBuy != ERC20(address(0)), "ERC20 token variable not set.");
    tokenToBuy.transfer(msg.sender, _amount);
  }

  function withdrawAllA13Tokens() onlyOwner public {
    require(tokenToBuy != ERC20(address(0)), "ERC20 token variable not set.");
    tokenToBuy.transfer(msg.sender, ERC20(tokenToBuy).balanceOf(contractAddress));
  }

  function withdrawEther() onlyOwner public {
    payable(msg.sender).transfer(contractAddress.balance);
  }

}

