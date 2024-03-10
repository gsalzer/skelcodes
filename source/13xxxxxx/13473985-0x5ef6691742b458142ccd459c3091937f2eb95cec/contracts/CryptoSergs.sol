pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IMinter.sol";


contract CryptoSergs is ERC721, Ownable {
	using ECDSA for bytes32;
	using SafeMath for uint256;

	IMinter public sergsMinter;
	
    string private baseURI;

	// Events
    constructor(string memory _baseURI, address _minter) ERC721("CryptoSergs","CSERGS") {
		setBaseURI(_baseURI);
		sergsMinter = IMinter(_minter);
	}

	function migrate(address _to, uint256 _tokenId) external{
        require(msg.sender == address(sergsMinter), "Can't call this");
        _mint(_to, _tokenId);
    }

    function setMinter(address _minter) public onlyOwner {
		sergsMinter = IMinter(_minter);
	}

	function setBaseURI(string memory newURI) public onlyOwner {
		baseURI = newURI;
	}

	function tokenURI(uint256 _tokenId) override public view returns (string memory) {
		return string(abi.encodePacked(baseURI, uint2str(_tokenId)));
    }

	function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function baseTokenURI() private view returns (string memory) {
        return baseURI;
    }

	function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return "0";
		}
		uint256 j = _i;
		uint256 len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint256 k = len;
		while (_i != 0) {
			k = k - 1;
			uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}

}
