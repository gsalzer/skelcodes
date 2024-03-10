pragma solidity ^0.5.8;

contract IWithdraw {
    event WithdrawEvent(address indexed user, uint256 indexed amount, uint256 indexed nonce);
    event DrawEvent(address indexed user, uint256 indexed amount);

    function verifySign(uint256 amount, uint256 nonce, address userAddr, bytes memory signature) public view returns (bool);
    function withdraw(uint256 amount, uint256 nonce, bytes memory signature) public returns (bool);

}
