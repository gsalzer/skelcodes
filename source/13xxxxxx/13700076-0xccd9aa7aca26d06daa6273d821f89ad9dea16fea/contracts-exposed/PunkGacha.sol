// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/PunkGacha.sol";

contract XPunkGacha is PunkGacha {
    constructor(address vrfCoordinator, address link, bytes32 keyHash, uint256 fee, address cryptopunks) PunkGacha(vrfCoordinator, link, keyHash, fee, cryptopunks) {}

    function xfulfillRandomness(bytes32 arg0,uint256 randomness) external {
        return super.fulfillRandomness(arg0,randomness);
    }

    function xrequestRandomness(bytes32 _keyHash,uint256 _fee) external returns (bytes32) {
        return super.requestRandomness(_keyHash,_fee);
    }

    function xmakeVRFInputSeed(bytes32 _keyHash,uint256 _userSeed,address _requester,uint256 _nonce) external pure returns (uint256) {
        return super.makeVRFInputSeed(_keyHash,_userSeed,_requester,_nonce);
    }

    function xmakeRequestId(bytes32 _keyHash,uint256 _vRFInputSeed) external pure returns (bytes32) {
        return super.makeRequestId(_keyHash,_vRFInputSeed);
    }

    function x_stake(GachaState.Chip calldata chip) external {
        return super._stake(chip);
    }

    function x_refund(address sender,uint256[] calldata chipIndexes) external returns (uint256) {
        return super._refund(sender,chipIndexes);
    }

    function x_pick(uint256 randomness) external view returns (address) {
        return super._pick(randomness);
    }

    function x_reset() external {
        return super._reset();
    }

    function x_checkMaintainSegment(uint256 offset) external view returns (bool) {
        return super._checkMaintainSegment(offset);
    }

    function x_performMaintainSegment() external {
        return super._performMaintainSegment();
    }

    function x_transferOwnership(address newOwner) external {
        return super._transferOwnership(newOwner);
    }

    function x_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function x_msgData() external view returns (bytes memory) {
        return super._msgData();
    }
}

