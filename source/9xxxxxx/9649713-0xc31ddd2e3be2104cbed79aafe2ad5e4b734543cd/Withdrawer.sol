pragma solidity 0.5.11;

import "./IERC20.sol";


contract Withdrawer {

    address constant internal DGTX = 0x1C83501478f1320977047008496DACBD60Bb15ef; // for tests: 0x0045a2eBfFE0Cd3395c68fC124B1ED98b5B52c37
    address payable constant internal HOT_WALLET = 0xe3229A304165341EdFa7dd078030b13F87cA65E4; // for tests: 0xF33FEBF3069984bf26FfA9bf92097174DeD1DeeE

    constructor() public {
        uint256 balanceDGTX = IERC20(DGTX).balanceOf(address(this));
        IERC20(DGTX).transfer(HOT_WALLET, balanceDGTX);
        selfdestruct(HOT_WALLET);
    }
}

