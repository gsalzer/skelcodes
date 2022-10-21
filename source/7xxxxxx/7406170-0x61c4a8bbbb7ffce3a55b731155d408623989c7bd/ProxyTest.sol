pragma solidity ^0.5.0;


contract ProxyTest {

    event ETHSent(uint amt);

    function sendETH() public payable {
        address(msg.sender).transfer(msg.value);
        emit ETHSent(msg.value);
    }

}
