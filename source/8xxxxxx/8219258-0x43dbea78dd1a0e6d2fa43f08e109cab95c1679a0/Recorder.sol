pragma solidity ^0.4.24;

contract Recorder {
    
    struct Record{
        address from;
        address to;
        uint256 tokenId;
        uint256 transferTime;
    }
    
    mapping(uint256 => uint256) public tokenIdToRecIndex;
    
    Record[] public recs;
    
    function _record(address _from, address _to, uint256 _tokenId) internal {
        uint256 index = recs.push(Record(_from, _to, _tokenId, block.timestamp)) - 1;
        tokenIdToRecIndex[_tokenId] = index;
    }

    function totalRecords() external view returns(uint256) {
        uint256 count = recs.length;
        return count;
    }

}


