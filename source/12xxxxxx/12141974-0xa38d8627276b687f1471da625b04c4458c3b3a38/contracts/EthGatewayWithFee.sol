// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IEthGateway.sol";

contract EthGatewayWithFee is Ownable {
    IERC20 public immutable token;
    IEthGateway public immutable gateway;
    uint256 public fee;

    event TransferredToSmartChain(address from, uint256 amount, uint256 fee);
    event FeeUpdated(uint256 newFee);

    constructor(IERC20 _token, IEthGateway _gateway, uint256 _fee) {
        token = _token;
        gateway = _gateway;
        fee = _fee;
    }

    function transferToSmartChain(uint256 amount) payable public {
        // collect fee
        require(msg.value == fee, "EthGatewayWithFee: Wrong fee value");
        payable(owner()).transfer(msg.value);

        // send tokens to gateway
        token.transferFrom(msg.sender, address(this), amount);
        token.approve(address(gateway), amount);
        gateway.transferToSmartChain(amount);

        // emit event
        emit TransferredToSmartChain(msg.sender, amount, fee);
    }

    function updateFee(uint256 _fee) public onlyOwner {
        fee = _fee;
        emit FeeUpdated(fee);
    }
}
