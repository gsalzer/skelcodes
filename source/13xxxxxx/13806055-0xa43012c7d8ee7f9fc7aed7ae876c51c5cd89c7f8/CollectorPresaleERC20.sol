// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./IGenArt721CoreV2.sol";

contract CollectorPresaleERC20 is ERC20 {
    using SafeMath for uint256;

    IGenArt721CoreV2 genArtCoreContract;

    string public name;
    string public symbol;

    event Mint(uint256 amount);
    event Burn(uint256 amount);

    modifier onlyGenArtWhitelist() {
        require(genArtCoreContract.isWhitelisted(msg.sender), "only gen art whitelisted");
        _;
    }

    constructor(
        address genArtCoreAddress,
        string memory _name,
        string memory _symbol,
        uint256 initialAmount
    ) ERC20() public {
        name = _name;
        symbol = _symbol;
        genArtCoreContract = IGenArt721CoreV2(genArtCoreAddress);
        require(genArtCoreContract.isWhitelisted(msg.sender), "only gen art whitelisted");
        _mint(msg.sender, initialAmount);
    }

    function burn(uint256 amount) public onlyGenArtWhitelist {
        _burn(msg.sender, amount);
        emit Burn(amount);
    }

    function mint(uint256 amount) public onlyGenArtWhitelist {
        _mint(msg.sender, amount);
        emit Mint(amount);
    }

}

