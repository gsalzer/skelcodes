
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/community_interface.sol";

import "./bagobones.sol";
import "./pixiedust.sol";

import "hardhat/console.sol";


contract toddler_community is pixiedust, community_interface {
    using SafeMath for uint256;

    SkeletonCrew _token;

    uint256         constant    OMNIPILLAR    = 0;
    uint256         constant    TODDLERPILLAR = 1;
    uint256         constant    EGG_DWELLER   = 2;
    uint256 []                  allowances    = [8,6,2];

    // delays are 
    uint256 []                  before_presale = [48 hours,48 hours,24 hours];

    mapping (address => uint256) public override community_claimed;
    


    event CommunitySale(uint256 tokenCount,uint256 value, address buyer, uint256 role);
    event TestMode();

    constructor(SkeletonCrew token) {
        _token = token;
        uint256 id;
        assembly {
            id := chainid()
        }
        if (id == 4) {
            before_presale = [20 minutes,20 minutes,10 minutes];
            emit TestMode();
        } 
    }


    function _split(uint256 amount) internal { // duplicated to save an extra call
        bool sent;
        uint256 _total;
        for (uint256 j = 0; j < _wallets.length; j++) {
            uint256 _amount = amount * _shares[j] / 1000;
            if (j == _wallets.length-1) {
                _amount = amount - _total;
            } else {
                _total += _amount;
            }
            ( sent, ) = _wallets[j].call{value: _amount}(""); // don't use send or xfer (gas)
            require(sent, "Failed to send Ether");
        }
    }

    function omnipillars_active() external view returns (bool) {
        return block.timestamp >= (_presaleStart - before_presale[0]);
    }
    function toddlerpillars_active() external view returns (bool) {
        return block.timestamp >= (_presaleStart - before_presale[1]);
    }
    function early_adopters_active() external view returns (bool) {
        return block.timestamp >= (_presaleStart - before_presale[2]);
    }

    function communityPurchase(address recipient, uint256 tokenCount, bytes memory signature, uint256 role) external override payable {
        require(msg.sender == address(_token),"This can only be called from Skeletor contract");
        require(verify(recipient, signature, role), "Recipient is not on the Presale List");
        require(role < allowances.length, "Invalid ROLE");
        require(block.timestamp >= _presaleStart - before_presale[role],"Your sale is not open yet");
        require(block.timestamp <= _saleEnd,"Sale is over");
        uint256 this_taken = community_claimed[recipient] + tokenCount;

        require(this_taken <= allowances[role],"Too many tokens requested");
        require(msg.value >= tokenCount.mul(_communityPrice),"price not met");
        community_claimed[recipient] = this_taken;
        _token.mintCards(tokenCount, recipient);
        _split(msg.value);
        emit CommunitySale(tokenCount, msg.value, recipient, role);
    }

    function verify(address signedAddr, bytes memory signature, uint256 role) internal  pure returns (bool) {
        require(signedAddr != address(0), "INVALID_SIGNER");
        bytes32 hash = keccak256(abi.encode(signedAddr, role));

        
        require (signature.length == 65,"Invalid signature length");
        bytes32 sigR;
        bytes32 sigS;
        uint8   sigV;
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        assembly {
            sigR := mload(add(signature, 0x20))
            sigS := mload(add(signature, 0x40))
            sigV := byte(0, mload(add(signature, 0x60)))
        }

        bytes32 data =  keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        address recovered = ecrecover(
                data,
                sigV,
                sigR,
                sigS
            );
        
        
        return
            _signer == recovered;
    }

}
