// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import '@openzeppelin/contracts/cryptography/MerkleProof.sol';

interface ITokenLocker {
    function merkleRoot() external view returns (bytes32);

    function lockOf(address _account) external view returns (uint256);

    function released(address _account) external view returns (uint256);

    function canUnlockAmount(address _account) external view returns (uint256);

    function firstUnlockAmount(uint256 _lockAmount) external view returns (uint256);

    function unlock(address _account) external;

    function firstUnlock(
        uint256 _index,
        address _account,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external;
}

contract TokenLocker is ITokenLocker, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public token;

    uint256 public startReleaseTimestamp;
    uint256 public endReleaseTimestamp;

    mapping(address => uint256) private _locks;
    mapping(address => uint256) private _released;

    bytes32 public override merkleRoot;

    event Lock(address indexed to, uint256 value);
    event UnLock(address indexed to, uint256 value);

    constructor(
        IERC20 _token,
        uint256 _startReleaseTimestamp,
        uint256 _endReleaseTimestamp,
        bytes32 _merkleRoot
    ) public {
        require(_endReleaseTimestamp > _startReleaseTimestamp, 'endReleaseTimestamp < startReleaseTimestamp');
        token = _token;
        startReleaseTimestamp = _startReleaseTimestamp;
        endReleaseTimestamp = _endReleaseTimestamp;
        merkleRoot = _merkleRoot;
    }

    function lockOf(address _account) external view override returns (uint256) {
        return _locks[_account];
    }

    function released(address _account) external view override returns (uint256) {
        return _released[_account];
    }

    function canUnlockAmount(address _account) public view override returns (uint256) {
        uint256 timestamp = block.timestamp;
        if (timestamp < startReleaseTimestamp) {
            return 0;
        } else if (timestamp >= endReleaseTimestamp) {
            return _locks[_account].sub(_released[_account]);
        } else {
            uint256 _releasedTime = timestamp.sub(startReleaseTimestamp);
            uint256 _totalVestingTime = endReleaseTimestamp.sub(startReleaseTimestamp);
            return _locks[_account].mul(_releasedTime).div(_totalVestingTime).sub(_released[_account]);
        }
    }

    function firstUnlockAmount(uint256 _lockAmount) public view override returns (uint256) {
        uint256 timestamp = block.timestamp;
        if (timestamp < startReleaseTimestamp) {
            return 0;
        } else if (timestamp >= endReleaseTimestamp) {
            return _lockAmount;
        } else {
            uint256 _releasedTime = timestamp.sub(startReleaseTimestamp);
            uint256 _totalVestingTime = endReleaseTimestamp.sub(startReleaseTimestamp);
            return _lockAmount.mul(_releasedTime).div(_totalVestingTime);
        }
    }

    function firstUnlock(
        uint256 _index,
        address _account,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external override nonReentrant {
        require(block.timestamp > startReleaseTimestamp, 'still locked');
        require(_locks[_account] == 0, 'User claimed once');
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(_index, _account, _amount));
        require(MerkleProof.verify(_merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');
        _setLockAmount(_account, _amount);
        _unlock(_account);
    }

    function unlock(address _account) public override nonReentrant {
        require(block.timestamp > startReleaseTimestamp, 'still locked');
        require(_locks[_account] > _released[_account], 'no locked');
        _unlock(_account);
    }

    function setLockAmount(address _account, uint256 _amount) external onlyOwner {
        _setLockAmount(_account, _amount);
    }

    function updateRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function emergencyWithdraw(IERC20 _token, uint256 _amount) external onlyOwner {
        _safeTransfer(_token, owner(), _amount);
    }

    function _safeTransfer(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) internal {
        if (_token == IERC20(0)) {
            (bool success, ) = _to.call{value: _amount}('');
            require(success, 'transfer failed');
        } else {
            _token.safeTransfer(_to, _amount);
        }
    }

    function _unlock(address _account) internal {
        uint256 _amount = canUnlockAmount(_account);

        require(_amount > 0, 'zero unlock');

        token.safeTransfer(_account, _amount);
        _released[_account] = _released[_account].add(_amount);
        emit UnLock(_account, _amount);
    }

    function _setLockAmount(address _account, uint256 _amount) internal {
        _locks[_account] = _amount;
        emit Lock(_account, _amount);
    }
}
