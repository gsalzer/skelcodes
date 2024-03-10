// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../helpers/errors.sol";
import "../../ImplBase.sol";

/**
@title Anyswap L2 Implementation.
@notice This is the L2 implementation, so this is used when transferring from
l2 to supported l2s or L1.
Called by the registry if the selected bridge is Anyswap bridge.
@dev Follows the interface of ImplBase.
@author Movr Network.
*/
interface AnyswapV3Router {
    function anySwapOutUnderlying(
        address token,
        address to,
        uint256 amount,
        uint256 toChainID
    ) external;
}

contract AnyswapImplL1 is ImplBase {
    using SafeERC20 for IERC20;
    AnyswapV3Router public immutable router;

    /**
    @notice Constructor sets the router address and registry address.
    @dev anyswap v3 address is constant. so no setter function required.
    */
    constructor(AnyswapV3Router _router, address _registry)
        ImplBase(_registry)
    {
        router = _router;
    }

    /**
    @notice function responsible for calling cross chain transfer using anyswap bridge.
    @dev the token to be passed on to anyswap function is supposed to be the wrapper token
    address.
    @param _amount amount to be sent.
    @param _from sender address. 
    @param _to receivers address.
    @param _token this is the main token address on the source chain. 
    @param _toChainId destination chain Id
    @param _data data contains the wrapper token address for the token
    */
    function outboundTransferTo(
        uint256 _amount,
        address _from,
        address _to,
        address _token,
        uint256 _toChainId,
        bytes memory _data
    ) external override onlyRegistry {
        address _wrapperTokenAddress = abi.decode(_data, (address));
        IERC20(_token).safeTransferFrom(_from, address(this), _amount);
        IERC20(_token).safeIncreaseAllowance(address(router), _amount);
        router.anySwapOutUnderlying(
            _wrapperTokenAddress,
            _to,
            _amount,
            _toChainId
        );
    }
}

