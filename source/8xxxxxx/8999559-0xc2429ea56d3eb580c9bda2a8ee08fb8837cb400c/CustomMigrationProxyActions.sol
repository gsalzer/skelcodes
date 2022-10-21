pragma solidity ^0.5.0;


contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
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

contract TokenInterface {
    function allowance(address, address) public returns (uint);
    function balanceOf(address) public returns (uint);
    function approve(address, uint) public;
    function transfer(address, uint) public returns (bool);
    function transferFrom(address, address, uint) public returns (bool);
    function deposit() public payable;
    function withdraw(uint) public;
}

contract Vat {

    struct Urn {
        uint256 ink;   
        uint256 art;   
    }

    struct Ilk {
        uint256 Art;   
        uint256 rate;  
        uint256 spot;  
        uint256 line;  
        uint256 dust;  
    }

    mapping (bytes32 => mapping (address => Urn )) public urns;
    mapping (bytes32 => Ilk)                       public ilks;

    function can(address, address) public view returns (uint);
    function dai(address) public view returns (uint);
    function frob(bytes32, address, address, address, int, int) public;
    function hope(address) public;
    function move(address, address, uint) public;
}

contract Gem {
    function dec() public returns (uint);
    function gem() public returns (Gem);
    function join(address, uint) public payable;
    function exit(address, uint) public;

    function approve(address, uint) public;
    function transfer(address, uint) public returns (bool);
    function transferFrom(address, address, uint) public returns (bool);
    function deposit() public payable;
    function withdraw(uint) public;
    function allowance(address, address) public returns (uint);
}

contract DaiJoin {
    function vat() public returns (Vat);
    function dai() public returns (Gem);
    function join(address, uint) public payable;
    function exit(address, uint) public;
}

contract OtcInterface {
    function buyAllAmount(address, uint, address, uint) public returns (uint);

    function getPayAmount(address, address, uint) public view returns (uint);
    function getBuyAmount(address, address, uint) public view returns (uint);
}

contract ValueLike {
    function peek() public returns (uint, bool);
}

contract VoxLike {
    function par() public returns (uint);
}

contract SaiTubLike {
    function skr() public view returns (Gem);
    function gem() public view returns (Gem);
    function gov() public view returns (Gem);
    function sai() public view returns (Gem);
    function pep() public view returns (ValueLike);
    function vox() public view returns (VoxLike);
    function bid(uint) public view returns (uint);
    function ink(bytes32) public view returns (uint);
    function tag() public view returns (uint);
    function tab(bytes32) public returns (uint);
    function rap(bytes32) public returns (uint);
    function draw(bytes32, uint) public;
    function shut(bytes32) public;
    function exit(uint) public;
    function give(bytes32, address) public;
    function lad(bytes32 cup) public view returns (address);
    function cups(bytes32) public returns (address, uint, uint, uint);
}

contract ScdMcdMigration {
    SaiTubLike public tub;
    DaiJoin public daiJoin;

    function swapSaiToDai(uint) external;
    function swapDaiToSai(uint) external;
    function migrate(bytes32) external returns (uint);
}

contract CustomMigrationProxyActions is DSMath {

    function migrate(
        address payable scdMcdMigration,    
        bytes32 cup                         
    ) public returns (uint cdp) {
        SaiTubLike tub = ScdMcdMigration(scdMcdMigration).tub();
        
        (uint val, bool ok) = tub.pep().peek();
        if (ok && val != 0) {
            
            uint govFee = wdiv(tub.rap(cup), val);

            

            address owner = DSProxy(uint160(address(this))).owner();

            require(tub.gov().transferFrom(owner, address(scdMcdMigration), govFee), "transfer-failed");
        }
        
        tub.give(cup, address(scdMcdMigration));
        
        cdp = ScdMcdMigration(scdMcdMigration).migrate(cup);
    }

    function migratePayFeeWithGem(
        address payable scdMcdMigration,    
        bytes32 cup,                        
        address otc,                        
        address payGem,                     
        uint maxPayAmt                      
    ) public returns (uint cdp) {
        SaiTubLike tub = ScdMcdMigration(scdMcdMigration).tub();
        
        (uint val, bool ok) = tub.pep().peek();
        if (ok && val != 0) {
            
            uint govFee = wdiv(tub.rap(cup), val);

            
            uint payAmt = OtcInterface(otc).getPayAmount(payGem, address(tub.gov()), govFee);
            
            require(maxPayAmt >= payAmt, "maxPayAmt-exceeded");
            
            if (Gem(payGem).allowance(address(this), otc) < payAmt) {
                Gem(payGem).approve(otc, payAmt);
            }

            address owner = DSProxy(uint160(address(this))).owner();
            
            require(Gem(payGem).transferFrom(owner, address(this), payAmt), "transfer-failed");
            
            OtcInterface(otc).buyAllAmount(address(tub.gov()), govFee, payGem, payAmt);
            
            require(tub.gov().transfer(address(scdMcdMigration), govFee), "transfer-failed");
        }
        
        tub.give(cup, address(scdMcdMigration));
        
        cdp = ScdMcdMigration(scdMcdMigration).migrate(cup);
    }

    function _getRatio(
        SaiTubLike tub,
        bytes32 cup
    ) internal returns (uint ratio) {
        ratio = rdiv(
                        rmul(tub.tag(), tub.ink(cup)),
                        rmul(tub.vox().par(), tub.tab(cup))
                    );
    }

    function migratePayFeeWithDebt(
        address payable scdMcdMigration,    
        bytes32 cup,                        
        address otc,                        
        uint maxPayAmt,                     
        uint minRatio                       
    ) public returns (uint cdp) {
        SaiTubLike tub = ScdMcdMigration(scdMcdMigration).tub();
        
        (uint val, bool ok) = tub.pep().peek();
        if (ok && val != 0) {
            
            uint govFee = wdiv(tub.rap(cup), val) + 1; 

            
            uint payAmt = OtcInterface(otc).getPayAmount(address(tub.sai()), address(tub.gov()), govFee);
            
            require(maxPayAmt >= payAmt, "maxPayAmt-exceeded");
            
            tub.draw(cup, payAmt);

            require(_getRatio(tub, cup) > minRatio, "minRatio-failed");

            
            if (Gem(address(tub.sai())).allowance(address(this), otc) < payAmt) {
                Gem(address(tub.sai())).approve(otc, payAmt);
            }
            
            OtcInterface(otc).buyAllAmount(address(tub.gov()), govFee, address(tub.sai()), payAmt);
            
            govFee = wdiv(tub.rap(cup), val);
            require(tub.gov().transfer(address(scdMcdMigration), govFee), "transfer-failed");
        }
        
        tub.give(cup, address(scdMcdMigration));
        
        cdp = ScdMcdMigration(scdMcdMigration).migrate(cup);
    }
}
