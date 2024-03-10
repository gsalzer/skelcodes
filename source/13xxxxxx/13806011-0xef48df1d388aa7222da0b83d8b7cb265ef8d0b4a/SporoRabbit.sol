// File: contracts/lib/States.sol

pragma solidity ^0.8.10;


library States {
    int8 constant Annihilated = -128;
    int8 constant Unminted = -1;
    int8 constant Unopened = 1;
    int8 constant Alive = 10;
    int8 constant Ethereal = 20;
    int8 constant Lost = 127;
}

library Phase {    
    uint8 constant Disabled = 1;
    uint8 constant Registration = 2;
    uint8 constant PrivatePresale = 3;
    uint8 constant PublicPresale = 4;
    uint8 constant Released = 5;
    uint8 constant Closed = 6;
}

// File: contracts/lib/Utils.sol






contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

library Utils {

    function isOpenSeaProxy(address proxy, address _owner, address operator) internal view returns (bool){
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxy);
        if (address(proxyRegistry.proxies(_owner)) == operator) {
            return true;
        }
        return false;
    }
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // slither-disable-next-line assembly 
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function toString(int8 value) internal pure returns (string memory) {
        return toString(uint(int(value)));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

// File: contracts/lib/Interfaces.sol






interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


interface IERC721 is IERC165 {

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);


    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Enumerable is IERC721 {

    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);
}


interface IERC721Metadata is IERC721 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}


interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: contracts/lib/ERC721.sol



/********************
* @modified code provided by Squeebo *
********************/





abstract contract ERC721 is IERC165, IERC721, IERC721Metadata {
    string private _name;
    string private _symbol;
    address[] internal _owners;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "410"
        );

        uint256 count = 0;
        uint256 length = _owners.length;
        for (uint256 i = 0; i < length; ++i) {
            if (owner == _owners[i]) ++count;
        }
        return count;
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "404"
        );
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "420");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "900"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "404"
        );
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved)
        external
        virtual
        override
    {
        require(operator != msg.sender, "950");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "911"
        );
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "911"
        );
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            "420"
        );
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId < _owners.length && _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "404"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "420"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "800");
        require(!_exists(tokenId), "920");

        _beforeTokenTransfer(address(0), to, tokenId);
        _owners.push(to);

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);
        _approve(address(0), tokenId);
        _owners[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "910"
        );
        require(to != address(0), "810");

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (Utils.isContract(to)) {
            // slither-disable-next-line unused-return 
            try 
                // slither-disable-next-line variable-scope 
                IERC721Receiver(to).onERC721Received(msg.sender, from,tokenId,_data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;       
            // slither-disable-next-line variable-scope          
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("420");
                } else {
                    // slither-disable-next-line assembly 
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    // slither-disable-next-line dead-code 
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: contracts/lib/ERC721Enumerable.sol






/********************
 * @modified code provided by Squeebo *
 ********************/

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    mapping(address => uint256[]) internal _balances;

    function balanceOf(address owner)
        public
        view
        virtual
        override(ERC721, IERC721)
        returns (uint256)
    {
        require(owner != address(0), "800");
        return _balances[owner].length;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256 tokenId)
    {
        require(index < ERC721.balanceOf(owner), "404");
        return _balances[owner][index];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _owners.length - 1;
    }

    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(index < _owners.length, "404");
        return index;
    }

    //internal - costs 20k
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        address zero = address(0);
        if (from != zero || to == zero) {
            //find this token and remove it
            uint256 length = _balances[from].length;
            for (uint256 i; i < length; ++i) {
                if (_balances[from][i] == tokenId) {
                    _balances[from][i] = _balances[from][length - 1];
                    _balances[from].pop();
                    break;
                }
            }
        }
        
        if (to != zero) _balances[to].push(tokenId);
    }
}

// File: contracts/v1/DimmCityV1Base.sol







