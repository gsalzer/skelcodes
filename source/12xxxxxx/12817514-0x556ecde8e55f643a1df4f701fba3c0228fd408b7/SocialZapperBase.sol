// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./IATokenV1.sol";
import "./ICToken.sol";
import "./IComptroller.sol";
import "./ISushiBar.sol";
import "./ILendingPoolV1.sol";
import "./ICompoundLens.sol";
import "./IUniswapV2.sol";
import "./IBasicIssuanceModule.sol";
import "./IOneInch.sol";

import "./SafeMath.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./BMIZapper.sol";

// Basket Weaver is a way to socialize gas costs related to minting baskets tokens
contract SocialZapperBase is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public governance;
    address public bmi;

    // **** ERC20 **** //

    // Token => Id
    mapping(address => uint256) public curId;

    // Token => User Address => Id => Amount deposited
    mapping(address => mapping(address => mapping(uint256 => uint256))) public deposits;

    // Token => User Address => Id => Claimed
    mapping(address => mapping(address => mapping(uint256 => bool))) public claimed;

    // Token => Id => Amount deposited
    mapping(address => mapping(uint256 => uint256)) public totalDeposited;

    // Token => Basket zapped per weaveId
    mapping(address => mapping(uint256 => uint256)) public zapped;

    // Approved users to call weave
    // This is v important as invalid inputs will
    // be basically a "fat finger"
    mapping(address => bool) public approvedWeavers;

    // **** Constructor and modifiers ****

    constructor(address _governance, address _bmi) {
        governance = _governance;
        bmi = _bmi;
    }

    modifier onlyGov() {
        require(msg.sender == governance, "!governance");
        _;
    }

    modifier onlyWeavers {
        require(msg.sender == governance || approvedWeavers[msg.sender], "!weaver");
        _;
    }

    receive() external payable {}

    // **** Protected functions ****

    function approveWeaver(address _weaver) public onlyGov {
        approvedWeavers[_weaver] = true;
    }

    function revokeWeaver(address _weaver) public onlyGov {
        approvedWeavers[_weaver] = false;
    }

    function setGov(address _governance) public onlyGov {
        governance = _governance;
    }

    // Emergency
    function recoverERC20(address _token) public onlyGov {
        IERC20(_token).safeTransfer(governance, IERC20(_token).balanceOf(address(this)));
    }

    // **** Public functions ****

    /// @notice Deposits ERC20 to be later converted into the Basket by some kind soul
    function deposit(address _token, uint256 _amount) public nonReentrant {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        deposits[_token][msg.sender][curId[_token]] = deposits[_token][msg.sender][curId[_token]].add(_amount);
        totalDeposited[_token][curId[_token]] = totalDeposited[_token][curId[_token]].add(_amount);
    }

    /// @notice User doesn't want to wait anymore and just wants their ERC20 back
    function withdraw(address _token, uint256 _amount) public nonReentrant {
        // Reverts if withdrawing too many
        deposits[_token][msg.sender][curId[_token]] = deposits[_token][msg.sender][curId[_token]].sub(_amount);
        totalDeposited[_token][curId[_token]] = totalDeposited[_token][curId[_token]].sub(_amount);

        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    // **** Internal functions ****

    /// @notice User withdraws <x> token
    function _withdrawZapped(
        address _target,
        address _token,
        uint256 _id
    ) internal nonReentrant {
        require(_id < curId[_token], "!weaved");
        require(!claimed[_token][msg.sender][_id], "already-claimed");
        uint256 userDeposited = deposits[_token][msg.sender][_id];
        require(userDeposited > 0, "!deposit");

        uint256 ratio = userDeposited.mul(1e18).div(totalDeposited[_token][_id]);
        uint256 userZappedAmount = zapped[_token][_id].mul(ratio).div(1e18);
        claimed[_token][msg.sender][_id] = true;

        IERC20(address(_target)).safeTransfer(msg.sender, userZappedAmount);
    }

    /// @notice User withdraws converted Basket token
    function _withdrawZappedMany(
        address _target,
        address[] memory _tokens,
        uint256[] memory _ids
    ) public {
        assert(_tokens.length == _ids.length);

        for (uint256 i = 0; i < _tokens.length; i++) {
            _withdrawZapped(_target, _tokens[i], _ids[i]);
        }
    }
}

