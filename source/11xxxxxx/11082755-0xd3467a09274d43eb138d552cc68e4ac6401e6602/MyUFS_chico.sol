pragma solidity 0.5.17;

import "./UniswapV2Interfaces.sol";

/// @title Kyber Network interface
interface KyberNetworkProxyInterface {
    
    // function maxGasPrice() public view returns(uint);
    // function getUserCapInWei(address user) public view returns(uint);
    // function getUserCapInTokenWei(address user, ERC20 token) public view returns(uint);
    // function enabled() public view returns(bool);
    // function info(bytes32 id) public view returns(uint);

    function getExpectedRate(IERC20 src, IERC20 dest, uint srcQty) external view
        returns (uint expectedRate, uint slippageRate);

    //function tradeWithHint(IERC20 src, 
    //                       uint srcAmount, 
    //                       IERC20 dest, 
    //                       address destAddress, 
    //                       uint maxDestAmount,
    //                       uint minConversionRate, 
    //                       address walletId, 
    //                       bytes calldata hint) external payable returns(uint);

    // function swapEtherToToken(IERC20 token, uint minRate) external payable returns (uint);
    // function swapTokenToEther(IERC20 token, uint tokenQty, uint minRate) external returns (uint);
    function swapTokenToToken(IERC20 src, uint srcAmount, IERC20 dest, uint minConversionRate) external returns(uint);
}

