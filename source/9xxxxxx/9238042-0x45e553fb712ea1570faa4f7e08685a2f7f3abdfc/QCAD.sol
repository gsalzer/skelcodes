pragma solidity 0.5.12;

import "./ERC20Pausable.sol";

contract QCAD is ERC20Pausable {
    function initialize(
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        address[] calldata admins
    ) external initializer {
        ERC20Detailed.initialize(name, symbol, decimals);
        Ownable.initialize(_msgSender());
        Pausable.initialize();

        for (uint256 i = 0; i < admins.length; ++i) {
            _addAdmin(admins[i]);
        }
    }

    function mint(address account, uint256 amount)
        external
        onlyAdmin
        whenNotPaused
        returns (bool)
    {
        require(isWhitelisted(account), "minting to non-whitelisted address");
        _mint(account, amount);
        return true;
    }

    function burn(uint256 amount)
        external
        onlyAdmin
        whenNotPaused
        returns (bool)
    {
        _burn(address(this), amount);
        return true;
    }
}

