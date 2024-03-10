pragma solidity ^0.4.25;

import "./SafeMath.sol";

contract Repaying {
    using SafeMath for uint256;
    bool repayLock;
    uint256 maxGasPrice = 4000000000;
    event Repaid(address user, uint256 amt);

    modifier repayable {
        if(!repayLock) {
            repayLock = true;
            uint256 startGas = gasleft();
            _;
            uint256 gasUsed = startGas.sub(gasleft());
            uint256 gasPrice = maxGasPrice.min256(tx.gasprice);
            uint256 repayal = gasPrice.mul(gasUsed.add(41761));
            tx.origin.send(repayal);
            emit Repaid(tx.origin, repayal);
            repayLock = false;
        }
        else {
            _;
        }
    }
}
