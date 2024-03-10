pragma solidity ^0.5.17;

import "./GTToken.sol";


/**
 * @title GTTokenV2
 * @dev The GTTokenV2 contract extends GTToken contract for upgradability testing
 */
contract GTTokenV2 is GTToken {


    /* Storage */

    uint256 public updatedTokenAmount;


    /* External functions */

    /**
     * @dev Allows setting up of GTTokenV2, sets the isSetup to true
     * @param _updatedTokenAmount uint The updated fixed token amount value
     */
    function setupV2(uint256 _updatedTokenAmount)
        external
        onlyOwner
    {
        require(updatedTokenAmount == 0 && _updatedTokenAmount > 0);

        updatedTokenAmount = _updatedTokenAmount;
        isSetup = true;
    }

    /**
     * @dev Allows allocation of GT Token to investors with V2 logic
     * @param investorAddress address The address of the investor
     * @param tokenAmount uint The GT token amount to be allocated
     */
    function allocateTokens(
        address investorAddress,
        uint tokenAmount
    )
        external

        isGTTokenSetup
        returns(bool)
    {
        require(investorRegistered[investorAddress]);
        require(tokenAmount == updatedTokenAmount);

        _mint(investorAddress, tokenAmount);

        emit AllocateTokens(investorAddress, balanceOf(investorAddress));

        return true;
    }
}

