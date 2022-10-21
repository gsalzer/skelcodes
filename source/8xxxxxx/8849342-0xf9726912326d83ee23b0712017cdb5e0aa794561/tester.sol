//Copyright Octobase.co 2019
pragma solidity ^0.5.1;
import "./statuscodes.sol";
import "./safemath.sol";

contract Tester
{
    event Log(string message);

    constructor() public { }

    function()
        external
        payable
    {
        emit Log("fall back");
    }

    function externalLog()
        external
    {
        emit Log("external");
    }

    function publicLog()
        public
    {
        emit Log("public");
    }
}

contract Reverter
{
    constructor() public { }

    function()
        external
    {
        revert("Always revert");
    }
}

contract NotSuccessfulRoundTableFactory
{
    using SafeMath for uint256;

    constructor() public { }

    uint256 public count;

    function produceRoundTable(address _ward, address[] calldata _guardians)
        external
        returns
        (StatusCodes.Status status, address roundTable)
    {
        count = count.add(_guardians.length);
        count = count.add(_guardians.length.div(2));
        return (StatusCodes.Status.Failure, _ward);
    }
}
