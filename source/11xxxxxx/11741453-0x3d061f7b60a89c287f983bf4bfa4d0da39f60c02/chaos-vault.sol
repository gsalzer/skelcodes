pragma solidity ^0.7.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";

contract ChaosVault is Ownable, ERC20
{
   using SafeERC20 for IERC20;

   address operator;
   IERC20  basisToken;
   uint    price;
   uint    premium;
   uint    cap;
   bool    buyAvailable;
   bool    redeemAvailable;

   constructor (address _operator, address _basisToken, uint _price, uint _premium, uint _cap)
     ERC20("Chaos Vault Token", "CHAOS")
   {
      updateStateVars(_operator, _basisToken, _price, _premium, _cap, true, false);
   }

   // ----- Public functions --------------------------------------------------

   function buy (uint amount) public
   {
      require(buyAvailable, "!buyAvailable");
      require(price * totalSupply() <= cap, "> cap");

      basisToken.safeTransferFrom(msg.sender, operator, amount);

      _mint(msg.sender, (amount * 1 ether) / (price + premium));
   }

   function redeem (uint amount) public
   {
      require(redeemAvailable, "!redeemAvailable");
      require(amount <= balanceOf(msg.sender), "amount > balance");

      _burn(msg.sender, amount);

      basisToken.safeTransferFrom(operator, msg.sender, (amount * price) / 1 ether);
   }

   // ----- Admin functions ---------------------------------------------------

   function updateStateVars (address _operator,
                             address _basisToken,
                             uint    _price,
                             uint    _premium,
                             uint    _cap,
                             bool    _buyAvailable,
                             bool    _redeemAvailable)
     public onlyOwner
   {
      operator        = _operator;
      basisToken      = IERC20(_basisToken);
      price           = _price;
      premium         = _premium;
      cap             = _cap;
      buyAvailable    = _buyAvailable;
      redeemAvailable = _redeemAvailable;
   }

   function updateOperator (address _operator) public onlyOwner
   {
      operator = _operator;
   }

   function updateBasisToken (address _basisToken) public onlyOwner
   {
      basisToken = IERC20(_basisToken);
   }

   function updatePrice (uint _price) public onlyOwner
   {
      price = _price;
   }

   function updatePremium (uint _premium) public onlyOwner
   {
      premium = _premium;
   }

   function updateCap (uint _cap) public onlyOwner
   {
      cap = _cap;
   }

   function toggleBuy () public onlyOwner
   {
      buyAvailable = !buyAvailable;
   }

   function toggleRedeem () public onlyOwner
   {
      redeemAvailable = !redeemAvailable;
   }

   function rescueTokens (address _token) public onlyOwner
   {
      if (_token == address(0))
      {
         (bool success, ) = msg.sender.call{ value: address(this).balance }("");
         require(success, "Transfer failed");
      }
      else
      {
         IERC20 token = IERC20(_token);
         token.safeTransfer(msg.sender, token.balanceOf(address(this))); 
      }
   }
}

