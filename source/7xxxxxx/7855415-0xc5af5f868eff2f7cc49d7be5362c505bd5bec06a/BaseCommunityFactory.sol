pragma solidity >=0.5.3 < 0.6.0;

/// @author Ryan @ Protea 
/// @title Community Factory interface for later expansion 
contract BaseCommunityFactory {
    struct Community {
        string name;
        address creator;
        address tokenManagerAddress;
        address membershipManagerAddress;
        address[] utilities; 
    }

    mapping(uint256 => Community) internal communities_;
    uint256 internal numberOfCommunities_ = 0;

    uint256 internal publishedBlocknumber_;
    address internal daiAddress_;
    address internal proteaAccount_;
    address internal admin_;
    address internal tokenManagerFactory_;
    address internal membershipManagerFactory_;

    event FactoryRegistered(address oldFactory, address newFactory);

    event CommunityCreated(
        address indexed publisher,
        uint256 index, 
        address indexed tokenManager, 
        address indexed membershipManager, 
        address[] utilities
    );

    /// Constructor of V1 factory
    /// @param _daiTokenAddress         Address of the DAI token account
    /// @param _proteaAccount           Address of the Protea DAI account
    /// @notice                         Also sets a super admin for changing factories at a later stage, unused at present
    /// @author Ryan                
    constructor (address _daiTokenAddress, address _proteaAccount) public {
        admin_ = msg.sender;
        daiAddress_ = _daiTokenAddress;
        proteaAccount_ = _proteaAccount;
        publishedBlocknumber_ = block.number;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin_, "Not authorised");
        _;
    }

    /// Allows the creation of a community
    /// @param _communityName           :string Name of the community
    /// @param _communitySymbol         :string Symbol of the community token
    /// @param _communityManager        :address The address of the super admin
    /// @param _gradientDemoninator     :uint256 The gradient modifier in the curve, not required in V1
    /// @param _contributionRate        :uint256 Percentage of incoming DAI to be diverted to the community account, from 0 to 100
    /// @return uint256                 Index of the deployed ecosystem
    /// @dev                            Also sets a super admin for changing factories at a later stage, unused at present
    /// @author Ryan
    function createCommunity(
        string calldata _communityName,
        string calldata _communitySymbol,
        address _communityManager,
        uint256 _gradientDemoninator,
        uint256 _contributionRate
    )
        external
        returns(uint256);

    /// @dev                            By passing through a list, this allows greater flexibility of the interface for different factories
    /// @param _factories               :address[]  List of factories
    /// @notice                         Introspection or interface confirmation should be used at later stages
    function initialize(address[] calldata _factories) external;

    function setTokenManagerFactory(address _newFactory) external;

    function setMembershipManagerFactory(address _newFactory) external;

    /// Fetching community data
    /// @param _index                   :uint256 Index of the community
    /// @dev                            Fetches all data and contract addresses of deployed communities by index
    /// @return Community               Returns a Community struct matching the provided index
    /// @author Ryan
    function getCommunity(uint256 _index)
        external
        view
        returns(
            string memory,
            address,
            address,
            address,
            address[] memory
        );

    function getFactories() external view returns (address[] memory);

    function publishedBlocknumber() external view returns(uint256) {
        return publishedBlocknumber_;
    }
}
