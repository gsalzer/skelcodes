// File: contracts/busd-oracle/interfaces/IOracle.sol

pragma solidity 0.4.26;

contract IOracle {
    function getValue() public view returns (uint256);
}

// File: contracts/busd-oracle/interfaces/IAggregator.sol

pragma solidity 0.4.26;

contract IAggregator {
    function latestAnswer() public view returns (int256);
}

// File: contracts/token/interfaces/IERC20Token.sol

pragma solidity 0.4.26;

/*
    ERC20 Standard Token interface
*/
contract IERC20Token {
    // these functions aren't abstract since the compiler emits automatically generated getter functions as external
    function name() public view returns (string) {this;}
    function symbol() public view returns (string) {this;}
    function decimals() public view returns (uint8) {this;}
    function totalSupply() public view returns (uint256) {this;}
    function balanceOf(address _owner) public view returns (uint256) {_owner; this;}
    function allowance(address _owner, address _spender) public view returns (uint256) {_owner; _spender; this;}

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

// File: contracts/busd-oracle/Owned.sol

pragma solidity 0.4.26;

contract Owned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address _prevOwner, address _newOwner);

    constructor () public { owner = msg.sender; }

    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

    function setOwner(address _newOwner) public ownerOnly {
        require(_newOwner != owner && _newOwner != address(0), "Unauthorized");
        emit OwnerUpdate(owner, _newOwner);
        owner = _newOwner;
        newOwner = address(0);
    }

    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner, "Invalid");
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner, "Unauthorized");
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

// File: contracts/busd-oracle/Oracle.sol

pragma solidity 0.4.26;





contract Oracle is IOracle, Owned {

    IAggregator public aggregator;

    constructor(IAggregator _aggregator) public {
        aggregator = _aggregator;
    }

    function updateAggregator(IAggregator _aggregator) public ownerOnly {
        aggregator = _aggregator;
    }

    function getValue() public view returns (uint256) {
        return uint256(aggregator.latestAnswer()/100);
    }

    function transferERC20Token(IERC20Token _token, address _to, uint256 _amount) public ownerOnly {
        _token.transfer(_to, _amount);
    }

}
