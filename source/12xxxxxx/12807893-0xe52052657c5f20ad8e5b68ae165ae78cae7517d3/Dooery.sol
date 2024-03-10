// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.8.5;
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721.sol";

contract Dooery is Ownable { 

    using SafeMath for uint256;

    struct Doo {
        uint256 dooId;
    }

    Doo[] public doos;
    string internal baseTokenURI = 'https://shibahybrids.com/api/v1/';

    mapping (uint256 => address) public dooToOwner;
    mapping (address => uint256) ownerDooCount;

    modifier onlyOwnerOf(uint _dooId) {
        require(msg.sender == dooToOwner[_dooId]);
        _;
    }
}
