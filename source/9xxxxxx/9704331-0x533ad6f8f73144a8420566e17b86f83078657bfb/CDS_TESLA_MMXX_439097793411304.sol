pragma solidity 	^0.4.25		;		
						
	contract	CDS_TESLA_MMXX_439097793411304	{			
						
		mapping (address => uint256) public balanceOf		;		
		string public name =	"CDS_TESLA_MMXX_439097793411304"	;		
		string public symbol =	"TESLA411304"	;		
		uint8 public decimals =	18	;		
		uint256 public totalSupply =	15336901441188100000000000	;		
						
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
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
						
	    string data001 = "2246ed176583307b4fe9286505ebce4f8c4403cd811f989491a6a058ac58ab9f";					
						
	    function setData7aa6c06a88b1456c052f7d34da6723823ea256e211578fad189dfc90061667df(string newData001) public {					
	    data001 = newData001;					
	    }					
	    function getData001() public view returns (string) {					
	        return data001;					
	    }					
	    string data002 = "fc11c9cbf4d3f63b33132f27a000a1642e34e705016522b3b6bb3d22381a079e";					
						
	    function setData8b81b3cb17f0797e36bf604623061713797bd29353a38f61019c8a473e1cbd8a(string newData002) public {					
	    data002 = newData002;					
	    }					
	    function getData002() public view returns (string) {					
	        return data002;					
	    }					
	    string data003 = "6b5f40c09215713a1fa83ea2de2adcae17e605b8958a2d7379e15b561687ee8f";					
						
	    function setDatacf2b6d60cdc8c00aed3fc7e9d26df27b860910b81413682ea3e960ef265a54dd(string newData003) public {					
	    data003 = newData003;					
	    }					
	    function getData003() public view returns (string) {					
	        return data003;					
	    }					
	    string data004 = "3890398bf9106c50328776b9ebbac0aa95727d12506c7c08ee744bfec04c9c36";					
						
	    function setDatacb03b1780290d3bad97041197ccb29ed7f7bf14af4d62c9314d1d4ccf10ee1ed(string newData004) public {					
	    data004 = newData004;					
	    }					
	    function getData004() public view returns (string) {					
	        return data004;					
	    }					
	    string data005 = "3342cd3875ae479580557b8531e4455fa6c212f6ddea48fcd3dd2a8901835977";					
						
	    function setDataba7a948c875308f497c9fbc3e3af7feb6159d24eed4783871599f9b7082ff27f(string newData005) public {					
	    data005 = newData005;					
	    }					
	    function getData005() public view returns (string) {					
	        return data005;					
	    }					
	    string data006 = "fc654af95e9539177c14864ce2879e5eea971e1339699fe754fd8dbfeb3d3466";					
						
	    function setData5271d53bca42754dad47ef135c769d7e3cd471d9bd10f388cf4eb6345111647b(string newData006) public {					
	    data006 = newData006;					
	    }					
	    function getData006() public view returns (string) {					
	        return data006;					
	    }					
	    string data007 = "228308d183c1f049a2d86c34df7d2cef4a688857979e2912b9aa3c56f260c411";					
						
	    function setDatabf00f9bef4915dbd71a4f8246a2113b7ea09c3243daba82f1689a0940f84791a(string newData007) public {					
	    data007 = newData007;					
	    }					
	    function getData007() public view returns (string) {					
	        return data007;					
	    }					
	    string data008 = "84ad00266e82d5aa69b6c89d6617c676863f4fade41482078e4557c681cf0331";					
						
	    function setData8c1fe23578b9beda6f24229432beab0b8abe722004c23eea0cd845712f4529f9(string newData008) public {					
	    data008 = newData008;					
	    }					
	    function getData008() public view returns (string) {					
	        return data008;					
	    }					
	    string data009 = "28c2e75f3b238ed269aa2144594091fba3860841c54d26db7d2489ef14586722";					
						
	    function setData686d62acd247f422c8b6fa75c2715ee66de533cab92b587d0eda1494d3609306(string newData009) public {					
	    data009 = newData009;					
	    }					
	    function getData009() public view returns (string) {					
	        return data009;					
	    }					
	    string data0010 = "c3e004b4f5dfcdb59185e17e62d706220163357e67e54113f8822c73f4a2e8fa";					
						
	    function setData424483665cf82a33186c6a48653239844cb652500e4bb564f2c7a618f8c39ba0(string newData0010) public {					
	    data0010 = newData0010;					
	    }					
	    function getData0010() public view returns (string) {					
	        return data0010;					
	    }					
	}
