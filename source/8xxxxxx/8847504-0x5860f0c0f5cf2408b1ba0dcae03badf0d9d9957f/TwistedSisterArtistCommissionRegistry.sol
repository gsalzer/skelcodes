/**
Author: Blockrocket.tech.

*/

pragma solidity ^0.5.12;


library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        
        
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract ITwistedSisterArtistCommissionRegistry {
    function getCommissionSplits() external view returns (uint256[] memory _percentages, address payable[] memory _artists);
    function getMaxCommission() external view returns (uint256);
}

contract ITwistedSisterAccessControls {
    function isWhitelisted(address account) public view returns (bool);

    function isWhitelistAdmin(address account) public view returns (bool);
}

contract TwistedSisterArtistCommissionRegistry is ITwistedSisterArtistCommissionRegistry {
    using SafeMath for uint256;

    ITwistedSisterAccessControls public accessControls;

    address payable[] public artists;

    uint256 public maxCommission = 10000;

    
    mapping(address => uint256) public artistCommissionSplit;

    modifier isWhitelisted() {
        require(accessControls.isWhitelisted(msg.sender), "Caller not whitelisted");
        _;
    }

    constructor(ITwistedSisterAccessControls _accessControls) public {
        accessControls = _accessControls;
    }

    function setCommissionSplits(uint256[] calldata _percentages, address payable[] calldata _artists) external isWhitelisted returns (bool) {
        require(_percentages.length == _artists.length, "Differing percentage or recipient sizes");

        
        for(uint256 i = 0; i < artists.length; i++) {
            address payable artist = artists[i];
            delete artistCommissionSplit[artist];
            delete artists[i];
        }
        artists.length = 0;

        uint256 total;

        for(uint256 i = 0; i < _artists.length; i++) {
            address payable artist = _artists[i];
            require(artist != address(0x0), "Invalid address");
            artists.push(artist);
            artistCommissionSplit[artist] = _percentages[i];
            total = total.add(_percentages[i]);
        }

        require(total == maxCommission, "Total commission does not match allowance");

        return true;
    }

    function getCommissionSplits() external view returns (uint256[] memory _percentages, address payable[] memory _artists) {
        require(artists.length > 0, "No artists have been registered");
        _percentages = new uint256[](artists.length);
        _artists = new address payable[](artists.length);

        for(uint256 i = 0; i < artists.length; i++) {
            address payable artist = artists[i];
            _percentages[i] = artistCommissionSplit[artist];
            _artists[i] = artist;
        }
    }

    function getMaxCommission() external view returns (uint256) {
        return maxCommission;
    }
}
