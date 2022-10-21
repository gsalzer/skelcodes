pragma solidity ^0.8.0;

interface ILiquidityProtection {
    function liquidityAdded(
        uint _liquidity_block_number,
        uint _added_liquidity_amount,
        bool _IDOFactoryEnabled,
        uint _IDONumber,
        uint _IDOBlocks,
        uint _IDOParts,
        bool _firstBlockProtectionEnabled,
        bool _blockProtectionEnabled,
        uint _blocksToProtect,
        address _token
        ) external;
    function updateIDOPartAmount(address _from, uint _amount) external returns(bool);
    function verifyAmountPercent(uint _amount, uint _amountProtectorPercent) external view returns (bool);
    function verifyBlockNumber() external view returns(bool);
    function verifyFirstBlock() external view returns (bool);
    function verifyPriceAffect(address _from, uint _amount, uint _priceAfeectValue) external returns(bool);
    function updateRateLimitProtector(address _from, address _to, uint _rateLimitTime) external returns(bool);
    function verifyBlockedAddress(address _from, address _to) external view returns (bool);
    function blockAddress(address _address) external;
    function blockAddresses(address[] memory _addresses) external;
    function unblockAddress(address _address) external;
    function unblockAddresses(address[] memory _addresses) external;
}
