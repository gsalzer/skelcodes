pragma solidity >=0.5.8 <0.7.0;

import "./MinimeToken.sol";
import "./Ownable.sol";


contract Distribution is Ownable {
    event EthSent(address indexed receiver, uint256 amount);
    event ERC20Sent(address indexed token, address indexed receiver, uint256 amount);

    constructor() public {}

    function () external payable {
    }

    function distributeEth(uint256 _amount, address payable[] memory _recipients) public onlyOwner {
        // note: can overflow, this is only a sanity check
        require(address(this).balance >= (_amount * _recipients.length), "must have enough ETH");
        require(_recipients.length < 255);

        for (uint8 i = 0; i < _recipients.length; i++) {
            address payable recipient = _recipients[i];
            // send ETH
            recipient.transfer(_amount);
            emit EthSent(recipient, _amount);
        }
    }

    function retrieveEth() public onlyOwner {
        owner().transfer(address(this).balance);
    }

    function distributeTokens(address _contract, uint256[] memory _amounts, address[] memory _recipients) public onlyOwner {
        ERC20 token = ERC20(_contract);

        // note: can overflow, this is only a sanity check
        require(_recipients.length < 255);
        require(_recipients.length == _amounts.length);

        for (uint8 i = 0; i < _recipients.length; i++) {
            address recipient = _recipients[i];
            uint256 amount = _amounts[i];
            // send tokens
            token.transfer(recipient, amount);
            emit ERC20Sent(_contract, recipient, amount);
        }
    }

    function retrieveTokens(address _contract) public onlyOwner {
        ERC20 token = ERC20(_contract);
        token.transfer(owner(), token.balanceOf(address(this)));
    }
}

