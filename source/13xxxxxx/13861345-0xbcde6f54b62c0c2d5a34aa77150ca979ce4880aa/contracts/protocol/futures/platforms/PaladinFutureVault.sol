// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
import "contracts/protocol/futures/HybridFutureVault.sol";
import "contracts/interfaces/platforms/IpalStTokenPool.sol";

/**
 * @title Contract for Paladin Future
 * @notice Handles the future mechanisms for palStTokens
 */
contract PaladinFutureVault is HybridFutureVault {
    IpalStTokenPool public constant POOL_CONTRACT = IpalStTokenPool(0xCDc3DD86C99b58749de0F697dfc1ABE4bE22216d);

    /**
     * @notice Getter for the rate of the IBT
     * @return the uint256 rate, IBT x rate must be equal to the quantity of underlying tokens
     */
    function getIBTRate() public view virtual override returns (uint256) {
        return POOL_CONTRACT.exchangeRateStored();
    }
}

