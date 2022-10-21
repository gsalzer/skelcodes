// SPDX-License-Identifier: MIT
pragma solidity =0.7.5;


import "LibSafeMath.sol";
import "LibBaseAuth.sol";
import "LibIPermille.sol";


contract WithVestingPermille is BaseAuth {
    using SafeMath for uint256;
    
    IPermille private _issuedVestingPermilleContract;
    IPermille private _bonusesVestingPermilleContract;

    /**
     * @dev Set Vesting Permille Contract(s).
     */
    function setIRPC(address issuedVestingPermilleContract)
        external
        onlyAgent
    {
        _issuedVestingPermilleContract = IPermille(issuedVestingPermilleContract);
    }

    function setBRPC(address bonusesVestingPermilleContract)
        external
        onlyAgent
    {
        _bonusesVestingPermilleContract = IPermille(bonusesVestingPermilleContract);
    }

    /**
     * @dev Returns the Vesting Permille Contract(s).
     */
    function VestingPermilleContracts()
        public
        view
        returns (
            IPermille issuedVestingPermilleContract,
            IPermille bonusesVestingPermilleContract
        )
    {
        issuedVestingPermilleContract = _issuedVestingPermilleContract;
        bonusesVestingPermilleContract = _bonusesVestingPermilleContract;
    }

    /**
     * @dev Returns vesting amount for issued of `amount`.
     */
    function _getVestingAmountForIssued(uint256 amount)
        internal
        view
        returns (uint256 vesting)
    {
        if (amount > 0) {
            vesting = _getVestingAmount(amount, _issuedVestingPermilleContract, 900);
        }
    }

    /**
     * @dev Returns vesting amount for bonuses of `amount`.
     */
    function _getVestingAmountForBonuses(uint256 amount)
        internal
        view
        returns (uint256 vesting)
    {
        if (amount > 0) {
            vesting = _getVestingAmount(amount, _bonusesVestingPermilleContract, 1_000);
        }
    }

    /**
     * @dev Returns vesting amount via the `permilleContract`.
     */
    function _getVestingAmount(uint256 amount, IPermille permilleContract, uint16 defaultPermille)
        private
        view
        returns (uint256 vesting)
    {
        vesting = amount;

        uint16 permille = defaultPermille;

        if (permilleContract != IPermille(0)) {
            try permilleContract.permille() returns (uint16 permille_) {
                permille = permille_;
            }

            catch {
                //
            }
        }
        
        if (permille == 0) {
            vesting = 0;
        }

        else if (permille < 1_000) {
            vesting = vesting.mul(permille).div(1_000);
        }
    }
}

