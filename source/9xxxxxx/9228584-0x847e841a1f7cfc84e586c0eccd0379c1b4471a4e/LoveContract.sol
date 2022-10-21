pragma solidity >=0.4.21 <0.6.0;

contract LoveContract {
  string whoami = "This is the very personal space for Jennifer and Philipp - the so called 'Faultiere'";

  mapping(uint => string) private messages;
  uint messageIndex = 0;

  function addMsg(string memory text) public {
    messages[messageIndex] = text;
    messageIndex++;
  }

  function getMsg(uint index) public view returns (string memory) {
    return messages[index];
  }

  function getWhoami() public view returns (string memory) {
    return whoami;
  }

  function getCurrentIndex() public view returns (uint) {
    return messageIndex;
  }
}
