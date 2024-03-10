// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {VariableDebtToken} from './VariableDebtToken.sol';
import {Ownable} from './Ownable.sol';
import {StringLib} from './StringLib.sol';

contract VariableTokensHelper is Ownable {
  address payable private pool;
  address private addressesProvider;
  event deployedContracts(address variableToken);

  constructor(address payable _pool, address _addressesProvider) public {
    pool = _pool;
    addressesProvider = _addressesProvider; 
  }

  function initDeployment(
    address[] calldata tokens,
    string[] calldata symbols,
    uint8[] calldata decimals
  ) external onlyOwner {
    require(tokens.length == symbols.length, 'Arrays not same length');
    require(pool != address(0), 'Pool can not be zero address');
    for (uint256 i = 0; i < tokens.length; i++) {
      emit deployedContracts(
        address(
          new VariableDebtToken(
            addressesProvider,
            tokens[i],
            StringLib.concat('Lever variable debt bearing ', symbols[i]),
            StringLib.concat('d', symbols[i]),
            decimals[i]
          )
        )
      );
    }
  }

}

