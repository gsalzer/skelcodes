pragma solidity 0.8.6;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract DeepMusicNote is
    Initializable,
    ERC20CappedUpgradeable,
    OwnableUpgradeable
{
    function initialize(
        string memory name,
        string memory symbol,
        uint256 cap
    ) public virtual initializer {
        __ERC20_init(name, symbol);
        __ERC20Capped_init(cap);
        __Ownable_init();
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }
}

