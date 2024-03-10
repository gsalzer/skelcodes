pragma solidity ^0.4.18;

import "./Ownable.sol";
import "./CoinBase.sol";
import "./TheValentineCoinBase.sol";


contract TheValentineCoinAdministration is TheValentineCoinBase {
  bool public reservationActive;

  function TheValentineCoinAdministration() public {
    reservationActive = true;
  }

  // Administration: emergencyCoinErasure(uint256 coinId, string erasureReason) public onlyOwner
  function emergencyCoinErasure(uint256 coinId, string erasureReason) public onlyOwner {
    require(bytes(engravings[coinId]).length != 0);
    engravings[coinId] = erasureReason;
  }

  // Administration: sendMoneyToScript() public onlyOwner
  function sendMoneyToScript() public onlyOwner {
    require(scriptAddress != address(0));
    require(this.balance >= 33 finney);
    scriptAddress.transfer(33 finney);
  }

  // Administration: toggleReservationState() public onlyOwnerOrScript
  function toggleReservationState() public onlyOwnerOrScript {
    reservationActive = !reservationActive;
  }

  // Administration: withdrawFunds() public onlyOwner
  function withdrawFunds() public onlyOwner {
    owner.transfer(this.balance);
  }
}

