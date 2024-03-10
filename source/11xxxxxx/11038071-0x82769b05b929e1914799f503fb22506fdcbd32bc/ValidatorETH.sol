// SPDX-License-Identifier: No License (None)
pragma solidity ^0.6.9;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./provableAPI_0.6.sol";

interface IGateway {
    function validatorCallback(uint256 requestId, address tokenForeign, address user, uint256 balanceForeign) external returns(bool);
}

interface ICompanyOracle {
    function getBalance(uint256 network, address token, address user) external returns(uint256);
}

contract Validator is Ownable, usingProvable {
    using SafeMath for uint256;

    struct Request {
        uint32 network;
        uint32 approves;
        address sender;
        address tokenForeign;
        address user;
        uint256 balanceForeign;
    }

    Request[] public requests;
    
    mapping(address => bool) public isAllowedAddress; 
    uint32 public approves_required = 1;
    address public companyOracle;
    mapping (uint256 => uint256) public companyOracleRequests;  // companyOracleRequest ID => requestId
    mapping (bytes32 => uint256) public provableOracleRequests;  // provableOracleRequests ID => requestId

    uint256 public customGasPrice;
    uint256 public gasLimit = 80000;

    constructor () public {
        requests.push();    // request ID starts from 1. ID = 0 means completed/empty
    }

    function setApproves_required(uint32 n) external onlyOwner returns(bool) {
        approves_required = n;
        return true;
    }

    function setCompanyOracle(address _addr) external onlyOwner returns(bool) {
        companyOracle = _addr;
        return true;
    }

    function changeAllowedAddress(address _which,bool _bool) external onlyOwner returns(bool){
        isAllowedAddress[_which] = _bool;
        return true;
    }

    function checkBalance(uint256 network, address tokenForeign, address user) external returns(uint256 requestId) {
        require(isAllowedAddress[msg.sender],"ERR_ALLOWED_ADDRESS_ONLY");
        requestId = requests.length;
        requests.push(Request(uint32(network),0,msg.sender,tokenForeign,user,0));
        //uint256 myId = ICompanyOracle(companyOracle).getBalance(network, tokenForeign, user);
        //companyOracleRequests[myId] = requestId;
        _provable_request(requestId, network, tokenForeign, user);
    }

    function oracleCallback(uint256 requestId, uint256 balance) external returns(bool) {
        require (companyOracle == msg.sender, "Wrong Oracle");
        uint256 r_id = companyOracleRequests[requestId];
        require(r_id != 0, "Wrong requestId");
        companyOracleRequests[requestId] = 0;   // requestId fulfilled
        _oracleResponse(r_id, balance);
        return true;
    }

    function _oracleResponse(uint256 requestId, uint256 balance) internal {
        Request storage r = requests[requestId];
        if (r.approves == 0) {
            r.balanceForeign = balance;
        }
        else {
            require(r.balanceForeign == balance, "Balance mismatch");
        }
        r.approves++;
        if (r.approves >= approves_required) {
            IGateway(r.sender).validatorCallback(requestId, r.tokenForeign, r.user, r.balanceForeign);
        }
    }

    function setCustomGasPrice(uint amount) external returns (bool) {
        require(isAllowedAddress[msg.sender],"ERR_ALLOWED_ADDRESS_ONLY");
        customGasPrice = amount;
        provable_setCustomGasPrice(amount);
        return true;
    }

    function setGasLimit(uint amount) external returns (bool) {
        require(isAllowedAddress[msg.sender],"ERR_ALLOWED_ADDRESS_ONLY");
        gasLimit = amount;
        return true;
    }
    
    function withdraw(uint amount) external returns (bool) {
        require(isAllowedAddress[msg.sender],"ERR_ALLOWED_ADDRESS_ONLY");
        msg.sender.transfer(amount);
        return true;
    }

    receive() external payable {}

    function __callback(bytes32 myid, string memory result) public override {
        require(msg.sender == provable_cbAddress(), "ERR_WRONG_SENDER");
        uint256 r_id = provableOracleRequests[myid];
        require(r_id != 0, "Wrong requestId");
        provableOracleRequests[myid] = 0;   // requestId fulfilled
        uint256 balance = parseInt(result);
        _oracleResponse(r_id, balance);
    }

    function _provable_request(uint256 requestId, uint256 network, address tokenForeign, address user) internal {
        require(provable_getPrice("URL") <= address(this).balance,"Insufficient balance");
        //string memory a = "json(https://api-testnet.bscscan.com/api?module=account&action=tokenbalance&contractaddress=0x";
        string memory a = "json(https://api.bscscan.com/api?module=account&action=tokenbalance&contractaddress=0x";
        string memory b = "&address=0x";
        string memory c = "&tag=latest).result";
        string memory s = strConcat(a,_address2hex(tokenForeign),b,_address2hex(user),c);
        bytes32 myid = provable_query("URL", s, gasLimit);
        provableOracleRequests[myid] = requestId;
    }

    // Converts address to hex string
    function _address2hex(address addr) internal pure returns (string memory) {
        bytes memory b = abi.encodePacked(addr);
        uint len = b.length;
        bytes memory s = new bytes(len*2);
        uint8 t;
        for (uint i = 0; i < len; i++) {
            t = uint8(b[i]) / 16 + 0x30;
            if (t > 0x39) t += 0x27;
            s[i*2] = byte(t);
            t = (uint8(b[i]) & 0x0f) + 0x30;
            if (t > 0x39) t += 0x27;
            s[i*2+1] = byte(t);
        }
        return string(s);
    }

}
