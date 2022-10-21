// SPDX-License-Identifier: MIT
pragma solidity ~0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

/// @title Solomon Vesting
/// @author Solomon DeFi
/// @notice ERC20 Vesting Contract
contract SolomonVesting is Ownable {

    /// Vested tokens originate from this ERC20 token contract 
    ERC20 public token;

    /// @notice Emitted when tokens are released to the beneficiary
    /// @param amount The number of tokens released
    event Released(uint256 amount);

    /// The beneficiary of the vesting schedule
    address public beneficiary;

    /// Number of tokens vested to `beneficiary`
    uint256 public released;

    /// Period between vesting releases in seconds
    uint256 public period;

    /// Number of payments to be made
    uint256 public installments;

    /// Timestamp of vesting start
    uint256 public startTime;

    /// @param _beneficiary The account that receives vested tokens
    /// @param _token The address of the ERC20 token contract
    /// @param _beneficiary The address that receives vested tokens
    /// @param _period The period in seconds between installments
    /// @param _installments The number of vesting installments
    constructor(address _token, address _beneficiary, uint256 _period, uint256 _installments) {
        beneficiary = _beneficiary;
        token = ERC20(_token);
        period = _period;
        installments = _installments;
    }

    /// @notice Initialize the vesting contract using tokens approved by `provider`
    /// @param provider Address that provides tokens for vesting
    function initializeFrom(address provider) public onlyOwner {
        uint256 approval = token.allowance(provider, address(this));
        require(approval > 0, "Must initialize with tokens");
        startTime = block.timestamp;
        token.transferFrom(provider, address(this), approval);
    }

    /// @notice Transfer vested tokens to beneficiary.
    function release() external {
        require((msg.sender == _owner) || (msg.sender == beneficiary));
        
        uint256 unreleased = tokensAvailable();
        require(unreleased > 0);

        released = released + unreleased;

        token.transfer(beneficiary, unreleased);

        emit Released(unreleased);
    }

    function balance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function currentInstallment() public view returns (uint256) {
        return (block.timestamp - startTime) / period;
    }

    /// @notice Calculates the amount that has already vested but hasn't been released yet.
    /// @return Number of releasable tokens
    function tokensAvailable() public view returns (uint256) {
        uint256 tokens = balance();

        uint256 curInstallment = currentInstallment();
        if(curInstallment >= installments) {
            return tokens;
        }
        uint256 releasePerInstallment = (tokens + released) / installments;
        uint256 releasable = curInstallment * releasePerInstallment;
        return releasable - released;
    }
}


