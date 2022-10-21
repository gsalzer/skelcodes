// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.10;

import "@openzeppelin/contracts/math/SafeMath.sol"; // TODO: Bring into @yield-protocol/utils
import "@yield-protocol/utils/contracts/math/DecimalMath.sol"; // TODO: Make into library
import "@yield-protocol/utils/contracts/utils/SafeCast.sol";
import "@yield-protocol/utils/contracts/utils/YieldAuth.sol";
import "@yield-protocol/vault-v1/contracts/interfaces/IFYDai.sol";
import "@yield-protocol/vault-v1/contracts/interfaces/ITreasury.sol";
import "@yield-protocol/vault-v1/contracts/interfaces/IController.sol";
import "@yield-protocol/yieldspace-v1/contracts/interfaces/IPool.sol";
import "dss-interfaces/src/dss/AuthGemJoinAbstract.sol";
import "dss-interfaces/src/dss/DaiAbstract.sol";
import "./interfaces/IUSDC.sol";
import "./interfaces/DssPsmAbstract.sol";


library RoundingMath {
    function divrup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require (y > 0, "USDCProxy: Division by zero");
        return x % y == 0 ? x / y : x / y + 1;
    }
}

interface IEventRelayer {
    enum EventType {BorrowedUSDCType, RepaidDebtEarlyType, RepaidDebtMatureType}
    function relay(EventType eventType, address user) external;
}

