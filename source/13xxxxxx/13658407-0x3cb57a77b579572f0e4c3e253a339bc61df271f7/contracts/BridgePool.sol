// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IBridgePool.sol";

contract BridgePool is AccessControl, ReentrancyGuard, Multicall, EIP712, IBridgePool {
    using SafeERC20 for ERC20;

    mapping(bytes32 => bool) private withdrawn;

    bytes32 public constant AUTHORITY_ROLE = keccak256("AUTHORITY_ROLE");
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
    bytes32 public constant WITHDRAW_TYPEHASH = keccak256("Withdraw(bytes32 idHash,address token,uint256 amount,uint256 bonus,address receiver)");

    event Deposit(address indexed sender, address indexed token, uint8 indexed to, uint amount, bool bonus, bytes receiver);
    event Withdraw(bytes indexed id, address indexed token, address indexed receiver, uint amount);

    modifier markWithdrawn(bytes calldata id) {
        bytes32 key = keccak256(id);
        require(!withdrawn[key], "already withdrawn");
        _;
        withdrawn[key] = true;
    }

    constructor () EIP712("BridgePool", "1") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function isWithdrawn(bytes calldata id) external view returns (bool) {
        return withdrawn[keccak256(id)];
    }

    function deposit(
        ERC20 token,
        uint amount,
        uint8 to,
        bool bonus,
        bytes calldata receiver
    ) override external payable nonReentrant() {
        require(address(token) != address(0) && amount > 0 && receiver.length >= 20, "invalid input");
        require(!Address.isContract(msg.sender) || hasRole(CREATOR_ROLE, msg.sender), "call from unauthorized contract");

        if (address(token) == address(1)) {
            require(amount == msg.value, "value must equal amount");
        } else {
            token.safeTransferFrom(msg.sender, address(this), amount);
        }

        emit Deposit(msg.sender, address(token), to, amount, bonus, receiver);
    }

    function withdraw(
        bytes calldata id,
        ERC20 token,
        uint amount,
        uint bonus,
        address payable receiver,
        bytes calldata signature
    ) override external nonReentrant() markWithdrawn(id) {
        if (signature.length == 0) {
            require(hasRole(AUTHORITY_ROLE, msg.sender), "forbidden");
        } else {
            bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(WITHDRAW_TYPEHASH, keccak256(id), token, amount, bonus, receiver)));
            require(hasRole(AUTHORITY_ROLE, ECDSA.recover(digest, signature)), "forbidden or invalid signature");
        }

        if (address(token) == address(1)) {
            require(address(this).balance >= amount, "too low token balance");
            (bool success, ) = receiver.call{value: amount}("");
            require(success, "native transfer error");
        } else {
            require(token.balanceOf(address(this)) >= amount, "too low token balance");
            token.safeTransfer(receiver, amount);
        }

        if (bonus > 0) {
            // may fail on contracts
            receiver.call{value: bonus}("");
        }

        emit Withdraw(id, address(token), receiver, amount);
    }

    function take(
        ERC20 token,
        uint amount,
        address payable to
    ) external override nonReentrant() onlyRole(AUTHORITY_ROLE) {
        if (address(token) == address(1)) {
            to.transfer(amount);
        } else {
            token.safeTransfer(to, amount);
        }
    }

    receive() external payable {}
}

