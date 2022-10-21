pragma solidity >=0.4.22 <0.7.0;

contract checkBalances {
    
    function getAccountWithBalance(address[] memory addresses) public view returns(address[] memory){
        address[] memory addresses_with_balance = new address[](100);
        uint counter = 0;
        for (uint i=0; i<addresses.length; i++) {
            if(addresses[i].balance > 0){
                addresses_with_balance[counter] = addresses[i];
                counter = counter + 1;
            }
        }
        return addresses_with_balance;
    }
}
