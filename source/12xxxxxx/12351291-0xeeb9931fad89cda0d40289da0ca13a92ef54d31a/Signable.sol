// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
 * @title Signable
 * @version 1.0.0
 * @author Francesco Sullo <francesco@sullo.co>
 * @dev Manages identities
 */

import "./Ownable.sol";
import "./ECDSA.sol";

contract Signable is Ownable {

    using ECDSA for bytes32;

    event OracleUpdated(
        address _oracle
    );

    address public oracle;

    constructor(
        address _oracle
    )
    {
        oracle = _oracle;
    }

    function updateOracle(
        address _oracle
    ) external
    onlyOwner
    {
        oracle = _oracle;
        emit OracleUpdated(_oracle);
    }

    function isSignedByOracle(
        bytes32 _hash,
        bytes memory _signature
    ) public view
    returns (bool)
    {
        return oracle == ECDSA.recover(_hash, _signature);
    }

}

