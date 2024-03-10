// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IERC20Mintable.sol";
import "./interfaces/IPriceOracle.sol";

contract Gateway is OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Mintable;
    using SafeMath for uint128;
    using SafeMath for uint256;

    enum ReleaseMethod { MINT, UNLOCK }

    struct Token {
        address tokenAddress; // address on the chain that this contract is deployed to
        ReleaseMethod releaseMethod;
    }

    uint128 public minVariableFeeInUsd;
    uint128 public maxVariableFeeInUsd;
    uint128 public serviceFeePercent;
    uint128 public serviceFeePercentWhenNoPrice;
    uint256 public feeShareToTheTeam;
    address public orgWallet;
    address public teamWallet;
    IPriceOracle public priceOracle;
    Token[] public tokens;
    mapping(address => uint256) public addressToTokenId;
    mapping(address => uint256) public feeToWithdraw;
    mapping(uint256 => uint256) public networksFee;
    mapping(bytes32 => bool) public processedRequests;
    mapping(uint256 => mapping(uint256 => bool)) supportedChains;

    event TransferredToAnotherChain(
        uint256 indexed tokenId,
        uint256 indexed toChainId,
        address from,
        address to,
        uint256 amount,
        uint256 amountToTransfer,
        uint256 networkFee
    );
    event TransferredFromAnotherChain(
        bytes32 indexed requestKey,
        uint256 indexed tokenId,
        uint256 indexed fromChainId,
        address to,
        uint256 amount
    );
    event NetworkFeeUpdated(uint256 indexed chainId, uint256 newNetworkFee);
    event TokenAdded(uint256 indexed tokenId, address tokenAddress, ReleaseMethod releaseMethod, uint256[] supportedChains);
    event TokenSupportedChainsUpdated(uint256 indexed tokenId, uint256 chainId, bool active);

    function initialize(IPriceOracle _priceOracle, address _orgWallet, address _teamWallet) public initializer {
        __Ownable_init();

        minVariableFeeInUsd = 1e18; // $1
        maxVariableFeeInUsd = 100e18; // $100
        serviceFeePercentWhenNoPrice = 1e16; // 1%
        serviceFeePercent = 1e16; // 1%
        feeShareToTheTeam = 5e17; // 50%

        priceOracle = _priceOracle;
        orgWallet = _orgWallet;
        teamWallet = _teamWallet;
    }

    function addToken(address tokenAddress, ReleaseMethod releaseMethod, uint256[] memory chains)
        public
        onlyOwner
    {
        require(tokenAddress != address(0), "Gateway: invalid tokenAddress");
        require(addressToTokenId[tokenAddress] == 0 && (tokens.length == 0 || tokens[0].tokenAddress != tokenAddress), "Gateway: address already added");

        uint256 tokenId = tokens.length;

        tokens.push(Token({
            tokenAddress: tokenAddress, 
            releaseMethod: releaseMethod
        }));
        addressToTokenId[tokenAddress] = tokenId;

        for (uint256 i = 0; i < chains.length; ++i) {
            supportedChains[tokenId][chains[i]] = true;
        }

        if (address(priceOracle) != address(0)) {
            priceOracle.addToken(tokenAddress);
        }

        emit TokenAdded(tokenId, tokenAddress, releaseMethod, chains);
    }

    function updateTokenSupportedChain(uint256 tokenId, uint256 chainId, bool active) public onlyOwner {
        require(networksFee[chainId] > 0,"Gateway: this chain hasn't networkFee set");
        supportedChains[tokenId][chainId] = active;
        emit TokenSupportedChainsUpdated(tokenId, chainId, active);
    }

    function transferFromAnotherChain(
        uint256 tokenId,
        uint256 fromChainId,
        bytes32 requestTxHash,
        uint256 logIndex,
        address to,
        uint256 amount
    ) external onlyOwner {
        require(tokens.length > tokenId, "Gateway: token doesn't exist");
        
        bytes32 requestKey = toRequestKey(fromChainId, requestTxHash, logIndex);
        require(!processedRequests[requestKey], "Gateway: request already processed");

        processedRequests[requestKey] = true;

        IERC20Mintable token = IERC20Mintable(tokens[tokenId].tokenAddress);
        if (tokens[tokenId].releaseMethod == ReleaseMethod.MINT) {
            token.mint(to, amount);
        } else {
            token.safeTransfer(to, amount);
        }

        emit TransferredFromAnotherChain(requestKey, tokenId, fromChainId, to, amount);
    }

    function toRequestKey(uint256 fromChainId, bytes32 requestTxHash, uint256 logIndex) public pure returns (bytes32 requestKey) {
        requestKey = keccak256(abi.encodePacked(fromChainId, requestTxHash, logIndex));
    }

    function transferToAnotherChain(
        uint256 tokenId,
        uint256 toChainId,
        address to,
        uint256 amount
    ) external payable {
        require(amount > 0, "Gateway: amount should be > 0");
        require(msg.value == networksFee[toChainId], "Gateway: wrong network fee value");
        require(tokens.length > tokenId, "Gateway: token doesn't exist");
        require(supportedChains[tokenId][toChainId], "Gateway: chain isn't supported");

        IERC20Mintable token = IERC20Mintable(tokens[tokenId].tokenAddress);

        if (address(priceOracle) != address(0)) {
            priceOracle.update(address(token));
        }

        uint256 balanceBefore = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), amount);
        uint256 actualAmount = token.balanceOf(address(this)).sub(balanceBefore);

        uint256 fee = feeCalculation(address(token), actualAmount);

        if (tokens[tokenId].releaseMethod == ReleaseMethod.MINT) {
            token.burn(address(this), actualAmount.sub(fee));
        }

        feeToWithdraw[address(token)] = feeToWithdraw[address(token)].add(fee);

        emit TransferredToAnotherChain(tokenId, toChainId, msg.sender, to, actualAmount, actualAmount.sub(fee), networksFee[toChainId]);
    }

    function setFeeParameters(uint128 _minVariableFeeInUsd, uint128 _maxVariableFeeInUsd, uint128 _serviceFeePercentWhenNoPrice, uint128 _serviceFeePercent, uint256 _feeShareToTheTeam) public onlyOwner {
        require(_minVariableFeeInUsd < _maxVariableFeeInUsd, "Gateway: minVariableFeeInUsd should be < maxVariableFeeInUsd");
        require(_serviceFeePercentWhenNoPrice <= 1e18, "Gateway: Invalid serviceFeePercentWhenNoPrice");
        require(_serviceFeePercent <= 1e18, "Gateway: Invalid serviceFeePercent");
        require(_feeShareToTheTeam <= 1e18, "Gateway: Invalid feeShareToTheTeam");

        minVariableFeeInUsd = _minVariableFeeInUsd;
        maxVariableFeeInUsd = _maxVariableFeeInUsd;
        serviceFeePercentWhenNoPrice = _serviceFeePercentWhenNoPrice;
        serviceFeePercent = _serviceFeePercent;
        feeShareToTheTeam = _feeShareToTheTeam;
    }

    function getNetworkFee(uint256 toChainId) public view returns (uint256 networkFee) {
        networkFee = networksFee[toChainId];
    }

    function feeCalculation(address token, uint256 tokenAmount) public view returns(uint256 fee) {
        uint256 usdAmount = address(priceOracle) != address(0) ? priceOracle.priceOf(token, tokenAmount) : 0;
        if (usdAmount == 0 || usdAmount <= minVariableFeeInUsd) {
            return tokenAmount.mul(serviceFeePercentWhenNoPrice).div(1e18);
        }
        
        uint256 feeInUsd = usdAmount.mul(serviceFeePercent).div(1e18);

        if (feeInUsd < minVariableFeeInUsd) {
            return tokenAmount.mul(minVariableFeeInUsd).div(usdAmount);
        } else if(feeInUsd > maxVariableFeeInUsd) {
            return tokenAmount.mul(maxVariableFeeInUsd).div(usdAmount);
        }

        return tokenAmount.mul(serviceFeePercent).div(1e18);
    }

    function updateNetworkFee(uint256 chainId, uint256 _networkFee) public onlyOwner {
        networksFee[chainId] = _networkFee;
        emit NetworkFeeUpdated(chainId, _networkFee);
    }

    function setPriceOracle(IPriceOracle _priceOracle) public onlyOwner {
        priceOracle = _priceOracle;
    }

    function withdrawAllFees() external {
        withdrawTokenFees(address(0));

        for (uint256 i = 0; i < tokens.length; ++i) {
            withdrawTokenFees(tokens[i].tokenAddress);
        }
    }

    // Note: Use ZeroAddress for network coin (e.g ETH,BNB)
    function withdrawTokenFees(address token) public {
        uint256 total = getFeeToWithdraw(token);

        if (total == 0) {
            return;
        }

        if (token == address(0)) {
            // ETH/BNB go to the owner to cover tx costs
            payable(owner()).transfer(address(this).balance);
        } else  {
            uint256 teamAmount = total.mul(feeShareToTheTeam).div(1e18);
            IERC20(token).safeTransfer(teamWallet, teamAmount);
            IERC20(token).safeTransfer(orgWallet, total.sub(teamAmount));
            delete feeToWithdraw[token];
        }
    }

    function getFeeToWithdraw(address token) public view returns (uint256 amount) {
        if(token == address(0)) {
            amount = address(this).balance;
        } else {
            amount = feeToWithdraw[token];
        }
    }

    function updateWallets(address _orgWallet, address _teamWallet) public onlyOwner {
        orgWallet = _orgWallet;
        teamWallet = _teamWallet;
    }

    function getChainId() external pure returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }
}

