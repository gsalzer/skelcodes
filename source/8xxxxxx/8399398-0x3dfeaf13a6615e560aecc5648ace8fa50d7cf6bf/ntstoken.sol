pragma solidity ^0.5.0;

import "./ERC20Pausable.sol";
import "./ERC20Detailed.sol";

contract NTSToken is ERC20Pausable, ERC20Detailed {
    constructor() ERC20Detailed("Nerthus", "NTS", 12) public {
        _mint(msg.sender, 2500000000000000000000);
    }
}
