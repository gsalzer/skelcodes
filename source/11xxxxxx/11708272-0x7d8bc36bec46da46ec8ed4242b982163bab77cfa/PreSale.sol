// SPDX-License-Identifier: UNLICENSED
pragma solidity <=0.7.5;
import "./Usdt.sol";

interface ERC {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}



contract Presale{

    TetherToken public Tether;
    ERC public Token;
    
    AggregatorV3Interface internal ref;

    int8 public salePhase = 1;

    address public admin;

    struct History{
        uint256[] timeStamp;
        int8[] paymentMethod;
        uint256[] amount;
    }

    modifier isAdmin(){
        require(msg.sender == admin,"Access Error");
        _;
    }

    mapping(address => History) history;

    /**
        mapping phases of sale with price, total sold
        and sale caps.
     */

    mapping(int8 => uint256) public tokenPrice;      // 6 precision - 1 USD = 1000000
    mapping(int8 => uint256) public sold;
    mapping(int8 => uint256) public saleCap;

    function Presale(address _tetherContract, address _tokenContract) public {
        Tether = TetherToken(_tetherContract);
        Token = ERC(_tokenContract);
        ref = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        admin = msg.sender;
    }

    function PurchaseWithEther() public payable returns(bool){
        uint256 _amountToken = resolverEther(msg.value);
        History storage h = history[msg.sender];
                        h.timeStamp.push(block.timestamp);
                        h.paymentMethod.push(2);
                        h.amount.push(_amountToken);
        Token.transfer(msg.sender,_amountToken);
        admin.transfer(msg.value);
        return true;
    }
    
    /*
        @dev returns the amount of purchased Tokens
        for equivalent ethers
    */
    
    function resolverEther(uint256 _amountEther) public view returns(uint256){
        uint256 ethPrice = uint256(fetchEthPrice());
                ethPrice = SafeMath.mul(_amountEther,ethPrice); // 18 * 8
                ethPrice = SafeMath.div(ethPrice,10**2);        // 26 / 2
        uint256 _tokenAmount = SafeMath.div(ethPrice,tokenPrice[salePhase]); // 24 / 6
        return _tokenAmount;
    }

    function PurchaseWithTether(
        uint256 _amountTether
        ) 
        public returns(bool){
        require(
                Tether.allowance(msg.sender,address(this)) >= _amountTether,
                "Allowance Exceeded"
                );
        uint256 _amountToken = resolverTether(_amountTether);
        History storage h = history[msg.sender];
                        h.timeStamp.push(block.timestamp);
                        h.paymentMethod.push(1);
                        h.amount.push(_amountToken);
        Tether.transferFrom(msg.sender,admin,_amountTether);
        Token.transfer(msg.sender,_amountToken);
        return true;
    }

    /**
        @dev returns the amount of purchased tokens.
     */
    
    function resolverTether(uint256 _amountTether) private view returns(uint256){
        uint256 _tempAmount = SafeMath.mul(_amountTether,10**18);
        uint256 _tokenAmount = SafeMath.div(_tempAmount,tokenPrice[salePhase]);
        return _tokenAmount;
    }

    /**
       @dev returns the purchase history of a user.
       Pass the user address to the function arguments.
     */

    function fetchPurchaseHistory(address _user) public view returns(
        uint256[] memory timeStamp,
        int8[] memory paymentMethod,
        uint256[] memory amount
    ){
        History storage h = history[_user];
        return (
            h.timeStamp,
            h.paymentMethod,
            h.amount
        );
    }

    function fetchEthPrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = ref.latestRoundData();
        return price;
    }

    function setPrice(int8 _phase,uint256 _price) public isAdmin returns(bool){
        tokenPrice[_phase] = _price;
        return true;
    }

    function setSaleCap(int8 _phase,uint256 _cap) public isAdmin returns(bool){
        saleCap[_phase] = _cap;
        return true;
    }

    function updateSalePhase(int8 _phase) public isAdmin returns(bool){
        salePhase = _phase;
        return true;
    }
    
    function getCurrentSalePrice() public view returns(uint256){
        return tokenPrice[salePhase];
    }
    
    function getAllowance() public view returns(uint256){
        return Tether.allowance(msg.sender,address(this));
    }

    function updateAdmin(address _user) public isAdmin returns(bool){
        admin = _user;
        return true;
    }

    function updateRef(address _newRef) public isAdmin returns(bool){
        ref = AggregatorV3Interface(_newRef);
        return true;
    }

}

