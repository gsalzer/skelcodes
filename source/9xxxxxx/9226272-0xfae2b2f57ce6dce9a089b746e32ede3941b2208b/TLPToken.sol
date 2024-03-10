pragma solidity >=0.4.21 <0.6.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./ERC20Capped.sol";
import "./ERC20Burnable.sol";

// 测试用的Token
contract KOCToken is ERC20, ERC20Detailed, ERC20Burnable {

    event CreateTokenSuccess(address owner, uint256 balance);

    uint256 amount = 10000000;
    constructor(

    )
    ERC20Burnable()
    ERC20Detailed("TLP", "TLP", 18)
    ERC20()
    public
    {
        _mint(address(0x0152536d0A8838dfAA852D1D2d70E27e32174b17), amount * (10 ** 18));
        emit CreateTokenSuccess(address(0x0152536d0A8838dfAA852D1D2d70E27e32174b17), balanceOf(msg.sender));
    }
}

