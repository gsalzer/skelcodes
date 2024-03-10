pragma solidity ^0.4.24;

import "./Ownable.sol";

contract Whitelist is Ownable{

  // Whitelisted address
  mapping(address => bool) public whitelist;
  mapping(address => bool) public presalewhitelist;

  event AddedBeneficiary(address indexed _beneficiary);
  event AddedPresaleBeneficiary(address indexed _beneficiary);

  function isPresaleWhitelisted(address _beneficiary) public view returns (bool) {
    return (presalewhitelist[_beneficiary]);
  }

  function addManyToPresaleWhitelist(address[] _beneficiaries) public onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      presalewhitelist[_beneficiaries[i]] = true;
      emit AddedPresaleBeneficiary(_beneficiaries[i]);
    }
  }

  function removeFromPresaleWhitelist(address _beneficiary) public onlyOwner {
    presalewhitelist[_beneficiary] = false;
  }

  function addManyToWhitelist(address[] _beneficiaries) public onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
      emit AddedBeneficiary(_beneficiaries[i]);
    }
  }

  function removeFromWhitelist(address _beneficiary) public onlyOwner {
    whitelist[_beneficiary] = false;
  }

  function isWhitelisted(address _beneficiary) public view returns (bool) {
    return (whitelist[_beneficiary]);
  }

}

