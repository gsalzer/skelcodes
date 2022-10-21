pragma solidity ^0.4.22;
contract notapaper {
    string PaperHash;
    uint256 PaperId;

    
    function set_all(uint256 newPaperId, string newPaperHash) public {
    PaperId = newPaperId;
    PaperHash = newPaperHash;
    }
    
    function get_all() view public returns(uint256, string) {
    return (PaperId, PaperHash);
    }
}
