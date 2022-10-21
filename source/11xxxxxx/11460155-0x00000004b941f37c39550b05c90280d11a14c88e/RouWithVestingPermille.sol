// SPDX-License-Identifier: MIT
pragma solidity =0.7.5;


import "LibSafeMath.sol";
import "LibBaseAuth.sol";
import "LibIPermille.sol";


contract WithVestingPermille is BaseAuth {
    using SafeMath for uint256;

    IPermille private _v1ClaimedVestingPermilleContract;
    IPermille private _v1BonusesVestingPermilleContract;
    IPermille private _v2ClaimedVestingPermilleContract;
    IPermille private _v2BonusesVestingPermilleContract;

    /**
     * @dev Set Vesting Permille Contract(s).
     */
    function setV1CRPC(address permilleContract)
        external
        onlyAgent
    {
        _v1ClaimedVestingPermilleContract = IPermille(permilleContract);
    }

    function setV1BRPC(address permilleContract)
        external
        onlyAgent
    {
        _v1BonusesVestingPermilleContract = IPermille(permilleContract);
    }

    function setV2CRPC(address permilleContract)
        external
        onlyAgent
    {
        _v2ClaimedVestingPermilleContract = IPermille(permilleContract);
    }

    function setV2BRPC(address permilleContract)
        external
        onlyAgent
    {
        _v2BonusesVestingPermilleContract = IPermille(permilleContract);
    }

    /**
     * @dev Returns the Vesting Permille Contract(s).
     */
    function VestingPermilleContracts()
        public
        view
        returns (
            IPermille v1ClaimedVestingPermilleContract,
            IPermille v1BonusesVestingPermilleContract,
            IPermille v2ClaimedVestingPermilleContract,
            IPermille v2BonusesVestingPermilleContract
        )
    {
        v1ClaimedVestingPermilleContract = _v1ClaimedVestingPermilleContract;
        v1BonusesVestingPermilleContract = _v1BonusesVestingPermilleContract;
        v2ClaimedVestingPermilleContract = _v2ClaimedVestingPermilleContract;
        v2BonusesVestingPermilleContract = _v2BonusesVestingPermilleContract;
    }

    /**
     * @dev Returns the `Vesting` amount for v1Claimed.
     */
    function _getV1ClaimedVestingAmount(uint256 amount)
        internal
        view
        returns (uint256 Vesting)
    {
        if (amount > 0) {
            Vesting = _getVestingAmount(amount, _v1ClaimedVestingPermilleContract);
        }
    }

    /**
     * @dev Returns the `Vesting` amount for v1Bonuses.
     */
    function _getV1BonusesVestingAmount(uint256 amount)
        internal
        view
        returns (uint256 Vesting)
    {
        if (amount > 0) {
            Vesting = _getVestingAmount(amount, _v1BonusesVestingPermilleContract);
        }
    }

    /**
     * @dev Returns the `Vesting` amount for v2Claimed.
     */
    function _getV2ClaimedVestingAmount(uint256 amount)
        internal
        view
        returns (uint256 Vesting)
    {
        if (amount > 0) {
            Vesting = _getVestingAmount(amount, _v2ClaimedVestingPermilleContract);
        }
    }

    /**
     * @dev Returns the `Vesting` amount for v2Bonuses.
     */
    function _getV2BonusesVestingAmount(uint256 amount)
        internal
        view
        returns (uint256 Vesting)
    {
        if (amount > 0) {
            Vesting = _getVestingAmount(amount, _v2BonusesVestingPermilleContract);
        }
    }
    
    
    /**
     * @dev Returns the `Vesting` amount via a `permilleContract`.
     */
    function _getVestingAmount(uint256 amount, IPermille permilleContract)
        private
        view
        returns (uint256 Vesting)
    {
        Vesting = amount;
        
        if (permilleContract != IPermille(0)) {
            try permilleContract.permille() returns (uint16 permille) {
                if (permille == 0) {
                    Vesting = 0;
                }

                else if (permille < 1_000) {
                    Vesting = Vesting.mul(permille).div(1_000);
                }
            }

            catch {
                //
            }
        }
    }
}

