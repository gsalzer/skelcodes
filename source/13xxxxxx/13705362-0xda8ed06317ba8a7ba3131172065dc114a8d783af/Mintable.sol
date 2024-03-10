// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IMintable.sol";
import "./Minting.sol";

abstract contract Mintable is Ownable, IMintable {
    address public imx;
    mapping(uint256 => bytes) public blueprints;

    event AssetMinted(address to, uint256 id, bytes blueprint);

    constructor(address _owner, address _imx) {
        imx = _imx;
        require(_owner != address(0), "Owner must not be empty");
        transferOwnership(_owner);
    }

    modifier onlyIMX() {
        require(msg.sender == imx, "Function can only be called by IMX");
        _;
    }

    function mintFor(
        address user,
        uint256 quantity,
        bytes calldata mintingBlob
    ) external override onlyIMX {
        require(quantity == 1, "Mintable: invalid quantity");
        (uint256 id, bytes memory blueprint) = Minting.split(mintingBlob);
        _mintFor(user, id, blueprint);
        blueprints[id] = blueprint;
        emit AssetMinted(user, id, blueprint);
    }

    function _mintFor(
        address to,
        uint256 id,
        bytes memory blueprint
    ) internal virtual;
}

