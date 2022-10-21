// SPDX-License-Identifier: MIT

pragma solidity 0.7.3;

import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./NFT.sol";

contract SWAP is Context, ReentrancyGuard {
    address public authAddress;
    //IERC1155 private NFTInstance;

    constructor (address _houseAddress, address _nftAddress) {
        authAddress = _houseAddress;
        NFTInstance = NFTLootboxNFT(_nftAddress);
    }
    NFTLootboxNFT private NFTInstance;

    function _validateSwap(uint256[] memory _burnedAddresses, uint256[] memory _burnedAmount) private {
        require(_burnedAddresses.length == _burnedAmount.length);
        //creates quantity number for the require statement
        uint quantity = 0;
        for(uint i = 0; i < _burnedAmount.length; i++){
            quantity += _burnedAmount[i];
        }
        require(quantity == 10);
    }

    // This is for users to swap their nfts with the sites inventory
    // in the future users will be able to swap with one another   
    function swapWithHouse(uint256[] memory idArr, uint256[] memory quantArr, uint256 prizeID, uint8 v, bytes32 r, bytes32 s ) public {

        //security
        _validateSwap(idArr, quantArr);
        bytes32 hash = keccak256(abi.encode(idArr, quantArr, prizeID));
        address signer = ecrecover(hash, v, r, s);
        require(signer == authAddress, "Invalid signature");

        //transfering nfts to contract
        NFTInstance.safeBatchTransferFrom(_msgSender(), address(this), idArr, quantArr, "");

        //the ten nfts need to be burned
        NFTInstance.burnBatch(idArr, quantArr);

        // the one nft is awarded to the user
        NFTInstance.safeTransferFrom(authAddress, _msgSender(), prizeID, 1, "");
    }

}

