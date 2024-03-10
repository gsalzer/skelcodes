// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import '@openzeppelin/contracts/utils/EnumerableSet.sol';

import "./uniswapV2/interfaces/IUniswapV2Router02.sol";
import "./uniswapV2/interfaces/IWETH.sol";
import "./PremiaBondingCurve.sol";

/// @author Premia
/// @title A contract receiving all protocol fees, swapping them for eth, and using eth to purchase premia on the bonding curve
contract PremiaMaker is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    // UniswapRouter contracts which can be used to swap tokens
    EnumerableSet.AddressSet private _whitelistedRouters;

    // The premia token
    IERC20 public premia;
    // The premia bonding curve
    PremiaBondingCurve public premiaBondingCurve;
    // The premia staking contract (xPremia)
    address public premiaStaking;

    // The treasury address which will receive a portion of the protocol fees
    address public treasury;
    // The percentage of protocol fees the treasury will get (in basis points)
    uint256 public treasuryFee = 2e3; // 20%

    uint256 private constant _inverseBasisPoint = 1e4;

    // Set a custom swap path for a token
    mapping(address=>address[]) public customPath;

    ////////////
    // Events //
    ////////////

    event Converted(address indexed account, address indexed router, address indexed token, uint256 tokenAmount, uint256 premiaAmount);

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    //////////////////////////////////////////////////

    // @param _premia The premia token
    // @param _premiaBondingCurve The premia bonding curve
    // @param _premiaStaking The premia staking contract (xPremia)
    // @param _treasury The treasury address which will receive a portion of the protocol fees
    constructor(IERC20 _premia, address _premiaStaking, address _treasury) {
        premia = _premia;
        premiaStaking = _premiaStaking;
        treasury = _treasury;
    }

    //////////////////////////////////////////////////
    //////////////////////////////////////////////////
    //////////////////////////////////////////////////

    receive() external payable {}

    ///////////
    // Admin //
    ///////////

    /// @notice Set a custom swap path for a token
    /// @param _token The token
    /// @param _path The swap path
    function setCustomPath(address _token, address[] memory _path) external onlyOwner {
        customPath[_token] = _path;
    }

    /// @notice Set a new treasury fee
    /// @param _fee New fee
    function setTreasuryFee(uint256 _fee) external onlyOwner {
        require(_fee <= _inverseBasisPoint);
        treasuryFee = _fee;
    }

    /// @notice Set premia bonding curve contract
    /// @param _premiaBondingCurve PremiaBondingCurve contract
    function setPremiaBondingCurve(PremiaBondingCurve _premiaBondingCurve) external onlyOwner {
        premiaBondingCurve = _premiaBondingCurve;
    }

    /// @notice Add UniswapRouters to the whitelist so that they can be used to swap tokens.
    /// @param _addr The addresses to add to the whitelist
    function addWhitelistedRouter(address[] memory _addr) external onlyOwner {
        for (uint256 i=0; i < _addr.length; i++) {
            _whitelistedRouters.add(_addr[i]);
        }
    }

    /// @notice Remove UniswapRouters from the whitelist so that they cannot be used to swap tokens.
    /// @param _addr The addresses to remove the whitelist
    function removeWhitelistedRouter(address[] memory _addr) external onlyOwner {
        for (uint256 i=0; i < _addr.length; i++) {
            _whitelistedRouters.remove(_addr[i]);
        }
    }

    //////////////////////////

    /// @notice Get the list of whitelisted routers
    /// @return The list of whitelisted routers
    function getWhitelistedRouters() external view returns(address[] memory) {
        uint256 length = _whitelistedRouters.length();
        address[] memory result = new address[](length);

        for (uint256 i=0; i < length; i++) {
            result[i] = _whitelistedRouters.at(i);
        }

        return result;
    }

    /// @notice Convert tokens into ETH, use ETH to purchase Premia on the bonding curve, and send Premia to PremiaStaking contract
    /// @param _router The UniswapRouter contract to use to perform the swap (Must be whitelisted)
    /// @param _token The token to swap to premia
    function convert(IUniswapV2Router02 _router, address _token) public {
        require(address(premiaBondingCurve) != address(0), "Premia bonding curve not set");
        require(_whitelistedRouters.contains(address(_router)), "Router not whitelisted");

        IERC20 token = IERC20(_token);

        uint256 amount = token.balanceOf(address(this));
        uint256 fee = amount.mul(treasuryFee).div(_inverseBasisPoint);
        uint256 amountMinusFee = amount.sub(fee);

        token.safeTransfer(treasury, fee);

        if (amountMinusFee == 0) return;

        token.safeIncreaseAllowance(address(_router), amountMinusFee);

        address weth = _router.WETH();
        uint256 premiaAmount;

        if (_token != address(premia)) {
            if (_token != weth) {
                address[] memory path = customPath[_token];

                if (path.length == 0) {
                    path = new address[](2);
                    path[0] = _token;
                    path[1] = weth;
                }

                _router.swapExactTokensForETH(
                    amountMinusFee,
                    0,
                    path,
                    address(this),
                    block.timestamp.add(60)
                );
            } else {
                IWETH(weth).withdraw(amountMinusFee);
            }

            premiaAmount = premiaBondingCurve.buyTokenWithExactEthAmount{value: address(this).balance}(0, premiaStaking);
        } else {
            premiaAmount = amountMinusFee;
            premia.safeTransfer(premiaStaking, premiaAmount);
            // Just for the event
            _router = IUniswapV2Router02(0);
        }

        emit Converted(msg.sender, address(_router), _token, amountMinusFee, premiaAmount);
    }
}

