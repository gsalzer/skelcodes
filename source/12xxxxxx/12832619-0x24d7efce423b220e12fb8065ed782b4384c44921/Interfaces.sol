// SPDX-License-Identifier: -- 💰️ --

pragma solidity ^0.8.0;

interface ITokenContract {

    function transfer(
        address _to,
        uint256 _value
    )
        external
        returns
    (
        bool success
    );

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        external
        returns
    (
        bool success
    );
}
