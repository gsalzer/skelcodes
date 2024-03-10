pragma solidity ^0.5.0;

import "./Ownable.sol";
import "./IERC20.sol";


contract Exchange is Ownable {
    event Collect(address indexed from, uint256 amount, bytes32 desc);
    event Withdraw(address indexed from, address indexed to, uint256 amount, bytes32 desc);

    IERC20 public token;

    constructor (address token_) public {
        token = IERC20(token_);
    }

    function withdraw(address from, address to, uint256 amount, bytes32 desc) public onlyOwner {
        token.transfer(to, amount);
        emit Withdraw(from, to, amount, desc);
    }

    function collect(address from, uint256 amount, bytes32 desc) public {
        token.transferFrom(from, address(this), amount);
        emit Collect(from, amount, desc);
    }

    function batchCollect(address[] memory from, uint256[] memory amount, bytes32[] memory desc) public {
        require(from.length == amount.length && from.length == desc.length, "array length mismatch");

        for (uint256 i = 0; i < from.length; i++) {
            token.transferFrom(from[i], address(this), amount[i]);
            emit Collect(from[i], amount[i], desc[i]);
        }
    }
}

