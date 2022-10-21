pragma solidity 0.6.4;

contract Ownable {

    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) internal {
        require(initialOwner != address(0));
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_isOwner(), "Caller is not the owner");
        _;
    }

    function _isOwner() internal view returns (bool) {
        return msg.sender == _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

/**
 * @title The FinAid contract.
 */
contract FinAid is Ownable {

    uint256 public price;

    uint256 public REF_LIMIT = 2;

    uint256 public fee;

    address payable public wallet;

    address inception = 0x7700000000000000000000000000000000000000;

    struct User {
        bool active;
        address referrer;
        address[] referrals;
        uint256 fourth;
        uint256 profit;
    }

    mapping (address => User) public users;

    event getIn(address indexed account, address indexed referrer, uint256 price);
    event getOut(address indexed account, uint256 profit);
    event withdrawn(address indexed account, uint256 amount);

    constructor(address initialOwner, address payable walletAddr, uint256 initialPrice, uint256 initialFee) public Ownable(initialOwner) {
        wallet = walletAddr;
        price = initialPrice;
        fee = initialFee;
    }

    fallback() external payable {
        if (msg.value == 0) {

            withdraw();

        } else if (msg.value == price) {

            regUser(_bytesToAddress(bytes(msg.data)), false);

        } else revert('Incorrect value');
    }

    function regUser(address referrer, bool overflow) public payable {
        require(msg.sender != wallet, 'Fee wallet cannot participate');
        require(referrer != msg.sender, 'User cannot be a referrer for himself');
        require(!users[msg.sender].active, 'User is already in the structure');
        require(msg.value == price, 'Value must be equal to the price');

        if (getProfit(msg.sender) > 0) {
            withdraw();
        }

        if (referrer != inception) {
            require(users[referrer].active, 'You must provide an active referrer address');

            if (users[referrer].referrals.length == REF_LIMIT || getLevel(referrer) == 4) {
                if (overflow) {
                    referrer = _findReferrer(referrer);
                } else {
                    revert('Referrer cannot accept a referral');
                }
            }

            users[referrer].referrals.push(msg.sender);
            users[msg.sender].referrer = referrer;
        }

        users[msg.sender].active = true;

        emit getIn(msg.sender, users[msg.sender].referrer, price);

        if (getLevel(msg.sender) < 4) {

            users[wallet].profit += price;

        } else {

            uint256 feeAmount = price * fee / 10000;
            if (feeAmount > 0) {
                users[wallet].profit += feeAmount;
            }

            address root = msg.sender;
            for (uint256 i = 1; i <= 4; i++) {
                if (users[users[root].referrer].active) {
                    root = users[root].referrer;
                } else break;
            }

            users[root].fourth++;
            users[root].profit += price - feeAmount;

            if (users[root].fourth >= 8) {
                delete users[users[root].referrals[0]].referrer;
                delete users[users[root].referrals[1]].referrer;

                uint256 prize = users[root].profit;

                delete users[root];

                users[root].profit = prize;

                emit getOut(root, prize);
            }

        }

    }

    function withdraw() public {
        uint256 amount = getProfit(msg.sender);

        require(amount > 0, 'User has no profit');
        require(!users[msg.sender].active, 'User must get out of the structure to withdraw profit');

        users[msg.sender].profit = 0;
        if (!msg.sender.send(amount)) {
            revert('Unsufficient balance');
        }

        emit withdrawn(msg.sender, amount);
    }

    function _findReferrer(address referrer) internal view returns(address) {
        if (users[referrer].referrals.length < REF_LIMIT && getLevel(referrer) < 4) {
            return referrer;
        }

        address[] memory accounts = getStructure(referrer);

        for (uint256 i = 0; i < 7; i++) {
            if (accounts[i] != address(0) && users[accounts[i]].referrals.length < REF_LIMIT) {
                return accounts[i];
            }
        }
    }

    function setWallet(address payable newWallet) public onlyOwner {
        require(newWallet != address(0));
        require(!users[newWallet].active);

        wallet = newWallet;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        require(newPrice != 0);

        price = newPrice;
    }

    function setFee(uint256 newFee) public onlyOwner {
        require(newFee <= 500);

        fee = newFee;
    }

    function getReferrer(address account) public view returns(address) {
        return users[account].referrer;
    }

    function getProfit(address account) public view returns(uint256) {
        return users[account].profit;
    }

    function getUserReferrals(address account) public view returns(address[] memory) {
        return users[account].referrals;
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function getLevel(address account) public view returns(uint256) {
        if (users[account].active) {
            uint256 i;

            for (i = 1; i <= 4; i++) {
                if (users[users[account].referrer].active) {
                    account = users[account].referrer;
                } else break;
            }

            return i;
        }
    }

    function getStructure(address account) public view returns(address[] memory) {

        address[] memory referrals = new address[](15);
        uint256 count;

        address root;
        if (users[account].active) {
            root = account;
        } else {
            return referrals;
        }

        for (uint256 i = 1; i <= 4; i++) {
            if (users[users[root].referrer].active) {
                root = users[root].referrer;
            } else break;
        }

        referrals[count] = root;
        count++;

        for (uint256 i = 0; i < referrals.length; i++) {
            if (referrals[i] != address(0)) {
                for (uint256 l = 0; l <= 1; l++) {
                    if (users[referrals[i]].referrals.length > l) {
                        referrals[count] = users[referrals[i]].referrals[l];
                    }
                    count++;
                }
            } else {
                count += REF_LIMIT;
            }
        }

        return referrals;

    }

    function _bytesToAddress(bytes memory source) internal pure returns(address parsedReferrer) {
        assembly {
            parsedReferrer := mload(add(source,0x14))
        }
        return parsedReferrer;
    }

}
