pragma solidity 0.6.9;

import "./ERC20.sol";

abstract contract ERC20Burnable is ERC20 {
    event Burn(address indexed burned, uint256 amount);

    function burn(uint256 amount)
        external
        returns (bool success)
    {
        success = _burn(msg.sender, amount);
        emit Burn(msg.sender, amount);
        success = true;
    }

    function burnFrom(address burned, uint256 amount)
        external
        returns (bool success)
    {
        _burn(burned, amount);
        emit Burn(burned, amount);
        success = _approve(
            burned,
            msg.sender,
            _allowances[burned][msg.sender].sub(
                amount,
                "ERC20Burnable/burnFrom : Cannot burn more than allowance"
            )
        );
    }
}

