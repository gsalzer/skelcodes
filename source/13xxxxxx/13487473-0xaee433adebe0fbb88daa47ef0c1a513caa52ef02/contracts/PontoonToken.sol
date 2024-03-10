// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libs/ERC20Permit.sol";

/**
 * @title Pontoon Token
 * @dev Pontoon ERC20 Token
 */
contract PontoonToken is ERC20Permit, Ownable {
    uint256 public constant MAX_CAP = 100 * (10**6) * (10**18); // 100 million

    address public governance;

    event RecoverToken(address indexed token, address indexed destination, uint256 indexed amount);
    event GovernanceChanged(address indexed previousGovernance, address indexed newGovernance);

    modifier onlyGovernance() {
        require(msg.sender == governance, "!governance");
        _;
    }

    constructor() ERC20("PontoonToken", "TOON") {
        governance = msg.sender;
        _mint(governance, MAX_CAP);
    }

    /**
     * @notice Function to set governance contract
     * Owner is assumed to be governance
     * @param _governance Address of governance contract
     */
    function setGovernance(address _governance) public onlyGovernance {
        governance = _governance;
        emit GovernanceChanged(msg.sender, _governance);
    }

    /**
     * @notice Function to recover funds
     * Owner is assumed to be governance or Pontoon trusted party for helping users
     * @param token Address of token to be rescued
     * @param destination User address
     * @param amount Amount of tokens
     */
    function recoverToken(
        address token,
        address destination,
        uint256 amount
    ) external onlyGovernance {
        require(token != destination, "Invalid address");
        require(IERC20(token).transfer(destination, amount), "Retrieve failed");
        emit RecoverToken(token, destination, amount);
    }
}

