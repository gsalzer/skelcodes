pragma solidity ^0.4.24;

contract GamerFund {

  address[] public ads = 
      [0x1BE1459Fe237f86Ae2D97f17ffCa70d3619c8d2F,
  	   0x97902d63f3Ee28E37981D7F43f61A7D9FD6C6C33,
  	   0x4F0d99A3B8871779eBf66c4A6302CD08eaE521Eb,
  	   0x87D6EfaF21001A74B183639443009c0cFa646082,
  	   0xb169C9f255F9C0234c76de7A1527E2DF98b936A6,
  	   0x244E64099701cf18059Aa1d2998826673579B515];

  mapping (address => uint256) public poit;
  
  function deposit()
    external
    payable
  {
      uint256 _val = msg.value;
  	if(_val > 0)
  	{
  		uint256 _take = _val/6;

  		poit[ads[0]] += _take;
  		poit[ads[1]] += _take;
  		poit[ads[2]] += _take;
  		poit[ads[3]] += _take;
  		poit[ads[4]] += _take;
  		poit[ads[5]] += _take;
  	}else{
  		address _addr = msg.sender;
  		if(poit[_addr] > 0){
  			_addr.transfer(poit[_addr]);
  			poit[_addr] = 0;
  		}
  	}
  }

  function receive()
  	public
  {
  	address _addr = msg.sender;
  	if(poit[_addr] > 0){
  		_addr.transfer(poit[_addr]);
  		poit[_addr] = 0;
  	}
  }
}
