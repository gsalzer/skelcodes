// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IFeeApprover {

    function check(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function setFeePercentX100(uint _feePercentX100) external;
    function feePercentX100() external view returns (uint);

    function setTokenUniswapPair(address _tokenUniswapPair) external;
   
    function setCoreTokenAddress(address _coreTokenAddress) external;
    function updateTxState() external;
    function calculateAmountsAfterFee(        
        address sender, 
        address recipient, 
        uint256 amount
    ) external  returns (uint256 transferToAmount, uint256 transferToFeeBearerAmount);

    function setTransfersPaused() external;
 

}
