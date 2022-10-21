pragma solidity 0.5.17;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Detailed.sol";
// import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Mintable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Capped.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Burnable.sol";


contract TokenLogic is
    Initializable,
    ERC20,
    ERC20Detailed,
    // ERC20Mintable,
    ERC20Capped,
    ERC20Burnable
{
    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimal,
        address _bridge
    ) public initializer {
        ERC20Detailed.initialize(_name, _symbol, _decimal);
        // ERC20Mintable.initialize(msg.sender);
        ERC20Capped.initialize(10000000000e18, msg.sender);
        mint(_bridge, 1000000000e18);
    }
}

