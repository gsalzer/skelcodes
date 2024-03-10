pragma solidity ^0.4.25;

import "./ownable.sol";

contract WednesdayClubUser is Ownable {

    struct User {
        address id;
        string username;
        string about;
        string profilePic;
        string site;
    }

    modifier whenNotSuspended() {
        require(hasSuspensionElapsed());
        _;
    }

    mapping(address => User) public users;

    // banned users
    mapping (address => uint) public suspendedUsers;

    // blocked users
    mapping (address => address[]) public blockedUsers;

    // followers: list of who is following
    mapping(address => address[]) public followers;

    // following: list of who you are following
    mapping(address => address[]) public following;

    // minimum amount For following
    uint256 public minimumForFollow;

    // minimum amount For updating profile
    uint256 public minimumForUpdatingProfile;

    // minimum amount For blocking user
    uint256 public minimumForBlockingUser;

    function hasSuspensionElapsed() public view returns (bool) {
        if (now >= suspendedUsers[msg.sender]) {
            //has elapsed from suspendedUsers[msg.sender]
            return true;
        }
        return false;
    }

    function suspendUser(address _user, uint _time) public onlyOwner {
        suspendedUsers[_user] = now + _time;
    }

    function setMinimumForFollow(uint _minimumForFollow) public onlyOwner {
        minimumForFollow = _minimumForFollow;
    }

    function getFollowersLength(address _address) public view returns (uint256){
        return followers[_address].length;
    }

    function getFollowingLength(address _address) public view returns (uint256){
        return following[_address].length;
    }
}
