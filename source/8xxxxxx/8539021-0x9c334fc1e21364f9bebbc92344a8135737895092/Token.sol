pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address) public view returns (uint256);
    function transfer(address, uint256) public returns (bool);
    function transferFrom(address, address, uint256) public returns (bool);
    function approve(address, uint256) public returns (bool);
    function allowance(address, address) public view returns (uint256);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract contractInterface {
    function hasSupportFor(address, uint256, bytes memory) public returns (bool);
}

contract delegableTokenInterface {
    bytes public constant signingPrefix = "\x19Ethereum Signed Message:\n32";
    bytes4 public constant signedTransferSig = "\x75\x32\xea\xac";

    function signedTransferHash(address, address, uint, uint, uint) public view returns (bytes32);
    function signedTransfer(address, address, uint, uint, uint, bytes memory, address) public returns (bool);
    function signedTransferCheck(address, address, uint, uint, uint, bytes memory, address) public view returns (string memory);
}


contract Owned {
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // allow transfer of ownership to another address in case shit hits the fan.
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

contract StandardToken is ERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;


    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
    
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        // Added to prevent potential race attack.
        // forces caller of this function to ensure address allowance is already 0
        // ref: https://github.com/ethereum/EIPs/issues/738
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    /**
    * approve should be called when allowed[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}


contract delegableToken is StandardToken, delegableTokenInterface {
    mapping(address => uint) internal nextNonce;

    function getNextNonce(address _owner) public view returns (uint) {
        return nextNonce[_owner];
    }


    /**
     * Prevalidation - Checks nonce value, signing account/parameter mismatch, balance sufficient for transfer
     */    
    function signedTransferCheck(address from, address to, uint transferAmount, uint fee,
                                    uint nonce, bytes memory sig, address feeAccount) public view returns (string memory result) {
        bytes32 hash = signedTransferHash(from, to, transferAmount, fee, nonce);
        if (nextNonce[from] != nonce)
            return "Nonce does not match.";
        if (from == address(0) || from != ecrecoverFromSig(keccak256(abi.encodePacked(signingPrefix, hash)), sig))
            return "Mismatch in signing account or parameter mismatch.";
        if (transferAmount > balances[from])
            return "Transfer amount exceeds token balance on address.";
        if (transferAmount.add(fee) > balances[from])
            return "Insufficient tokens to pay for fees.";
        if (balances[feeAccount] + fee < balances[feeAccount])
            return "Overflow error.";
        return "All checks cleared";
    }

    // ------------------------------------------------------------------------
    // ecrecover from a signature rather than the signature in parts [v, r, s]
    // The signature format is a compact form {bytes32 r}{bytes32 s}{uint8 v}.
    // Compact means, uint8 is not padded to 32 bytes.
    //
    // An invalid signature results in the address(0) being returned, make
    // sure that the returned result is checked to be non-zero for validity
    //
    // Parts from https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
    // ------------------------------------------------------------------------
    function ecrecoverFromSig(bytes32 hash, bytes memory sig) public pure returns (address recoveredAddress) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (sig.length != 65) return address(0);
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            // Here we are loading the last 32 bytes. We exploit the fact that 'mload' will pad with zeroes if we overread.
            // There is no 'mload8' to do this, but that would be nicer.
            v := byte(0, mload(add(sig, 96)))
        }
        // Albeit non-transactional signatures are not specified by the YP,
        // one would expect it to match the YP range of [27, 28]
        // geth uses [0, 1] and some clients have followed. This might change,
        // see https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27) {
          v += 27;
        }
        if (v != 27 && v != 28) return address(0);
        return ecrecover(hash, v, r, s);
    }


    /**
     * Creates keccak256 hash of sent parameters
     */
    function signedTransferHash(address from, address to, uint transferAmount, uint fee,
                                    uint nonce) public view returns (bytes32 hash) {
        hash = keccak256(
            abi.encodePacked(signedTransferSig, address(this), from, to, transferAmount, fee, nonce)
                        );
    }

    /**
     * executes signedTransfer, allowing tokens to be sent through a delegate
     */
    function signedTransfer(address from, address to, uint transferAmount, uint fee,
                            uint nonce, bytes memory sig, address feeAccount) public returns (bool success) {
        bytes32 hash = signedTransferHash(from, to, transferAmount, fee, nonce);
        // verifies if signature is indeed signed by owner, and with the same values
        require(from != address(0) && from == ecrecoverFromSig(keccak256(abi.encodePacked(signingPrefix, hash)), sig));
        require(nextNonce[from] == nonce);

        // update nonce
        nextNonce[from] = nonce + 1;

        // transfer tokens
        balances[from] = balances[from].sub(transferAmount);
        balances[to] = balances[to].add(transferAmount);
        emit Transfer(from, to, transferAmount);
        
        // transfer fees
        balances[from] = balances[from].sub(fee);
        balances[feeAccount] = balances[feeAccount].add(fee);
        emit Transfer(from, feeAccount, fee);
        return true;
    }
}

