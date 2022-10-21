pragma solidity 0.8.6;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/token/ERC20/IERC20.sol";

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/utils/Context.sol";

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/utils/math/SafeMath.sol";

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/utils/Address.sol";

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/token/ERC20/ERC20.sol";


contract QuackedDuck is ERC20("QuackedDuck", "qDUCK"){
    using SafeMath for uint256;
    IERC20 internal constant duck = IERC20(0x92E187a03B6CD19CB6AF293ba17F2745Fd2357D5);

    // Quack your DUCK to earn some DUCK
    function quack(uint256 _amount) public {
        uint256 totalDucks = duck.balanceOf(address(this));
        uint256 totalShares = totalSupply();
        if (totalShares == 0 || totalDucks == 0) {
            _mint(msg.sender, _amount);
        } else {
            uint256 what = _amount.mul(totalShares).div(totalDucks);
            _mint(msg.sender, what);
        }
        duck.transferFrom(msg.sender, address(this), _amount);
    }

    // Unquack to get your DUCK back
    function unquack(uint256 qDuckAmount) public {
        _burn(msg.sender, qDuckAmount);
        duck.transfer(msg.sender, toDUCK(qDuckAmount));
    }
    
    function getExchangeRate() public view returns (uint256) {
        return (duck.balanceOf(address(this)) * 1e18) / totalSupply();
    }

    function toDUCK(uint256 qDuckAmount) public view returns (uint256) {
        return (qDuckAmount * duck.balanceOf(address(this))) / totalSupply();
    }

    function toQDUCK(uint256 duckAmount) public view returns (uint256 xSushiAmount) {
        return (duckAmount * totalSupply()) / duck.balanceOf(address(this));
    }
}
