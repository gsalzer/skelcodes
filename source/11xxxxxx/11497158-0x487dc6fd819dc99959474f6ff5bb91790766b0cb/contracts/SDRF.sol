// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract SDRF is ERC20, Ownable {

    address public minter;

    modifier onlyMinter {
        require(msg.sender == minter, 'Only minter');
        _;
    }

    constructor() public ERC20('Swappable drift.finance', 'sDRF') {
    }

    function init(address _minter) external onlyOwner {
        minter = _minter;
        renounceOwnership();
    }

    function mint(address account, uint256 amount) external onlyMinter {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyMinter {
        _burn(account, amount);
    }

}
