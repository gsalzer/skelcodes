pragma solidity ^0.5.8;

import "./ERC20Pausable.sol";
import "./ERC20Detailed.sol";

/**
 * @dev Nerthus Token
 * 该 Token 使用 zeppelin 提供的 ERC20Pausable 实现。
 * 代币名 NTS，小数位 12 位（同 Nerthus 主链币的小数位一致）
 * Token 总量 25 亿。
 */
contract NTSToken is ERC20Pausable, ERC20Detailed {
    constructor() ERC20Detailed("Nerthus", "NTS", 12) public {
        _mint(msg.sender, 2500000000000000000000);
    }
}
