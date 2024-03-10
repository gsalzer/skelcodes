pragma solidity ^0.5.13;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";
import "./MultiOwned.sol";
import "./XAudTokenConfig.sol";
import "./MinterRole.sol";

contract ERC20Mintable is XAudTokenConfig, MultiOwned, ERC20, MinterRole {
    uint256 public mintCapacity;
    uint256 public amountMinted;
    uint public mintPeriod;
    uint public mintPeriodStart;

    event MintCapacity(uint256 amount);
    event MintPeriod(uint duration);

    constructor(uint256 _mintCapacity, uint _mintPeriod)
        public
    {
        _setMintCapacity(_mintCapacity);
        _setMintPeriod(_mintPeriod);
    }

    function addMinter(address _addr)
        public
        onlySelf
    {
        _addMinter(_addr);
    }

    function mint(address _to, uint256 _amount)
        public
    {
        if (msg.sender != address(this)) {
            require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
            require(isUnderMintLimit(_amount), "ERC20: exceeds minting capacity");
        }
        _mint(_to, _amount);
    }

    function removeMinter(address _addr)
        public
        onlySelf
    {
        _removeMinter(_addr);
    }

    function renounceMinter()
        public
        returns (bool)
    {
        _removeMinter(msg.sender);
        return true;
    }

    function setMintCapacity(uint256 _amount)
        public
        onlySelf
    {
        _setMintCapacity(_amount);
    }

    function setMintPeriod(uint _duration)
        public
        onlySelf
    {
        _setMintPeriod(_duration);
    }

    function _mint(address _to, uint256 _amount)
        internal
    {
        require(_to != address(0), "ERC20: mint to the zero address");
        require(_to != address(this), "ERC20: mint to token contract");

        if (now > mintPeriodStart + mintPeriod) {
            amountMinted = 0;
            mintPeriodStart = now;
        }
        amountMinted = amountMinted.add(_amount);
        tokenTotalSupply = tokenTotalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        if (balances[_to] > 0) holders.insert(_to);
        emit Transfer(address(0), _to, _amount);
        emit Mint(_to, _amount);
    }

    function _setMintCapacity(uint256 _amount)
        internal
    {
        mintCapacity = _amount;
        emit MintCapacity(_amount);
    }

    function _setMintPeriod(uint _duration)
        internal
    {
        require(_duration < (1 << 64),
                "ERC20: mint period must be less than 2^64 seconds");
        mintPeriod = _duration;
        emit MintPeriod(_duration);
    }

    function isUnderMintLimit(uint256 _amount)
        internal
        view
        returns (bool)
    {
        uint256 effAmountMinted = (now > mintPeriodStart + mintPeriod) ? 0 : amountMinted;
        if (effAmountMinted + _amount > mintCapacity
            || effAmountMinted + _amount < effAmountMinted) {
            return false;
        }
        return true;
    }

    function remainingMintCapacity()
        public
        view
        returns (uint256)
    {
        if (now > mintPeriodStart + mintPeriod)
            return mintCapacity;
        if (mintCapacity < amountMinted)
            return 0;
        return mintCapacity - amountMinted;
    }
}

