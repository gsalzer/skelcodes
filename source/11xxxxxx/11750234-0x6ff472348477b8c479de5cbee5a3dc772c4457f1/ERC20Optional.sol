// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";
import "./ERC20.sol";
import "./Ownable.sol";

abstract contract ERC20Optional is Context, ERC20, Ownable {

    mapping (address => uint256) private _releaseTimestamp;

    function lock(address account, uint256 releaseTimestamp) public virtual {
        require(owner() == _msgSender(), "ERC20Optional: you're not owner");

        _releaseTimestamp[account] = releaseTimestamp;
    }

    function isLocked(address account) public view returns (bool) {
        return (block.timestamp < _releaseTimestamp[account]);
    }

    function releaseTimestamp(address account) public view returns (uint256) {
        return _releaseTimestamp[account];
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(block.timestamp >= _releaseTimestamp[from], "ERC20Optional: account is locked");
    }
}