abstract contract DimmCityV1Base is ERC721Enumerable {
    uint256 private _tokenIdCounter;
    uint8 public MaxPack;
    uint8 public ReleasePhase;
    bool EnforceRoyality;
    uint256 public MaxSupply;
    address public WithdrawalAddress;
    address public ProxyRegistryAddress;
    string public MetaDataUri;
    mapping(uint256 => int8) private _states;
    mapping(address => uint8) private _presaleList;
    mapping(int8 => mapping(int8 => uint256)) _costs;
    mapping(address => bool) public Admins;
    mapping(address => bool) public Markets;

    event ReleasePhaseChanged(uint8 indexed state);
    event StateChanged(
        address indexed sender,
        uint256 indexed tokenId,
        int8 indexed state
    );

    constructor(
        string memory releaseName,
        string memory releaseSymbol,
        string memory relativeUri,
        uint256 packCost,
        uint256 resurrectionCost,
        uint256 restorationCost
    ) ERC721(releaseName, releaseSymbol) {
        MetaDataUri = string(
            abi.encodePacked(
                "https://sporosnft.io/api/v1",
                relativeUri
            )
        );
        _tokenIdCounter = 1;
        _owners.push(address(0));

        MaxPack = 10;
        WithdrawalAddress = msg.sender;
        Admins[msg.sender] = true;
        MaxSupply = 3000;
        ReleasePhase = Phase.Registration;
        //EnforceRoyality = true;
        ProxyRegistryAddress = address(
            0x000a5409ec958c83c3f309868babaca7c86dcb077c1
        );

        _costs[States.Unminted][States.Unopened] = packCost;
        _costs[States.Lost][States.Alive] = restorationCost;
        _costs[States.Ethereal][States.Alive] = resurrectionCost;
    }

    modifier nonZero(address input) {
        require(input != address(0), "800");
        _;
    }

    //#region Admin

    modifier onlyAdmins() {
        require(isAdmin(msg.sender), "900");
        _;
    }

    function isAdmin(address admin) internal view returns (bool) {
        return Admins[admin];
    }

    function removeAdmin(address admin)
        external
        virtual
        nonZero(admin)
        onlyAdmins
    {
        require(admin != msg.sender, "940");
        delete Admins[admin];
    }

    function addAdmin(address newAdmin)
        external
        virtual
        nonZero(newAdmin)
        onlyAdmins
    {
        require(!isAdmin(newAdmin), "930");
        Admins[newAdmin] = true;
    }

    function owner() public view virtual returns (address) {
        return WithdrawalAddress;
    }

    function addMarket(address newMarket)
        external
        virtual
        nonZero(newMarket)
        onlyAdmins
    {
        Markets[newMarket] = true;
    }

    function removeMarket(address market)
        external
        virtual
        nonZero(market)
        onlyAdmins
    {
        delete Markets[market];
    }

    //#endregion

    function setWithdawalAddress(address newAddress)
        external
        nonZero(newAddress)
        onlyAdmins
    {
        WithdrawalAddress = newAddress;
    }

    function setMaxSupply(uint256 supply) external onlyAdmins {
        require(supply >= _owners.length, "510");
        MaxSupply = supply;
    }

    function setMaxPack(uint8 perPack) external onlyAdmins {
        MaxPack = perPack;
    }

    function setGuard(bool enabled) external onlyAdmins {
        EnforceRoyality = enabled;
    }

    function setMetaDataUri(string memory baseURI) external onlyAdmins {
        MetaDataUri = baseURI;
    }

    function setProxyRegistryAddress(address proxyAddress) external onlyAdmins {
        ProxyRegistryAddress = proxyAddress;
    }

    function getUserCredits(address wallet)
        external
        view
        returns (uint8 credits)
    {
        require(msg.sender == wallet || isAdmin(msg.sender), "900");
        return _presaleList[wallet];
    }

    //ToDo bulk set states

    function bulkUpdateCredits(
        address[] calldata list,
        uint8[] calldata credits
    ) external onlyAdmins {
        require(list.length == credits.length, "520");

        for (uint256 i = 0; i < list.length; i++) {
            _presaleList[list[i]] = credits[i];
        }
    }

    function getPackCost() external view returns (uint256) {
        return _costs[States.Unminted][States.Unopened];
    }

    function setStateCost(
        int8 from,
        int8 to,
        uint256 cost
    ) external onlyAdmins {
        _costs[from][to] = cost;
    }

    function setReleasePhase(uint8 state) external onlyAdmins {
        ReleasePhase = state;
        emit ReleasePhaseChanged(ReleasePhase);
    }

    function getState(uint256 tokenId) external view returns (int8) {
        require(_exists(tokenId), "404");
        return _states[tokenId];
    }

    function setState(uint256 tokenId, int8 state)
        public
        payable
        returns (int8)
    {
        require(state != States.Unopened, "915");
        if (!isAdmin(msg.sender)) {
            require(ownerOf(tokenId) == msg.sender, "910");
            require(msg.value >= _costs[_states[tokenId]][state], "200");
            require(
                _states[tokenId] >= States.Unopened && state > States.Unopened,
                "915"
            );
        }
        _states[tokenId] = state;
        emit StateChanged(msg.sender, tokenId, state);
        return state;
    }

    function burn(uint256 tokenId) external onlyAdmins {
        _burn(tokenId);
        setState(tokenId, States.Annihilated);
    }

    function buyPack(
        address to,
        uint8 numberOfTokens,
        bool openNow
    ) external payable virtual {
        require(
            ReleasePhase >= Phase.PrivatePresale && ReleasePhase < Phase.Closed,
            "000"
        );
        require(numberOfTokens > 0 && numberOfTokens <= MaxPack, "500");

        uint256 currentId = _owners.length;
        require((currentId + numberOfTokens) <= MaxSupply, "400");

        bool admin = isAdmin(msg.sender);
        require(
            admin ||
                msg.value >=
                (_costs[States.Unminted][States.Unopened] * numberOfTokens),
            "200"
        );
        require(
            admin ||
                ReleasePhase >= Phase.PublicPresale ||
                numberOfTokens <= _presaleList[msg.sender],
            "100"
        );

        if (to == address(0)) to = msg.sender;

        int8 initialState = States.Unopened;
        if (ReleasePhase >= Phase.Released && openNow)
            initialState = States.Alive;

        for (uint8 i = 0; i < numberOfTokens; i++) {
            _states[currentId] = initialState;

            if (!admin && _presaleList[msg.sender] > 0)
                _presaleList[msg.sender] = _presaleList[msg.sender] - 1;

            _safeMint(to, currentId);
            currentId++;
        }
        delete currentId;
        delete admin;
    }

    function openPack(uint256[] calldata tokens) external payable virtual {
        require(ReleasePhase >= Phase.Released, "001");
        require(
            msg.value >=
                (_costs[States.Unopened][States.Alive] * tokens.length),
            "200"
        );

        for (uint256 index = 0; index < tokens.length; index++) {
            uint256 tokenId = tokens[index];
            if (
                _states[tokenId] == States.Unopened &&
                msg.sender == ownerOf(tokenId)
            ) {
                _states[tokenId] = States.Alive;
            }
            delete tokenId;
        }
    }

    function sendPack(address to, uint8 numberOfTokens)
        external
        onlyAdmins
        nonZero(to)
    {
        require(numberOfTokens > 0, "410");

        uint256 currentId = _owners.length;
        require(currentId + numberOfTokens <= MaxSupply, "400");
        for (uint8 i = 0; i < numberOfTokens; i++) {
            _states[currentId] = States.Unopened;
            _safeMint(to, currentId);
            currentId++;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable) {
        if (to != address(0) && from != address(0) && !allowTransfer(from)) {
            _states[tokenId] = States.Lost;
            emit StateChanged(msg.sender, tokenId, States.Lost);
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function isApprovedForAll(address _owner, address operator)
        public
        view
        override
        returns (bool)
    {
        if (
            ProxyRegistryAddress != address(0) &&
            Utils.isOpenSeaProxy(ProxyRegistryAddress, _owner, operator)
        ) return true;

        return super.isApprovedForAll(_owner, operator);
    }

    function allowTransfer(address _owner) internal view returns (bool) {
        if (!EnforceRoyality) return true;

        bool result = (isAdmin(msg.sender) || Markets[msg.sender]);

        if (!result && ProxyRegistryAddress == address(0)) return false;

        if (
            !result &&
            Utils.isOpenSeaProxy(ProxyRegistryAddress, _owner, msg.sender)
        ) {
            return true;
        }
        return result;
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(MetaDataUri, "/contract.json"));
    }

    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "404");

        return
            string(
                abi.encodePacked(
                    MetaDataUri,
                    "/",
                    Utils.toString(tokenId),
                    ".json?s=",
                    Utils.toString(_states[tokenId])
                )
            );
    }

    function withdraw() external nonZero(WithdrawalAddress) onlyAdmins {
        require(isAdmin(WithdrawalAddress), "910");
        (bool sent, ) = WithdrawalAddress.call{value: address(this).balance}(
            ""
        );

        require(sent, "999");
        delete sent;
    }
}

// File: contracts/v1/SporoRabbit.sol





contract SporoRabbit is DimmCityV1Base {
    constructor()
     DimmCityV1Base(
            "Sporos",
            "D.C.S1R1",
            "/sporos/s1r1",
            0.04 ether, 
            0.005 ether,
            0.005 ether
        )
    {        
    }
}
