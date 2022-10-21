pragma solidity >=0.4.0 <0.7.0;

interface token { function transferFrom(address _from, address _to, uint256 _value) external returns (bool success); }

contract CZRMainNetMapping
{
    address tokenAddress;
    mapping(bytes=>uint) private record;
    token t;
    event Mapping(uint indexed amount,bytes czrAddr,address from,uint time);
    
    constructor(address _CZRAddress) public {
        tokenAddress=_CZRAddress;
        t = token(tokenAddress);
    }
    
    /// @notice impl tokenRecipient interface
    function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) public OnlyTokenAddressCanCall{
        require(
            _token == tokenAddress
            &&_extraData.length == 32
            &&_value>0
            &&record[_extraData]<record[_extraData]+_value
        );
        t.transferFrom(_from, address(this), _value);
        record[_extraData]+=_value;
        emit Mapping(_value,_extraData,_from,now);
    }
    
    function getRecord(bytes memory _extraData) view public returns(uint amount){
        return record[_extraData];
    }
    
    modifier OnlyTokenAddressCanCall(){
        require(msg.sender==tokenAddress);
        _;
    }
}
