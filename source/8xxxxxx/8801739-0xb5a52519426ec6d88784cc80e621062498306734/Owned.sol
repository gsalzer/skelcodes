pragma solidity ^0.5.5;

contract Owned {
    // 상태변수
    address public owner; // 소유자 주소
    address oldaddr;
    // 소유자 변경 시 이벤트
    event TransferOwnership(address oldaddr, address newaddr);

    // 소유자 한정 메서드용 수식자
    modifier onlyOwner() { 
      if (msg.sender != owner) revert();
      _; 
        
    }

    // 생성자
    constructor() public {
        owner = msg.sender; // 처음에 계약을 생성한 주소를 소유자로 한다
    }
    
    // (1) 소유자 변경
    function transferOwnership(address _new) public onlyOwner {
        oldaddr = owner;
        owner = _new;
        emit TransferOwnership(oldaddr, owner);
    }
}
