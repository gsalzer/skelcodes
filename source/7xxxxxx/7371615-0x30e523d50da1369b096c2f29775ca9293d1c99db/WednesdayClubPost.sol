pragma solidity ^0.4.25;

import "./ownable.sol";

contract WednesdayClubPost is Ownable {
    // The structure of a post
    struct Post {
        uint256 id;
        address poster;
        uint256 value;
        uint256 likes;
        uint256 timestamp;
        uint256 reportCount;
    }

    modifier whenTimeElapsedPost() {
        require(hasElapsedPost());
        _;
    }

    event PostContent(uint256 indexed id, string content, string media);

    // The posts that each address has written
    mapping(address => uint256[]) public userPosts;

    // All the posts ever written by ID
    mapping(uint256 => Post) public posts;

    // Keep track of all IDs - use for loading
    uint256[] public postIds;

    // amountForPost
    uint256 public amountForPost;

    //ensure that each user can only post once at everyinterval
    mapping(address => uint) public postTime;

    //interval user has to wait to be able to post
    uint public postInterval;

    // minimum amount For likes
    uint256 public minimumToLikePost;

    // minimum amount For reporting
    uint256 public minimumForReporting;

    //ensure that each user can only post once at everyinterval
    mapping(address => uint) public reportTime;

    //interval user has to wait to be able to post
    uint public reportInterval;

    function getUserPostLength(address _user) public view returns (uint256){
        return userPosts[_user].length;
    }

    function hasElapsedPost() public view returns (bool) {
        if (now >= postTime[msg.sender] + postInterval) {
            //has elapsed from postTime[msg.sender]
            return true;
        }
        return false;
    }

    function hasElapsedReport() public view returns (bool) {
        if (now >= reportTime[msg.sender] + reportInterval) {
            //has elapsed from reportTime[msg.sender]
            return true;
        }
        return false;
    }

    function getPostIdsLength() public view returns (uint256){
        return postIds.length;
    }

    function setAmountForPost(uint256 _amountForPost) public onlyOwner {
        amountForPost = _amountForPost;
    }

    function setPostInterval(uint _postInterval) public onlyOwner {
        postInterval = _postInterval;
    }

    function setReportingInterval(uint _reportInterval) public onlyOwner {
        reportInterval = _reportInterval;
    }

    function setMinimumForReporting(uint _minimumForReporting) public onlyOwner {
        minimumForReporting = _minimumForReporting;
    }

    function setMinimumToLikePost(uint _minimumToLikePost) public onlyOwner {
        minimumToLikePost = _minimumToLikePost;
    }
}
