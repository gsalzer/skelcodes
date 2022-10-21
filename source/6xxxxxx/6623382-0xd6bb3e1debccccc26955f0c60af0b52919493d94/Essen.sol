contract Essen {
    //Address for promo expences
    address constant private PROMO = 0x2392169A23B989C053ECED808E4899c65473E4af;
    //Percent for promo expences
    uint constant public PROMO_PERCENT = 7; //6 for advertizing, 1 for techsupport
    //How many percent for your deposit to be multiplied
    uint constant public MULTIPLIER = 121;

    //The deposit structure holds all the info about the deposit made
    struct Deposit {
        address depositor; //The depositor address
        uint128 deposit;   //The deposit amount
        uint128 expect;    //How much we should pay out (initially it is 121% of deposit)
    }

    Deposit[] private queue;  //The queue
    uint public currentReceiverIndex = 0; //The index of the first depositor in the queue. The receiver of investments!





    //Get the count of deposits of specific investor
    function getDepositsCount(address depositor) public view returns (uint) {
        uint c = 0;
        for(uint i=currentReceiverIndex; i<queue.length; ++i){
            if(queue[i].depositor == depositor)
                c++;
        }
        return c;
    }

   

}
