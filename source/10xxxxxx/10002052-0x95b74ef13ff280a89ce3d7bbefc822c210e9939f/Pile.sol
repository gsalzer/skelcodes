// Verified using https://dapp.tools

// hevm: flattened sources of src/borrower/pile.sol
pragma solidity >=0.4.23 >=0.5.3 >=0.5.15 >=0.5.0 <0.6.0 >=0.5.15 <0.6.0;

////// lib/tinlake-auth/lib/ds-note/src/note.sol
/// note.sol -- the `note' modifier, for logging calls as events

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
/* pragma solidity >=0.5.15; */

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint256           wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;
        uint256 wad;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
            wad := callvalue()
        }

        _;

        emit LogNote(msg.sig, msg.sender, foo, bar, wad, msg.data);
    }
}

////// lib/tinlake-auth/src/auth.sol
// Copyright (C) Centrifuge 2020, based on MakerDAO dss https://github.com/makerdao/dss
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

/* pragma solidity >=0.5.15 <0.6.0; */

/* import "ds-note/note.sol"; */

contract Auth is DSNote {
    mapping (address => uint) public wards;
    function rely(address usr) public auth note { wards[usr] = 1; }
    function deny(address usr) public auth note { wards[usr] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }
}

////// lib/tinlake-math/src/math.sol
// Copyright (C) 2018 Rain <rainbreak@riseup.net>
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

/* pragma solidity >=0.5.15 <0.6.0; */

contract Math {
    uint256 constant ONE = 10 ** 27;

    function safeAdd(uint x, uint y) public pure returns (uint z) {
        require((z = x + y) >= x);
    }

    function safeSub(uint x, uint y) public pure returns (uint z) {
        require((z = x - y) <= x);
    }

    function safeMul(uint x, uint y) public pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function safeDiv(uint x, uint y) public pure returns (uint z) {
        z = x / y;
    }

    function rmul(uint x, uint y) public pure returns (uint z) {
        z = safeMul(x, y) / ONE;
    }

    function rdiv(uint x, uint y) public pure returns (uint z) {
        require(y > 0, "division by zero");
        z = safeAdd(safeMul(x, ONE), y / 2) / y;
    }

    function rdivup(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, "division by zero");
        // always rounds up
        z = safeAdd(safeMul(x, ONE), safeSub(y, 1)) / y;
    }


}

////// lib/tinlake-math/src/interest.sol
// Copyright (C) 2018 Rain <rainbreak@riseup.net> and Centrifuge, referencing MakerDAO dss => https://github.com/makerdao/dss/blob/master/src/pot.sol
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

/* pragma solidity >=0.5.15 <0.6.0; */

/* import "./math.sol"; */

contract Interest is Math {
    // @notice This function provides compounding in seconds
    // @param chi Accumulated interest rate over time
    // @param ratePerSecond Interest rate accumulation per second in RAD(10ˆ27)
    // @param lastUpdated When the interest rate was last updated
    // @param pie Total sum of all amounts accumulating under one interest rate, divided by that rate
    // @return The new accumulated rate, as well as the difference between the debt calculated with the old and new accumulated rates.
    function compounding(uint chi, uint ratePerSecond, uint lastUpdated, uint pie) public view returns (uint, uint) {
        require(block.timestamp >= lastUpdated, "tinlake-math/invalid-timestamp");
        require(chi != 0);
        // instead of a interestBearingAmount we use a accumulated interest rate index (chi)
        uint updatedChi = _chargeInterest(chi ,ratePerSecond, lastUpdated, block.timestamp);
        return (updatedChi, safeSub(rmul(updatedChi, pie), rmul(chi, pie)));
    }

    // @notice This function charge interest on a interestBearingAmount
    // @param interestBearingAmount is the interest bearing amount
    // @param ratePerSecond Interest rate accumulation per second in RAD(10ˆ27)
    // @param lastUpdated last time the interest has been charged
    // @return interestBearingAmount + interest
    function chargeInterest(uint interestBearingAmount, uint ratePerSecond, uint lastUpdated) public view returns (uint) {
        if (block.timestamp >= lastUpdated) {
            interestBearingAmount = _chargeInterest(interestBearingAmount, ratePerSecond, lastUpdated, block.timestamp);
        }
        return interestBearingAmount;
    }

    function _chargeInterest(uint interestBearingAmount, uint ratePerSecond, uint lastUpdated, uint current) internal pure returns (uint) {
        return rmul(rpow(ratePerSecond, current - lastUpdated, ONE), interestBearingAmount);
    }


    // convert pie to debt/savings amount
    function toAmount(uint chi, uint pie) public pure returns (uint) {
        return rmul(pie, chi);
    }

    // convert debt/savings amount to pie
    function toPie(uint chi, uint amount) public pure returns (uint) {
        return rdivup(amount, chi);
    }

    function rpow(uint x, uint n, uint base) public pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                let xx := mul(x, x)
                if iszero(eq(div(xx, x), x)) { revert(0,0) }
                let xxRound := add(xx, half)
                if lt(xxRound, xx) { revert(0,0) }
                x := div(xxRound, base)
                if mod(n,2) {
                    let zx := mul(z, x)
                    if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                    let zxRound := add(zx, half)
                    if lt(zxRound, zx) { revert(0,0) }
                    z := div(zxRound, base)
                }
            }
            }
        }
    }
}

////// src/borrower/pile.sol
// Copyright (C) 2018  Rain <rainbreak@riseup.net>, Centrifuge
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

/* pragma solidity >=0.5.15 <0.6.0; */

