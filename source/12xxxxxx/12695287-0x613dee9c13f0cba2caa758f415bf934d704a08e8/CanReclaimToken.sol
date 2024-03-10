pragma solidity ^0.7.0;



import "./ERC20If.sol";
import "./OwnableIf.sol";

/// @title CanReclaimToken
abstract contract CanReclaimToken is OwnableIf {

    function reclaimToken(ERC20If _token) external onlyOwner {
        uint256 balance = _token.balanceOf((address)(this));
        require(_token.transfer(_owner(), balance));
    }

}


