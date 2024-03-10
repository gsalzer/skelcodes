// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./FotToken.sol";
import "./StandardToken.sol";

contract CloneFactory {
    function createClone(address target)
        internal
        returns (address payable result)
    {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
    }

    function isClone(address target, address query)
        internal
        view
        returns (bool result)
    {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000
            )
            mstore(add(clone, 0xa), targetBytes)
            mstore(
                add(clone, 0x1e),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(
                eq(mload(clone), mload(other)),
                eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
            )
        }
    }
}

contract TokenFactory is CloneFactory {
    address payable private standardMasterContract;
    address payable private fotMasterContract;
    event FotTokenCreated(address id, string name, string symbol, uint256 basicSupply, string tokenType, address newTokenAddress);
    event StdTokenCreated(address id, string name, string symbol, uint256 basicSupply, string tokenType, bool isPool, address newTokenAddress);
    address payable public clone;
    constructor (address payable standardContractToClone, address payable fotContractToClone) {
        standardMasterContract = standardContractToClone;
        fotMasterContract = fotContractToClone;
    }
    function createToken(
        string memory name,
        string memory symbol,
        uint256 basicSupply,
        uint256 maxTxnAmount,
        uint256[4] memory fees,
        address charityAddress,
        address dexAddress
    ) public payable {
        clone = createClone(fotMasterContract);
        FotToken(clone).init(
            name,
            symbol,
            basicSupply,
            maxTxnAmount,
            fees,
            charityAddress,
            dexAddress,
            msg.sender
        );
        emit FotTokenCreated(msg.sender, name, symbol, basicSupply * (10**6), "fot",  clone);
    }

    function createStandardToken(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 tokenInitialAmount,
        bool isPool,
        address dexAddress
    ) public payable {
        clone = createClone(standardMasterContract);
        StandardToken(clone).init(
            tokenName,
            tokenSymbol,
            tokenInitialAmount,
            msg.sender,
            isPool,
            dexAddress
        );
        emit StdTokenCreated(msg.sender, tokenName, tokenSymbol, tokenInitialAmount, "standard", isPool,  clone);
    }
}

