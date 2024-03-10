// SPDX-License-Identifier: MIT
pragma solidity =0.7.5;


import "LibSafeMath.sol";
import "LibBaseAuth.sol";
import "LibIPermille.sol";


contract WithVestingPermille is BaseAuth {
    using SafeMath for uint256;
    
    IPermille private _vestingPermilleContract;

    /**
     * @dev Set Vesting Permille Contract(s).
     */
    function setVestingPermilleContract(address vpContract)
        external
        onlyAgent
    {
        _vestingPermilleContract = IPermille(vpContract);
    }

    /**
     * @dev Returns the Vesting Permille Contract.
     */
    function vestingPermilleContract()
        public
        view
        returns (IPermille)
    {
        return _vestingPermilleContract;
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
            vesting = _getVestingAmount(amount, _vestingPermilleContract, 970);
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

