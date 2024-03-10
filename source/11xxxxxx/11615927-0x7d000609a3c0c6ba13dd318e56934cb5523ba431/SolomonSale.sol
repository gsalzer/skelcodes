// SPDX-License-Identifier: MIT
pragma solidity ~0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

/// @title Solomon Sale
/// @author Solomon DeFi
/// @notice ERC20 sale contract
contract SolomonSale is Ownable {

    /// @notice ETH has been exchanged for tokens
    /// @param buyer The address of the exchanger
    /// @param paid The amount of ETH paid
    /// @param tokenAmount The number of tokens exchanged
    event Exchange(address buyer, uint256 paid, uint256 tokenAmount);

    /// @dev ERC20 token used for the sale
    ERC20 private _token;

    /// @dev Exchange rate of ETH to SLM
    uint256 private _exchangeRate;

    /// @dev Minimum amount of ETH for a valid exchange
    uint256 private _minimum;

    /// @dev Track contributions to enforce per-address maximums
    mapping(address => uint256) private _contributions;

    /// @dev Maximum amount of ETH an address can exchange
    uint256 private _maximum;

    /// @dev Exchange disabled when paused
    bool private _paused = false;

    /// @notice Set up the sale with the token
    /// @param token Token used for sale
    /// @param initialExchangeRate Number of SLM provided for 1 ETH
    /// @param minExchange Initial minimum ETH for a valid exchange
    /// @param maxExchange Initial maximum ETH for a valid exchange
    constructor(
        address token, uint256 initialExchangeRate, uint256 minExchange, uint256 maxExchange
    ) {
        require(token != address(0), "Invalid token address");
        require(initialExchangeRate > 0, "Invalid exchange rate");
        _token = ERC20(token);
        _exchangeRate = initialExchangeRate;
        _minimum = minExchange;
        _maximum = maxExchange;
        // Check to see if the token is initialized
        require(_token.totalSupply() > 0, "Token not initialized");
    }

    /// @notice Get the ETH -> ERC20 exchange rate
    /// @return Sale exchange rate
    function exchangeRate() public view returns (uint256) {
        return _exchangeRate;
    }

    /// @notice Set the ETH -> ERC20 exchange rate
    /// @param newExchangeRate The new exchange rate
    function setExchangeRate(uint256 newExchangeRate) external onlyOwner {
        require(newExchangeRate > 0, "Invalid exchange rate");
        _exchangeRate = newExchangeRate;
    }

    /// @notice Set the minimum amount of ETH (wei) per transaction
    function setMinimumExchange(uint256 newMinimum) external onlyOwner {
        _minimum = newMinimum;
    }

    /// @notice Get the minimum amount of ETH (wei) per transaction
    /// @return Minimum ETH (wei) per transaction
    function minimum() public view returns (uint256) {
        return _minimum;
    }

    /// @notice Set the maximum amount of ETH (wei) each address can exchange
    function setMaximumExchange(uint256 newMaximum) external onlyOwner {
        _maximum = newMaximum;
    }

    /// @notice Get the maximum amount of ETH (wei) each address can exchange
    /// @return Maximum ETH (wei) per address
    function maximum() public view returns (uint256) {
        return _maximum;
    }

    /// @notice Pause the sale
    function pause() external onlyOwner {
        _paused = true;
    }

    /// @notice Unpause the sale
    function unpause() external onlyOwner {
        _paused = false;
    }

    /// @notice Get whether the sale is paused
    /// @return true if the sale is paused, false otherwise
    function paused() public view returns (bool) {
        return _paused;
    }
    
    /// @notice Get the total ETH contribution by `wallet`
    /// @param wallet The wallet address to check
    /// @return Total ETH (wei) contributed
    function getContribution(address wallet) public view returns (uint256) {
        return _contributions[wallet];
    }

    /// @notice Get the number of tokens currently up for sale
    /// @return Total tokens available
    function availableTokens() public view returns (uint256) {
        return _token.balanceOf(address(this));
    }

    /// @notice Exchange the value of ETH sent in the transaction for ERC20 tokens
    function exchange() public payable {
        require(!_paused, "Sale is paused");
        require(msg.value >= _minimum, "Value less than minimum");

        uint256 contributed = _contributions[msg.sender] + msg.value;
        require((_maximum == 0) || (contributed <= _maximum), "Contribution limit exceeded");

        uint256 tokenAmount = msg.value * _exchangeRate;
        require(availableTokens() >= tokenAmount, "Sale funds low");

        _contributions[msg.sender] = contributed;

        _token.transfer(msg.sender, tokenAmount);

        emit Exchange(msg.sender, msg.value, tokenAmount);
    }

    /// @notice Exchange the value of ETH sent in the transaction for ERC20 tokens
    receive() external payable {
        exchange();
    }

    /// @notice Return excess tokens to the owner
    function recoverTokens() external onlyOwner {
        _token.transfer(msg.sender, availableTokens());
    }

    /// @notice Send contract ETH to the owner
    function withdrawEth() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
