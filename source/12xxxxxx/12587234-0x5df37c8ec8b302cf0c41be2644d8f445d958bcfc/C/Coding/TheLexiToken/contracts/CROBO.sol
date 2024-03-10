// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import './owner/Operator.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol';

contract CROBO is ERC20Burnable, Operator {
    /**
     * @notice Constructs Token ERC-20 contract.
     *
     */
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    constructor() public ERC20('MyCryptoRobo', 'CROBO') {
        //TODO we must mint some number of tokens
        _mint(msg.sender, 100000000 * 10**18);
    }

    function mint(address _recipient, uint256 _amount)
        public
        onlyOperator
        returns (bool)
    {
        uint256 balanceBefore = balanceOf(_recipient);
        _mint(_recipient, _amount);
        uint256 balanceAfter = balanceOf(_recipient);

        return balanceAfter > balanceBefore;
    }

    function burn(uint256 amount) public override onlyOperator {
        super.burn(amount);
    }

    function burnFrom(address account, uint256 amount)
        public
        override
        onlyOperator
    {
        super.burnFrom(account, amount);
    }
}

