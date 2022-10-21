pragma solidity ^0.6.0;

// ERC721
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// ERC1155
import "@openzeppelin/contracts/token/ERC1155/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./ERC20.sol";

import "@openzeppelin/contracts/utils/EnumerableSet.sol";

interface IFactory {
    function fee() external view returns (uint256);
}

contract NFT20Pair is ERC20, IERC721Receiver, ERC1155Receiver {
    address public factory;
    address public nftAddress;
    uint256 public nftType;
    uint256 public nftValue;

    mapping(uint256 => uint256) public track1155;

    using EnumerableSet for EnumerableSet.UintSet;
    EnumerableSet.UintSet lockedNfts;

    event Withdraw(uint256[] indexed _tokenIds, uint256[] indexed amounts);

    // create new token
    constructor() public {}

    function init(
        string memory _name,
        string memory _symbol,
        address _nftAddress,
        uint256 _nftType
    ) public payable {
        require(factory == address(0)); //Watch out TEST this is so we can init several time
        factory = msg.sender;
        nftType = _nftType;
        name = _name;
        symbol = _symbol;
        decimals = 18;
        nftAddress = _nftAddress;
        nftValue = 100 * 10**18;
    }

    function getInfos()
        public
        view
        returns (
            uint256 _type,
            string memory _name,
            string memory _symbol,
            uint256 _supply
        )
    {
        _type = nftType;
        _name = name;
        _symbol = symbol;
        _supply = totalSupply / 100 ether;
    }

    // withdraw nft and burn tokens
    function withdraw(
        uint256[] calldata _tokenIds,
        uint256[] calldata amounts,
        address receipient
    ) external {
        if (nftType == 1155) {
            if (_tokenIds.length == 1) {
                _burn(msg.sender, nftValue.mul(amounts[0]));
                _withdraw1155(
                    address(this),
                    receipient,
                    _tokenIds[0],
                    amounts[0]
                );
            } else {
                _batchWithdraw1155(
                    address(this),
                    receipient,
                    _tokenIds,
                    amounts
                );
            }
        } else if (nftType == 721) {
            _burn(msg.sender, nftValue.mul(_tokenIds.length));
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                _withdraw721(address(this), receipient, _tokenIds[i]);
            }
        }

        emit Withdraw(_tokenIds, amounts);
    }

    function _withdraw1155(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 value
    ) internal {
        track1155[_tokenId] = track1155[_tokenId].sub(value);
        if (track1155[_tokenId] == 0) {
            lockedNfts.remove(_tokenId);
        }
        IERC1155(nftAddress).safeTransferFrom(_from, _to, _tokenId, value, "");
    }

    function _batchWithdraw1155(
        address _from,
        address _to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        uint256 qty = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            track1155[ids[i]] = track1155[ids[i]].sub(amounts[i]);
            if (track1155[ids[i]] == 0) {
                lockedNfts.remove(ids[i]);
            }
            qty = qty + amounts[i];
        }
        // burn tokens
        _burn(msg.sender, nftValue.mul(qty));

        IERC1155(nftAddress).safeBatchTransferFrom(
            _from,
            _to,
            ids,
            amounts,
            "0x0"
        );
    }

    function multi721Deposit(uint256[] memory _ids, address _referral) public {
        uint256 fee = IFactory(factory).fee();

        for (uint256 i = 0; i < _ids.length; i++) {
            require(!lockedNfts.contains(_ids[i]), "forbidden");
            lockedNfts.add(_ids[i]);

            IERC721(nftAddress).transferFrom(
                msg.sender,
                address(this),
                _ids[i]
            );
        }

        address referral = _referral == address(0x0) ? factory : _referral;

        _mint(
            msg.sender,
            (nftValue.mul(_ids.length)).mul(uint256(100).sub(fee)).div(100)
        );
        _mint(referral, (nftValue.mul(_ids.length)).mul(fee).div(100));
    }

    function swap721(uint256 _in, uint256 _out) external {
        lockedNfts.add(_in);
        lockedNfts.remove(_out);

        IERC721(nftAddress).transferFrom(msg.sender, address(this), _in);
        IERC721(nftAddress).safeTransferFrom(address(this), msg.sender, _out);
    }

    function swap1155(
        uint256[] calldata in_ids,
        uint256[] calldata in_amounts,
        uint256[] calldata out_ids,
        uint256[] calldata out_amounts
    ) external {
        uint256 ins;
        uint256 outs;

        for (uint256 i = 0; i < in_ids.length; i++) {
            ins = ins.add(in_amounts[i]);
        }
        for (uint256 i = 0; i < out_ids.length; i++) {
            outs = outs.add(out_amounts[i]);
            track1155[out_ids[i]] = track1155[out_ids[i]].sub(out_amounts[i]);
            if (track1155[out_ids[i]] == 0) {
                lockedNfts.remove(out_ids[i]);
            }
        }

        require(ins == outs, "Need to swap same amount of NFTs");

        IERC1155(nftAddress).safeBatchTransferFrom(
            address(this),
            msg.sender,
            out_ids,
            out_amounts,
            "0x0"
        );
        IERC1155(nftAddress).safeBatchTransferFrom(
            msg.sender,
            address(this),
            in_ids,
            in_amounts,
            "INTERNAL"
        );
    }

    function _withdraw721(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        lockedNfts.remove(_tokenId);
        IERC721(nftAddress).safeTransferFrom(_from, _to, _tokenId);
    }

    function onERC721Received(
        address operator,
        address,
        uint256 tokenId,
        bytes memory data
    ) public virtual override returns (bytes4) {
        require(nftAddress == msg.sender, "forbidden");
        require(!lockedNfts.contains(tokenId), "forbidden");
        lockedNfts.add(tokenId);
        uint256 fee = IFactory(factory).fee();

        address referral =
            bytesToAddress(data) == address(0x0)
                ? factory
                : bytesToAddress(data);

        _mint(referral, nftValue.mul(fee).div(100));
        _mint(operator, nftValue.mul(uint256(100).sub(fee)).div(100));
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public virtual override returns (bytes4) {
        require(nftAddress == msg.sender, "forbidden");
        if (keccak256(data) != keccak256("INTERNAL")) {
            if (!lockedNfts.contains(id)) {
                lockedNfts.add(id);
            }

            track1155[id] = track1155[id].add(value);
            uint256 fee = IFactory(factory).fee();

            address referral =
                bytesToAddress(data) == address(0x0)
                    ? factory
                    : bytesToAddress(data);

            _mint(referral, (nftValue.mul(value)).mul(fee).div(100));
            _mint(
                operator,
                (nftValue.mul(value)).mul(uint256(100).sub(fee)).div(100)
            );
        }
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public virtual override returns (bytes4) {
        require(nftAddress == msg.sender, "forbidden");
        if (keccak256(data) != keccak256("INTERNAL")) {
            uint256 qty = 0;

            for (uint256 i = 0; i < ids.length; i++) {
                if (!lockedNfts.contains(ids[i])) {
                    lockedNfts.add(ids[i]);
                }

                qty = qty + values[i];
                track1155[ids[i]] = track1155[ids[i]].add(values[i]);
            }
            uint256 fee = IFactory(factory).fee();

            address referral =
                bytesToAddress(data) == address(0x0)
                    ? factory
                    : bytesToAddress(data);

            _mint(
                operator,
                (nftValue.mul(qty)).mul(uint256(100).sub(fee)).div(100)
            );
            _mint(referral, (nftValue.mul(qty)).mul(fee).div(100));
        }
        return this.onERC1155BatchReceived.selector;
    }

    // set new params
    function setParams(
        uint256 _nftType,
        string calldata _name,
        string calldata _symbol,
        uint256 _nftValue
    ) external {
        require(msg.sender == factory, "!authorized");
        nftType = _nftType;
        name = _name;
        symbol = _symbol;
        nftValue = _nftValue;
    }

    function bytesToAddress(bytes memory b) public view returns (address) {
        uint256 result = 0;
        for (uint256 i = b.length - 1; i + 1 > 0; i--) {
            uint256 c = uint256(uint8(b[i]));

            uint256 to_inc = c * (16**((b.length - i - 1) * 2));
            result += to_inc;
        }
        return address(result);
    }
}

