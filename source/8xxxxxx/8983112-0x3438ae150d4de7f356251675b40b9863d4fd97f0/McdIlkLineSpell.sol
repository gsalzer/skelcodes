// Verified using https://dapp.tools

// hevm: flattened sources of src/McdIlkLineSpell.sol
pragma solidity =0.5.12;

////// src/McdIlkLineSpell.sol
// Copyright (C) 2019 Maker Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.5.12; */

contract PauseLike {
    function delay() public view returns (uint256);
    function plot(address, bytes32, bytes memory, uint256) public;
    function exec(address, bytes32, bytes memory, uint256) public;
}

contract McdIlkLineSpell {
    // uint constant WAD = 10 ** 18;
    // uint constant RAY = 10 ** 27;
    uint constant RAD = 10 ** 45;

    PauseLike public pause = PauseLike(0xbE286431454714F511008713973d3B053A2d38f3);
    address   public plan = 0x4F5f0933158569c026d617337614d00Ee6589B6E;
    address   public vat = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    bytes32   public ilk = "ETH-A";
    uint256   public line = 0 * RAD;
    bytes32   public tag;
    uint256   public eta;
    bytes     public sig;
    bool      public done;

    constructor() public {
        sig   = abi.encodeWithSignature(
                "file(address,bytes32,bytes32,uint256)",
                vat,
                ilk,
                bytes32("line"),
                line
        );
        address _plan = plan;
        bytes32 _tag;
        assembly { _tag := extcodehash(_plan) }
        tag = _tag;
    }

    function schedule() public {
        require(eta == 0, "spell-already-scheduled");
        eta = now + PauseLike(pause).delay();
        pause.plot(plan, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(plan, tag, sig, eta);
    }
}

