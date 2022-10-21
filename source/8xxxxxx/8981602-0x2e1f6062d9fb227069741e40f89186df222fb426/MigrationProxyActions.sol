pragma solidity 0.5.12;

/// math.sol -- mixin for inline numerical wizardry

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

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

contract ScdMcdMigrationLike {
    function daiJoin() public view returns (JoinLike);
    function wethJoin() public view returns (JoinLike);
    function tub() public view returns (SaiTubLike);
    function migrate(bytes32) public returns (uint);
    function swapSaiToDai(uint) public;
    function swapDaiToSai(uint) public;
}

contract GemLike {
    function allowance(address, address) public returns (uint);
    function approve(address, uint) public;
    function transfer(address, uint) public returns (bool);
    function transferFrom(address, address, uint) public returns (bool);
}

contract ValueLike {
    function peek() public returns (uint, bool);
}

contract SaiTubLike {
    function skr() public view returns (GemLike);
    function gem() public view returns (GemLike);
    function gov() public view returns (GemLike);
    function sai() public view returns (GemLike);
    function pep() public view returns (ValueLike);
    function vox() public view returns (VoxLike);
    function bid(uint) public view returns (uint);
    function ink(bytes32) public view returns (uint);
    function tag() public view returns (uint);
    function tab(bytes32) public returns (uint);
    function rap(bytes32) public returns (uint);
    function draw(bytes32, uint) public;
    function shut(bytes32) public;
    function exit(uint) public;
    function give(bytes32, address) public;
}

contract VoxLike {
    function par() public returns (uint);
}

contract JoinLike {
    function ilk() public returns (bytes32);
    function gem() public returns (GemLike);
    function dai() public returns (GemLike);
    function join(address, uint) public;
    function exit(address, uint) public;
}

contract JugLike {
    function drip(bytes32) public;
}

contract OtcLike {
    function getPayAmount(address, address, uint) public view returns (uint);
    function buyAllAmount(address, uint, address, uint) public;
}

