pragma solidity >=0.4.25 <0.6.0;


interface BalanceRecordable {
    
    function balanceRecordsCount(address account)
    external
    view
    returns (uint256);

    
    function recordBalance(address account, uint256 index)
    external
    view
    returns (uint256);

    
    function recordBlockNumber(address account, uint256 index)
    external
    view
    returns (uint256);

    
    function recordIndexByBlockNumber(address account, uint256 blockNumber)
    external
    view
    returns (int256);
}

library SafeMathUintLib {
    function mul(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
    {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
    {
        
        uint256 c = a / b;
        
        return c;
    }

    function sub(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    
    
    
    function clamp(uint256 a, uint256 min, uint256 max)
    public
    pure
    returns (uint256)
    {
        return (a > max) ? max : ((a < min) ? min : a);
    }

    function clampMin(uint256 a, uint256 min)
    public
    pure
    returns (uint256)
    {
        return (a < min) ? min : a;
    }

    function clampMax(uint256 a, uint256 max)
    public
    pure
    returns (uint256)
    {
        return (a > max) ? max : a;
    }
}

contract BalanceAucCalculator {
    using SafeMathUintLib for uint256;

    
    
    
    
    
    
    
    
    
    
    function calculate(BalanceRecordable balanceRecordable, address wallet, uint256 startBlock, uint256 endBlock)
    public
    view
    returns (uint256)
    {
        
        if (endBlock < startBlock)
            return 0;

        
        uint256 recordsCount = balanceRecordable.balanceRecordsCount(wallet);

        
        if (0 == recordsCount)
            return 0;

        
        int256 _endIndex = balanceRecordable.recordIndexByBlockNumber(wallet, endBlock);

        
        if (0 > _endIndex)
            return 0;

        
        uint256 endIndex = uint256(_endIndex);

        
        
        startBlock = startBlock.clampMin(balanceRecordable.recordBlockNumber(wallet, 0));

        
        uint256 startIndex = uint256(balanceRecordable.recordIndexByBlockNumber(wallet, startBlock));

        
        uint256 result = 0;

        
        if (startIndex < endIndex)
            result = result.add(
                balanceRecordable.recordBalance(wallet, startIndex).mul(
                    balanceRecordable.recordBlockNumber(wallet, startIndex.add(1)).sub(startBlock)
                )
            );

        
        for (uint256 i = startIndex.add(1); i < endIndex; i = i.add(1))
            result = result.add(
                balanceRecordable.recordBalance(wallet, i).mul(
                    balanceRecordable.recordBlockNumber(wallet, i.add(1)).sub(
                        balanceRecordable.recordBlockNumber(wallet, i)
                    )
                )
            );

        
        result = result.add(
            balanceRecordable.recordBalance(wallet, endIndex).mul(
                endBlock.sub(
                    balanceRecordable.recordBlockNumber(wallet, endIndex).clampMin(startBlock)
                ).add(1)
            )
        );

        
        return result;
    }
}
