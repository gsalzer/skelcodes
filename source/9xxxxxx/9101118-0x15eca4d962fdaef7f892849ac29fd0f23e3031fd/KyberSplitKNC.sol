pragma solidity 0.5.11;


/// @title Kyber Reserve contract
interface KyberReserveInterface {

    function trade(
        ERC20 srcToken,
        uint srcAmount,
        ERC20 destToken,
        address destAddress,
        uint conversionRate,
        bool validate
    )
        external
        payable
        returns(bool);

    function getConversionRate(ERC20 src, ERC20 dest, uint srcQty, uint blockNumber) external view returns(uint);
}

interface ERC20 {
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract PermissionGroups {

    address public admin;
    address public pendingAdmin;

    constructor() public {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    event TransferAdminPending(address pendingAdmin);

    /**
     * @dev Allows the current admin to set the pendingAdmin address.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0));
        emit TransferAdminPending(pendingAdmin);
        pendingAdmin = newAdmin;
    }

    /**
     * @dev Allows the current admin to set the admin in one tx. Useful initial deployment.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdminQuickly(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0));
        emit TransferAdminPending(newAdmin);
        emit AdminClaimed(newAdmin, admin);
        admin = newAdmin;
    }

    event AdminClaimed( address newAdmin, address previousAdmin);

    /**
     * @dev Allows the pendingAdmin address to finalize the change admin process.
     */
    function claimAdmin() public {
        require(pendingAdmin == msg.sender);
        emit AdminClaimed(pendingAdmin, admin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }
}

/// @title Kyber Network interface
interface KyberNetworkProxyInterface {
    function tradeWithHint(ERC20 src, uint srcAmount, ERC20 dest, address destAddress, uint maxDestAmount,
        uint minConversionRate, address walletId, bytes calldata hint) external payable returns(uint);
}

contract Withdrawable is PermissionGroups {

    event TokenWithdraw(ERC20 token, uint amount, address sendTo);

    /**
     * @dev Withdraw all ERC20 compatible tokens
     * @param token ERC20 The address of the token contract
     */
    function withdrawToken(ERC20 token, uint amount, address sendTo) external onlyAdmin {
        require(token.transfer(sendTo, amount));
        emit TokenWithdraw(token, amount, sendTo);
    }

    event EtherWithdraw(uint amount, address sendTo);

    /**
     * @dev Withdraw Ethers
     */
    function withdrawEther(uint amount, address payable sendTo) external onlyAdmin {
        sendTo.transfer(amount);
        emit EtherWithdraw(amount, sendTo);
    }
}

contract KyberSplitKNC is Withdrawable {

    ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    uint  constant internal DECIMALS = 18;
    uint constant internal PRECISION = 10**18;
    ERC20 constant internal KNC_TOKEN = ERC20(0xdd974D5C2e2928deA5F71b9825b8b646686BD200);
    KyberReserveInterface constant internal fprReserve = KyberReserveInterface(0x63825c174ab367968EC60f061753D3bbD36A0D8F);
    KyberReserveInterface constant internal aprReserve = KyberReserveInterface(0x607d7751d9F4845C5a1dE9eeD39c56f4fC0F855d);
    KyberNetworkProxyInterface constant internal networkProxy = KyberNetworkProxyInterface(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
    address constant internal walletID = address(0x80B603bCE2D8Cc3acb43B6692514b463a16FB425);

    constructor(address _admin) public {
        admin = _admin;
        KNC_TOKEN.approve(address(networkProxy), 2**255);
    }

    function() external payable {} // solhint-disable-line no-empty-blocks

    function getConversionRate(bool isEthToKNC, uint srcQty)
        public
        view
        returns(uint totalDestAmount, uint rateFPR, uint rateAPR) {
        ERC20 src = isEthToKNC ? ETH_TOKEN_ADDRESS : KNC_TOKEN;
        ERC20 dest = isEthToKNC ? KNC_TOKEN : ETH_TOKEN_ADDRESS;
        uint destAmount;
        uint rate1;
        uint rate2;
        (totalDestAmount, rateFPR, rateAPR) = getEstimatedDestAmount(src, dest, srcQty/2, srcQty - srcQty/2);
        (destAmount, rate1, rate2) = getEstimatedDestAmount(src, dest, srcQty, 0);
        if (totalDestAmount < destAmount) {
            totalDestAmount = destAmount;
            rateFPR = rate1;
            rateAPR = rate2;
        }
        (destAmount, rate1, rate2) = getEstimatedDestAmount(src, dest, 0, srcQty);
        if (totalDestAmount < destAmount) {
            totalDestAmount = destAmount;
            rateFPR = rate1;
            rateAPR = rate2;
        }
    }

    function getEstimatedDestAmount(ERC20 src, ERC20 dest, uint firstQty, uint secondQty)
        public
        view
        returns(uint totalDestAmount, uint rateFPR, uint rateAPR)
    {
        if (firstQty > 0) {
            rateFPR = fprReserve.getConversionRate(src, dest, firstQty, block.number);
            totalDestAmount += calcDestAmount(firstQty, rateFPR);
        }
        if (secondQty > 0) {
            rateAPR = aprReserve.getConversionRate(src, dest, secondQty, block.number);
            totalDestAmount += calcDestAmount(secondQty, rateAPR);
        }
    }

    function trade(
        bool isEthToKNC,
        uint srcAmount,
        bool isSplit,
        uint expectedDestAmount
    )
        public
        payable
    {

        ERC20 src = isEthToKNC ? ETH_TOKEN_ADDRESS : KNC_TOKEN;
        ERC20 dest = isEthToKNC ? KNC_TOKEN : ETH_TOKEN_ADDRESS;

        if (src == ETH_TOKEN_ADDRESS) {
            require(msg.value == srcAmount, "trade: ETH amount is not correct");
        } else {
            // collect token
            require(src.transferFrom(msg.sender, address(this), srcAmount));
        }

        uint totalDestAmount;
        if (!isSplit) {
            totalDestAmount = networkProxy.tradeWithHint.value(msg.value)(
                src,
                srcAmount,
                dest,
                msg.sender,
                2**255,
                0,
                walletID,
                "PERM"
            );
        } else {
            uint firstQty = srcAmount / 2;
            uint tradeAmount = isEthToKNC ? firstQty : 0;
            totalDestAmount = networkProxy.tradeWithHint.value(tradeAmount)(
                src,
                firstQty,
                dest,
                msg.sender,
                2**255,
                0,
                walletID,
                "PERM"
            );
            firstQty = srcAmount - firstQty;
            tradeAmount = isEthToKNC ? firstQty : 0;
            totalDestAmount += networkProxy.tradeWithHint.value(tradeAmount)(
                src,
                firstQty,
                dest,
                msg.sender,
                2**255,
                0,
                walletID,
                "PERM"
            );
        }
        require(totalDestAmount >= expectedDestAmount, "Total dest amount is smaller than expected dest amount");
    }

    function calcDstQty(uint srcQty, uint srcDecimals, uint dstDecimals, uint rate) internal pure returns(uint) {
        if (dstDecimals >= srcDecimals) {
            return (srcQty * rate * (10**(dstDecimals - srcDecimals))) / PRECISION;
        } else {
            return (srcQty * rate) / (PRECISION * (10**(srcDecimals - dstDecimals)));
        }
    }

    function calcDestAmount(uint srcAmount, uint rate) internal pure returns(uint) {
        return calcDstQty(srcAmount, DECIMALS, DECIMALS, rate);
    }

}
