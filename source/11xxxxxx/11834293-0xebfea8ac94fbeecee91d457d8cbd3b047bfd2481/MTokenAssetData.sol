/*
  Copyright 2019,2020 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.11;

abstract contract MTokenAssetData {

    // NOLINTNEXTLINE: external-function.
    function getAssetInfo(uint256 assetType)
        public
        view
        virtual
        returns (bytes memory assetInfo);

    function extractTokenSelector(bytes memory assetInfo)
        internal
        pure
        virtual
        returns (bytes4 selector);

    function isEther(uint256 assetType)
        internal
        view
        virtual
        returns (bool);

    function isFungibleAssetType(uint256 assetType)
        internal
        view
        virtual
        returns (bool);

    function isMintableAssetType(uint256 assetType)
        internal
        view
        virtual
        returns (bool);

    function extractContractAddress(bytes memory assetInfo)
        internal
        pure
        virtual
        returns (address _contract);

    function calculateNftAssetId(uint256 assetType, uint256 tokenId)
        internal
        pure
        virtual
        returns(uint256 assetId);

    function calculateMintableAssetId(uint256 assetType, bytes memory mintingBlob)
        internal
        pure
        virtual
        returns(uint256 assetId);
}

