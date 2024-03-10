pragma solidity >=0.5.2;

// this is hackathon edition. Not optimized!
contract Caviar {
  string link;

  function setupLink(string memory input) public returns(bool) {
    link = input;
    return true;
  }

  function viewLink() public view returns(string memory) {
      string memory _link = link;
      return _link;
  }

}
