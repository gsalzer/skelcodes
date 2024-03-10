pragma solidity ^0.4.25;

import "./Ownalbe.sol";


contract Contracts is Ownable {
    uint private constant ETH_BASE_UINT = 1000000000000000000;

    // can accept token
    function() external payable {
    }

    //transfer token to owner
    function withdrawToOwner(uint payout) external onlyOwner {
        _owner.transfer(payout);
    }

    function kill() external onlyOwner {
        selfdestruct(owner());
    }

}

