pragma solidity ^0.5.8;
import './SafeMath.sol';

contract InvitationBasic {
    function signUp(address referrer, address addr, uint256 phase, uint256 ePhase) external;
    function getParent(address addr) external view returns(address);
    function getAncestors(address addr) external view returns(address[] memory);
    function isRoot(address addr) external view returns (bool);
    function isSignedUp(address addr) public view returns (bool);
    function newRoot(address addr, uint256 phase) external;
    function newSignupCount(uint256 phase) external view returns (uint);
    function getPoints(uint256 phase, address addr) external view returns (uint256);
    function getTop(uint256 phase) external view returns(address[] memory);
    function distributeBonus(uint256 len) external pure returns(uint256[] memory);
}

contract Invitation is InvitationBasic {
    using SafeMath for uint256;

    /*
     * STATES
     */
    address public master;
    address public caller;

    bool public paused;

    mapping (address => bool) public rootList;
    mapping (address => address) public referenceParentList;
    mapping (address => address[]) public referenceChildList;
    mapping (uint256 => mapping (address => uint256)) public addressPoints;
    mapping (uint256 => address[]) public newSignupList;
    mapping (uint256 => address[]) public inviterList;
    mapping (uint256 => address[]) public top;

    uint maxChildrenCount = 0;
    uint256 basePoints = 100000;
    uint256 pointRate = 0;
    uint256 maxPointLevel = 10;
    uint256 winnerCount = 10;

    /*
     * MODIFIERS
     */
    /// only master can call the function
    modifier onlyOwner {
        require(master == msg.sender, "only owner can call");
        _;
    }

    /// only master can call the function
    modifier onlyCaller {
        require(caller == msg.sender, "only caller can call");
        _;
    }

    /// function not paused
    modifier notPaused {
        require(paused == false, "function is paused");
        _;
    }

    function setPause(bool value) external onlyOwner {
        paused = value;
    }

    function setWinnerCount(uint256 _count) external onlyOwner {
        winnerCount = _count;
    }

    function isSignedUp(address addr) public view returns (bool) {
        return rootList[addr] == true || referenceParentList[addr] != address(0);
    }

    function signUp(address referrer, address addr, uint256 phase, uint256 ePhase) external onlyCaller notPaused {
        require(isSignedUp(referrer), "invalid referrer");
        require(!isSignedUp(addr), "address has signed up");

        setUpParent(referrer, addr);
        updatePoints(referrer, addr, ePhase);
        newSignupList[phase].push(addr);
    }

    function isRoot(address addr) external view returns (bool) {
        return rootList[addr] == true;
    }

    function newRoot(address addr, uint256 phase) external onlyCaller notPaused {
        require(!isSignedUp(addr), "address has signed up");
        rootList[addr] = true;
        newSignupList[phase].push(addr);
    }

    function getTop(uint256 phase) external view returns(address[] memory) {
      return top[phase];
    }

    /*
    function getTopInviter(uint256 phase, uint256 topN) external onlyCaller returns(address[] memory) {
        if (inviterList[phase].length == 0 || top[phase].length > 0){
            return top[phase];
        }
        uint256 k = topN;
        randomizedSelect(inviterList[phase], 0, inviterList[phase].length - 1, k, phase);

        for (uint256 i = 0; i< k && i < inviterList[phase].length; i++){
            top[phase].push(inviterList[phase][i]);
        }
        return top[phase];
    }
    */

    function getChild(address addr) external view returns(address[] memory) {
        return referenceChildList[addr];
    }

    function getPoints(uint256 phase, address addr) external view returns (uint256) {
        return addressPoints[phase][addr];
    }

    function getParent(address addr) external view returns(address) {
        return referenceParentList[addr];
    }

    function getNewSignup(uint256 phase) external view returns(address[] memory) {
        return newSignupList[phase];
    }

    function newSignupCount(uint256 phase) external view returns (uint) {
        return newSignupList[phase].length;
    }

    function setCaller(address who) external onlyOwner {
        caller = who;
    }

    function setOwner(address who) external onlyOwner {
        master = who;
    }

    constructor(uint _maxChildrenCount, uint _pointRate, uint256 _winnerCount) public {
        master = msg.sender; // master account
        maxChildrenCount = _maxChildrenCount;  // child node max number
        pointRate = _pointRate;  // e.g. 618
        winnerCount = _winnerCount;
    }

    function setUpParent(address pAddress, address addr) internal {
        pAddress = findParent(pAddress);
        referenceParentList[addr] = pAddress;
        referenceChildList[pAddress].push(addr);
    }

    function updateTop(address addr, uint256 phase) internal {
        for (uint256 k = 0; k < top[phase].length; k++){
            if (top[phase][k] == addr) {
                for (uint256 i = k; i > 0; i--){
                    if (addressPoints[phase][top[phase][i]] > addressPoints[phase][top[phase][i-1]]) {
                        (top[phase][i], top[phase][i-1]) = (top[phase][i-1], top[phase][i]);
                    } else {
                        break;
                    }
                }
                return;
            }
        }

        if (top[phase].length < winnerCount){
            top[phase].push(addr);
        } else if (addressPoints[phase][addr] > addressPoints[phase][top[phase][top[phase].length - 1]]){
            top[phase][top[phase].length - 1] = addr;
        }

        for (uint256 i = top[phase].length - 1; i > 0; i--){
            if (addressPoints[phase][top[phase][i]] > addressPoints[phase][top[phase][i-1]]) {
                (top[phase][i], top[phase][i-1]) = (top[phase][i-1], top[phase][i]);
            } else {
              break;
            }
        }
    }

    function updatePoints(address referrer, address addr, uint256 phase) internal {
        uint256 points = basePoints;
        if (addressPoints[phase][referrer] == 0) {
            inviterList[phase].push(referrer);
        }
        addressPoints[phase][referrer] = addressPoints[phase][referrer].add(points);
        points = points.mul(pointRate).div(1000);
        updateTop(referrer, phase);

        address parent = referenceParentList[addr];
        uint256 level = 0;
        while (parent != address(0) && level < maxPointLevel){
            level = level.add(1);
            if (parent == referrer) {
                parent = referenceParentList[parent];
                continue;
            }
            if (addressPoints[phase][parent] == 0) {
                inviterList[phase].push(parent);
            }
            addressPoints[phase][parent] = addressPoints[phase][parent].add(points);
            points = points.mul(pointRate).div(1000);
            updateTop(parent, phase);
            parent = referenceParentList[parent];
        }
    }

    function findParent(address root) internal view returns (address) {
        uint len = 10000;
        address[] memory temp = new address[](len);
        uint startIndex = 0;
        uint currentIndex = 0;
        temp[startIndex] = root;
        while (true){
            address currentAddress = temp[startIndex];
            startIndex++;
            if (startIndex == len){
                startIndex = 0;
            }
            if (referenceChildList[currentAddress].length < maxChildrenCount){
                return currentAddress;
            }else {
                for(uint i = 0; i< referenceChildList[currentAddress].length; i++){
                    currentIndex++;
                    if (currentIndex == len){
                        currentIndex = 0;
                    }
                    temp[currentIndex] = referenceChildList[currentAddress][i];
                }
            }
        }
    }

    /*
    function randomizedSelect(address[] storage addressList, uint left, uint right, uint256 k, uint256 phase) internal{
        if (left == right) {
            return;
        }

        if (left < right) {
            uint mid = partition(addressList, left, right, phase);
            uint i = mid - left + 1;
            if (i == k){
                return;
            }

            if (k < i) {
                return randomizedSelect(addressList, left, mid - 1, k, phase);
            } else {
                return randomizedSelect(addressList, mid + 1, right, k - i, phase);
            }
        }
    }

    function partition(address[] storage addressList, uint left, uint right, uint256 phase) internal returns(uint) {
        address tmp = addressList[left];

        while (left < right) {
            while (left < right && addressPoints[phase][addressList[right]] < addressPoints[phase][tmp]) {
                right--;
            }
            addressList[left] = addressList[right];
            while (left < right && addressPoints[phase][addressList[left]] >= addressPoints[phase][tmp]) {
                left++;
            }
            addressList[right] = addressList[left];
        }
        addressList[left] = tmp;
        return left;
    }
    */

    function distributeBonus(uint256 len) external pure returns(uint256[] memory) {
        uint256[] memory factors = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            if (i < len.div(2)) {
              factors[i] = len.add(len.div(2).sub(i));
            } else {
              if (len % 2 == 0 ) {
                factors[i] = len.add(len.div(2)).sub(1).sub(i);
              } else {
                factors[i] = len.add(len.div(2)).sub(i);
              }
            }
        }
        return factors;
    }

    function getAncestors(address addr) external view returns(address[] memory) {
        address[] memory ancestors = new address[](maxPointLevel);
        address parent = referenceParentList[addr];

        for (uint256 i = 0; parent != address(0) && i < maxPointLevel; i++) {
            ancestors[i] = parent;
            parent = referenceParentList[parent];
        }
        return ancestors;
    }
}

