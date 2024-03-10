pragma solidity ^0.4.25;

import "./ownable.sol";

contract WednesdayClubComment is Ownable {
    //Structure of a comment
    struct Comment {
        uint256 id;
        uint256 parentId;
        address commenter;
        uint256 value;
        uint256 likes;
        uint256 timestamp;
        uint256 reportCount;
    }

    modifier whenTimeElapsedComment() {
        require(hasElapsedComment());
        _;
    }

    event CommentContent(uint256 indexed id, string content, string media);

    // list of ids of all comments
    mapping(uint256 => Comment) public comments;

    // The comments that each user has commented
    mapping(address => uint256[]) public userComments;

    // list of comments for each post id
    mapping(uint256 => uint256[]) public postComments;

    // amountForComment
    uint256 public amountForComment;

    //ensure that each user can only post once at everyinterval
    mapping(address => uint) public commentTime;

    //interval user has to wait to be able to post
    uint public commentInterval;

    // minimum amount For likes
    uint256 public minimumToLikeComment;

    function hasElapsedComment() public view returns (bool) {
        if (now >= commentTime[msg.sender] + commentInterval) {
            //has elapsed from postTime[msg.sender]
            return true;
        }
        return false;
    }

    function setMinimumToLikeComment(uint _minimumToLikeComment) public onlyOwner {
        minimumToLikeComment = _minimumToLikeComment;
    }

    function postCommentsLength(uint256 _postId) public view returns (uint256) {
        return postComments[_postId].length;
    }
}
