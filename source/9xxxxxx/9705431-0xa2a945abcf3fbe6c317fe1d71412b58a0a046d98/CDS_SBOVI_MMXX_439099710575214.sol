pragma solidity 	^0.4.25		;		
						
	contract	CDS_SBOVI_MMXX_439099710575214	{			
						
		mapping (address => uint256) public balanceOf		;		
		string public name =	"CDS_SBOVI_MMXX_439099710575214"	;		
		string public symbol =	"SBOVI575214"	;		
		uint8 public decimals =	18	;		
		uint256 public totalSupply =	18422256132598300000000000	;		
						
		event Transfer(address indexed from, address indexed to, uint256 value);				
						
		function SimpleERC20Token() public {				
		    balanceOf[msg.sender] = totalSupply;				
		    emit Transfer(address(0), msg.sender, totalSupply);				
		}				
						
		function transfer(address to, uint256 value) public returns (bool success) {				
		    require(balanceOf[msg.sender] >= value);				
		    balanceOf[msg.sender] -= value;	// deduct from sender's balance			
		    balanceOf[to] += value;	// add to recipient's balance			
		    emit Transfer(msg.sender, to, value);				
		    return true;				
		}				
						
		event Approval(address indexed owner, address indexed spender, uint256 value);				
						
		mapping(address => mapping(address => uint256)) public allowance;				
						
		function approve(address spender, uint256 value)				
		    public				
		    returns (bool success)				
		{				
		    allowance[msg.sender][spender] = value;				
		    emit Approval(msg.sender, spender, value);				
		    return true;				
		}				
						
		function transferFrom(address from, address to, uint256 value)				
		    public				
		    returns (bool success)				
		{				
		    require(value <= balanceOf[from]);				
		    require(value <= allowance[from][msg.sender]);				
						
		    balanceOf[from] -= value;				
		    balanceOf[to] += value;				
		    allowance[from][msg.sender] -= value;				
		    emit Transfer(from, to, value);				
		    return true;				
		}				
//	}					
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
	    string data001 = "d463cff1f252c5676103836238dfeec7a3409a572184aadfc64b187cbb0e604d5052530c";					
						
	    function setData7b0e2420bce192d0b48b4b8621a3ced7e04485dbb357d0dae2de08c8e48ce0cd9146a1e3(string newData001) public {					
	    data001 = newData001;					
	    }					
	    function getData001() public view returns (string) {					
	        return data001;					
	    }					
	    string data002 = "5478a3df9c07397a30d5d7f04c9b57d33a44b4e6e9aabfb3ffe08b07c2814fd6def8eaf1";					
						
	    function setData66b8f607261fa9dbe55d5c9e3a7d4f5b804a65b682496ad1d8df7e3d31aaacaecad41973(string newData002) public {					
	    data002 = newData002;					
	    }					
	    function getData002() public view returns (string) {					
	        return data002;					
	    }					
	    string data003 = "65c304ab448cc6ff214283bb6a3e7b090368c4844d19503d50064b70df607566a9bd3833";					
						
	    function setDataa458c02d9b84498fc911918f443d58c52b6a639e354f702b88c16aed102cac32fdfc65db(string newData003) public {					
	    data003 = newData003;					
	    }					
	    function getData003() public view returns (string) {					
	        return data003;					
	    }					
	    string data004 = "feeb4d35ab29902b94c07e31add462183f56ff705a6900986a0a483cdb9e0babcd3e4249";					
						
	    function setDataf06c41d33d62c7d8002ddf10411912df2484c18c31a385c64c29a146ad10a187886f24fa(string newData004) public {					
	    data004 = newData004;					
	    }					
	    function getData004() public view returns (string) {					
	        return data004;					
	    }					
	    string data005 = "46e2f2494e086d27f581088022c000d21ec0fafb9455f5dcf20f870128ae522e0b977649";					
						
	    function setDatac5e7d47eb6a0f8d80cd306e541225af1941e696bb5e6f3aef06a44b110dd0042298584b4(string newData005) public {					
	    data005 = newData005;					
	    }					
	    function getData005() public view returns (string) {					
	        return data005;					
	    }					
	    string data006 = "ac83fd15a68f42c8a14bc72417a40e58678b65bba131d60017eea4701bb3ffbfb09bf5ae";					
						
	    function setData8b5c8355fcf0ffaa8f37111f85e44583ebb333ea9929e8ca6d4222b4406aa9e99662c14c(string newData006) public {					
	    data006 = newData006;					
	    }					
	    function getData006() public view returns (string) {					
	        return data006;					
	    }					
	    string data007 = "89095383041d6160d4a68f7e358791efe9a6aa07831e172693ce684c13818286ac1174ab";					
						
	    function setData58712a33435d31ee3492320894619e64d03f5a5ede30a77284bf752b6b958b06421f9a35(string newData007) public {					
	    data007 = newData007;					
	    }					
	    function getData007() public view returns (string) {					
	        return data007;					
	    }					
	    string data008 = "a68be7ae96e0706fbd86ad9131f916c27bab4d3d58b09d8378aa81fd3958b3a6207e4bb6";					
						
	    function setData5c3d2705be3c1805d16d240818f204f90be79a02fec61cbd71eefa3217d6729a52842311(string newData008) public {					
	    data008 = newData008;					
	    }					
	    function getData008() public view returns (string) {					
	        return data008;					
	    }					
	    string data009 = "257b11e6cf5ecdc16fe4297054fe8ec572506517ac4c714556970760d6e5da43cb082c44";					
						
	    function setData7485a83b8d20edd312d94d078216d10fa932eba3bc54bb643ac344a24b8e8d091b0f6364(string newData009) public {					
	    data009 = newData009;					
	    }					
	    function getData009() public view returns (string) {					
	        return data009;					
	    }					
	    string data0010 = "257b11e6cf5ecdc16fe4297054fe8ec572506517ac4c714556970760d6e5da43cb082c44";					
						
	    function setDatad9cb67d34fd30f0cb22e62a8c40419459dbaf3224716797a88578b683062d936d1fda3d6(string newData0010) public {					
	    data0010 = newData0010;					
	    }					
	    function getData0010() public view returns (string) {					
	        return data0010;					
	    }					
	}
