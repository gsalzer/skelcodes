pragma solidity ^0.5.0;



contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract EcosystemVesting is Ownable {
    using SafeMath for uint256;

    mapping (address => Holding) public holdings;

    uint256 constant public Interval = 90 days;
    uint256 constant public MaximumHoldingPeriod = 630 days;

    uint256 constant public EcosystemCap = 54100000 ether; // 54.1 million tokens

    uint256 public totalEcosystemTokensCommitted;

    struct Holding {
        uint256 tokensCommitted;
        uint256 tokensRemaining;
        uint256 startTime;
    }

    event EcosystemVestingInitialized(address _to, uint256 _tokens, uint256 _startTime);
    event EcosystemVestingUpdated(address _to, uint256 _totalTokens, uint256 _startTime);

    function claimTokens(address beneficiary)
        external
        onlyOwner
        returns (uint256 tokensToClaim)
    {
        uint256 tokensRemaining = holdings[beneficiary].tokensRemaining;
        uint256 startTime = holdings[beneficiary].startTime;
        require(tokensRemaining > 0, "All tokens claimed");

        if (now.sub(startTime) >= MaximumHoldingPeriod) {

            tokensToClaim = tokensRemaining;
            delete holdings[beneficiary];

        } else {

            uint256 permill = calculatePermillToRelease(startTime);

            uint256 tokensNotToClaim = (holdings[beneficiary].tokensCommitted.mul(1000 - permill)).div(1000);
            tokensToClaim = tokensRemaining.sub(tokensNotToClaim);
            tokensRemaining = tokensNotToClaim;
            holdings[beneficiary].tokensRemaining = tokensRemaining;

        }
    }

    function calculatePermillToRelease(uint256 _startTime) internal view returns (uint256 permill) {
        // how many 90 day periods have passed
        uint periodsPassed = ((now.sub(_startTime)).div(Interval)).add(1);
        permill = periodsPassed.mul(125); // 125 per thousand to be released every 90 days
    }

    function initializeVesting(
        address _beneficiary,
        uint256 _tokens,
        uint256 _startTime
    )
        external
        onlyOwner
    {
        totalEcosystemTokensCommitted = totalEcosystemTokensCommitted.add(_tokens);
        require(totalEcosystemTokensCommitted <= EcosystemCap);

        if (holdings[_beneficiary].tokensCommitted != 0) {
            holdings[_beneficiary].tokensCommitted = holdings[_beneficiary].tokensCommitted.add(_tokens);
            holdings[_beneficiary].tokensRemaining = holdings[_beneficiary].tokensRemaining.add(_tokens);

            emit EcosystemVestingUpdated(
                _beneficiary,
                holdings[_beneficiary].tokensRemaining,
                holdings[_beneficiary].startTime
            );

        } else {
            holdings[_beneficiary] = Holding(
                _tokens,
                _tokens,
                _startTime
            );

            emit EcosystemVestingInitialized(_beneficiary, _tokens, _startTime);
        }
    }
}
