// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./helpers/errors.sol";

/**
@title Abstract Implementation Contract.
@notice All Bridge Implementation will follow this interface. 
*/
abstract contract ImplBase is Ownable {
    using SafeERC20 for IERC20;
    address public registry;

    constructor(address _registry) Ownable() {
        registry = _registry;
    }

    modifier onlyRegistry {
        require(msg.sender == registry, MovrErrors.INVALID_SENDER);
        _;
    }

    function updateRegistryAddress(address newRegistry) external onlyOwner {
        registry = newRegistry;
    }

    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(userAddress, amount);
    }

    function outboundTransferTo(
        uint256 _amount,
        address _from,
        address _to,
        address _token,
        uint256 _toChainId,
        bytes memory _extraData
    ) external virtual;
}

