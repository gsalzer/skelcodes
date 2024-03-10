pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WalleBot {
  event TransferSuccess(IERC20 token);
  event OwnerAdded(address owner);
  event OwnerRemoved(address owner);

  address[4] _owners;

	constructor() public {
    _owners[0] = msg.sender;
	}

  modifier onlyOwner() {
      require(isOwner(), "Ownable: caller is not the owner");
      _;
  }

  function isOwner() public view returns (bool) {
      return isOwnerForAddress(msg.sender);
  }

  function isOwnerForAddress(address addr) public view returns (bool) {
      if (addr == address(0)) {
        return false;
      }
      for (uint i = 0; i < _owners.length; i++) {
        if (addr == _owners[i]) {
          return true;
        }
      }
      return false;
  }

  function owners() public view returns (address[4] memory) {
    return _owners;
  }

  function setOwner(uint index, address addr) public onlyOwner {
    require(index < 4, "invalid index!");
    address oldAddr = _owners[index];
    _owners[index] = addr;
    if (oldAddr != address(0)) {
      emit OwnerRemoved(oldAddr);
    }
    emit OwnerAdded(addr);
  }


  function removeOwner(uint index) public onlyOwner {
    require(index < 4, "invalid index!");
    address addr = _owners[index];
    _owners[index] = address(0);
    emit OwnerRemoved(addr);
  }

	function batchSend(IERC20 token, address[] memory receiver, uint[] memory amounts) public onlyOwner returns(bool sufficient) {
    require(receiver.length == amounts.length, "WalleBot: address should match amounts");
    for (uint i = 0; i < receiver.length; i++) {
      require(token.transfer(receiver[i], amounts[i]), "WalleBot: transfer failed");
    }
    emit TransferSuccess(token);
		return true;
	}

	function getBalance(IERC20 token) public view returns(uint) {
		return token.balanceOf(address(this));
	}

  function withdraw(IERC20 token) public onlyOwner returns (bool) {
    token.transfer(msg.sender, token.balanceOf(address(this)));
    return true;
  }
}

