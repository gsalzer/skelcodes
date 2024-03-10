//Copyright Octobase.co 2019

pragma solidity ^0.5.0;

import "./safemath.sol";
import "./statuscodes.sol";
import "./roundtable.sol";

//Copyright Octobase.co 2019

contract RoundTableFactory is IRoundTableFactory
{
    using SafeMath for uint256;

    //State
    address public factoryOwner;
    address[] public roundTables;
    uint public roundTableCount;
    mapping(address=>bool) public roundTableMapping;
    mapping(address=>bool) public successors;

    //Events
    event ProduceRoundTable(address indexed producer, ISigner indexed ward, RoundTable indexed roundTable);

    modifier onlyOwner() {
        require (msg.sender == factoryOwner, "Only the owner may call this method");
        _;
    }

    constructor(address _factoryOwner)
        public
    {
        factoryOwner = _factoryOwner;
    }

    function produceRoundTable(ISigner _ward, address[] calldata _guardians)
        external
        returns
        (StatusCodes.Status _status, IRoundTable roundTable)
    {
        RoundTable createdRoundTable = new RoundTable(_ward, _guardians, this);
        address roundTableAddress = address(createdRoundTable);
        roundTables.push(roundTableAddress);
        roundTableMapping[roundTableAddress] = true;
        emit ProduceRoundTable(msg.sender, _ward, createdRoundTable);
        roundTableCount = roundTableCount.add(1);
        return (StatusCodes.Status.Success, IRoundTable(roundTableAddress));
    }

    function changeOwner(address _newFactoryOwner)
        external
        onlyOwner
    {
        factoryOwner = _newFactoryOwner;
    }

    function setSuccessor(address _successor, bool _isSuccessor)
        external
        onlyOwner
        returns (StatusCodes.Status status)
    {
        successors[_successor] = _isSuccessor;
        return StatusCodes.Status.Success;
    }

    function octobaseType()
        external
        pure
        returns (uint16 typeCode)
    {
        return 8;
    }

    function octobaseTypeVersion()
        external
        pure
        returns (uint32 typeVersion)
    {
        return 1;
    }
}