// This contract is intended to be executed via the Profile proxy of a user (DSProxy) which owns the SCD CDP
contract MigrationProxyActions is DSMath {
    function swapSaiToDai(
        address scdMcdMigration,            // Migration contract address
        uint wad                            // Amount to swap
    ) external {
        GemLike sai = ScdMcdMigrationLike(scdMcdMigration).tub().sai();
        GemLike dai = ScdMcdMigrationLike(scdMcdMigration).daiJoin().dai();
        sai.transferFrom(msg.sender, address(this), wad);
        if (sai.allowance(address(this), scdMcdMigration) < wad) {
            sai.approve(scdMcdMigration, wad);
        }
        ScdMcdMigrationLike(scdMcdMigration).swapSaiToDai(wad);
        dai.transfer(msg.sender, wad);
    }

    function swapDaiToSai(
        address scdMcdMigration,            // Migration contract address
        uint wad                            // Amount to swap
    ) external {
        GemLike sai = ScdMcdMigrationLike(scdMcdMigration).tub().sai();
        GemLike dai = ScdMcdMigrationLike(scdMcdMigration).daiJoin().dai();
        dai.transferFrom(msg.sender, address(this), wad);
        if (dai.allowance(address(this), scdMcdMigration) < wad) {
            dai.approve(scdMcdMigration, wad);
        }
        ScdMcdMigrationLike(scdMcdMigration).swapDaiToSai(wad);
        sai.transfer(msg.sender, wad);
    }

    function migrate(
        address scdMcdMigration,            // Migration contract address
        address jug,                        // Jug address to update fee status
        bytes32 cup                         // SCD CDP Id to migrate
    ) external returns (uint cdp) {
        SaiTubLike tub = ScdMcdMigrationLike(scdMcdMigration).tub();
        // Get necessary MKR fee and move it to the migration contract
        (uint val, bool ok) = tub.pep().peek();
        if (ok && val != 0) {
            // Calculate necessary value of MKR to pay the govFee
            uint govFee = wdiv(tub.rap(cup), val);

            // Get MKR from the user's wallet and transfer to Migration contract
            tub.gov().transferFrom(msg.sender, address(scdMcdMigration), govFee);
        }
        // Transfer ownership of SCD CDP to the migration contract
        tub.give(cup, address(scdMcdMigration));
        // Update stability fee rate
        JugLike(jug).drip(ScdMcdMigrationLike(scdMcdMigration).wethJoin().ilk());
        // Execute migrate function
        cdp = ScdMcdMigrationLike(scdMcdMigration).migrate(cup);
    }

    function migratePayFeeWithGem(
        address scdMcdMigration,            // Migration contract address
        address jug,                        // Jug address to update fee status
        bytes32 cup,                        // SCD CDP Id to migrate
        address otc,                        // Otc address
        address payGem,                     // Token address to be used for purchasing govFee MKR
        uint maxPayAmt                      // Max amount of payGem to sell for govFee MKR needed
    ) external returns (uint cdp) {
        SaiTubLike tub = ScdMcdMigrationLike(scdMcdMigration).tub();
        // Get necessary MKR fee and move it to the migration contract
        (uint val, bool ok) = tub.pep().peek();
        if (ok && val != 0) {
            // Calculate necessary value of MKR to pay the govFee
            uint govFee = wdiv(tub.rap(cup), val);

            // Calculate how much payGem is needed for getting govFee value
            uint payAmt = OtcLike(otc).getPayAmount(payGem, address(tub.gov()), govFee);
            // Fails if exceeds maximum
            require(maxPayAmt >= payAmt, "maxPayAmt-exceeded");
            // Set allowance, if necessary
            if (GemLike(payGem).allowance(address(this), otc) < payAmt) {
                GemLike(payGem).approve(otc, payAmt);
            }
            // Get payAmt of payGem from user's wallet
            require(GemLike(payGem).transferFrom(msg.sender, address(this), payAmt), "transfer-failed");
            // Trade it for govFee amount of MKR
            OtcLike(otc).buyAllAmount(address(tub.gov()), govFee, payGem, payAmt);
            // Transfer govFee amount of MKR to Migration contract
            tub.gov().transfer(address(scdMcdMigration), govFee);
        }
        // Transfer ownership of SCD CDP to the migration contract
        tub.give(cup, address(scdMcdMigration));
        // Update stability fee rate
        JugLike(jug).drip(ScdMcdMigrationLike(scdMcdMigration).wethJoin().ilk());
        // Execute migrate function
        cdp = ScdMcdMigrationLike(scdMcdMigration).migrate(cup);
    }

    function _getRatio(
        SaiTubLike tub,
        bytes32 cup
    ) internal returns (uint ratio) {
        ratio = rdiv(
                        rmul(tub.tag(), tub.ink(cup)),
                        rmul(tub.vox().par(), tub.tab(cup))
                    );
    }

    function migratePayFeeWithDebt(
        address scdMcdMigration,            // Migration contract address
        address jug,                        // Jug address to update fee status
        bytes32 cup,                        // SCD CDP Id to migrate
        address otc,                        // Otc address
        uint maxPayAmt,                     // Max amount of SAI to generate to sell for govFee MKR needed
        uint minRatio                       // Min collateralization ratio after generating new debt (e.g. 180% = 1.8 RAY)
    ) external returns (uint cdp) {
        SaiTubLike tub = ScdMcdMigrationLike(scdMcdMigration).tub();
        // Get necessary MKR fee and move it to the migration contract
        (uint val, bool ok) = tub.pep().peek();
        if (ok && val != 0) {
            // Calculate necessary value of MKR to pay the govFee
            uint govFee = wdiv(tub.rap(cup), val) + 1; // 1 extra wei MKR to avoid any possible rounding issue after drawing new SAI

            // Calculate how much SAI is needed for getting govFee value
            uint payAmt = OtcLike(otc).getPayAmount(address(tub.sai()), address(tub.gov()), govFee);
            // Fails if exceeds maximum
            require(maxPayAmt >= payAmt, "maxPayAmt-exceeded");
            // Get payAmt of SAI from user's CDP
            tub.draw(cup, payAmt);

            require(_getRatio(tub, cup) > minRatio, "minRatio-failed");

            // Set allowance, if necessary
            if (GemLike(address(tub.sai())).allowance(address(this), otc) < payAmt) {
                GemLike(address(tub.sai())).approve(otc, payAmt);
            }
            // Trade it for govFee amount of MKR
            OtcLike(otc).buyAllAmount(address(tub.gov()), govFee, address(tub.sai()), payAmt);
            // Transfer real needed govFee amount of MKR to Migration contract (it might leave some MKR dust in the proxy contract)
            govFee = wdiv(tub.rap(cup), val);
            tub.gov().transfer(address(scdMcdMigration), govFee);
        }
        // Transfer ownership of SCD CDP to the migration contract
        tub.give(cup, address(scdMcdMigration));
        // Update stability fee rate
        JugLike(jug).drip(ScdMcdMigrationLike(scdMcdMigration).wethJoin().ilk());
        // Execute migrate function
        cdp = ScdMcdMigrationLike(scdMcdMigration).migrate(cup);
    }
}
