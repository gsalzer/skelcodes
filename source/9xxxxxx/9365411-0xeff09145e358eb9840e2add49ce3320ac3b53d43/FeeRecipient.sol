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

// File: contracts/utility/interfaces/IOwned.sol

pragma solidity 0.4.26;

/*
    Owned contract interface
*/
contract IOwned {
    // this function isn't abstract since the compiler emits automatically generated getter functions as external
    function owner() public view returns (address) {this;}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

// File: contracts/token/interfaces/ISmartToken.sol

pragma solidity 0.4.26;



/*
    Smart Token interface
*/
contract ISmartToken is IOwned, IERC20Token {
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}

// File: contracts/busd-splitting-contract/Owned.sol

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

// File: contracts/busd-splitting-contract/FeeRecipient.sol

pragma solidity 0.4.26;




contract FeeRecipient is Owned {
    
    IERC20Token public stableToken;
    ISmartToken public relay1;
    ISmartToken public relay2;

    constructor (IERC20Token _token, ISmartToken _relay1, ISmartToken _relay2) public {
        stableToken = _token;
        relay1 = _relay1;
        relay2 = _relay2;
    }

    function token() public view returns(ISmartToken) {
        return relay1;
    }

    function setStableToken(IERC20Token _token) public ownerOnly {
        stableToken = _token;
    }

    function setRelay1(ISmartToken _relay1) public ownerOnly {
        relay1 = _relay1;
    }

    function setRelay2(ISmartToken _relay2) public ownerOnly {
        relay2 = _relay2;
    }

    function sendSplitFees() public {
        uint256 amount = stableToken.balanceOf(this) / 2;
        stableToken.transfer(relay1.owner(), amount);
        stableToken.transfer(relay2.owner(), amount);
    }

    function transferERC20Token(IERC20Token _token, address _to, uint256 _amount) public ownerOnly {
        _token.transfer(_to, _amount);
    }
}
