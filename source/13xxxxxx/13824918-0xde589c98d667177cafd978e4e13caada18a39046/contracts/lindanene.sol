// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "./ERC1155Tradable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";

// ██╗    ██╗██╗  ██╗ ██████╗     ██╗███████╗    ▄▄███▄▄· █████╗ ███╗   ███╗ ██████╗ ████████╗    ██████╗
// ██║    ██║██║  ██║██╔═══██╗    ██║██╔════╝    ██╔════╝██╔══██╗████╗ ████║██╔═══██╗╚══██╔══╝    ╚════██╗
// ██║ █╗ ██║███████║██║   ██║    ██║███████╗    ███████╗███████║██╔████╔██║██║   ██║   ██║         ▄███╔╝
// ██║███╗██║██╔══██║██║   ██║    ██║╚════██║    ╚════██║██╔══██║██║╚██╔╝██║██║   ██║   ██║         ▀▀══╝
// ╚███╔███╔╝██║  ██║╚██████╔╝    ██║███████║    ███████║██║  ██║██║ ╚═╝ ██║╚██████╔╝   ██║         ██╗
//  ╚══╝╚══╝ ╚═╝  ╚═╝ ╚═════╝     ╚═╝╚══════╝    ╚═▀▀▀══╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝    ╚═╝         ╚═╝

/**
 * @title LindaNene
 * WhoIsSamot - an 1155 contract for LindaNene
 */
contract LindaNene is ERC1155Tradable {
    using SafeMath for uint256;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _proxyRegistryAddress
    ) ERC1155Tradable(_name, _symbol, _uri, _proxyRegistryAddress) {
        create(
            0x399Db9b924bC348BfC3bD777817631eb5A79b152,
            0,
            10,
            "https://samotclub.mypinata.cloud/ipfs/QmVmoX2JCnati7X8krPnM6A6gXab3efExqsN1P6mu5hyPU/1.json",
            ""
        );
    }

    function createId(
        address _creator,
        uint256 _id,
        uint256 _initialSupply,
        string memory _uri
    ) public onlyOwner {
        create(_creator, _id, _initialSupply, _uri, "");
    }

    function reserve(
        address account,
        uint256 _id,
        uint256 _quantity
    ) public onlyOwner {
        _mint(account, _id, _quantity, "");
        tokenSupply[_id] = tokenSupply[_id].add(_quantity);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}

