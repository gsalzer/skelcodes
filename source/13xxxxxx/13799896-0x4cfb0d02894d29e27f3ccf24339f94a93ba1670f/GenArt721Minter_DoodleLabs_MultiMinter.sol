pragma solidity ^0.5.0;

import './GenArtMinterV2_DoodleLabs.sol';
import './SafeMath.sol';

contract GenArt721Minter_DoodleLabs_MultiMinter is GenArt721Minter_DoodleLabs {
    using SafeMath for uint256;

    event PurchaseMany(uint256 projectId, uint256 amount);
    event Purchase(uint256 _projectId);

    constructor(address _genArtCore) GenArt721Minter_DoodleLabs(_genArtCore) internal {}

    function _purchaseMany(uint256 projectId, uint256 amount) internal returns (uint256[] memory _tokenIds) {
        uint256[] memory tokenIds = new uint256[](amount);
        bool isDeferredRefund = false;

        // Refund ETH if user accidentially overpays
        // This is not needed for ERC20 tokens
        if (msg.value > 0) {
            uint256 pricePerTokenInWei = genArtCoreContract.projectIdToPricePerTokenInWei(projectId);
            uint256 refund = msg.value.sub(pricePerTokenInWei.mul(amount));
            isDeferredRefund = true;

            if (refund > 0) {
                msg.sender.transfer(refund);
            }
        }

        for (uint256 i = 0; i < amount; i++) {
            tokenIds[i] = purchaseTo(msg.sender, projectId, isDeferredRefund);
            emit Purchase(projectId);
        }

        return tokenIds;
    }

    function _purchase(uint256 _projectId) internal returns (uint256 _tokenId) {
        emit Purchase(_projectId);
        return purchaseTo(msg.sender, _projectId, false);
    }
}
