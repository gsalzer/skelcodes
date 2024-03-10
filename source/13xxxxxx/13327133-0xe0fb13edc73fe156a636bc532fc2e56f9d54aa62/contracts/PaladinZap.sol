//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     
pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT


import "./interfaces/IERC20.sol";
import "./interfaces/IPaladinController.sol";
import "./interfaces/IPalPool.sol";
import "./interfaces/IPalLoanToken.sol";
import "./interfaces/IStakedAave.sol";

import "./utils/Ownable.sol";
import "./utils/Pausable.sol";
import "./utils/SafeERC20.sol";

/** @title PaladinZap contract  */
/// @author Paladin
contract PalZap is Ownable, Pausable {
    using SafeERC20 for IERC20;

    //Storage
    mapping(address => bool) private allowedSwapTargets;

    IPaladinController public controller;
    IPalLoanToken public loanToken;

    address private aaveAddress;
    address private stkAaveAddress;

    //Events
    event ZapDeposit(address sender, address palPool, uint256 palTokenAmount);
    event ZapBorrow(address sender, address palPool, uint256 palLoanTokenId);
    event ZapExpandBorrow(address sender, address palPool, address palLoan, uint256 palLoanTokenId);


    //Constructor
    constructor(
        address _controller,
        address _loanToken,
        address _swapTarget,
        address _aaveAddress,
        address _stkAaveAddress
    ) {
        controller = IPaladinController(_controller);
        loanToken = IPalLoanToken(_loanToken);

        allowedSwapTargets[_swapTarget] = true;

        aaveAddress = _aaveAddress;
        stkAaveAddress = _stkAaveAddress;
    }


    //Functions
    function zapDeposit(
        address _fromTokenAddress,
        address _toTokenAddress,
        address _poolAddress,
        uint256 _amount,
        address _swapTarget,
        address _allowanceTarget,
        bytes memory _swapData
    ) external payable whenNotPaused returns(uint){
        //Check valid PalPool Address
        require(controller.isPalPool(_poolAddress), "Paladin Zap : Incorrect PalPool");
        IPalPool _pool = IPalPool(_poolAddress);

        //Check input values
        require(
            _toTokenAddress!= address(0) && _poolAddress!= address(0) && _swapTarget!= address(0),
            "Paladin Zap : Zero Address"
        );
        require(_amount > 0 || msg.value > 0 , "Paladin Zap : Zero amount");
        require(_toTokenAddress == _pool.underlying(), "Paladin Zap : Incorrect toToken");

        //Pull the fromToken to the Zap
        uint _pulledAmount = _pullTokens(_fromTokenAddress, _amount);

        //Check the swapTarget is allowed in the Zap
        require(allowedSwapTargets[_swapTarget], "Paladin Zap : SwapTarget not allowed");

        //Make the swap and receive the fromToken
        uint _receivedAmount = _makeSwap(_fromTokenAddress, _toTokenAddress, _pulledAmount, _swapTarget, _allowanceTarget, _swapData);

        //Deposit the fromToken to the PalPool and receive palTokens
        uint _palTokenAmount = _depositInPool(_toTokenAddress, _poolAddress, _receivedAmount);

        //Send the palTokens to the user
        address _palTokenAddress = _pool.palToken();
        IERC20(_palTokenAddress).safeTransfer(msg.sender, _palTokenAmount);

        //emit Event
        emit ZapDeposit(msg.sender, _poolAddress, _palTokenAmount);

        return _palTokenAmount;
    }

    function zapBorrow(
        address _fromTokenAddress,
        address _toTokenAddress,
        address _poolAddress,
        address _delegatee,
        uint256 _borrowAmount,
        uint256 _feesAmount,
        address _swapTarget,
        address _allowanceTarget,
        bytes memory _swapData
    ) external payable whenNotPaused returns(uint){
        //Check valid PalPool Address
        require(controller.isPalPool(_poolAddress), "Paladin Zap : Incorrect PalPool");
        IPalPool _pool = IPalPool(_poolAddress);

        //Check input values
        require(
            _toTokenAddress!= address(0) && _poolAddress!= address(0) && _delegatee!= address(0) && _swapTarget!= address(0),
            "Paladin Zap : Zero Address"
        );
        require(_borrowAmount > 0 && (_feesAmount > 0 || msg.value > 0), "Paladin Zap : Zero amount");
        require(_toTokenAddress == _pool.underlying(), "Paladin Zap : Incorrect toToken");

        //Pull the fromToken to the Zap
        uint _pulledAmount = _pullTokens(_fromTokenAddress, _feesAmount);

        //Check the swapTarget is allowed in the Zap
        require(allowedSwapTargets[_swapTarget], "Paladin Zap : SwapTarget not allowed");

        //Make the swap and receive the fromToken
        uint _receivedAmount = _makeSwap(_fromTokenAddress, _toTokenAddress, _pulledAmount, _swapTarget, _allowanceTarget, _swapData);

        uint _minBorrowAmount = _pool.minBorrowFees(_borrowAmount);
        require(_receivedAmount >= _minBorrowAmount, "Paladin Zap : Fee amount too low");

        //Make the Borrow to the PalPool, and get the new PalLoanToken Id
        uint _newTokenId = _borrowFromPool(_toTokenAddress, _poolAddress, _delegatee, _borrowAmount, _receivedAmount);

        //Check the Zap received the PalLoanToken
        require(
            loanToken.ownerOf(_newTokenId) == address(this),
            "Paladin Zap : PalPool Borrow failed"
        );

        //Send the PalLoanToken to the user
        loanToken.safeTransferFrom(address(this), msg.sender, _newTokenId);

        //emit Event
        emit ZapBorrow(msg.sender, _poolAddress, _newTokenId);

        return _newTokenId;
    }


    function zapExpandBorrow(
        address _fromTokenAddress,
        address _toTokenAddress,
        address _loanAddress,
        address _poolAddress,
        uint256 _amount,
        address _swapTarget,
        address _allowanceTarget,
        bytes memory _swapData
    ) external payable whenNotPaused returns(bool){
        //Check valid PalPool Address
        require(controller.isPalPool(_poolAddress), "Paladin Zap : Incorrect PalPool");
        IPalPool _pool = IPalPool(_poolAddress);

        //Check input values
        require(
            _toTokenAddress!= address(0) && _poolAddress!= address(0) && _loanAddress!= address(0) && _swapTarget!= address(0),
            "Paladin Zap : Zero Address"
        );
        require(_amount > 0 || msg.value > 0 , "Paladin Zap : Zero amount");
        require(_toTokenAddress == _pool.underlying(), "Paladin Zap : Incorrect toToken");

        //Check PalLoan ownership
        require(_pool.isLoanOwner(_loanAddress, msg.sender), "Paladin Zap : Not PalLoan owner");

        uint _tokenId = _pool.idOfLoan(_loanAddress);

        //Check PalLoan is linked to the given PalPool
        require(loanToken.poolOf(_tokenId) == _poolAddress, "Paladin Zap : Incorrect PalPool");

        //Check allowance to transfer the PalLoanToken
        require(loanToken.isApprovedForAll(msg.sender, address(this)), "Paladin Zap : Not approved for PalLoanToken");

        //Transfer PalLoanToken to Zap
        loanToken.safeTransferFrom(msg.sender, address(this), _tokenId);

        //Pull the fromToken to the Zap
        uint _pulledAmount = _pullTokens(_fromTokenAddress, _amount);

        //Check the swapTarget is allowed in the Zap
        require(allowedSwapTargets[_swapTarget], "Paladin Zap : SwapTarget not allowed");

        //Make the swap and receive the fromToken
        uint _receivedAmount = _makeSwap(_fromTokenAddress, _toTokenAddress, _pulledAmount, _swapTarget, _allowanceTarget, _swapData);

        //Pay fees of the PalLoan
        _increaseFees(_toTokenAddress, _loanAddress, _poolAddress, _receivedAmount);

        //Return the PalLoanToken to the user
        loanToken.safeTransferFrom(address(this), msg.sender, _tokenId);

        //emit Event
        emit ZapExpandBorrow(msg.sender, _poolAddress, _loanAddress, _tokenId);

        return true;
    }





    //Internal Functions
    function _pullTokens(
        address _fromTokenAddress,
        uint256 _amount
    ) internal returns(uint256 _receivedAmount) {
        if(_fromTokenAddress == address(0)){
            require(msg.value > 0 , "Paladin Zap : No ETH received");

            return msg.value;
        }
        
        require(_amount > 0 , "Paladin Zap : Token amount null");
        require(msg.value == 0, "Paladin Zap : Multiple tokens sent");

        IERC20 _fromToken = IERC20(_fromTokenAddress);

        require(_fromToken.allowance(msg.sender, address(this)) >= _amount, "Paladin Zap : Allowance too low");

        _fromToken.safeTransferFrom(msg.sender, address(this), _amount);

        return _amount;
    }


    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        if (_returnData.length < 68) return 'Transaction reverted silently';
    
        assembly {
            _returnData := add(_returnData, 0x04)
        }

        return abi.decode(_returnData, (string));
    }

    function _makeSwap(
        address _fromTokenAddress,
        address _toTokenAddress,
        uint256 _amount,
        address _swapTarget,
        address _allowanceTarget,
        bytes memory _swapData
    ) internal returns(uint256 _returnAmount) {
        //same token
        if(_fromTokenAddress == _toTokenAddress){
            return _amount;
        }

        //AAVE -> stkAAVE : just need to stake in the Safety Module
        if(_fromTokenAddress == aaveAddress && _toTokenAddress == stkAaveAddress){
            return _stakeInAave(_amount);
        }

        //If output token is stkAAVE -> swap to AAVE then stake in the Safety Module 
        address _outputTokenAddress = _toTokenAddress;
        if(_toTokenAddress == stkAaveAddress){
            _outputTokenAddress = aaveAddress;
        }

        uint256 _valueSwap;
        if (_fromTokenAddress == address(0)) {
            _valueSwap = _amount;
        } else {
            IERC20(_fromTokenAddress).safeIncreaseAllowance(_allowanceTarget, _amount);
        }

        IERC20 _outputToken = IERC20(_outputTokenAddress);
        uint256 _intitialBalance = _outputToken.balanceOf(address(this));

        //Make the swap
        (bool _success, bytes memory _res) = _swapTarget.call{ value: _valueSwap }(_swapData);
        require(_success, _getRevertMsg(_res));

        _returnAmount = _outputToken.balanceOf(address(this)) - _intitialBalance;

        //If the swap return AAVE, stake them to get stkAAVE
        if(_toTokenAddress == stkAaveAddress){
            _returnAmount = _stakeInAave(_amount);
        }

        require(_returnAmount > 0, "Paladin Zap : Swap output null");
    }


    function _stakeInAave(
        uint256 _amount
    ) internal returns(uint256 _stakedAmount) {
        IStakedAave _stkAave = IStakedAave(stkAaveAddress);

        uint256 _initialBalance = _stkAave.balanceOf(address(this));

        IERC20(aaveAddress).safeApprove(stkAaveAddress, _amount);
        _stkAave.stake(address(this), _amount);

        uint256 _newBalance = _stkAave.balanceOf(address(this));
        _stakedAmount = _newBalance - _initialBalance;

        require(_stakedAmount == _amount, "Paladin Zap : Error staking in Aave");

    }


    function _depositInPool(
        address _tokenAddress,
        address _poolAddress,
        uint256 _amount
    ) internal returns(uint256 _palTokenAmount) {
        IPalPool _pool = IPalPool(_poolAddress);
        IERC20 _palToken = IERC20(_pool.palToken());

        uint256 _initialBalance = _palToken.balanceOf(address(this));

        IERC20(_tokenAddress).safeApprove(_poolAddress, _amount);

        _palTokenAmount = _pool.deposit(_amount);

        uint256 _newBalance = _palToken.balanceOf(address(this));

        require(_newBalance - _initialBalance == _palTokenAmount, "Paladin Zap : Error depositing in PalPool");
        
    }


    function _borrowFromPool(
        address _tokenAddress,
        address _poolAddress,
        address _delegatee,
        uint256 _borrowAmount,
        uint256 _feesAmount
    ) internal returns(uint256 _tokenId) {
        IERC20(_tokenAddress).safeApprove(_poolAddress, _feesAmount);

        _tokenId = IPalPool(_poolAddress).borrow(_delegatee, _borrowAmount, _feesAmount);
    }


    function _increaseFees(
        address _tokenAddress,
        address _loanAddress,
        address _poolAddress,
        uint256 _feesAmount
    ) internal returns(bool) {
        IERC20(_tokenAddress).safeApprove(_poolAddress, _feesAmount);

        uint _paidFees = IPalPool(_poolAddress).expandBorrow(_loanAddress, _feesAmount);

        require(_feesAmount == _paidFees ,"Paladin Zap : Error expanding Borrow");

        return true;
    }


    //Admin Functions

    // In case tokens are stuck in the contract
    function sendToken(address _tokenAddress, address payable _recipient) external onlyOwner {
        if(_tokenAddress == address(0)){
            Address.sendValue(_recipient, address(this).balance);
        }
        else{
            IERC20(_tokenAddress).safeTransfer(_recipient, IERC20(_tokenAddress).balanceOf(address(this)));
        }
    }

    /**
    * @notice Set a new Controller
    * @dev Loads the new Controller for the Pool
    * @param  _newController address of the new Controller
    */
    function setNewController(address _newController) external onlyOwner {
        controller = IPaladinController(_newController);
    }

    function setNewPalLoanToken(address _newPalLoanToken) external onlyOwner {
        loanToken = IPalLoanToken(_newPalLoanToken);
    }


    function addSwapTarget(address _swapTarget) external onlyOwner {
        allowedSwapTargets[_swapTarget] = true;
    }



    receive() external payable {
        require(msg.sender != tx.origin, "Paladin Zap : Do not send ETH directly");
    }

}
