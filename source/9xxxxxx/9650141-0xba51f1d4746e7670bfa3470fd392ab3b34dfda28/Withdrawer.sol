pragma solidity 0.5.11;

contract Withdrawer {

    address payable constant internal HOT_WALLET = 0xe3229A304165341EdFa7dd078030b13F87cA65E4; // for tests: 0xF33FEBF3069984bf26FfA9bf92097174DeD1DeeE

    event ETHWithdrawal(uint256);

    constructor() public {
        uint256 balanceETH = address(this).balance;
        emit ETHWithdrawal(balanceETH);
        selfdestruct(HOT_WALLET);
    }
}

