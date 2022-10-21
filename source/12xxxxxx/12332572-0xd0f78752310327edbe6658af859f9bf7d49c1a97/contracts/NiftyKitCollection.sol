//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NiftyKitCollection is ERC721, Ownable, AccessControl {
    using Counters for Counters.Counter;

    Counters.Counter private _ids;
    uint256 internal _commission = 0; // parts per 10,000

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        _;
    }

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setBaseURI("ipfs://");
    }

    function mint(address recipient, string memory tokenURI)
        public
        onlyAdmin
        returns (uint256)
    {
        _ids.increment();
        uint256 id = _ids.current();
        _mint(recipient, id);
        _setTokenURI(id, tokenURI);
        return id;
    }

    function burn(uint256 id) public onlyAdmin {
        _burn(id);
    }

    function transfer(
        address from,
        address to,
        uint256 tokenId
    ) public onlyAdmin {
        _transfer(from, to, tokenId);
    }

    function setCommission(uint256 commission) public onlyAdmin {
        _commission = commission;
    }

    function getCommission() public view returns (uint256) {
        return _commission;
    }
}

