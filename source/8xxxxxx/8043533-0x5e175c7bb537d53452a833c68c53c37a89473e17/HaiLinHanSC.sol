pragma solidity >=0.4.25 <0.6.0;
contract HaiLinHanSC {
	event Added(string product_info);
    
	function Add(string memory product_info) public {
		emit Added(product_info);
	}
}
