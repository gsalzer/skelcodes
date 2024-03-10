pragma solidity ^0.4.24;

import "./Owned.sol";

contract KYCVerification is Owned{
    
    mapping(address => bool) public kycAddress;
    
    event LogKYCVerification(address _kycAddress,bool _status);
    
    constructor () public {
        owner = msg.sender;
    }

    function updateVerifcationBatch(address[] _kycAddress,bool _status) onlyOwner public returns(bool)
    {
        for(uint tmpIndex = 0; tmpIndex < _kycAddress.length; tmpIndex++)
        {
            kycAddress[_kycAddress[tmpIndex]] = _status;
            emit LogKYCVerification(_kycAddress[tmpIndex],_status);
        }
        
        return true;
    }
    
    function updateVerifcation(address _kycAddress,bool _status) onlyOwner public returns(bool)
    {
        kycAddress[_kycAddress] = _status;
        
        emit LogKYCVerification(_kycAddress,_status);
        
        return true;
    }
    
    function isVerified(address _user) view public returns(bool)
    {
        return kycAddress[_user] == true; 
    }
}
