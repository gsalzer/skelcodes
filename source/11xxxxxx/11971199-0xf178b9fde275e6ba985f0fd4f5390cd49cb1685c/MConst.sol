// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.5.12;

import "./MColor.sol";

contract MConst is MBronze {
    uint internal constant BONE              = 10**18;

    uint internal constant MIN_BOUND_TOKENS  = 2;
    uint internal constant MAX_BOUND_TOKENS  = 8;

    uint internal constant MIN_FEE           = BONE / 10**6;
    uint internal constant MAX_FEE           = BONE / 10;

    uint internal constant MIN_WEIGHT        = BONE;
    uint internal constant MAX_WEIGHT        = BONE * 50;
    uint internal constant MAX_TOTAL_WEIGHT  = BONE * 50;
    uint internal constant MIN_BALANCE       = BONE / 10**12;

    uint internal constant INIT_POOL_SUPPLY  = BONE * 100;

    uint internal constant MIN_BPOW_BASE     = 1 wei;
    uint internal constant MAX_BPOW_BASE     = (2 * BONE) - 1 wei;
    uint internal constant BPOW_PRECISION    = BONE / 10**10;

    uint internal constant MAX_IN_RATIO      = BONE / 2;
    uint internal constant MAX_OUT_RATIO     = (BONE / 3) + 1 wei;
}

