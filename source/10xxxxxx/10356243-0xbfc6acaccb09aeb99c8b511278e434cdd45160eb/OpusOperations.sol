pragma solidity ^0.4.25;

/// @title OPUS Operations Contract

import "./Ownable.sol";
//import "./math/SafeMath.sol";
import "./OpusToken.sol";


/*contract ContractReceiver{
    function tokenFallback(address _from, uint256 _value, bytes  _data) external;
}*/

contract OpusOperations is ContractReceiver, Ownable {
    using SafeMath for uint256;
    bool public apiAccessDisabled;  // api access control
    bool public contractEnabled;    // is smart contract enabled for operations

    OpusToken public opt;
    	
    /*struct PlayStatData { // royalties and fees
        uint256 period; // yyyymm
        string hash; // hash of table of data
        string voterAnswer;
    }
    mapping(uint256 => PlayStatData) public PlayStats;*/
    mapping(uint256 => string) public PlayStats; // yyyymm -> hash

    event LogPlayStatAdded(uint256 period, string hash);

    modifier onlyContractEnabled() {
        require(contractEnabled, "Smart contract must be enabled.");
        _;
    }

    constructor() public {
        contractEnabled = true;
        //opt = OpusToken(0xD158F87740074f4b4433a2F82Eb352aE06d10974); //TODO to jest rinkeby
        opt = OpusToken(0x4355fC160f74328f9b383dF2EC589bB3dFd82Ba0); //TODO to jest mainnet
    }

    // receive ETH
    function () public payable {
        require(contractEnabled, "Smart contract must be enabled.");
    }
    // send ETH from the contract to a given address
    function sendEth(address _receiver, uint _amount) public onlyOwner onlyContractEnabled {
        _receiver.transfer(_amount);
    }
	

    // receive OPT
    function tokenFallback(address _from, uint256 _value, bytes _data) external {
        require(contractEnabled, "Smart Contract must be enabled.");
        if (msg.sender == address(opt)) { // accept only OPT
        } else {
            revert("This smart contract accepts only OPUS OPT tokens.");
        }
    }
    // send OPT from the contract to a given address
    function sendOpt(address _receiver, uint _amount) public onlyOwnerOrApi onlyContractEnabled {
        if(ApiAddr[msg.sender] == true && apiAccessDisabled) revert("API access is disabled.");
        opt.transfer(_receiver, _amount);
    }

    // transfer OPT from other holder, up to amount allowed through opt.approve() function
    function getOptFromApproved(address _from, uint _amount) public onlyOwnerOrApi onlyContractEnabled {
        if(ApiAddr[msg.sender] == true && apiAccessDisabled) revert("API access is disabled.");
        opt.transferFrom(_from, address(this), _amount);
    }


    // add a play statistics
    function addPlayStat(uint256 _period, string _hash) public onlyOwnerOrApi onlyContractEnabled {
		PlayStats[_period] = _hash; 
		emit LogPlayStatAdded(_period, _hash);
    }
	
    // disable/enable contract access from API
    function disableApiAccess(bool _disabled) public onlyOwner {
        apiAccessDisabled = _disabled;
    }

     /* change owner address for allowing execution for the new owner */
    function setOwnerAddr(address _address) public onlySuperOwner {
        ownerAddr = _address;
    }

    /* add API address for allowing execution from the API */
    function addApiAddr(address _address) public onlyOwner {
        ApiAddr[_address] = true;
    }
    /* remove API address from allowing execution from the API */
    function removeApiAddr(address _address) public onlyOwner {
        ApiAddr[_address] = false;
    }

    /* add a contract address for allowing execution from the contract */
    function addContractAddr(address _address) public onlyOwner {
        ContractAddr[_address] = true;
    }
    /* remove a contract address from allowing execution from the contract */
    function removeContractAddr(address _address) public onlyOwner {
        ContractAddr[_address] = false;
    }

    // enable/disable the contract
    function setContractEnabled(bool _enabled) public onlyOwner {
        contractEnabled = _enabled;
    }

}

