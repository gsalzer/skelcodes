pragma solidity 0.5.17;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

contract Splitter is ReentrancyGuard {
    using SafeMath for uint256;

    address public currency;
    address[] public team;
    uint256 public totalShares;
    uint256 public totalIncome;
    uint256 public totalIncomeClaimed;
    uint256 public lastTokenBalance;

    struct Member {
        uint256 shares;
        uint256 incomeClaimed;
    }

    mapping(address => Member) public members;

    constructor(
        address[] memory _team,
        uint256[] memory _shares,
        address _currency
    ) public {
        require(_team.length > 0);
        require(_team.length == _shares.length);
        require(_currency != address(0));

        currency = _currency;
        team = _team;

        uint256 _totalShares = 0;

        for (uint256 i = 0; i < _team.length; i++) {
            address member = _team[i];
            uint256 share = _shares[i];

            require(member != address(0));
            require(share > 0);

            members[member] = Member(share, 0);
            _totalShares = _totalShares.add(share);
        }

        totalShares = _totalShares;
        lastTokenBalance = IERC20(currency).balanceOf(address(this));
    }

    function claimIncome() public nonReentrant {
        uint256 newIncome = IERC20(currency).balanceOf(address(this)).sub(lastTokenBalance);
        totalIncome = totalIncome.add(newIncome);

        Member storage member = members[msg.sender];
        require(member.shares > 0, "not a member");
        uint256 memberIncome = totalIncome.mul(member.shares).div(totalShares);
        uint256 newMemberIncome = memberIncome.sub(member.incomeClaimed);
        require(newMemberIncome > 0, "no income to claim");

        member.incomeClaimed = memberIncome;
        totalIncomeClaimed = totalIncomeClaimed.add(newMemberIncome);

        require(IERC20(currency).transfer(msg.sender, newMemberIncome), "transfer failed");

        lastTokenBalance = IERC20(currency).balanceOf(address(this));
    }
}

