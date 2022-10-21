pragma solidity ^0.5.12;

interface ChainFaces {
	function totalSupply() external view returns (uint256);
	function getFace(uint256 id) external view returns (string memory);
	function getGolfScore(uint256 id) external view returns (uint256);
	function getPercentBear(uint256 id) external view returns (uint256);
	function getFaceSymmetry(uint256 id) external view returns (uint256);
	function getTextColor(uint256 id) external view returns (uint256);
	function getBackgroundColor(uint256 id) external view returns (uint256);
}

contract PagedFaces {

	ChainFaces private cf = ChainFaces(0x91047Abf3cAb8da5A9515c8750Ab33B4f1560a7A);

	function getFace(uint256 _id) public view returns (bytes32 face, uint256 golfScore, uint256 percentBear, uint256 faceSymmetry, uint256 textColor, uint256 backgroundColor) {
		return (_stringToBytes32(cf.getFace(_id)), cf.getGolfScore(_id), cf.getPercentBear(_id), cf.getFaceSymmetry(_id), cf.getTextColor(_id), cf.getBackgroundColor(_id));
	}

	function getFaces(uint256[] memory _ids) public view returns (bytes32[] memory faces, uint256[] memory golfScores, uint256[] memory percentBears, uint256[] memory faceSymmetries, uint256[] memory textColors, uint256[] memory backgroundColors) {
		uint256 _length = _ids.length;
		faces = new bytes32[](_length);
		golfScores = new uint256[](_length);
		percentBears = new uint256[](_length);
		faceSymmetries = new uint256[](_length);
		textColors = new uint256[](_length);
		backgroundColors = new uint256[](_length);
		for (uint256 i = 0; i < _length; i++) {
			(faces[i], golfScores[i], percentBears[i], faceSymmetries[i], textColors[i], backgroundColors[i]) = getFace(_ids[i]);
		}
	}

	function getFacesTable(uint256 _limit, uint256 _page, bool _isAsc) public view returns (uint256[] memory ids, bytes32[] memory faces, uint256[] memory percentBears, uint256[] memory faceSymmetries, uint256[] memory textColors, uint256[] memory backgroundColors, uint256 totalFaces, uint256 totalPages) {
		require(_limit > 0);
		totalFaces = cf.totalSupply();

		if (totalFaces > 0) {
			totalPages = (totalFaces / _limit) + (totalFaces % _limit == 0 ? 0 : 1);
			require(_page < totalPages);

			uint256 _offset = _limit * _page;
			if (_page == totalPages - 1 && totalFaces % _limit != 0) {
				_limit = totalFaces % _limit;
			}

			ids = new uint256[](_limit);
			for (uint256 i = 0; i < _limit; i++) {
				ids[i] = (_isAsc ? _offset + i : totalFaces - _offset - i - 1);
			}
		} else {
			totalPages = 0;
			ids = new uint256[](0);
		}
		/* stack too deep so 1 return value needs to be dropped (golf score) */
		(faces, , percentBears, faceSymmetries, textColors, backgroundColors) = getFaces(ids);
	}

	function _stringToBytes32(string memory _s) internal pure returns (bytes32 b) {
		if (bytes(_s).length == 0) {
			return 0x0;
		}
		assembly { b := mload(add(_s, 32)) }
	}
}
