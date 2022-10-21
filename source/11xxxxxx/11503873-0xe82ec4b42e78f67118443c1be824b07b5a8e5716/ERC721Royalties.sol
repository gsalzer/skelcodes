// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
import "./ERC165.sol";

/**
 * @dev Implementation of royalties for 721s
 *
 */
abstract contract Royalties is ERC165 {
    /*
     * ERC165 bytes to add to interface array - set in parent contract implementing this standard
     *
     * bytes4(keccak256('royaltyInfo()')) == 0x46e80720
     * bytes4 private constant _INTERFACE_ID_ERC721ROYALTIES = 0x46e80720;
     * _registerInterface(_INTERFACE_ID_ERC721ROYALTIES);
     */

    uint256 private royalty_amount;
    address private creator;
    bytes4 private constant _INTERFACE_ID_ERC721ROYALTIES = 0x46e80720;
    /**
    @notice This event is emitted when royalties are transfered.

    @dev The marketplace would emit this event from their contracts. Or they would call royaltiesRecieved() function.

    @param creator The original creator of the NFT entitled to the royalties
    @param buyer The person buying the NFT on a secondary sale
    @param amount The amount being paid to the creator
    */
    event RecievedRoyalties(
        address indexed creator,
        address indexed buyer,
        uint256 indexed amount
    );

    /**
     *  @notice Constructor called from the NFT being deployed with the value for the royalty in percentage and the creator who will recieve the royalty payment
     *
     *  @param _amount The percentage value on each sale that will be transfered to the creator
     *  @param _creator The original creator of the NFT entitled to the royalties
     *
     */

    constructor(uint256 _amount, address _creator) internal {
        royalty_amount = _amount;
        creator = _creator;
        _registerInterface(_INTERFACE_ID_ERC721ROYALTIES);
    }

    /**
     *      @notice Called to return the royalty amount that was set and only return that amount
     */
    function royaltyAmount() public view returns (uint256) {
        return royalty_amount;
    }

    /**
     *      @notice Called to return both the creator's address and the royalty percentage - this would be the main function called by marketplaces unless they specifically need just the royaltyAmount
     */
    function royaltyInfo() external view returns (uint256, address) {
        return (royalty_amount, creator);
    }

    /**
     *      @notice Called to verify if contract implements royalties - OPTIONAL as supportsInterface()  can be called as well.
     *      @param _creator The original creator of the NFT entitled to the royalties
     *      @param _buyer The buyer of the NFT in a secondary sale
     *      @param _amount The amount paid for royalties on this secondary sale. (Price of ERC721 sold * Royalty Percentage)
     */
    function royaltiesRecieved(
        address _creator,
        address _buyer,
        uint256 _amount
    ) external {
        emit RecievedRoyalties(_creator, _buyer, _amount);
    }

    /**
     *      @notice Called to verify if contract implements royalties - OPTIONAL as supportsInterface()  can be called as well.
     */
    function hasRoyalties() public pure returns (bool) {
        return true;
    }
}

