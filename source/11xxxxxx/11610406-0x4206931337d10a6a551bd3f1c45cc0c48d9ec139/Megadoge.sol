// SPDX-License-Identifier: DOGE WORLD
pragma solidity ^0.8.0;

import "./IMegadoge.sol";
import "../ERC20.sol";
import "../SafelyOwned.sol";
import "../SafeERC20.sol";
import "./IDogey.sol";

contract Megadoge is ERC20("Megadoge", "MEGADOGE", 0), SafelyOwned, IMegadoge
{
    using SafeERC20 for IERC20;

    IDogey immutable dogey;

    constructor (IDogey _dogey)
    {
        dogey = _dogey;
    }

    function dogesNeeded(IERC20 _doge, uint256 _megadogeAmount) private view returns (uint256)
    {
        return _megadogeAmount * 1000000 * (10 ** _doge.decimals());
    }

    function create(IERC20 _doge, uint256 _megadogeAmount) public override
    {
        require (_megadogeAmount > 0, "Amount is 0");
        require (dogey.isDogey(_doge), "Token is not dogey");
        _doge.safeTransferFrom(msg.sender, address(this), dogesNeeded(_doge, _megadogeAmount));
        mintCore(msg.sender, _megadogeAmount);
    }

    function createFromManyDoges(IERC20[] calldata _doges, uint256[] calldata _amounts) public override
    {
        require (_doges.length == _amounts.length, "Bad params");
        uint256 len = _doges.length;
        uint256 totalDogeE18 = 0;
        for (uint256 x=0; x<len; ++x) {     
            IERC20 doge = _doges[x];       
            require (dogey.isDogey(doge), "Token is not dogey");
            uint8 decimals = doge.decimals();
            require (decimals <= 18, "Doge has too many decimals");
            totalDogeE18 += _amounts[x] * (10 ** (18 - decimals));
        }
        require (totalDogeE18 > 0, "Amount is 0");
        require (totalDogeE18 % (1000000 ether) == 0, "Sum doesn't exactly create megadoges");
        for (uint256 x=0; x<len; ++x) {
            _doges[x].safeTransferFrom(msg.sender, address(this), _amounts[x]);
        }
        mintCore(msg.sender, totalDogeE18 / (1000000 ether));
    }

    function createWithPermit(IERC20Permit _doge, uint256 _megadogeAmount, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s) public override
    {
        _doge.permit(msg.sender, address(this), dogesNeeded(_doge, _megadogeAmount), _deadline, _v, _r, _s);
        create(_doge, _megadogeAmount);
    }
}
