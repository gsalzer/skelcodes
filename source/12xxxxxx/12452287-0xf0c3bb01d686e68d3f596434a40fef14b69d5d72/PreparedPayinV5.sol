// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

contract PreparedPayinV5 {
    address private factory;

    constructor() {
        factory = msg.sender;
    }

    fallback() external {
        require(msg.sender == factory);

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, 0x64)

            let result := call(
                gas(),
                mload(add(ptr, 0x44)),
                0,
                ptr,
                0x44,
                0,
                0
            )

            if iszero(result) { revert(0, 0) }
        }
    }
}

