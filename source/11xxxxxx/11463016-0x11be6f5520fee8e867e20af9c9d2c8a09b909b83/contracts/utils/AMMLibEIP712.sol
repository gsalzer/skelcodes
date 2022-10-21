/**
 * Copyright 2018 ZeroEx Intl.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *   http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
pragma solidity ^0.6.0;

contract AMMLibEIP712 {
    /***********************************|
    |             Constants             |
    |__________________________________*/

    // EIP-191 Header
    string public constant EIP191_HEADER = "\x19\x01";

    // EIP712Domain
    string public constant EIP712_DOMAIN_NAME = "Tokenlon";
    string public constant EIP712_DOMAIN_VERSION = "v5";

    // EIP712Domain Separator
    bytes32 public immutable EIP712_DOMAIN_SEPARATOR = keccak256(
        abi.encode(
            keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
            keccak256(bytes(EIP712_DOMAIN_NAME)),
            keccak256(bytes(EIP712_DOMAIN_VERSION)),
            getChainID(),
            address(this)
        )
    );

    // keccak256("tradeWithPermit(address makerAddr,address takerAssetAddr,address makerAssetAddr,uint256 takerAssetAmount,uint256 makerAssetAmount,address userAddr,address receiverAddr,uint256 salt,uint256 deadline)");
    bytes32 public constant TRADE_WITH_PERMIT_TYPEHASH = keccak256(
        abi.encodePacked(
            "tradeWithPermit(",
            "address makerAddr,",
            "address takerAssetAddr,",
            "address makerAssetAddr,",
            "uint256 takerAssetAmount,",
            "uint256 makerAssetAmount,",
            "address userAddr,",
            "address receiverAddr,",
            "uint256 salt,",
            "uint256 deadline",
            ")"
        )
    );
    
    /**
        * @dev Return `chainId`
        */
    function getChainID() internal pure returns (uint) {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}
