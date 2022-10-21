interface ERC20 {
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
}

interface OneSplit {
    function swap(
        address,
        address,
        uint256,
        uint256,
        uint256[] calldata,
        uint256
    )
        external
        payable;
    function getExpectedReturn(
        address,
        address,
        uint256,
        uint256,
        uint256
    )
        external
        view
        returns (uint256, uint256[] memory);
}

contract Test {
    address internal constant ONE_SPLIT = 0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E;

    function getReturn(
        address fromToken,
        address toToken,
        uint256 ethAmount
    )
        public
        view
        returns (uint256, uint256[] memory)
    {
        OneSplit oneSplit = OneSplit(ONE_SPLIT);
        uint256 returnAmount;
        uint256[] memory distribution;
        (returnAmount, distribution) = oneSplit.getExpectedReturn(
            address(0),
            toToken,
            ethAmount,
            1,
            0
        );
    }
}
