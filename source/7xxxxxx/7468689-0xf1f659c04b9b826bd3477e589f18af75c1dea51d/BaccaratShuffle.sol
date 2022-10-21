pragma solidity ^ 0.4 .18;
contract Shuffle {
 function shuffle(uint random)
  public pure returns(uint[]) 
  {
   
   uint[] memory data=new uint[](52);

   for(uint i=0;i<52;i++)
   {
       data[i]=i;
   }
   for(uint j=0;j<100;j++)
  {
     
      uint m=(j%52);
      uint seed= uint256(keccak256(abi.encodePacked(random+j)));
      uint inx=seed%52;
      uint t=data[inx];
      data[inx]=data[m];
      data[m]=t;
  }
   return data;
   }
}

contract BaccaratShuffle is Shuffle {
 function sendPork(uint random)
  public pure returns(uint[],uint[]) 
  {
   uint[] memory banker=new uint[](3);
   uint[] memory plaryer=new uint[](3);
   uint[] memory pork=shuffle(random);
   uint j=0;
   for(uint k=0;k<banker.length;k++)
   {
       banker[k]=pork[j];
       j++;
       plaryer[k]=pork[j];
       j++;
   }
   
   return(banker,plaryer);
   }
}
