// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './interfaces/IBridgePool.sol';

contract BridgePool is IBridgePool {

    address public owner;

    /*
      operator modes:
        1 - contract:creator
        2 - contract:withdrawer
        4 - withdrawer
        8 - taker
    */
    mapping(address => uint8) public operator;
    mapping(bytes32 => bool) public withdrawn;

    bool private entered = false;
    modifier nonReentrant() {
        require(!entered, 'reentrant call');
        entered = true;
        _;
        entered = false;
    }

    constructor () {
        owner = tx.origin;
    }

    function setOwner(address newOwner) external {
        require(msg.sender == owner, 'forbidden');
        owner = newOwner;
    }

    function setOperatorMode(address account, uint8 mode) external {
        require(msg.sender == owner, 'forbidden');
        operator[account] = mode;
    }

    function deposit(IERC20 token, uint amount, uint8 to, bool bonus, bytes calldata recipient) override external payable nonReentrant() {
        // allowed only direct call or 'contract:creator' or 'contract:withdrawer'
        require(tx.origin == msg.sender || (operator[msg.sender] & (1 | 2) > 0), 'call from unauthorized contract');
        require(address(token) != address(0) && amount > 0 && recipient.length > 0, 'invalid input');

        if (address(token) == address(1)) {
            require(amount == msg.value, 'value must equal amount');
        } else {
            safeTransferFrom(token, msg.sender, address(this), amount);
        }

        emit Deposited(msg.sender, address(token), to, amount, bonus, recipient);
    }

    function withdraw(Withdraw[] memory ws) override external nonReentrant() {
        // allowed only 'withdrawer' or 'withdrawer' through 'contract:withdrawer'
        require(operator[msg.sender] == 4 || (operator[tx.origin] == 4 && operator[msg.sender] == 2), 'forbidden');

        for (uint i = 0; i < ws.length; i++) {
            Withdraw memory w = ws[i];

            require(!withdrawn[w.id], 'already withdrawn');
            withdrawn[w.id] = true;

            if (address(w.token) == address(1)) {
                require(address(this).balance >= w.amount + w.bonus, 'too low token balance');
                (bool success, ) = w.recipient.call{value: w.amount}('');
                require(success, 'native transfer error');
            } else {
                require(
                    w.token.balanceOf(address(this)) >= w.amount && address(this).balance >= w.bonus,
                    'too low token balance'
                );
                safeTransfer(w.token, w.recipient, w.amount);
            }

            if (w.bonus > 0) {
                // may fail on contracts
                w.recipient.call{value: w.bonus}('');
            }

            emit Withdrawn(w.id, address(w.token), w.recipient, w.amount);
        }
    }

    function take(IERC20 token, uint amount, address payable to) external override nonReentrant() {
        // allowed only 'taker'
        require(operator[msg.sender] == 8, 'forbidden');
        if (address(token) == address(1)) {
            to.transfer(amount);
        } else {
            safeTransfer(token, to, amount);
        }
    }

    receive() external payable {}

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(token.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'transfer failed');
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'transfer failed');
    }
}

