//Copyright Octobase.co 2019
pragma solidity ^0.5.1;
import "./safemath.sol";

contract TimeProvider
{
    using SafeMath for uint256;
    bool public isLive;
    uint256 public offset;

    constructor()
        public
    { }

    function travelForward(uint256 _seconds)
        public
    {
        offset = offset.add(_seconds);
    }

    function travelBackwards(uint256 _seconds)
        public
    {
        offset = offset.sub(_seconds);
    }

    function travelToNow()
        public
    {
        offset = 0;
    }

    function blocktime()
        external
        view
        returns (uint256)
    {
        return block.timestamp.add(offset);
    }
}

contract timeConsumer
{
    using SafeMath for uint256;

    TimeProvider public timeProvider;

    constructor(bool _useChainTime)
        public
    {
        if (_useChainTime)
            timeProvider = TimeProvider(address(0));
        else
            timeProvider = new TimeProvider();
    }

    function blocktime()
        public
        view
        returns(uint256)
    {
        if (address(timeProvider) == address(0))
        {
            return block.timestamp;
        }
        else
        {
            return timeProvider.blocktime();
        }
    }
}
