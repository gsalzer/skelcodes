// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";
contract Ownable {
    using SafeMath for uint256;
    
    address public mintAccessor = 0x8ee4ab8b16472eB836Aae484B2C8A642334d3c6e;
    address public mintDest = 0x00c06b1ce2FCA0fB76B1Da089894978CfbCc6E8D;
    address public mintAccessorChanger = 0xF96EEC085534DAfB6069B24C9464D89DCE4Eb888;
    address public mintDestChanger = 0xa5537E58488440A73f6b7958b321bBdDe9af4B59;
    
    event MintAccessorChanged (address indexed from, address indexed to);
    event MintDestChanged (address indexed from, address indexed to);
    event MintAccessorChangerChanged (address indexed from, address indexed to);
    event MintDestChangerChanged (address indexed from, address indexed to);
    
    /**
    * change destination of mint address
    */
    function changeMintDestAddress(address addr) public{
        require(msg.sender == mintDestChanger);
        emit MintDestChanged(mintDest, addr);
        mintDest = addr;
    }
    
    /**
    * change the mint destination changer
    */
    function changeMintDestChangerAddress(address addr) public{
        require(msg.sender == mintDestChanger);
        emit MintDestChangerChanged(mintDestChanger, addr);
        mintDestChanger = addr;
    }
    
     /**
    * change the mint accessor changer
    */
    function changeMintAccessorChanger(address addr) public{
        require(msg.sender == mintAccessorChanger);
        emit MintAccessorChangerChanged(mintAccessorChanger, addr);
        mintAccessorChanger = addr;
    }
    
     /**
    * change accessor of mint function
    */
    function changeMintAccessorAddress(address addr) public{
        require(msg.sender == mintAccessorChanger);
        emit MintAccessorChanged(mintAccessor, addr);
        mintAccessor = addr;
    }
}


