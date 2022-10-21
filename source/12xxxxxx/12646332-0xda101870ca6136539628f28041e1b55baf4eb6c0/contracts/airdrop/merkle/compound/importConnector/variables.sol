pragma solidity ^0.7.0;

import { InstaCompoundMerkleInterface } from "./interfaces.sol";

abstract contract Variables {
    /**
     * @dev Insta Compound Merkle
     */
    InstaCompoundMerkleInterface immutable internal instaCompoundMerkle;

    constructor(address _instaCompoundMerkle) {
        instaCompoundMerkle = InstaCompoundMerkleInterface(_instaCompoundMerkle);
    }
}

