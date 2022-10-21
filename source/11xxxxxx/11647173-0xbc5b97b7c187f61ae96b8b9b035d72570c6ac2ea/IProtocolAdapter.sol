// SPDX-License-Identifier: MIT
pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import "types.sol";

interface IProtocolAdapter {
    /**
     * @notice Emitted when a new option contract is purchased
     */
    event Purchased(
        address indexed caller,
        string indexed protocolName,
        address indexed underlying,
        address strikeAsset,
        uint256 expiry,
        uint256 strikePrice,
        OptionType optionType,
        uint256 amount,
        uint256 premium,
        uint256 optionID
    );

    /**
     * @notice Emitted when an option contract is exercised
     */
    event Exercised(
        address indexed caller,
        address indexed options,
        uint256 indexed optionID,
        uint256 amount,
        uint256 exerciseProfit
    );

    /**
     * @notice Name of the adapter. E.g. "HEGIC", "OPYN_V1". Used as index key for adapter addresses
     */
    function protocolName() external pure returns (string memory);

    /**
     * @notice Boolean flag to indicate whether to use option IDs or not.
     * Fungible protocols normally use tokens to represent option contracts.
     */
    function nonFungible() external pure returns (bool);

    /**
     * @notice Returns the purchase method used to purchase options
     */
    function purchaseMethod() external pure returns (PurchaseMethod);

    /**
     * @notice Returns true if the options protocol is European style options, ie only exercising after expiry
     */
    function isEuropean() external pure returns (bool);

    /**
     * @notice Check if an options contract exist based on the passed parameters.
     * @param optionTerms is the terms of the option contract
     */
    function optionsExist(OptionTerms calldata optionTerms)
        external
        view
        returns (bool);

    /**
     * @notice Get the options contract's address based on the passed parameters
     * @param optionTerms is the terms of the option contract
     */
    function getOptionsAddress(OptionTerms calldata optionTerms)
        external
        view
        returns (address);

    /**
     * @notice Gets the premium to buy `purchaseAmount` of the option contract in ETH terms.
     * @param optionTerms is the terms of the option contract
     * @param purchaseAmount is the number of options purchased
     */
    function premium(OptionTerms calldata optionTerms, uint256 purchaseAmount)
        external
        view
        returns (uint256 cost);

    /**
     * @notice Amount of profit made from exercising an option contract (current price - strike price). 0 if exercising out-the-money.
     * @param options is the address of the options contract
     * @param optionID is the ID of the option position in non fungible protocols like Hegic.
     * @param amount is the amount of tokens or options contract to exercise. Only relevant for fungle protocols like Opyn
     */
    function exerciseProfit(
        address options,
        uint256 optionID,
        uint256 amount
    ) external view returns (uint256 profit);

    /**
     * @notice Purchases the options contract.
     * @param optionTerms is the terms of the option contract
     * @param amount is the purchase amount in Wad units (10**18)
     */
    function purchase(OptionTerms calldata optionTerms, uint256 amount)
        external
        payable
        returns (uint256 optionID);

    /**
     * @notice Exercises the options contract.
     * @param options is the address of the options contract
     * @param optionID is the ID of the option position in non fungible protocols like Hegic.
     * @param amount is the amount of tokens or options contract to exercise. Only relevant for fungle protocols like Opyn
     * @param recipient is the account that receives the exercised profits. This is needed since the adapter holds all the positions and the msg.sender is an instrument contract.
     */
    function exercise(
        address options,
        uint256 optionID,
        uint256 amount,
        address recipient
    ) external payable;
}
