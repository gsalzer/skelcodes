pragma solidity ^0.5.7;

interface AddrMInterface {
     function getAddr(string calldata name_) external view returns(address);
}
