// SPDX-License-Identifier: MIT
 

interface MonaToken  {
    function balanceOf(address account) external view returns (uint256);
    function burn(uint256 amount) external;
}
