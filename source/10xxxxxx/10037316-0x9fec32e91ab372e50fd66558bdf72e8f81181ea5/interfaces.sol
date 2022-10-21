pragma solidity ^0.6.4;

interface DaiErc20 {
    function transfer(address, uint) external returns (bool);
    function transferFrom(address,address,uint256) external returns (bool);
    function approve(address,uint256) external returns (bool);
    function balanceOf(address) external view returns (uint);
    function allowance(address, address) external view returns (uint);
}


interface PotLike {
    function chi() external view returns (uint256);
    function rho() external view returns (uint256);
    function drip() external returns (uint256);
    function join(uint256) external;
    function exit(uint256) external;
    function pie(address) external view returns (uint256);

}

interface JoinLike {
    function join(address, uint256) external;
    function exit(address, uint256) external;
    function vat() external returns (VatLike);
    function dai() external returns (DaiErc20);

}


interface VatLike {
    function hope(address) external;
    function dai(address) external view returns (uint256);

}

interface cDaiErc20 {
    function mint(uint256) external returns (uint256);
    function redeem(uint) external returns (uint);
    function balanceOf(address) external view returns (uint);
}


