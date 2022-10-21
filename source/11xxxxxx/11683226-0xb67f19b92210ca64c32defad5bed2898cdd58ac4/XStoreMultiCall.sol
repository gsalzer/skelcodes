// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./IXStore.sol";

contract XStoreMultiCall {
    IXStore public xStore;

    constructor() public {
        xStore = IXStore(0xBe54738723cea167a76ad5421b50cAa49692E7B7);
    }

    function getVaultDataA(uint256 vaultId)
        public
        view
        returns (
            address xTokenAddress,
            address nftAddress,
            address manager,
            bool isClosed,
            bool isD2Vault,
            address d2AssetAddress
        )
    {
        address _xTokenAddress = xStore.xTokenAddress(vaultId);
        address _nftAddress = xStore.nftAddress(vaultId);
        address _manager = xStore.manager(vaultId);
        bool _isClosed = xStore.isClosed(vaultId);
        bool _isD2Vault = xStore.isD2Vault(vaultId);
        address _d2AssetAddress = xStore.d2AssetAddress(vaultId);

        return (
            _xTokenAddress,
            _nftAddress,
            _manager,
            _isClosed,
            _isD2Vault,
            _d2AssetAddress
        );
    }

    function getVaultDataB(uint256 vaultId)
        public
        view
        returns (
            bool allowMintRequests,
            bool flipEligOnRedeem,
            bool negateEligibility,
            bool isFinalized
        )
    {
        bool _allowMintRequests = xStore.allowMintRequests(vaultId);
        bool _flipEligOnRedeem = xStore.flipEligOnRedeem(vaultId);
        bool _negateEligibility = xStore.negateEligibility(vaultId);
        bool _isFinalized = xStore.isFinalized(vaultId);

        return (
            _allowMintRequests,
            _flipEligOnRedeem,
            _negateEligibility,
            _isFinalized
        );
    }
}

