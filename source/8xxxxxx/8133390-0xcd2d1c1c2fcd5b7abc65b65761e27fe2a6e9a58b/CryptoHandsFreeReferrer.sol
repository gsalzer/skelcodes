pragma solidity ^0.5.7;

contract CryptoHands  {
function viewUserReferral(address _user) public view returns(address[] memory);
}

contract CryptoHandsFreeReferrer {
   
   CryptoHands cryptoHands; 
    
    constructor() public {
        cryptoHands = CryptoHands(0xA315bD2e3227C2ab71f1350644B01757EAFf9cb4);
    }
    
    function findFreeReferrer(address _user) public view returns(address) {
        if(cryptoHands.viewUserReferral(_user).length < 3){
            return _user;
        }

        address[] memory referrals = new address[](4719);
        address[] memory fReferrals = new address[](3);
        fReferrals = cryptoHands.viewUserReferral(_user);
        referrals[0] = fReferrals[0]; 
        referrals[1] = fReferrals[1];
        referrals[2] = fReferrals[2];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i =0; i<4719;i++){
            if(cryptoHands.viewUserReferral(referrals[i]).length == 3){
                if(i<1452){
                    fReferrals = cryptoHands.viewUserReferral(referrals[i]);
                    
                    referrals[(i+1)*3] = fReferrals[0];
                    referrals[(i+1)*3+1] = fReferrals[1];
                    referrals[(i+1)*3+2] = fReferrals[2];
                }
            }else{
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }
        require(!noFreeReferrer, 'No Free Referrer');
        return freeReferrer;

    }    
    
}
