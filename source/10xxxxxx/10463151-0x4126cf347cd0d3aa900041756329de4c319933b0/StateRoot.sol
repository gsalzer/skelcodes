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
pragma solidity ^0.5.2;

import "IFactRegistry.sol";
import "MFreezable.sol";
import "FullWithdrawals.sol";
import "MStateRoot.sol";
import "MainStorage.sol";

/*
  Implements IVerifierActions.rootUpdate
  Uses MFreezable.
*/
contract StateRoot is MainStorage, MFreezable, MStateRoot
{
    event LogRootUpdate(
        uint256 sequenceNumber,
        uint256 batchId,
        uint256 vaultRoot,
        uint256 orderRoot
    );

    function initialize (
        uint256 initialSequenceNumber,
        uint256 initialVaultRoot,
        uint256 initialOrderRoot,
        uint256 initialVaultTreeHeight,
        uint256 initialOrderTreeHeight
    )
        internal
    {
        sequenceNumber = initialSequenceNumber;
        vaultRoot = initialVaultRoot;
        orderRoot = initialOrderRoot;
        vaultTreeHeight = initialVaultTreeHeight;
        orderTreeHeight = initialOrderTreeHeight;
    }

    function getVaultRoot()
        public view
        returns (uint256 root)
    {
        root = vaultRoot;
    }

    function getVaultTreeHeight()
        public view
        returns (uint256 height) {
        height = vaultTreeHeight;
    }

    function getOrderRoot()
        external view
        returns (uint256 root)
    {
        root = orderRoot;
    }

    function getOrderTreeHeight()
        external view
        returns (uint256 height) {
        height = orderTreeHeight;
    }

    function getSequenceNumber()
        external view
        returns (uint256 seq)
    {
        seq = sequenceNumber;
    }

    function getLastBatchId()
        external view
        returns (uint256 batchId)
    {
        batchId = lastBatchId;
    }

    /*
      Update state roots. Verify that the old roots and heights match.
    */
    function rootUpdate(
        uint256 oldVaultRoot,
        uint256 newVaultRoot,
        uint256 oldOrderRoot,
        uint256 newOrderRoot,
        uint256 vaultTreeHeightSent,
        uint256 orderTreeHeightSent,
        uint256 batchId
    )
        internal
        notFrozen()
    {
        // Assert that the old state is correct.
        require(oldVaultRoot == vaultRoot, "VAULT_ROOT_INCORRECT");
        require(oldOrderRoot == orderRoot, "ORDER_ROOT_INCORRECT");

        // Assert that heights are correct.
        require(vaultTreeHeight == vaultTreeHeightSent, "VAULT_HEIGHT_INCORRECT");
        require(orderTreeHeight == orderTreeHeightSent, "ORDER_HEIGHT_INCORRECT");

        // Update state.
        vaultRoot = newVaultRoot;
        orderRoot = newOrderRoot;
        sequenceNumber = sequenceNumber + 1;
        lastBatchId = batchId;

        // Log update.
        emit LogRootUpdate(sequenceNumber, batchId, vaultRoot, orderRoot);
    }
}

