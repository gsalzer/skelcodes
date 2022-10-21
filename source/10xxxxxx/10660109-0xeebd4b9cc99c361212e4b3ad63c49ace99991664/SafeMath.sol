library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }
  function mult(uint256 x, uint256 y) internal pure returns (uint256) {
      if (x == 0) {
          return 0;
      }

      uint256 z = x * y;
      require(z / x == y, "Mult overflow");
      return z;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  function divRound(uint256 x, uint256 y) internal pure returns (uint256) {
      require(y != 0, "Div by zero");
      uint256 r = x / y;
      if (x % y != 0) {
          r = r + 1;
      }

      return r;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

