pragma solidity ^0.5.11;


contract Context {
    
    
    constructor () internal { }
    

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    
    function owner() public view returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    
    function balanceOf(address owner) public view returns (uint256 balance);

    
    function ownerOf(uint256 tokenId) public view returns (address owner);

    
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

contract ICards is IERC721 {

    struct Batch {
        uint48 userID;
        uint16 size;
    }

    function batches(uint index) public view returns (uint48 userID, uint16 size);

    function userIDToAddress(uint48 id) public view returns (address);

    function getDetails(
        uint tokenId
    )
        public
        view
        returns (
        uint16 proto,
        uint8 quality
    );

    function setQuality(
        uint tokenId,
        uint8 quality
    ) public;

    function mintCards(
        address to,
        uint16[] memory _protos,
        uint8[] memory _qualities
    )
        public
        returns (uint);

    function mintCard(
        address to,
        uint16 _proto,
        uint8 _quality
    )
        public
        returns (uint);

    function burn(uint tokenId) public;

    function batchSize()
        public
        view
        returns (uint);
}

contract PromoFactory is Ownable {

    ICards public cards;

    mapping(uint16 => Promo) public promos;
    mapping(address => uint) public adminMintersMapping;

    address[] public adminMintersArray;

    struct Promo {
        bool isLocked;
        address[] minters;
    }

    

    event AdminMinterAdded(
        address minter
    );

    event AdminMinterRemoved(
        address minter
    );

    event PromoMinterAdded(
        uint16 proto,
        address minter
    );

    event PromoMinterRemoved(
        uint16 proto,
        address minter
    );

    event PromoLocked(
        uint16 proto
    );

    

    constructor(
        ICards _cards
    )
        public
    {
        cards = _cards;
    }

    

    
    function mint(
        address _to,
        uint16[] memory _protos,
        uint8[] memory _qualities
    )
        public
    {
        require(
            _protos.length == _qualities.length,
            "Promo Factory: array length mismatch between protos and qualities"
        );

        for (uint i; i < _protos.length; i++) {
            uint16 proto = _protos[i];
            require(
                isValidMinter(msg.sender, proto) == true,
                "Promo Factory: only assigned minter can mint for this proto"
            );

            require(
                promos[proto].isLocked == false,
                "Promo Factory: cannot mint a locked proto"
            );
        }

        cards.mintCards(_to, _protos, _qualities);
    }

    
    function mintSingle(
        address _to,
        uint16 _proto,
        uint8 _quality
    )
        public
    {

        require(
            isValidMinter(msg.sender, _proto) == true,
            "Promo Factory: only assigned minter can mint for this proto"
        );

        require(
            promos[_proto].isLocked == false,
            "Promo Factory: cannot mint a locked proto"
        );

        cards.mintCard(_to, _proto, _quality);
    }

    
    function validMinters(
        uint16 _proto
    )
        public
        view
        returns (address[] memory)
    {
        return promos[_proto].minters;
    }

    
    function isValidMinter(
        address _minter,
        uint16 _proto
    )
        public
        view
        returns (bool)
    {
        Promo memory promo = promos[_proto];
        for (uint256 i = 0; i < promo.minters.length; i++) {
            if (promo.minters[i] == _minter) {
                return true;
            }
        }

        return false;
    }

    
    function isPromoLocked(
        uint16 _proto
    )
        public
        view
        returns (bool)
    {
        return promos[_proto].isLocked;
    }

    
    function getAdminMinters() public view returns (address[] memory) {
        return adminMintersArray;
    }

    

    
    function addAdminMinter(
        address _minter
    )
        public
        onlyOwner
    {
        adminMintersMapping[_minter] = uint128(adminMintersArray.push(_minter));

        emit AdminMinterAdded(_minter);
    }

    
    function removeAdminMinter(
        address _minter
    )
        public
        onlyOwner
    {
        address last = adminMintersArray[adminMintersArray.length - 1];
        if(_minter != last) {
            uint256 targetIndex = adminMintersMapping[_minter] - 1;
            adminMintersArray[targetIndex] = last;
            adminMintersMapping[last] = targetIndex + 1;
        }

        adminMintersArray.length --;
        delete adminMintersMapping[_minter];

        emit AdminMinterRemoved(_minter);
    }

    
    function adminMintCards(
        address _to,
        uint16[] memory _protos,
        uint8[] memory _qualities
    )
        public
    {

        require(
            adminMintersMapping[msg.sender] > 0,
            "Promo Factory: must be an admin minter to call adminMintCards()"
        );

        cards.mintCards(_to, _protos, _qualities);
    }

    
    function addPromoMinter(
        address _minter,
        uint16 _proto
    )
        public
        onlyOwner
    {

        require(
            promos[_proto].isLocked == false,
            "Promo Factory: proto already locked"
        );

        promos[_proto].minters.push(_minter);

        emit PromoMinterAdded(_proto, _minter);
    }

    
    function removePromoMinter(
        address _minter,
        uint16 _proto
    )
        public
        onlyOwner
    {
        bool found = false;
        uint index = 0;

        Promo storage promo = promos[_proto];
        for (uint i = 0; i < promo.minters.length; i++) {
            if (promo.minters[i] == _minter) {
                index = i;
                found = true;
            }
        }

        require(
            found == true,
            "Promo Factory: Must be a valid minter"
        );

        for (uint i = index; i < promo.minters.length - 1; i++){
            promo.minters[i] = promo.minters[i+1];
        }

        delete promo.minters[promo.minters.length - 1];
        promo.minters.length--;

        emit PromoMinterRemoved(_proto, _minter);
    }

    
    function lock(
        uint16 _proto
    )
        public
        onlyOwner
    {
        require(
            promos[_proto].minters.length != 0,
            "Promo Factory: must be an assigned proto"
        );

        require(
            promos[_proto].isLocked == false,
            "Promo Factory: cannot lock a locked proto"
        );

        promos[_proto].isLocked = true;

        emit PromoLocked(_proto);
    }

}
