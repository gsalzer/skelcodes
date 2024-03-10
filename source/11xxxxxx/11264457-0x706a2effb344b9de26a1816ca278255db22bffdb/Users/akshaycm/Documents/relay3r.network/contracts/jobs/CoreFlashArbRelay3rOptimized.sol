import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '../interfaces/Keep3r/IKeep3rV1Mini.sol';
import '../interfaces/ICoreFlashArb.sol';

contract CoreFlashArbRelay3rOptimizedV2 is Ownable{

    modifier upkeep() {
        require(RL3R.isKeeper(msg.sender), "::isKeeper: keeper is not registered");
        _;
        RL3R.worked(msg.sender);
    }

    IKeep3rV1Mini public RL3R;
    ICoreFlashArb public CoreArb;
    IERC20 public CoreToken;
    //Init interfaces with addresses
    constructor (address token,address corearb,address coretoken) public {
        RL3R = IKeep3rV1Mini(token);
        CoreArb = ICoreFlashArb(corearb);
        CoreToken = IERC20(coretoken);
    }

    //Set new contract address incase core devs change the flash arb contract
    function setCoreArbAddress(address newContract) public onlyOwner {
        CoreArb = ICoreFlashArb(newContract);
    }

    function workable() public view returns (bool){
        for(uint i=0;i<CoreArb.numberOfStrategies();i++){
            if(CoreArb.strategyProfitInReturnToken(i) > 0)
                return true;
        }
    }
    function profitableCount() public view returns (uint){
        uint count = 0;
        for(uint i=0;i<CoreArb.numberOfStrategies();i++){
            if(CoreArb.strategyProfitInReturnToken(i) > 0)
                count++;
        }
        return count;
    }

    function profitableStrats () public view returns (uint[] memory){
        uint[] memory _profitable = new uint[](profitableCount());
        uint index = 0;
        for(uint i=0;i<CoreArb.numberOfStrategies();i++){
            if(CoreArb.strategyProfitInReturnToken(i) > 0){
                _profitable[index] = i;
                index++;
            }

        }
        return _profitable;
    }

    function workBatch(uint[] memory profitable) public upkeep{
        for(uint i=0;i<profitable.length;i++){
            CoreArb.executeStrategy(profitable[i]);
        }
        //At the end send the core gotten to the relay3r executing the work func
        CoreToken.transfer(msg.sender,CoreToken.balanceOf(address(this)));
    }
}
