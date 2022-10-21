pragma solidity ^0.5.0;

contract LinkedList{
    mapping(address=>mapping(bool=>address)) dllIndex;
    mapping(address => uint) balances;
    address head;
    address tail;
    uint arraySize = 0;
    
    constructor(address _owner) public{
        head=_owner;
        dllIndex[head][true]=_owner;
        dllIndex[head][false]=_owner;
        tail=_owner;
        dllIndex[tail][true]=_owner;
        dllIndex[tail][false]=_owner;
        arraySize++;
    }
    
    function add(address _addr) public
    {
        address nullAddress;
        
        if (dllIndex[_addr][false]==nullAddress && dllIndex[_addr][true]==nullAddress){
            //false==PREV
            //true==NEXT
            dllIndex[_addr][false] = tail;
            dllIndex[_addr][true] = _addr;
        
            // Insert the new node
            dllIndex[tail][true] = _addr;
            tail=_addr;
            arraySize++;
            getList();
        }
        
    }

    function remove(address _addr) public
    {
        if (arraySize>1){
            address previous = dllIndex[_addr][false];
            address next = dllIndex[_addr][true];
            
        
            if (_addr == head){
                head=next;
                dllIndex[previous][false]=next;
            } else if(_addr == tail){
                tail=previous;
                dllIndex[next][false]=previous;
            }else{
                dllIndex[dllIndex[_addr][false]][true] = next;
                dllIndex[dllIndex[_addr][true]][false] = previous;
            }
            //Delete state storage
            delete dllIndex[_addr][false];
            delete dllIndex[_addr][true];
            delete balances[_addr];
            arraySize--;
        }
        
    }
    
    function getList() public view returns(address[] memory){
        address[] memory addressList = new address[](arraySize);
        addressList[0]=head;
        if(arraySize==1){
            return addressList;
        }else{
            buildList(head, addressList, 1);
            return addressList;
        }
    }
    
    function buildList(address currentLink, address[] memory currentList, uint currentIndex) public view{
        if (currentLink != dllIndex[currentLink][true]){
            currentList[currentIndex]=dllIndex[currentLink][true];
            currentIndex++;
            buildList(dllIndex[currentLink][true], currentList, currentIndex);
        }
    }
    
    function getElement(address itemAddress) public view returns(address previous, address next){
        previous = dllIndex[itemAddress][false];
        next = dllIndex[itemAddress][true];
    }
}
