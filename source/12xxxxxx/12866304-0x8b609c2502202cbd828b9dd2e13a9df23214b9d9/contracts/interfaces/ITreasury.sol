// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./bloq/IAddressList.sol";

interface ITreasury {
    function withdraw(address _token, uint256 _amount) external;

    function withdraw(
        address _token,
        uint256 _amount,
        address _tokenReceiver
    ) external;

    function withdrawable(address _token) external view returns (uint256);

    function whitelistedTokens() external view returns (IAddressList);

    function vusd() external view returns (address);
}

