pragma solidity ^0.5.17;

import "./CTPurchaseOffer.sol";
import "./CTSellOffer.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Implementation.sol";
import "./ERC20.sol";


/**
 * @title GTToken
 * @dev The GTToken contract is an ERC20 standard based token implementation
 * It extends the Burnable, Detailed, Mintable, Pausable and Ownable functionalities
 */
contract GTToken is Implementation, Ownable, ERC20 {


    /* Usings */

    using SafeMath for uint256;


    /* Events */

    event GTTokenSetup(bool isSetup);
    event InvestorRegistered(address indexed investorRegistered);
    event CompanyTokenRegistered(
        string companyTokenName,
        uint indexed companyTokenAmounts
    );
    event CompanyTokenDistributed(
        string companyTokenName,
        address indexed initialShareHolders,
        uint indexed companyTokenAmounts,
        uint indexed distributedAmount
    );
    event CompanyTokenTransferred(
        string companyTokenName,
        address indexed fromAddress,
        address indexed toAddress,
        uint indexed amount
    );
    event AllocateTokens(
        address indexed investorAddress,
        uint indexed tokenAmount
    );
    event BurnTokens(
        address indexed investorAddress,
        uint indexed gtBalance
    );
    event ActivatePurchaseOffer(address indexed purchaseContract);
    event ActivateSellOffer(address indexed sellContract);
    event AcceptPurchaseOffer(address indexed purchaseContract);
    event AcceptSellOffer(address indexed sellContract);
    event WithdrawSellOffer(address indexed sellContract);


    /* Modifiers */

    modifier isGTTokenSetup() {
        require(isSetup);
        _;
    }

    modifier isAddressValid(address addr) {
        require(addr != address(0x0));
        _;
    }


    /* Storage */

    mapping (address => bool) investorRegistered;
    mapping (string => bool) companyTokenRegistered;
    mapping (string => uint) companyTokenCurrentSupply;
    mapping (string => uint) companyTokenCap;
    mapping (string => mapping (address => uint)) companyToken;

    string private name_;
    string private symbol_;
    uint8 private decimals_;


    /* External functions */

    /**
     * @dev Allows setting up of GTToken, sets the isSetup to true
     * @param _name string The name of the token
     * @param _symbol string The symbol of the token
     * @param _decimals uint The decimals for the token
     */
    function setup(
        string calldata _name,
        string calldata _symbol,
        uint8 _decimals
    )
        external
        returns(bool)
    {
        require(bytes(name_).length == 0 && bytes(_name).length > 0);
        require(bytes(symbol_).length == 0 && bytes(_symbol).length > 0);
        require(decimals_ == 0 && _decimals > 0);

        name_ = _name;
        symbol_ = _symbol;
        decimals_ = _decimals;

        isSetup = true;
        emit GTTokenSetup(isSetup);

        return true;
    }

    /**
     * @dev Allows registration of investor
     */
    function registerInvestor() external isGTTokenSetup returns(bool) {
        require(!investorRegistered[msg.sender]);

        investorRegistered[msg.sender] = true;

        emit InvestorRegistered(msg.sender);

        return true;
    }

    /**
     * @dev Returns true if the investor is registered
     * @param investorAddress address The address of the investor
     */
    function isInvestorRegistered(
        address investorAddress
    )
        external
        view
        returns(bool)
    {
        return investorRegistered[investorAddress];
    }

    /**
     * @return the name of the token.
     */
    function name() external view returns (string memory) {
        return name_;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() external view returns (string memory) {
        return symbol_;
    }

    function decimals() external view returns (uint8) {
        return decimals_;
    }

    /**
     * @dev Allows allocation of GT Token to investors
     * @param investorAddress address The address of the investor
     * @param tokenAmount uint The GT token amount to be allocated
     */
    function allocateTokens(
        address investorAddress,
        uint tokenAmount
    )
        external
        isGTTokenSetup
        onlyOwner

        returns(bool)
    {
        require(investorRegistered[investorAddress]);

        _mint(investorAddress, tokenAmount);

        emit AllocateTokens(investorAddress, balanceOf(investorAddress));

        return true;
    }

    /**
     * @dev Allows registration of a new company token. Can be called by the GT Admin/Owner only
     * @param companyTokenName string The name of company token
     */
    function registerCompanyToken(
        string calldata companyTokenName,
        uint ctTokenCap
    )
        external
        isGTTokenSetup
        onlyOwner
        returns(bool)
    {
        require(!companyTokenRegistered[companyTokenName]);
        require(ctTokenCap > 0);

        companyTokenRegistered[companyTokenName] = true;
        companyTokenCap[companyTokenName] = ctTokenCap;

        companyToken[companyTokenName][msg.sender] = ctTokenCap;

        emit CompanyTokenRegistered(companyTokenName, ctTokenCap);

        return true;
    }

    /**
     * @dev Provides functionality to distribute company token. Can be called by the GT Admin/Owner only
     * @param companyTokenName string The name of company token
     * @param initialShareHolders address[] The addresses of the investors for company token distribution
     * @param companyTokenAmounts uint[] The amount of the company token amount to be distributed
     */
    function distributeCompanyToken(
        string calldata companyTokenName,
        address[] calldata initialShareHolders,
        uint[] calldata companyTokenAmounts
    )
        external
        isGTTokenSetup
        onlyOwner
        returns(bool)
    {
        require(companyTokenRegistered[companyTokenName]);
        require(initialShareHolders.length == companyTokenAmounts.length);

        for (uint i = 0; i < initialShareHolders.length; i++) {
            require(investorRegistered[initialShareHolders[i]]);
        }

        uint askedSupply = companyTokenCurrentSupply[companyTokenName];

        for (uint i = 0; i < initialShareHolders.length; i++) {
            askedSupply = askedSupply.add(companyTokenAmounts[i]);
        }

        require(askedSupply <= companyTokenCap[companyTokenName]);

        for (uint i = 0; i < initialShareHolders.length; i++) {
            companyToken[companyTokenName][initialShareHolders[i]] = companyToken[companyTokenName][initialShareHolders[i]]
                .add(companyTokenAmounts[i]);
            companyToken[companyTokenName][msg.sender] = companyToken[companyTokenName][msg.sender].sub(companyTokenAmounts[i]);

            emit CompanyTokenDistributed(
                companyTokenName,
                initialShareHolders[i],
                companyToken[companyTokenName][initialShareHolders[i]],
                companyTokenAmounts[i]
            );
        }

        companyTokenCurrentSupply[companyTokenName] = askedSupply;

        return true;
    }

    /**
     * @dev Allows activation of purchase offer contracts
     * @param ctPurchaseOfferContract address The address of the purchase offer contract to be activated.
     * Can only be called by the purchase offer contract creator
     */
    function activatePurchaseOffer(
        address ctPurchaseOfferContract
    )
        external
        isAddressValid(ctPurchaseOfferContract)
        returns(bool)
    {
        CTPurchaseOffer ctPurchaseController = CTPurchaseOffer(ctPurchaseOfferContract);

        require(!ctPurchaseController.isOfferActive());
        require(!ctPurchaseController.isOfferCompleted());

        address buyer = ctPurchaseController.getBuyer();
        require(msg.sender == buyer);

        uint gtAmount = ctPurchaseController.getGTAmount();
        require(balanceOf(buyer) >= gtAmount);

        transfer(ctPurchaseOfferContract, gtAmount);
        ctPurchaseController.activateOffer();

        emit ActivatePurchaseOffer(ctPurchaseOfferContract);

        return true;
    }

    /**
     * @dev Allows activation of sell offer contracts
     * @param ctSellOfferContract address The address of the sell offer contract to be activated.
     * Can only be called by the sell offer contract creator
     */
    function activateSellOffer(
        address ctSellOfferContract
    )
        external
        isAddressValid(ctSellOfferContract)
        returns(bool)
    {
        CTSellOffer ctSellController = CTSellOffer(ctSellOfferContract);

        require(!ctSellController.isOfferActive());
        require(!ctSellController.isOfferCompleted());

        address seller = ctSellController.getSeller();
        require(msg.sender == seller);

        uint companyTokenAmount = ctSellController.getCompanyTokenAmount();
        string memory companyTokenName = ctSellController.getCompanyTokenName();

        require(getCompanyTokenBalance(companyTokenName, seller) >= companyTokenAmount);

        companyToken[companyTokenName][seller] = companyToken[companyTokenName][seller].sub(companyTokenAmount);
        companyToken[companyTokenName][ctSellOfferContract] = companyTokenAmount;
        ctSellController.activateOffer();

        emit ActivateSellOffer(ctSellOfferContract);

        return true;
    }

    /**
     * @dev Allows processing of acceptance of purchase offer contracts by a seller
     * @param ctPurchaseOfferContract address The address of the purchase offer contract to be accepted.
     * Can only be called by the registered seller of the purchase offer contract creator
     */
    function acceptPurchaseOffer(
        address ctPurchaseOfferContract
    )
        external
        isAddressValid(ctPurchaseOfferContract)
        returns(bool)
    {
        CTPurchaseOffer ctPurchaseController = CTPurchaseOffer(ctPurchaseOfferContract);
        require(ctPurchaseController.isOfferActive());

        address seller = ctPurchaseController.getSeller();
        require(seller == msg.sender);

        uint gtAmount = ctPurchaseController.getGTAmount();
        require(balanceOf(ctPurchaseOfferContract) == gtAmount);

        string memory companyTokenName = ctPurchaseController.getCompanyTokenName();
        uint tokenAmount = ctPurchaseController.getCompanyTokenAmount();

        require(getCompanyTokenBalance(companyTokenName, seller) >= tokenAmount);

        address buyer = ctPurchaseController.getBuyer();

        companyToken[companyTokenName][seller] = companyToken[companyTokenName][seller].sub(tokenAmount);
        companyToken[companyTokenName][buyer] = companyToken[companyTokenName][buyer].add(tokenAmount);

        ctPurchaseController.acceptOffer();

        emit AcceptPurchaseOffer(ctPurchaseOfferContract);
        emit CompanyTokenTransferred(
            companyTokenName,
            seller,
            buyer,
            tokenAmount
        );

        return true;
    }

    /**
     * @dev Allows processing of acceptance of sell offer contracts by a buyer
     * @param ctSellOfferContract address The address of the sell offer contract to be accepted.
     * Can only be called by the registered buyer of the sell offer contract creator
     */
    function acceptSellOffer(
        address ctSellOfferContract
    )
        external
        isAddressValid(ctSellOfferContract)
        returns(bool)
    {
        CTSellOffer ctSellController = CTSellOffer(ctSellOfferContract);
        require(ctSellController.isOfferActive());

        address buyer = ctSellController.getBuyer();
        require(msg.sender == buyer);


        uint companyTokenAmount = ctSellController.getCompanyTokenAmount();
        uint gtAmount = ctSellController.getGTAmount();
        string memory companyTokenName = ctSellController.getCompanyTokenName();

        require(balanceOf(buyer) >= gtAmount);
        require(getCompanyTokenBalance(companyTokenName, ctSellOfferContract) == companyTokenAmount);

        uint fee = gtAmount.div(100);

        delete companyToken[companyTokenName][ctSellOfferContract];
        companyToken[companyTokenName][buyer] = companyToken[companyTokenName][buyer].add(companyTokenAmount);

        address seller = ctSellController.getSeller();
        transfer(seller, gtAmount.sub(fee));
        burnTokens(fee);

        ctSellController.acceptOffer();

        emit AcceptSellOffer(ctSellOfferContract);
        emit CompanyTokenTransferred(
            companyTokenName,
            seller,
            buyer,
            companyTokenAmount
        );

        return true;
    }

    /**
     * @dev Allows withdrawal of the sell offer contracts by a seller
     * @param ctSellOfferContract address The address of the sell offer contract to be withdrawn.
     * Can only be called by the seller or buyer registered in the sell contract offer
     */
    function withdrawSellOffer(
        address ctSellOfferContract
    )
        external
        isAddressValid(ctSellOfferContract)
        returns(bool)
    {
        CTSellOffer ctSellController = CTSellOffer(ctSellOfferContract);
        require(ctSellController.isOfferActive());

        address seller = ctSellController.getSeller();
        address buyer = ctSellController.getBuyer();
        require(msg.sender == seller || msg.sender == buyer);

        uint companyTokenAmount = ctSellController.getCompanyTokenAmount();
        string memory companyTokenName = ctSellController.getCompanyTokenName();

        require(getCompanyTokenBalance(companyTokenName, ctSellOfferContract) == companyTokenAmount);

        companyToken[companyTokenName][seller] = companyToken[companyTokenName][seller].add(companyTokenAmount);
        delete companyToken[companyTokenName][ctSellOfferContract];

        ctSellController.deActivateOffer();

        emit WithdrawSellOffer(ctSellOfferContract);

        return true;
    }

    /* Public Functions */

    /**
     * @dev Returns the Company token balance of the investor
     * @param companyTokenName string The name of company token
     * @param investorAddress address The address of the investor
     */
    function getCompanyTokenBalance(
        string memory companyTokenName,
        address investorAddress
    )
        public
        view
        returns(uint)
    {
        return companyToken[companyTokenName][investorAddress];
    }

    /**
     * @dev Allows burning of investor GT Token
     * @param gtAmount uint The GT token amount to be allocated
     */
    function burnTokens(uint gtAmount) public returns(bool) {
        CTPurchaseOffer ctPurchaseController = CTPurchaseOffer(msg.sender);
        require(investorRegistered[msg.sender] || ctPurchaseController.isOfferActive());

        _burn(msg.sender, gtAmount);

        emit BurnTokens(msg.sender, balanceOf(msg.sender));

        return true;
    }
}

