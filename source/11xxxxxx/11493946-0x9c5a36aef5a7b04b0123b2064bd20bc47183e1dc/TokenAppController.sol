// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./Ownable.sol";
import "./ITokenManager.sol";

contract TokenAppController is Ownable {
    ITokenManager public tokenManager;
    address public tokenManagerAddr;

    function initTAC() internal {
        initOwnable();
    }

    function setTokenManager(address tokenManagerAddress) internal onlyOwner {
        tokenManagerAddr = tokenManagerAddress;
        tokenManager = ITokenManager(tokenManagerAddr);
    }

    function callMint(address _receiver, uint256 _amount) internal onlyOwner {
        tokenManager.mint(_receiver, _amount);
    }

    function callIssue(uint256 _amount) internal onlyOwner {
        tokenManager.issue(_amount);
    }

    function callAssign(address _receiver, uint256 _amount) internal onlyOwner {
        tokenManager.assign(_receiver, _amount);
    }

    function callBurn(address _holder, uint256 _amount) internal onlyOwner {
        tokenManager.burn(_holder, _amount);
    }

    function callAssignVested(
        address _receiver,
        uint256 _amount,
        uint64 _start,
        uint64 _cliff,
        uint64 _vested,
        bool _revokable
    ) internal returns (uint256) {
        return
            tokenManager.assignVested(
                _receiver,
                _amount,
                _start,
                _cliff,
                _vested,
                _revokable
            );
    }

    function callRevokeVesting(address _holder, uint256 _vestingId)
        internal
        onlyOwner
    {
        tokenManager.revokeVesting(_holder, _vestingId);
    }

}

