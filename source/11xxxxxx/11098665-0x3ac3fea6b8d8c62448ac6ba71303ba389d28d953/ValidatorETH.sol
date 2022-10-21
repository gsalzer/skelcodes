// SPDX-License-Identifier: No License (None)
pragma solidity ^0.6.9;

// TODO: get rate for tokens.

import "./SafeMath.sol";
import "./Ownable.sol";
import "./provableAPI_0.6.sol";

interface ISwapFactory {
    function balanceCallback(address payable pair, address user, uint256 balanceForeign) external returns(bool);
    function balancesCallback(
            address payable pair,
            address user,
            uint256 balanceForeign,
            uint256 nativeEncoded,
            uint256 foreignSpent,
            uint256 rate    // rate = foreignPrice.mul(NOMINATOR) / nativePrice;   // current rate
        ) external returns(bool);
}

interface ICompanyOracle {
    function getBalance(uint256 network, address token, address user) external returns(uint256);
    function getBalances(uint256 network, address token, address user, address user2, address user3) external returns(uint256);
}

interface IPrice {
    function getCurrencyPrice(address _which) external view returns(uint256);   // 0 - BNB, 1 - ETH, 2 - BTC
}


contract Validator is Ownable, usingProvable {
    using SafeMath for uint256;

    uint256 constant NOMINATOR = 10**9;     // rate nominator
    address constant NATIVE = address(-1);  // address which holds native token ballance that was spent
    address constant FOREIGN = address(-2); // address which holds foreign token encoded ballance that was spent

    struct Request {
        //uint32 approves;
        address factory;
        address tokenForeign;
        address user;
        address payable pair;
        uint256 req;
    }

    Request[] public requests;
    
    mapping(address => bool) public isAllowedAddress; 
    uint32 public approves_required = 1;

    //address public currencyPrice;   // CurrencyPrice contract return price of selected currency (decimals: 9)
    //address public companyOracle;
    //mapping (uint256 => uint256) public companyOracleRequests;  // companyOracleRequest ID => requestId
    mapping (bytes32 => uint256) public provableOracleRequests;  // provableOracleRequests ID => requestId
    mapping (uint256 => uint256) public gasLimit;  // request type => amount of gas (request type: 1 - cancel, 2 - claim)
    //string public ipfsAddress = "QmPLV3FUc35VjzXdAgGEq5GfSxQgQ44uppnCsFUnsYK81r";   // for BSC testnet
    string public ipfsAddress = "QmYGimKCXG5jHtM5S88L4JE2tqWaFxKXGNePftzsjGG9Si";   // for BSC mainnet
    uint256 public customGasPrice = 60 * 10**9; // 60 GWei

    event LogMsg(string description);
    event CompanyOracle(uint256 requestId, uint256 balance);
    event CompanyOracle3(uint256 requestId, uint256 balance1, uint256 balance2, uint256 balance3);

    modifier onlyAllowed() {
        require(isAllowedAddress[msg.sender],"ERR_ALLOWED_ADDRESS_ONLY");
        _;
    }

    constructor () public {
        //companyOracle = _oracle;
        //currencyPrice = _price;
        requests.push();    // request ID starts from 1. ID = 0 means completed/empty
        gasLimit[1] = 200000;       //cancel
        gasLimit[2] = 200000;       //claim
        gasLimit[3] = 200000;       //claim JNTR/e        
        provable_setCustomGasPrice(customGasPrice);
        provable_setProof(proofType_Android | proofStorage_IPFS);
    }


    function setApproves_required(uint32 n) external onlyOwner returns(bool) {
        approves_required = n;
        return true;
    }
/*
    function setCompanyOracle(address _addr) external onlyOwner returns(bool) {
        companyOracle = _addr;
        return true;
    }

    function setCurrencyPrice(address _addr) external onlyOwner returns(bool) {
        currencyPrice = _addr;
        return true;
    }
*/

    function changeAllowedAddress(address _which,bool _bool) external onlyOwner returns(bool){
        isAllowedAddress[_which] = _bool;
        return true;
    }

    // set IPFS address of script
    function setIPFS(string memory _ipfs) external onlyOwner returns (bool) {
        ipfsAddress = _ipfs;
        return true;
    }

    // returns: oracle fee
    function getOracleFee(uint256 req) external view returns(uint256) {  //req: 1 - cancel, 2 - claim, returns: value
        return gasLimit[req] * customGasPrice;
    }
    
    // cancel order request
    function checkBalance(address payable pair, address tokenForeign, address user) external onlyAllowed returns(uint256 requestId) {
        requestId = requests.length;
        requests.push(Request(msg.sender, tokenForeign, user, pair, 0));

        // Provable query
        //string memory a = "json(https://api-testnet.bscscan.com/api?module=account&action=tokenbalance&contractaddress=0x";
        string memory a = "json(https://api.bscscan.com/api?module=account&action=tokenbalance&contractaddress=0x";
        string memory b = "&address=0x";
        string memory c = "&tag=latest).result";
        string memory s = strConcat(a,_address2hex(tokenForeign),b,_address2hex(user),c);
        bytes32 myid = provable_query("URL", s, gasLimit[1]);
        provableOracleRequests[myid] = requestId;

        // Company Oracle
        //uint256 myId = ICompanyOracle(companyOracle).getBalance(network, tokenForeign, user);
        //companyOracleRequests[myId] = requestId;
    }

    // claim order request
    function checkBalances(address payable pair, address tokenForeign, address user) external onlyAllowed returns(uint256 requestId) {
        requestId = requests.length;
        requests.push(Request(msg.sender, tokenForeign, user, pair, 2));

        // Provable query
        string[] memory parameters = new string[](3);
        parameters[0] = ipfsAddress;
        parameters[1] = _address2hex(tokenForeign);
        parameters[2] = _address2hex(user);

        bytes32 queryId = provable_query("computation", parameters,  gasLimit[2]);
        provableOracleRequests[queryId] = requestId;

        // Company Oracle
        //uint256 myId = ICompanyOracle(companyOracle).getBalances(network, tokenForeign, user, NATIVE, FOREIGN);
        //companyOracleRequests[myId] = requestId;
    }

    // get rate on BSC side: ETH price / BNB price


    function withdraw(uint256 amount) external onlyAllowed returns (bool) {
        msg.sender.transfer(amount);
        return true;
    }

    // set gas limit to request: 1 - cancel request, 2 - claim request
    function setGasLimit(uint256 req, uint256 amount) external onlyAllowed returns (bool) {
        gasLimit[req] = amount;
        return true;
    }


    function setCustomGasPrice(uint256 amount) external onlyAllowed returns (bool) {
        customGasPrice = amount;
        provable_setCustomGasPrice(amount);
        return true;
    }

    receive() external payable {}

    function __callback(bytes32 myid, string memory result, bytes memory _proof) public override {
        require(msg.sender == provable_cbAddress(), "ERR_WRONG_SENDER");
        uint256 r_id = provableOracleRequests[myid];
        require(r_id != 0, "Wrong requestId");
        provableOracleRequests[myid] = 0;   // requestId fulfilled
        Request storage r = requests[r_id];
        if (r.req == 2) {
            uint[] memory resInt = _parseResponse(result);
            ISwapFactory(r.factory).balancesCallback(r.pair, r.user, resInt[0], resInt[2], resInt[1], resInt[3]);
            emit CompanyOracle3(r_id, resInt[2], resInt[1], resInt[3]);
        }
        else {
            uint256 balance = parseInt(result);
            ISwapFactory(r.factory).balanceCallback(r.pair, r.user, balance);
        }
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

    // parse string like "integer integer integer integer" into array of integers
    function _parseResponse(string memory _a) internal pure returns (uint[] memory) {
        bytes memory bresult = bytes(_a);
        uint[] memory resInt = new uint[](4);
        uint idx = 0;
        uint mint = 0;
        for (uint i = 0; i < bresult.length; i++) {
            if ((uint(uint8(bresult[i])) >= 48) && (uint(uint8(bresult[i])) <= 57)) {
                mint *= 10;
                mint += uint(uint8(bresult[i])) - 48;
            } else if (uint(uint8(bresult[i])) == 32) { // ' ' delimiter
                resInt[idx++] = mint;
                mint = 0;
                if (idx == 4) return resInt;
            }
        }
        resInt[idx++] = mint;
        return resInt;
    }
}