/* import "ds-note/note.sol"; */
/* import "tinlake-math/interest.sol"; */
/* import "tinlake-auth/auth.sol"; */

// ## Interest Group based Pile
// The following is one implementation of a debt module. It keeps track of different buckets of interest rates and is optimized for many loans per interest bucket. It keeps track of interest
// rate accumulators (chi values) for all interest rate categories. It calculates debt each
// loan according to its interest rate category and pie value.
contract Pile is DSNote, Auth, Interest {
    // --- Data ---

    /// stores all needed information of an interest rate group
    struct Rate {
        uint   pie;                 // Total debt of all loans with this rate
        uint   chi;                 // Accumulated rates
        uint   ratePerSecond;       // Accumulation per second
        uint48 lastUpdated;         // Last time the rate was accumulated
    }

    /// Interest Rate Groups are identified by a `uint` and stored in a mapping
    mapping (uint => Rate) public rates;

    /// mapping of all loan debts
    /// the debt is stored as pie
    /// pie is defined as pie = debt/chi therefore debt = pie * chi
    /// where chi is the accumulated interest rate index over time
    mapping (uint => uint) public pie;
    /// loan => rate
    mapping (uint => uint) public loanRates;


    /// total debt of all ongoing loans
    uint public total;

    constructor() public {
        wards[msg.sender] = 1;
        /// pre-definition for loans without interest rates
        rates[0].chi = ONE;
        rates[0].ratePerSecond = ONE;
    }

     // --- Public Debt Methods  ---
    /// increases the debt of a loan by a currencyAmount
    /// a change of the loan debt updates the rate debt and total debt
    function incDebt(uint loan, uint currencyAmount) external auth note {
        uint rate = loanRates[loan];
        require(now == rates[rate].lastUpdated, "rate-group-not-updated");
        uint pieAmount = toPie(rates[rate].chi, currencyAmount);

        pie[loan] = safeAdd(pie[loan], pieAmount);
        rates[rate].pie = safeAdd(rates[rate].pie, pieAmount);
        total = safeAdd(total, currencyAmount);
    }

    /// decrease the loan's debt by a currencyAmount
    /// a change of the loan debt updates the rate debt and total debt
    function decDebt(uint loan, uint currencyAmount) external auth note {
        uint rate = loanRates[loan];
        require(now == rates[rate].lastUpdated, "rate-group-not-updated");
        uint pieAmount = toPie(rates[rate].chi, currencyAmount);

        pie[loan] = safeSub(pie[loan], pieAmount);
        rates[rate].pie = safeSub(rates[rate].pie, pieAmount);

        if (currencyAmount > total) {
            total = 0;
            return;
        }

        total = safeSub(total, currencyAmount);
    }

    /// returns the current debt based on actual block.timestamp (now)
    function debt(uint loan) external view returns (uint) {
        uint rate_ = loanRates[loan];
        uint chi_ = rates[rate_].chi;
        if (now >= rates[rate_].lastUpdated) {
            chi_ = chargeInterest(rates[rate_].chi, rates[rate_].ratePerSecond, rates[rate_].lastUpdated);
        }
        return toAmount(chi_, pie[loan]);
    }

    /// returns the total debt of a interest rate group
    function rateDebt(uint rate) external view returns (uint) {
        uint chi_ = rates[rate].chi;
        uint pie_ = rates[rate].pie;

        if (now >= rates[rate].lastUpdated) {
            chi_ = chargeInterest(rates[rate].chi, rates[rate].ratePerSecond, rates[rate].lastUpdated);
        }
        return toAmount(chi_, pie_);
    }

    // --- Interest Rate Group Implementation ---

    // set rate loanRates for a loan
    function setRate(uint loan, uint rate) external auth note {
        require(pie[loan] == 0, "non-zero-debt");
        // rate category has to be initiated
        require(rates[rate].chi != 0, "rate-group-not-set");
        loanRates[loan] = rate;
    }

    // change rate loanRates for a loan
    function changeRate(uint loan, uint newRate) external auth note {
        require(rates[newRate].chi != 0, "rate-group-not-set");
        uint currentRate = loanRates[loan];
        drip(currentRate);
        drip(newRate);
        uint pie_ = pie[loan];
        uint debt_ = toAmount(rates[currentRate].chi, pie_);
        rates[currentRate].pie = safeSub(rates[currentRate].pie, pie_);
        pie[loan] = toPie(rates[newRate].chi, debt_);
        rates[newRate].pie = safeAdd(rates[newRate].pie, pie[loan]);
        loanRates[loan] = newRate;
    }

    // set/change the interest rate of a rate category
    function file(bytes32 what, uint rate, uint ratePerSecond) external auth note {
        if (what == "rate") {
            require(ratePerSecond != 0, "rate-per-second-can-not-be-0");
            if (rates[rate].chi == 0) {
                rates[rate].chi = ONE;
                rates[rate].lastUpdated = uint48(now);
            } else {
                drip(rate);
            }
            rates[rate].ratePerSecond = ratePerSecond;
        } else revert("unknown parameter");

    }

    // accrue needs to be called before any debt amounts are modified by an external component
    function accrue(uint loan) external {
        drip(loanRates[loan]);
    }

    // drip updates the chi of the rate category by compounding the interest and
    // updates the total debt
    function drip(uint rate) public {
        if (now >= rates[rate].lastUpdated) {
            (uint chi, uint deltaInterest) = compounding(rates[rate].chi, rates[rate].ratePerSecond, rates[rate].lastUpdated, rates[rate].pie);
            rates[rate].chi = chi;
            rates[rate].lastUpdated = uint48(now);
            total = safeAdd(total, deltaInterest);
        }
    }
}

