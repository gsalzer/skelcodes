// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface ITrinity {
  function alchemy (  ) external;
  function getLastAlchemy (  ) external view returns ( uint256 );
  function getAlchemyInterval (  ) external view returns ( uint256 );
  function getMinTokenForAlchemy (  ) external view returns ( uint256 );
}
