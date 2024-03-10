pragma solidity ^0.4.0;

import "./Erc20Token.sol";
import "./SignatureRecover.sol";

contract TokenContractWithTokenFee is Erc20Token, SignatureRecover {

    mapping(bytes32 => bool) public signatures;

    event TransferPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);

    modifier smallerOrLessThan(uint256 _value1, uint256 _value2, string errorMessage) {
        require(_value1 <= _value2, errorMessage);
        _;
    }

    modifier validAddress(address _address, string errorMessage) {
        require(_address != address(0), errorMessage);
        _;
    }

    /**
    * burn the specific signature from the signatures
    *
    * Requirement:
    * - sender(Caller) should be signer of that specific signature
    */
    function burnTransaction(bytes32 s, bytes32 r, uint8 v, address _to, uint256 _value, uint256 _fee, uint256 _nonce) validAddress(_to, "_to address is not valid") public {
        require(!signatures[s], "this signature is burned or done before");
        address from = testVerify(s, r, v, _to, _value, _fee, _nonce);
        require(from == msg.sender, "you're not permitted to burn this signature");
        signatures[s] = true;
    }

    /**
    * check if the transferPreSigned is valid or not!?
    *
    * Requirement:
    * - '_to' can not be zero address.
    */
    function validTransaction(bytes32 s, bytes32 r, uint8 v, address _to, uint256 _value, uint256 _fee, uint256 _nonce) validAddress(_to, "_to address is not valid") view public returns (bool, address) {
        address from = testVerify(s, r, v, _to, _value, _fee, _nonce);
        require(!isBlackListed[from], "from address is blacklisted");
        return (from != address(0) && !signatures[s] && balances[from] >= _value.add(_fee), from);
    }


    /**
    * submit the transferPreSigned
    *
    * Requirement:
    * - '_to' can not be zero address.
    * signature must be unused
    */
    function transferPreSigned(bytes32 s, bytes32 r, uint8 v, address _to, uint256 _value, uint256 _fee, uint256 _nonce) validAddress(_to, "_to address is not valid") public returns (bool){
        require(signatures[s] == false, "signature has been used");
        address from = testVerify(s, r, v, _to, _value, _fee, _nonce);
        require(from != address(0), "signature is wrong");
        require(!isBlackListed[from], "from address is blacklisted");
        balances[from] = balances[from].sub(_value.add(_fee));
        balances[_to] = balances[_to].add(_value);
        balances[msg.sender] = balances[msg.sender].add(_fee);
        signatures[s] = true;
        emit Transfer(from, _to, _value);
        emit Transfer(from, msg.sender, _fee);
        emit TransferPreSigned(from, _to, msg.sender, _value, _fee);
        return true;
    }

}

