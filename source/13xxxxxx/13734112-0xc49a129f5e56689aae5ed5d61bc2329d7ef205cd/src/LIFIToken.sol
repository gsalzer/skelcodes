// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Standard ERC-20
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// Burnable Token
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
// ERC-2612/ERC-712 Permit
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
// ERC-165 Introspection
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
// ECDSA
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
// Access Control
import "@openzeppelin/contracts/access/AccessControl.sol";
// Recover tokens and ETH
import "./extensions/ERC20TokenRecover.sol";

interface ITransferReceiver {
    function onTokenTransfer(
        address,
        uint256,
        bytes calldata
    ) external returns (bool);
}

interface IApprovalReceiver {
    function onTokenApproval(
        address,
        uint256,
        bytes calldata
    ) external returns (bool);
}

contract LIFIToken is ERC20, ERC20Burnable, AccessControl, ERC20Permit, ERC20TokenRecover {
    using ECDSA for bytes32;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant TRANSFER_TYPEHASH =
        keccak256("Transfer(address owner,address to,uint256 value,uint256 nonce,uint256 deadline)");

    constructor(address owner) ERC20("LiFi Token", "LIFI") ERC20Permit("LiFi Token") ERC20TokenRecover(owner) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(MINTER_ROLE, owner);
    }

    //---- ERC20 Extras ----//

    function approveAndCall(
        address spender,
        uint256 value,
        bytes calldata data
    ) external returns (bool) {
        _approve(msg.sender, spender, value);
        return IApprovalReceiver(spender).onTokenApproval(msg.sender, value, data);
    }

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool) {
        _transfer(msg.sender, to, value);
        return ITransferReceiver(to).onTokenTransfer(msg.sender, value, data);
    }

    function transferWithPermit(
        address target,
        address to,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool) {
        require(block.timestamp <= deadline, "LIFI Token: Expired permit");

        bytes32 hashStruct = keccak256(abi.encode(TRANSFER_TYPEHASH, target, to, value, _useNonce(target), deadline));

        require(
            target == hashStruct.toEthSignedMessageHash().recover(v, r, s) || target == hashStruct.recover(v, r, s),
            "LIFI Token: Invalid Signature"
        );

        _transfer(msg.sender, to, value);

        return true;
    }

    //---- Cross-chain ----//

    event LogSwapin(bytes32 indexed txhash, address indexed account, uint256 amount);
    event LogSwapout(address indexed account, address indexed bindaddr, uint256 amount);

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyRole(MINTER_ROLE) returns (bool) {
        require(from != address(0), "LIFIToken: address(0x0)");
        _burn(from, amount);
        return true;
    }

    function Swapin(
        bytes32 txhash,
        address account,
        uint256 amount
    ) public onlyRole(MINTER_ROLE) returns (bool) {
        _mint(account, amount);
        emit LogSwapin(txhash, account, amount);
        return true;
    }

    function Swapout(uint256 amount, address bindaddr) public returns (bool) {
        require(bindaddr != address(0), "LIFIToken: address(0x0)");
        _burn(msg.sender, amount);
        emit LogSwapout(msg.sender, bindaddr, amount);
        return true;
    }
}

