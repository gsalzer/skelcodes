# @version 0.2.12
# @author skozin <info@lido.fi>
# @licence MIT

@external
@view
def total_shares_burnt() -> uint256:
    # currently, applying insurance is not supported by the protocol
    return 0