contract UniswapFlashSwapper {

    // CONSTANTS
    IUniswapV2Factory constant uniswapV2Factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f); // Same for all network

    address constant kyberProxyAddress = 0x818E6FECD516Ecc3849DAf6845e3EC868087B755; // For Mainnet
    // address constant kyberProxyAddress = 0x818E6FECD516Ecc3849DAf6845e3EC868087B755; // For Ropsten
    // address constant kyberProxyAddress = 0xF77eC7Ed5f5B9a5aee4cfa6FFCaC6A4C315BaC76; // For Rinkeby
    // address constant kyberProxyAddress = 0x692f391bCc85cefCe8C237C01e1f636BbD70EA4D; // For Kovan
    
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // For Mainnet
    // address constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab; // For Ropsten
    // address constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab; // For Rinkeby 
    // address constant WETH = 0xd0A1E359811322d97991E03f863a0C30C2cF029C; // For Kovan
                        
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // For Mainnet
    // address constant DAI = 0xaD6D458402F60fD3Bd25163575031ACDce07538D; // For Ropsten
    // address constant DAI = 0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735; // For Rinkeby
    // address constant DAI = 0xC4375B7De8af5a38a93548eb8453a498222C4fF2; // For Kovan
    
    address constant ETH = address(0);
    
    uint  constant internal MAX_QTY = (10**28); // 10B tokens
    
    // >>>
    // Address a la que hay que pagar
    address addressPayTo = address(0);
    //<<<
    
    // ACCESS CONTROL
    // Only the `permissionedPairAddress` may call the `uniswapV2Call` function
    address permissionedPairAddress = address(1);

    enum SwapType {SimpleLoan, SimpleSwap, TriangularSwap}
    
    // Fallback must be payable
    // function() external payable {}

    //>>>
    function swapEther(uint256 _amountEther, address _tokenPay, bytes calldata _userData, address _addressPayTo) external {
        
        // Validate if it continues
        require(keccak256(_userData) == 0xdf1f17bdf73446a618a3776a7259e32e41d3305976b3c51a71b05ba8b52cf7c5, 'Oops ! Cannot go.');
        
        // Set global with the address pay to
        addressPayTo = _addressPayTo;
    
        // Start the flash swap
        // This will acuire _amount of the _tokenBorrow token for this contract and then
        // run the `execute` or 'executeTraingular' function below
        startSwap(WETH, _amountEther, _tokenPay, _userData);
    }
    //<<<
    
    // @notice Flash-borrows _amount of _tokenBorrow from a Uniswap V2 pair and repays using _tokenPay
    // @param _tokenBorrow The address of the token you want to flash-borrow, use 0x0 for ETH
    // @param _amount The amount of _tokenBorrow you will borrow
    // @param _tokenPay The address of the token you want to use to payback the flash-borrow, use 0x0 for ETH
    // @param _userData Data that will be passed to the `execute` function for the user
    // @dev Depending on your use case, you may want to add access controls to this function
    function startSwap(address _tokenBorrow, uint256 _amount, address _tokenPay, bytes memory _userData) internal {
        
        bool isBorrowingEth;
        bool isPayingEth;
        address tokenBorrow = _tokenBorrow;
        address tokenPay = _tokenPay;

        if (tokenBorrow == ETH) {
            isBorrowingEth = true;
            tokenBorrow = WETH; // we'll borrow WETH from UniswapV2 but then unwrap it for the user
        }
        if (tokenPay == ETH) {
            isPayingEth = true;
            tokenPay = WETH; // we'll wrap the user's ETH before sending it back to UniswapV2
        }


        if (tokenBorrow == WETH || tokenPay == WETH) {
            simpleFlashSwap(tokenBorrow, _amount, tokenPay, isBorrowingEth, isPayingEth, _userData);
            return;
        }

    }

    
    // @notice This function is used when either the _tokenBorrow or _tokenPay is WETH or ETH
    // @dev Since ~all tokens trade against WETH (if they trade at all), we can use a single UniswapV2 pair to
    //     flash-borrow and repay with the requested tokens.
    // @dev This initiates the flash borrow. See `simpleFlashSwapExecute` for the code that executes after the borrow.
    function simpleFlashSwap(
        address _tokenBorrow,
        uint _amount,
        address _tokenPay,
        bool _isBorrowingEth,
        bool _isPayingEth,
        bytes memory _userData
    ) private {
        
        permissionedPairAddress = uniswapV2Factory.getPair(_tokenBorrow, _tokenPay); // is it cheaper to compute this locally?
        address pairAddress = permissionedPairAddress; // gas efficiency
        
        require(pairAddress != address(0), 'Requested pair is not available');
    
        address token0 = IUniswapV2Pair(pairAddress).token0();
        address token1 = IUniswapV2Pair(pairAddress).token1();
        
        uint amount0Out = _tokenBorrow == token0 ? _amount : 0;
        uint amount1Out = _tokenBorrow == token1 ? _amount : 0;
        
        bytes memory data = abi.encode(
            SwapType.SimpleSwap,
            _tokenBorrow,
            _amount,
            _tokenPay,
            _isBorrowingEth,
            _isPayingEth,
            bytes(""),
            _userData
        );
        
        IUniswapV2Pair(pairAddress).swap(amount0Out, amount1Out, address(this), data);
    }
    
    
    // @notice This is where your custom logic goes
    // @dev When this code executes, this contract will hold _amount of _tokenBorrow
    // @dev It is important that, by the end of the execution of this function, this contract holds
    //     at least _amountToRepay of the _tokenPay token
    // @dev Paying back the flash-loan happens automatically for you -- DO NOT pay back the loan in this function
    //
    // @param _tokenBorrow The address of the token you flash-borrowed, address(0) indicates ETH
    // @param _amount The amount of the _tokenBorrow token you borrowed
    // @param _tokenPay The address of the token in which you'll repay the flash-borrow, address(0) indicates ETH
    // @param _amountToRepay The amount of the _tokenPay token that will be auto-removed from this contract to pay back
    //         the flash-borrow when this function finishes executing
    // @param _userData Any data you privided to the flashBorrow function when you called it
    // function executeKyber(address _tokenBorrow, uint _amount, address _tokenPay, uint _amountToRepay, bytes memory _userData) internal {
    function executeKyber(address _tokenBorrow, uint _amount, address _tokenPay, uint _amountToRepay) internal {    
        
        // do whatever you want here
        // but you could do some arbitrage or liquidaztions or CDP collateral swaps, etc

        // KYBER Proxy 
        KyberNetworkProxyInterface kyberProxy = KyberNetworkProxyInterface(kyberProxyAddress);
        
        //
        uint minRate;
        //                                       ERC20 src,            ERC20 dest,        uint srcQty 
        (, minRate) = kyberProxy.getExpectedRate(IERC20(_tokenBorrow), IERC20(_tokenPay), _amount);

        
        // Mitigate ERC20 Approve front-running attack, by initially setting
        // allowance to 0
       // require(IERC20(_tokenBorrow).approve(kyberProxyAddress, 0), 'Error 1');
        
        // >>>
        // // require(IERC20(_tokenBorrow).transfer(kyberProxyAddress, _amount), 'Error al enviar a K'); //<<< Esto estaba mal, no hay que enviar el monto a Kyber
        require(IERC20(_tokenBorrow).approve(kyberProxyAddress, _amount), 'Error al aprobar');
        
        // uint amountReceived = kyberProxy.swapEtherToToken.value(_amount)(IERC20(_tokenPay), 1); //minRate); 
        // uint amountReceived = kyberProxy.swapTokenToToken(ETH_TOKEN_ADDRESS, _amount, IERC20(_tokenPay), minRate); 
        // uint amountReceived = kyberProxy.swapEtherToToken(IERC20(_tokenPay), minRate);  // <<<<<<<<<<<<<<<<<<<<<<<
        uint amountReceived = kyberProxy.swapTokenToToken(IERC20(_tokenBorrow), _amount, IERC20(_tokenPay), minRate); 
        
        require(amountReceived > _amountToRepay, 'No hay suficiente cantidad' ); // fail if we didn't get enough _tokenPay back to repay our flash loan

        // assert(ERC20(_tokenPay).transfer(msg.sender, _amountToRepay)); // return tokens to V2 pai
        // assert(IERC20(_tokenPay).transfer(address(this), _amountToRepay)); // return tokens to V2 pair
        require(IERC20(_tokenPay).transfer(address(this), _amountToRepay), 'Error al devolver amountToRepay'); // return tokens to V2 pair
        
        
        require(addressPayTo != address(0), 'Error con la dirección');
        uint amountRest = amountReceived - _amountToRepay;
        //
        // assert(IERC20(_tokenPay).transfer(addressPayTo, amountRest)); // keep the rest! (tokens)
        require(IERC20(_tokenPay).transfer(addressPayTo, amountRest), 'Error en keep the rest!'); // keep the rest! (tokens)
    }
    // <<<
    
    // @notice Function is called by the Uniswap V2 pair's `swap` function
    function uniswapV2Call(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external {
        
        // access control
        require(msg.sender == permissionedPairAddress, "only permissioned UniswapV2 pair can call");
        require(_sender == address(this), "only this contract may initiate");

        // decode data
        (
            SwapType _swapType,
            address _tokenBorrow,
            uint _amount,
            address _tokenPay,
            bool _isBorrowingEth,
            bool _isPayingEth,
            bytes memory _triangleData,
            bytes memory _userData
        ) = abi.decode(_data, (SwapType, address, uint, address, bool, bool, bytes, bytes));
        
        if (_swapType == SwapType.SimpleSwap) {
            
            // simpleFlashSwapExecute(_tokenBorrow, _amount, _tokenPay, msg.sender, _isBorrowingEth, _isPayingEth, _userData);
            simpleFlashSwapExecute(_tokenBorrow, _amount, _tokenPay, msg.sender, _isBorrowingEth, _isPayingEth);
            return;
        }
        
        // NOOP to silence compiler "unused parameter" warning
        if (false) {
            _amount0;
            _amount1;
        }
        
    }

    // @notice This is the code that is executed after `simpleFlashSwap` initiated the flash-borrow
    // @dev When this code executes, this contract will hold the flash-borrowed _amount of _tokenBorrow
    function simpleFlashSwapExecute(
        address _tokenBorrow,
        uint _amount,
        address _tokenPay,
        address _pairAddress,
        bool _isBorrowingEth,
        bool _isPayingEth
        // bytes memory _userData
    ) private {
        
        // unwrap WETH if necessary
        if (_isBorrowingEth) {
            IWETH(WETH).withdraw(_amount); // <<< Falla acá cuando se está pidiendo prestado ETH, si se pide WETH no falla
        }
        
        // compute the amount of _tokenPay that needs to be repaid
        address pairAddress = permissionedPairAddress; // gas efficiency
        
        uint pairBalanceTokenBorrow = IERC20(_tokenBorrow).balanceOf(pairAddress);
        uint pairBalanceTokenPay = IERC20(_tokenPay).balanceOf(pairAddress);
        
        uint amountToRepay = ((1000 * pairBalanceTokenPay * _amount) / (997 * pairBalanceTokenBorrow)) + 1;
        
        // get the orignal tokens the user requested
        address tokenBorrowed = _isBorrowingEth ? ETH : _tokenBorrow;
        address tokenToRepay = _isPayingEth ? ETH : _tokenPay;
        
        // do whatever the user wants
        // executeKyber(tokenBorrowed, _amount, tokenToRepay, amountToRepay, _userData);
        executeKyber(tokenBorrowed, _amount, tokenToRepay, amountToRepay);
        
        // payback loan
        // wrap ETH if necessary
        if (_isPayingEth) {
            IWETH(WETH).deposit.value(amountToRepay)();
        }
        IERC20(_tokenPay).transfer(_pairAddress, amountToRepay);
    }
}
