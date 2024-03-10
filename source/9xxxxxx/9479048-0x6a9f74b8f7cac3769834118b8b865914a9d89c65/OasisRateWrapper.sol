pragma solidity 0.6.1;

interface IERC20 {
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

interface OasisInterface {
    function getConversionRate(IERC20 src, IERC20 dest, uint srcQty, uint) external view returns(uint);
}

contract OasisRateWrapper {

    function getTokenRates(OasisInterface oasisConversionRateContract, uint[] memory srcAmounts, IERC20 src, IERC20 dst)
    public view
    returns (uint[] memory rates)
    {
        rates = new uint[](srcAmounts.length);
        for ( uint i = 0; i < srcAmounts.length; i++) {
            rates[i] = oasisConversionRateContract.getConversionRate(src, dst, srcAmounts[i], 0);
        }
    }

}
