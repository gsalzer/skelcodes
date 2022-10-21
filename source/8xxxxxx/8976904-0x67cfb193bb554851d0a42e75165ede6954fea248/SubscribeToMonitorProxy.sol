pragma solidity ^0.5.0;


contract DSGuard {
    function canCall(address src_, address dst_, bytes4 sig) public view returns (bool);

    function permit(bytes32 src, bytes32 dst, bytes32 sig) public;
    function forbid(bytes32 src, bytes32 dst, bytes32 sig) public;

    function permit(address src, address dst, bytes32 sig) public;
    function forbid(address src, address dst, bytes32 sig) public;

}

contract DSGuardFactory {
    function newGuard() public returns (DSGuard guard);
}

contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint              wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }

        emit LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);

        _;
    }
}

contract DSProxy is DSAuth, DSNote {
    DSProxyCache public cache;  

    constructor(address _cacheAddr) public {
        require(setCache(_cacheAddr));
    }

    function() external payable {
    }

    
    function execute(bytes memory _code, bytes memory _data)
        public
        payable
        returns (address target, bytes32 response)
    {
        target = cache.read(_code);
        if (target == address(0)) {
            
            target = cache.write(_code);
        }

        response = execute(target, _data);
    }

    function execute(address _target, bytes memory _data)
        public
        auth
        note
        payable
        returns (bytes32 response)
    {
        require(_target != address(0));

        
        assembly {
            let succeeded := delegatecall(sub(gas, 5000), _target, add(_data, 0x20), mload(_data), 0, 32)
            response := mload(0)      
            switch iszero(succeeded)
            case 1 {
                
                revert(0, 0)
            }
        }
    }

    
    function setCache(address _cacheAddr)
        public
        payable
        auth
        note
        returns (bool)
    {
        require(_cacheAddr != address(0));        
        cache = DSProxyCache(_cacheAddr);  
        return true;
    }
}

contract DSProxyCache {
    mapping(bytes32 => address) cache;

    function read(bytes memory _code) public view returns (address) {
        bytes32 hash = keccak256(_code);
        return cache[hash];
    }

    function write(bytes memory _code) public returns (address target) {
        assembly {
            target := create(0, add(_code, 0x20), mload(_code))
            switch iszero(extcodesize(target))
            case 1 {
                
                revert(0, 0)
            }
        }
        bytes32 hash = keccak256(_code);
        cache[hash] = target;
    }
}

contract SubscribeToMonitorProxy {

    address public constant MONITOR_PROXY_ADDRESS = 0x1a7C7F3088411Dd5e2f9d1f725b3c06C521a7bF9;

    function allow() public {
        DSGuard guard = getDSGuard();

        guard.permit(MONITOR_PROXY_ADDRESS, address(this), bytes4(keccak256("execute(address,bytes)")));
    }

    function getDSGuard() internal view returns (DSGuard) {
        DSProxy proxy = DSProxy(address(uint160(address(this))));
        DSAuth auth = DSAuth(address(proxy.authority));

        return DSGuard(address(auth));
    }
}
