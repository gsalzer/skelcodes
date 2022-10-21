# Contract to migrate between old and new pools
from vyper.interfaces import ERC20

N_COINS: constant(int128) = 2
ZERO256: constant(uint256) = 0  # This hack is really bad XXX
ZEROS: constant(uint256[N_COINS]) = [ZERO256, ZERO256]  # <- changeuint256

contract Old:
    def remove_liquidity(_amount: uint256, deadline: timestamp,
                         min_amounts: uint256[N_COINS]): modifying

contract New:
    def add_liquidity(amounts: uint256[N_COINS],
                      min_mint_amount: uint256): modifying
    def calc_token_amount(
        amounts: uint256[N_COINS], deposit: bool) -> uint256: constant

old: Old
new: New
old_token: ERC20
new_token: ERC20

coins: public(address[N_COINS])


@public
def __init__(_old: address, _old_token: address,
             _new: address, _new_token: address,
             _coins: address[N_COINS]):
    self.old = Old(_old)
    self.new = New(_new)
    self.old_token = ERC20(_old_token)
    self.new_token = ERC20(_new_token)
    self.coins = _coins


@public
@nonreentrant('lock')
def migrate():
    old_token_amount: uint256 = self.old_token.balanceOf(msg.sender)
    assert_modifiable(
        self.old_token.transferFrom(msg.sender, self, old_token_amount))
    self.old.remove_liquidity(old_token_amount, block.timestamp + 86400, ZEROS)

    balances: uint256[N_COINS] = ZEROS
    for i in range(N_COINS):
        balances[i] = ERC20(self.coins[i]).balanceOf(self)
        ERC20(self.coins[i]).approve(self.new, balances[i])

    min_mint_amount: uint256 = 0
    if self.new_token.totalSupply() > 0:
        min_mint_amount = self.new.calc_token_amount(balances, True)
        min_mint_amount = min_mint_amount * 999 / 1000

    self.new.add_liquidity(balances, min_mint_amount)

    new_mint_amount: uint256 = self.new_token.balanceOf(self)

    assert new_mint_amount > 99 * old_token_amount / 100, "High slippage alert"

    assert_modifiable(
        self.new_token.transfer(msg.sender, new_mint_amount))
