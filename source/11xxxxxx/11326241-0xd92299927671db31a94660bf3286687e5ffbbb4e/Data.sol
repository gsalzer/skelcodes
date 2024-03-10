pragma solidity ^0.5.16;

import "./Address.sol";

contract Data {
    address public proxy;
    
    struct Asset {
		uint256 typeid;
        bytes32 name;
        address tokenAddress;
        string partnerIssuer;
    }

    mapping(uint256 => Asset) internal Assets;
    mapping (uint256 => uint256) internal AssetIndex;
	uint256[] internal AssetIds;

    constructor(address _proxy) public {
        require(_proxy != address(0), "zero address is not allowed");
        proxy = _proxy;
    }

    // 验证对model的操作是否来源于Proxy
    modifier onlyAuthorized {
        require(msg.sender == proxy, "Data: must be called by entry contract");
        _;
    }

    function _checkParam(uint256 _typeid, bytes32 _name, address _tokenAddress, string memory _partnerIssuer) internal view {
		require(_typeid != uint256(0), "Data: _typeid null is not allowed");
		require(_name != bytes32(0), "Data: _name null is not allowed");
		require(_tokenAddress != address(0), "Data: _tokenAddress null is not allowed");
		require(Address.isContract(_tokenAddress), "_tokenAddress is a non-contract address");
		require(bytes(_partnerIssuer).length > 0, "Data: _partnerIssuer null is not allowed");
	}

    function _insert(
		uint256 _typeid,
        bytes32 _name,
        address _tokenAddress,
        string memory _partnerIssuer
    ) internal {
        _checkParam(_typeid, _name, _tokenAddress, _partnerIssuer);
        require(
            Assets[_typeid].typeid == uint256(0),
            "Data: current Asset exist"
        );
        Asset memory a = Asset(_typeid, _name, _tokenAddress, _partnerIssuer);
        Assets[_typeid] = a;
        AssetIds.push(_typeid);
		AssetIndex[_typeid] = AssetIds.length;
    }

    function insert(
        uint256 _typeid,
		bytes32 _name,
		address _tokenAddress,
		string calldata _partnerIssuer
    ) external onlyAuthorized {
        _insert(_typeid, _name, _tokenAddress, _partnerIssuer);
    }

    function _update(
        uint256 _typeid,
		bytes32 _name,
		address _tokenAddress,
		string memory _partnerIssuer
    ) internal {
        require(
            _typeid != uint256(0),
            "Data: _typeid 0 is not allowed"
        );
        require(
            Assets[_typeid].typeid != uint256(0),
            "Data: current Asset not exist"
        );

        Asset memory a = Assets[_typeid];
        if (_name != bytes32(0)) {
            a.name = _name;
        }
        if (_tokenAddress != address(0)) {
            a.tokenAddress = _tokenAddress;
        }
        if (bytes(_partnerIssuer).length > 0) {
            a.partnerIssuer = _partnerIssuer;
        }
        Assets[_typeid] = a;
    }

    function update(
        uint256 _typeid,
		bytes32 _name,
		address _tokenAddress,
		string calldata _partnerIssuer
    ) external onlyAuthorized {
		_update(_typeid, _name, _tokenAddress, _partnerIssuer);
    }

    function _search(uint256 _typeid)
        internal
        view
        returns (
            uint256,
			bytes32,
			address,
			string memory
        )
    {
        require(
            _typeid != uint256(0),
            "Data: _typeid 0 is not allowed"
        );
        require(
            Assets[_typeid].typeid != uint256(0),
            "Data: current Asset not exist"
        );

        Asset memory a = Assets[_typeid];
        return (a.typeid, a.name, a.tokenAddress, a.partnerIssuer);
    }

    function search(uint256 _typeid)
        external
        view
		onlyAuthorized
        returns (
            uint256,
			bytes32,
			address,
			string memory
        )
    {
        return _search(_typeid);
    }

    function _delete(uint256 _typeid) internal {
		require(_typeid != uint256(0), "Data: _typeid 0 is not allowed");
        require(Assets[_typeid].typeid != uint256(0), "Data: current Asset not exist");
        uint256 _deleteIndex = AssetIndex[_typeid] - 1;
		uint256 _lastIndex = AssetIds.length - 1;
        if(_deleteIndex != _lastIndex){
			AssetIds[_deleteIndex] = AssetIds[_lastIndex];
			AssetIndex[AssetIds[_lastIndex]] = _deleteIndex + 1;
		}
		AssetIds.pop();
        delete Assets[_typeid];
    }

    function del(uint256 _typeid) external onlyAuthorized {
        _delete(_typeid);
    }

    //return Array of assetId
    function getAssetIds() external view onlyAuthorized returns (uint256[] memory){
        uint256[] memory ret = AssetIds;
        return ret;
    }
}

