pragma solidity ^0.6.0;

import "./IERC20.sol";

contract BatchSend {
    address payable owner = 0xcDd02Efb201A94D5226B09752f7396669cfbaB15;
    
   modifier isOwner() {
        require(
            msg.sender == owner,
            "x_X"
        );
        _;
    }
    
    modifier isParamsLengthMatch(address[] memory tokens, address[] memory dests, uint[] memory amounts) {
        require(
            tokens.length == dests.length && tokens.length == amounts.length,
            "Token, destination or amount length mismatch"
        );
        _;
    }

    function sendTokens(address[] memory tokens, address[] memory dests, uint[] memory amounts) public isParamsLengthMatch(tokens, dests, amounts) isOwner {
        for (uint i=0; i<tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);
            token.transfer(dests[i], amounts[i]);
        }
    }
    
    function withdrawEth() public isOwner {
        uint balance = address(this).balance;
        owner.transfer(balance);
    }
    
    receive() external payable{}
}

