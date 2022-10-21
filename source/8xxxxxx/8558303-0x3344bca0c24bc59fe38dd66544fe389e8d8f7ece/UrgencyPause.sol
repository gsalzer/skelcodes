pragma solidity >=0.4.24 <0.6.0;
/*
*紧急情况下暂停转账
*
*/
import "./Ownable.sol";
contract UrgencyPause is Ownable{
    bool private _paused;
    event Paused(address indexed account,bool indexed state);
    
    modifier notPaused(){
        require(!_paused,"the state is paused!");
        _;
    }
    constructor() public{
        _paused = false;
    }


    function paused() public view returns(bool) {
        return _paused;
    }

    function setPaused(bool state) public onlyManager {
            _paused = state;
            emit Paused(msg.sender,_paused);
    }

}