contract USDCProxy is IEventRelayer, DecimalMath {
    using SafeCast for uint256;
    using SafeMath for uint256;
    using RoundingMath for uint256;
    using YieldAuth for DaiAbstract;
    using YieldAuth for IFYDai;
    using YieldAuth for IUSDC;
    using YieldAuth for IController;
    using YieldAuth for IPool;

    event BorrowedUSDC(address indexed user);
    event RepaidDebtEarly(address indexed user);
    event RepaidDebtMature(address indexed user);

    DaiAbstract public immutable dai;
    IUSDC public immutable usdc;
    IController public immutable controller;
    DssPsmAbstract public immutable psm;
    IEventRelayer public immutable usdcProxy;

    address public immutable treasury;

    bytes32 public constant WETH = "ETH-A";

    constructor(IController _controller, DssPsmAbstract psm_) public {
        ITreasury _treasury = _controller.treasury();
        dai = _treasury.dai();
        treasury = address(_treasury);
        controller = _controller;
        psm = psm_;
        usdc = IUSDC(AuthGemJoinAbstract(psm_.gemJoin()).gem());
        usdcProxy = IEventRelayer(address(this)); // This contract has two functions, as itself, and delegatecalled by a dsproxy.
    }

    /// @dev Workaround to emit events from the USDCProxy contract when being executed through a dsProxy delegate call.
    function relay(EventType eventType, address user) public override {
        if (eventType == EventType.BorrowedUSDCType) emit BorrowedUSDC(user);
        if (eventType == EventType.RepaidDebtEarlyType) emit RepaidDebtEarly(user);
        if (eventType == EventType.RepaidDebtMatureType) emit RepaidDebtMature(user);
    }

    /// @dev Borrow fyDai from Controller, sell it immediately for Dai in a pool, and sell the Dai for USDC in Maker's PSM, for a maximum fyDai debt.
    /// Must have approved the operator with `controller.addDelegate(borrowProxy.address)` or with `borrowDaiForMaximumFYDaiWithSignature`.
    /// Caller must have called `borrowDaiForMaximumFYDaiWithSignature` at least once before to set proxy approvals.
    /// @param collateral Valid collateral type.
    /// @param maturity Maturity of an added series
    /// @param to Wallet to send the resulting Dai to.
    /// @param usdcToBorrow Exact amount of USDC that should be obtained.
    /// @param maximumFYDai Maximum amount of FYDai to borrow.
    function borrowUSDCForMaximumFYDai(
        IPool pool,
        bytes32 collateral,
        uint256 maturity,
        address to,
        uint256 usdcToBorrow,
        uint256 maximumFYDai
    )
        public
        returns (uint256)
    {
        pool.fyDai().approve(address(pool), type(uint256).max); // TODO: Move to right place
        
        uint256 usdcToBorrow18 = usdcToBorrow.mul(1e12); // USDC has 6 decimals
        uint256 fee = usdcToBorrow18.mul(psm.tout()) / 1e18; // tout has 18 decimals
        uint256 daiToBuy = usdcToBorrow18.add(fee);

        uint256 fyDaiToBorrow = pool.buyDaiPreview(daiToBuy.toUint128()); // If not calculated on-chain, there will be fyDai left as slippage
        require (fyDaiToBorrow <= maximumFYDai, "USDCProxy: Too much fyDai required");

        // The collateral for this borrow needs to have been posted beforehand
        controller.borrow(collateral, maturity, msg.sender, address(this), fyDaiToBorrow);
        pool.buyDai(address(this), address(this), daiToBuy.toUint128());
        psm.buyGem(to, usdcToBorrow); // PSM takes USDC amounts with 6 decimals

        usdcProxy.relay(EventType.BorrowedUSDCType, msg.sender);

        return fyDaiToBorrow;
    }

    /// @dev Repay an amount of fyDai debt in Controller using a given amount of USDC exchanged Dai in Maker's PSM, and then for fyDai at pool rates, with a minimum of fyDai debt required to be paid.
    /// Must have approved the operator with `controller.addDelegate(borrowProxy.address)` or with `repayMinimumFYDaiDebtForDaiWithSignature`.
    /// Must have approved the operator with `pool.addDelegate(borrowProxy.address)` or with `repayMinimumFYDaiDebtForDaiWithSignature`.
    /// If `repaymentInUSDC` exceeds the existing debt, the surplus will be locked in the proxy.
    /// @param collateral Valid collateral type.
    /// @param maturity Maturity of an added series
    /// @param to Yield Vault to repay fyDai debt for.
    /// @param usdcRepayment Exact amount of USDC that should be spent on the repayment.
    /// @param minFYDaiRepayment Minimum amount of fyDai debt to repay.
    function repayDebtEarly(
        IPool pool,
        bytes32 collateral,
        uint256 maturity,
        address to,
        uint256 usdcRepayment,
        uint256 minFYDaiRepayment
    )
        public
        returns (uint256)
    {
        uint256 usdcRepayment18 = usdcRepayment.mul(1e12); // USDC has 6 decimals
        uint256 fee = usdcRepayment18.mul(psm.tin()) / 1e18; // Fees in PSM are fixed point in WAD
        uint256 daiObtained = usdcRepayment18.sub(fee); // If not right, the `sellDai` might revert.

        usdc.transferFrom(msg.sender, address(this), usdcRepayment);
        psm.sellGem(address(this), usdcRepayment); // PSM takes USDC amounts with 6 decimals
        uint256 fyDaiRepayment =  pool.sellDai(address(this), address(this), daiObtained.toUint128());
        require(fyDaiRepayment >= minFYDaiRepayment, "USDCProxy: Not enough debt repaid");
        controller.repayFYDai(collateral, maturity, address(this), to, fyDaiRepayment);

        usdcProxy.relay(EventType.RepaidDebtEarlyType, msg.sender);

        return daiObtained;
    }

    /// @dev Repay all debt in Controller using for a maximum amount of USDC, reverting if surpassed.
    /// Must have approved the operator with `controller.addDelegate(borrowProxy.address)` or with `repayAllWithFYDaiWithSignature`.
    /// Must have approved the operator with `pool.addDelegate(borrowProxy.address)` or with `repayAllWithFYDaiWithSignature`.
    /// @param collateral Valid collateral type.
    /// @param maturity Maturity of an added series
    /// @param to Yield Vault to repay fyDai debt for.
    /// @param maxUSDCIn Maximum amount of USDC that should be spent on the repayment.
    function repayAllEarly(
        IPool pool,
        bytes32 collateral,
        uint256 maturity,
        address to,
        uint256 maxUSDCIn
    )
        public
        returns (uint256)
    {
        uint256 fyDaiDebt = controller.debtFYDai(collateral, maturity, to);
        uint256 daiIn = pool.buyFYDaiPreview(fyDaiDebt.toUint128());
        uint256 usdcIn18 = (daiIn * 1e18).divrup(1e18 + psm.tin()); // Fixed point division with 18 decimals - We are working an usdc value from a dai one, so we round up.
        uint256 usdcIn = usdcIn18.divrup(1e12); // We are working an usdc value from a dai one, so we round up.

        require (usdcIn <= maxUSDCIn, "USDCProxy: Too much USDC required");
        usdc.transferFrom(msg.sender, address(this), usdcIn);
        psm.sellGem(address(this), usdcIn);
        pool.buyFYDai(address(this), address(this), fyDaiDebt.toUint128());
        controller.repayFYDai(collateral, maturity, address(this), to, fyDaiDebt);

        usdcProxy.relay(EventType.RepaidDebtEarlyType, msg.sender);

        return usdcIn;
    }

    /// @dev Repay an exact amount of Dai-denominated debt in Controller using USDC.
    /// Must have approved the operator with `controller.addDelegate(borrowProxy.address)` or with `repayAllWithFYDaiWithSignature`.
    /// Must have approved the operator with `pool.addDelegate(borrowProxy.address)` or with `repayAllWithFYDaiWithSignature`.
    /// @param collateral Valid collateral type.
    /// @param maturity Maturity of an added series
    /// @param to Yield Vault to repay fyDai debt for.
    /// @param daiRepayment Amount of Dai that should be bought from the PSM for the repayment.
    /// @return Amount of USDC that was taken from the user for the repayment.
    function repayDebtMature(
        bytes32 collateral,
        uint256 maturity,
        address to,
        uint256 daiRepayment
    )
        public
        returns (uint256)
    {
        return _repayDebtMature(
            collateral,
            maturity,
            to,
            daiRepayment
        );
    }

    /// @dev Repay all debt for an user and series in Controller using USDC.
    /// Must have approved the operator with `controller.addDelegate(borrowProxy.address)` or with `repayAllWithFYDaiWithSignature`.
    /// Must have approved the operator with `pool.addDelegate(borrowProxy.address)` or with `repayAllWithFYDaiWithSignature`.
    /// @param collateral Valid collateral type.
    /// @param maturity Maturity of an added series
    /// @param to Yield Vault to repay fyDai debt for.
    /// @return Amount of USDC that was taken from the user for the repayment.
    function repayAllMature(
        bytes32 collateral,
        uint256 maturity,
        address to
    )
        public
        returns (uint256)
    {
        return _repayDebtMature(
            collateral,
            maturity,
            to,
            controller.debtDai(collateral, maturity, msg.sender)
        );
    }

    /// @dev Repay an exact amount of Dai-denominated debt in Controller using USDC.
    /// Must have approved the operator with `controller.addDelegate(borrowProxy.address)` or with `repayAllWithFYDaiWithSignature`.
    /// Must have approved the operator with `pool.addDelegate(borrowProxy.address)` or with `repayAllWithFYDaiWithSignature`.
    /// @param collateral Valid collateral type.
    /// @param maturity Maturity of an added series
    /// @param to Yield Vault to repay fyDai debt for.
    /// @return Amount of USDC that was taken from the user for the repayment.
    function _repayDebtMature(
        bytes32 collateral,
        uint256 maturity,
        address to,
        uint256 daiRepayment
    )
        internal
        returns (uint256)
    {
        uint256 usdcRepayment18 = (daiRepayment * 1e18).divrup(1e18 - psm.tin());
        uint256 usdcRepayment = usdcRepayment18.divrup(1e12);
        usdc.transferFrom(msg.sender, address(this), usdcRepayment);
        psm.sellGem(address(this), usdcRepayment);
        controller.repayDai(collateral, maturity, address(this), to, daiRepayment);

        usdcProxy.relay(EventType.RepaidDebtMatureType, msg.sender);

        return usdcRepayment;
    }

    /// --------------------------------------------------
    /// Signature method wrappers
    /// --------------------------------------------------

    /// @dev Set proxy approvals for `borrowUSDCForMaximumFYDai` with a given pool.
    function borrowUSDCForMaximumFYDaiApprove(IPool pool) public {
        // allow the pool to pull FYDai/dai from us for trading
        if (pool.fyDai().allowance(address(this), address(pool)) < type(uint112).max)
            pool.fyDai().approve(address(pool), type(uint256).max);
        
        if (dai.allowance(address(this), address(psm)) < type(uint256).max)
            dai.approve(address(psm), type(uint256).max); // Approve to provide Dai to the PSM
    }

    /// @dev Borrow fyDai from Controller, sell it immediately for Dai in a pool, and sell the Dai for USDC in Maker's PSM, for a maximum fyDai debt.
    /// Must have approved the operator with `controller.addDelegate(borrowProxy.address)` or with `borrowDaiForMaximumFYDaiWithSignature`.
    /// Caller must have called `borrowDaiForMaximumFYDaiWithSignature` at least once before to set proxy approvals.
    /// @param collateral Valid collateral type.
    /// @param maturity Maturity of an added series
    /// @param to Wallet to send the resulting Dai to.
    /// @param usdcToBorrow Exact amount of USDC that should be obtained.
    /// @param maximumFYDai Maximum amount of FYDai to borrow.
    /// @param controllerSig packed signature for delegation of this proxy in the controller. Ignored if '0x'.
    function borrowUSDCForMaximumFYDaiWithSignature(
        IPool pool,
        bytes32 collateral,
        uint256 maturity,
        address to,
        uint256 usdcToBorrow,
        uint256 maximumFYDai,
        
        bytes memory controllerSig
    )
        public
        returns (uint256)
    {
        borrowUSDCForMaximumFYDaiApprove(pool);
        if (controllerSig.length > 0) controller.addDelegatePacked(controllerSig);
        return borrowUSDCForMaximumFYDai(pool, collateral, maturity, to, usdcToBorrow, maximumFYDai);
    }

    /// @dev Set proxy approvals for `repayDebtEarly` with a given pool.
    function repayDebtEarlyApprove(IPool pool) public {
        // Send the USDC to the PSM
        if (usdc.allowance(address(this), address(psm.gemJoin())) < type(uint112).max) // USDC reduces allowances when set to MAX
            usdc.approve(address(psm.gemJoin()), type(uint256).max);
        
        // Send the Dai to the Pool
        if (dai.allowance(address(this), address(pool)) < type(uint256).max)
            dai.approve(address(pool), type(uint256).max);

        // Send the fyDai to the Treasury
        if (pool.fyDai().allowance(address(this), treasury) < type(uint112).max)
            pool.fyDai().approve(treasury, type(uint256).max);
    }

    /// @dev Repay an amount of fyDai debt in Controller using a given amount of USDC exchanged Dai in Maker's PSM, and then for fyDai at pool rates, with a minimum of fyDai debt required to be paid.
    /// If `repaymentInDai` exceeds the existing debt, only the necessary Dai will be used.
    /// @param collateral Valid collateral type.
    /// @param maturity Maturity of an added series
    /// @param to Yield Vault to repay fyDai debt for.
    /// @param fyDaiDebt Amount of fyDai debt to repay.
    /// @param repaymentInUSDC Exact amount of USDC that should be spent on the repayment.
    /// @param usdcSig packed signature for permit of USDC transfers to this proxy. Ignored if '0x'.
    /// @param controllerSig packed signature for delegation of this proxy in the controller. Ignored if '0x'.
    function repayDebtEarlyWithSignature(
        IPool pool,
        bytes32 collateral,
        uint256 maturity,
        address to,
        uint256 repaymentInUSDC,
        uint256 fyDaiDebt, // Calculate off-chain, works as slippage protection
        bytes memory usdcSig,
        bytes memory controllerSig
    )
        public
        returns (uint256)
    {
        repayDebtEarlyApprove(pool);
        if (usdcSig.length > 0) usdc.permitPacked(address(this), usdcSig);
        if (controllerSig.length > 0) controller.addDelegatePacked(controllerSig);
        return repayDebtEarly(pool, collateral, maturity, to, repaymentInUSDC, fyDaiDebt);
    }

    /// @dev Repay all debt in Controller using for a maximum amount of USDC, reverting if surpassed.
    /// @param collateral Valid collateral type.
    /// @param maturity Maturity of an added series
    /// @param to Yield Vault to repay fyDai debt for.
    /// @param maxUSDCIn Maximum amount of USDC that should be spent on the repayment.
    /// @param usdcSig packed signature for permit of USDC transfers to this proxy. Ignored if '0x'.
    /// @param controllerSig packed signature for delegation of this proxy in the controller. Ignored if '0x'.
    function repayAllEarlyWithSignature(
        IPool pool,
        bytes32 collateral,
        uint256 maturity,
        address to,
        uint256 maxUSDCIn,
        bytes memory usdcSig,
        bytes memory controllerSig
    )
        public
        returns (uint256)
    {
        repayDebtEarlyApprove(pool); // Same permissions
        if (usdcSig.length > 0) usdc.permitPacked(address(this), usdcSig);
        if (controllerSig.length > 0) controller.addDelegatePacked(controllerSig);
        return repayAllEarly(pool, collateral, maturity, to, maxUSDCIn);
    }

    /// @dev Set proxy approvals for `repayDebtMature`
    function repayDebtMatureApprove() public {
        // Send the USDC to the PSM
        if (usdc.allowance(address(this), address(psm.gemJoin())) < type(uint112).max) // USDC reduces allowances when set to MAX
            usdc.approve(address(psm.gemJoin()), type(uint256).max);
        
        // Send the Dai to the Treasury
        if (dai.allowance(address(this), address(treasury)) < type(uint256).max)
            dai.approve(address(treasury), type(uint256).max);
    }

    /// @dev Repay an amount of fyDai debt in Controller using a given amount of USDC exchanged Dai in Maker's PSM.
    /// If the amount of Dai obtained by selling USDC exceeds the existing debt, the surplus will be locked in the proxy.
    /// @param collateral Valid collateral type.
    /// @param maturity Maturity of an added series
    /// @param to Yield Vault to repay fyDai debt for.
    /// @param repaymentInUSDC Exact amount of USDC that should be spent on the repayment.
    /// @param usdcSig packed signature for permit of USDC transfers to this proxy. Ignored if '0x'.
    /// @param controllerSig packed signature for delegation of this proxy in the controller. Ignored if '0x'.
    function repayDebtMatureWithSignature(
        bytes32 collateral,
        uint256 maturity,
        address to,
        uint256 repaymentInUSDC,
        bytes memory usdcSig,
        bytes memory controllerSig
    )
        public
        returns (uint256)
    {
        repayDebtMatureApprove();
        if (usdcSig.length > 0) usdc.permitPacked(address(this), usdcSig);
        if (controllerSig.length > 0) controller.addDelegatePacked(controllerSig);
        return repayDebtMature(collateral, maturity, to, repaymentInUSDC);
    }

    /// @dev Repay all debt for an user in Controller for a mature series using Maker's PSM.
    /// @param collateral Valid collateral type.
    /// @param maturity Maturity of an added series
    /// @param to Yield Vault to repay fyDai debt for.
    /// @param usdcSig packed signature for permit of USDC transfers to this proxy. Ignored if '0x'.
    /// @param controllerSig packed signature for delegation of this proxy in the controller. Ignored if '0x'.
    function repayAllMatureWithSignature(
        bytes32 collateral,
        uint256 maturity,
        address to,
        bytes memory usdcSig,
        bytes memory controllerSig
    )
        public
        returns (uint256)
    {
        repayDebtMatureApprove(); // Same permissions
        if (usdcSig.length > 0) usdc.permitPacked(address(this), usdcSig);
        if (controllerSig.length > 0) controller.addDelegatePacked(controllerSig);
        return repayAllMature(collateral, maturity, to);
    }

    /// --------------------------------------------------
    /// Convenience functions
    /// --------------------------------------------------

    /// @dev Return PSM's tin, so the frontend needs to do one less call.
    function tin() public view returns (uint256) {
        return psm.tin();
    }

    /// @dev Return PSM's tout, so the frontend needs to do one less call.
    function tout() public view returns (uint256) {
        return psm.tout();
    }
}
