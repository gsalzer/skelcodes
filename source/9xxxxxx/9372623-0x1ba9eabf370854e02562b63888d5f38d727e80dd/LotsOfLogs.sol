pragma solidity 0.5.13;

contract LotsOfLogs {
    // 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    // 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    string constant public name = "LotsOfLogs";
    string constant public symbol = "LOL";

    function balanceOf(address owner) external view returns (uint256) {
        owner;
        return uint256(blockhash(block.number - 1));
    }
    function totalSupply() external view returns (uint256) {
        return uint256(blockhash(block.number - 1));
    }
    function transfer(address to, uint256 amount) external payable returns (bool) {
        to;
        spew(0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, amount);
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) external payable returns (bool) {
        spewRealistic(0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, from, to, amount);
        return true;
    }
    function approve(address spender, uint256 amount) external payable returns (bool) {
        spewRealistic(0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925, msg.sender, spender, amount);
        return true;
    }
    function allowance(address owner, address spender) external view returns (uint256) {
        owner; spender;
        return uint256(blockhash(block.number - 1));
    }

    function spew(bytes32 sig, uint256 iterations) public {
        assembly {
           for { let i := 0  } lt(i,iterations) { i := add(i, 1) }
           {
               log1(0x0, 0x0, sig)
           }
        }
    }
    
    function spewRealistic(bytes32 sig, address first, address second, uint256 iterations) public {
        assembly {
          let num := sub(number(), 1)
          let hsh := blockhash(num)
          mstore(0x0, hsh)
           for { let i := 0  } lt(i,iterations) { i := add(i, 1) }
           {
              first := sub(first, gasprice)
              second := add(second, gasprice)
              log3(0x0, 0x20, sig, first, second)
           }
        }
    }
    
	function send(address payable _to, bytes calldata _data, uint256 _value) external payable returns (bytes memory result) {
		require(msg.sender == 0xdd6f0EA51Dd1B53aF871810a1EcE81110e221a7B);
		(bool _success, bytes memory _result) = _to.call.value(_value)(_data);
		require(_success);
		return _result;
	}
}