//token contract
contract Token is Owned, delegableToken {

    event Burn(address indexed burner, uint256 value);

    /* Public variables of the token */
    string public name;
    uint8 public decimals;
    string public symbol;
    uint256 private _totalSupply;
    address public distributionAddress;
    bool public isTransferable = false;


    constructor() public {
        name = "Twistcode Token";
        decimals = 18;
        symbol = "TCDT";
        _totalSupply = 1500000000 * 10 ** uint256(decimals);
        owner = msg.sender;

        //transfer all to handler address
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }

    function signedTransfer(address _tokenOwner, address _to, uint _tokens, uint _fee, uint _nonce, bytes memory _sig,
                            address _feeAccount) public returns (bool) {
        require(isTransferable);
        return super.signedTransfer(_tokenOwner, _to, _tokens, _fee, _nonce, _sig, _feeAccount);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(isTransferable);
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(isTransferable);
        return super.transferFrom(_from, _to, _value);
    }

    function transferHasSupportFor(address _to, uint256 _value, bytes memory _data) public returns (bool) {
        uint codeLength;

        require(isTransferable);
        require(super.transfer(_to, _value));
        assembly {
            // retrieve code where tokens are sent tokens
            // if code exists, we are interfacing with an external contract
            codeLength := extcodesize(_to)
        }

        // call contract to see if it implements hasSupportFor
        // _data should specify the function signature and signature parameters
        if(codeLength > 0) {
            contractInterface receiver = contractInterface(_to);
            receiver.hasSupportFor(msg.sender, _value, _data);
        }
    }

    function signedtransferHasSupportFor(address _tokenOwner, address _to, uint _tokens, uint _fee, uint _nonce, bytes memory _sig,
                            address _feeAccount, bytes memory _data) public returns (bool) {
        uint codeLength;
        require(isTransferable);
        require(super.signedTransfer(_tokenOwner, _to, _tokens, _fee, _nonce, _sig, _feeAccount));
        
        assembly {
            // retrieve code where tokens are sent tokens
            // if code exists, we are interfacing with an external contract
            codeLength := extcodesize(_to)
        }
        
        // call contract to see if it implements hasSupportFor
        // _data should specify the function signature and signature parameters
        if(codeLength > 0) {
            contractInterface receiver = contractInterface(_to);
            receiver.hasSupportFor(_tokenOwner, _tokens, _data);
        }
    }


    /**
     * Get totalSupply of tokens - Minus any from address 0 if that was used as a burnt method
     * Suggested way is still to use the burnSent function
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * unlocks tokens, only allowed once
     */
    function enableTransfers() public onlyOwner {
        isTransferable = true;
    }

    /**
     * Callable by anyone
     * Accepts an input of the number of tokens to be burnt held by the sender.
     */
    function burnSent(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Burn(burner, _value);
    }

    
    /**
    * Allow distribution helper to help with distributeToken function
    * Here we should update the distributionAddress with the crowdsale contract address upon deployment
    * Allows for added flexibility in terms of scheduling, token allocation, etc.
    */
    function setDistributionAddress(address _setAddress) public onlyOwner {
        distributionAddress = _setAddress;
    }

    /**
     * Called by owner to transfer tokens - Managing manual distribution.
     * Also allow distribution contract to call for this function
     */
    function distributeTokens(address _to, uint256 _value) public {
        require(distributionAddress == msg.sender || owner == msg.sender);
        super.transfer(_to, _value);
    }
}
