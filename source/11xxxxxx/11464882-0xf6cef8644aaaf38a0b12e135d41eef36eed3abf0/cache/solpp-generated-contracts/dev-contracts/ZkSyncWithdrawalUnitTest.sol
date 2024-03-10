pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: UNLICENSED




import "../ZkSync.sol";

contract ZkSyncWithdrawalUnitTest is ZkSync {
    function setBalanceToWithdraw(
        address _owner,
        uint16 _token,
        uint128 _amount
    ) external {
        balancesToWithdraw[packAddressAndTokenId(_owner, _token)].balanceToWithdraw = _amount;
    }

    function receiveETH() external payable {}

    function withdrawOrStoreExternal(
        uint16 _tokenId,
        address _recipient,
        uint128 _amount
    ) external {
        return withdrawOrStore(_tokenId, _recipient, _amount);
    }
}

