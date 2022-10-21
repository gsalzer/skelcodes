// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {BytesLib} from "./bytes.sol";
import "./ERC20.sol";

contract FTokenFactory {
    using BytesLib for bytes;

    FToken[] internal allContracts;

    function createContract(bytes memory raw, address receiver) public {
        uint256 offset;
        uint8 size;
        string memory name;
        string memory symbol;
        uint256 cap;
        while (offset < raw.length) {
            size = raw.toUint8(offset);
            offset = offset + 1;
            require(offset + size <= raw.length, "invalid data");
            name = string(raw.slice(offset, size));
            offset = offset + size;

            size = raw.toUint8(offset);
            offset = offset + 1;
            require(offset + size <= raw.length, "invalid data");
            symbol = string(raw.slice(offset, size));
            offset = offset + size;

            require(offset + 8 <= raw.length, "invalid data");
            cap = raw.toUint64(offset);
            offset = offset + 8;

            uint256 balance = cap * 10**18;
            FToken newContract = new FToken(
                name,
                symbol,
                balance,
                address(this)
            );
            allContracts.push(newContract);

            newContract.transfer(receiver, balance);
        }
    }
}

contract FToken is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 cap,
        address minter
    ) public ERC20(name, symbol) {
        // send all supply to minter
        _mint(minter, cap);
    }
}

