pragma solidity 0.5.10;

import './tokenModel.sol';



interface IFactory {
   function createCampaign(uint[] calldata _data,address _token,uint _pool_rate,uint _lock_duration,uint _uniswap_rate) external returns (address campaign_address);
}


contract tokenDeployer {
     address public campaignFactory;
     address[] public Tokens;
     address public owner;

    
    constructor(address _campaignFactory) public
    {
        
        campaignFactory = _campaignFactory;
        owner = msg.sender;
    }
    function createTokenWithCampaign(string memory _name, string memory _symbol, uint8 _decimals,uint _totalSupply,uint[] memory _data,uint _pool_rate,uint _lock_duration,uint _uniswap_rate) public returns(address token_address){
     bytes memory bytecode = type(ERC20).creationCode;
     bytes32 salt = keccak256(abi.encodePacked(_name, msg.sender));
     assembly {
            token_address := create2(0, add(bytecode, 32), mload(bytecode), salt)
     }
     ERC20(token_address).initialize(_name,_symbol,_decimals,_totalSupply);
     IERC20(token_address).approve(campaignFactory,IERC20(token_address).balanceOf(address(this)));
     IFactory(campaignFactory).createCampaign(_data,token_address,_pool_rate,_lock_duration,_uniswap_rate);
     IERC20(token_address).transfer(msg.sender,IERC20(token_address).balanceOf(address(this)));
     Tokens.push(token_address);
     return token_address;
        
    }
    function changeCampaign(address _newCampaignFactory) public returns(uint){
        require(msg.sender == owner,'You are not allowed');
        campaignFactory = _newCampaignFactory;
        return 1;
    }


}


