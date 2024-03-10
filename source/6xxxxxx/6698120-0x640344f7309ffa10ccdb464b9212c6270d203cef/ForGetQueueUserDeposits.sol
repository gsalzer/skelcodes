pragma solidity ^0.4.25;

contract FromResponsibleInvestors {
    uint public currentReceiverIndex = 0; //The index of the first depositor in the queue. The receiver of investments!
    
    function getDepositsCount() public view returns (uint);
    
    function getDeposit(uint idx) public view returns (address depositor, uint deposit, uint expect, uint paymentTime);
    
    function getUserDepositsCount(address depositor) public view returns (uint);
}

contract ForGetQueueUserDeposits {
    FromResponsibleInvestors private fri;
    
    constructor () public {
        fri = FromResponsibleInvestors(address(0xbb4F286F88881aFff196F8170105AD91B6217e0b));
    }
    
    function getUserDeposits(address depositor) public view returns (uint[] idxs, uint[] paymentTime, uint[] amount, uint[] expects) {
        address depos = depositor;
        uint c = fri.getUserDepositsCount(depos);

        idxs = new uint[](c);
        paymentTime = new uint[](c);
        expects = new uint[](c);
        amount = new uint[](c);
        
        uint cri = fri.currentReceiverIndex();
        uint dc = fri.getDepositsCount();
        uint all = cri + dc;
        
        address user;
        uint deposit;
        uint topay;
        uint payTime;
        
        if(c > 0) {
            uint j = 0;
            for(uint i=0; i<all; ++i){
                (user, deposit, topay, payTime) = fri.getDeposit(i);
                if(user == depositor){
                    idxs[j] = i;
                    paymentTime[j] = payTime;
                    amount[j] = deposit;
                    expects[j] = topay;
                    j++;
                }
            }
        }
    }
}
