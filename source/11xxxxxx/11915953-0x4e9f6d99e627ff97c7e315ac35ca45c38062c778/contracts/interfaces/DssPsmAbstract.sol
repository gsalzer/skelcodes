// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.10;
import "dss-interfaces/src/dss/AuthGemJoinAbstract.sol";
import "dss-interfaces/src/dss/DaiJoinAbstract.sol";


interface DssPsmAbstract {
    function gemJoin() external view returns(AuthGemJoinAbstract);
    function daiJoin() external view returns(DaiJoinAbstract);
    function tin() external view returns(uint256);
    function tout() external view returns(uint256);
    function file(bytes32 what, uint256 data) external;
    function sellGem(address usr, uint256 gemAmt) external;
    function buyGem(address usr, uint256 gemAmt) external;
}

