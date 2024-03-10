pragma solidity 0.5.17;

import './safeMath.sol';

interface Curve {
    function get_virtual_price() external view returns (uint);
}

interface Yearn {
    function getPricePerFullShare() external view returns (uint);
    function token() external view returns (address);
}

interface UnderlyingToken {
    function decimals() external view returns (uint8);
}

interface Compound {
    function exchangeRateStored() external view returns (uint);
    function underlying() external view returns (address);
}

interface Cream {
    function exchangeRateStored() external view returns (uint);
    function underlying() external view returns (address);
}

contract Normalizer {
    using SafeMath for uint;

    mapping(address => bool) public native;
    mapping(address => bool) public yearn;
    mapping(address => bool) public curve;
    mapping(address => address) public curveSwap;
    mapping(address => bool) public vaults;
    mapping(address => bool) public compound;
    mapping(address => bool) public cream;
    mapping(address => uint) public underlyingDecimals;

    constructor() public {
        native[0xdAC17F958D2ee523a2206206994597C13D831ec7] = true; // USDT
        native[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = true; // USDC
        native[0x4Fabb145d64652a948d72533023f6E7A623C7C53] = true; // BUSD
        native[0x0000000000085d4780B73119b644AE5ecd22b376] = true; // TUSD

        yearn[0xACd43E627e64355f1861cEC6d3a6688B31a6F952] = true; // vault yDAI (yDAI)
        yearn[0x37d19d1c4E1fa9DC47bD1eA12f742a0887eDa74a] = true; // vault yTUSD (yTUSD)
        yearn[0x597aD1e0c13Bfe8025993D9e79C69E1c0233522e] = true; // vault yUSDC (yUSDC)
        yearn[0x2f08119C6f07c006695E079AAFc638b8789FAf18] = true; // vault yUSDT (yUSDT)
        yearn[0x5dbcF33D8c2E976c6b560249878e6F1491Bca25c] = true; // vault yCRV (yUSD)
        yearn[0x9cA85572E6A3EbF24dEDd195623F188735A5179f] = true; // vault 3Crv (y3Crv)

        yearn[0xC2cB1040220768554cf699b0d863A3cd4324ce32] = true; // bDAI
        yearn[0x26EA744E5B887E5205727f55dFBE8685e3b21951] = true; // bUSDC
        yearn[0xE6354ed5bC4b393a5Aad09f21c46E101e692d447] = true; // bUSDT
        yearn[0x04bC0Ab673d88aE9dbC9DA2380cB6B79C4BCa9aE] = true; // bBUSD

        curve[0x845838DF265Dcd2c412A1Dc9e959c7d08537f8a2] = true; // cCompound
        curveSwap[0x845838DF265Dcd2c412A1Dc9e959c7d08537f8a2] = 0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56;
        curve[0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8] = true; // yCRV
        curveSwap[0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8] = 0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51;
        curve[0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490] = true; // 3Crv
        curveSwap[0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490] = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
        curve[0x3B3Ac5386837Dc563660FB6a0937DFAa5924333B] = true; // cBUSD
        curveSwap[0x3B3Ac5386837Dc563660FB6a0937DFAa5924333B] = 0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27;
        curve[0xC25a3A3b969415c80451098fa907EC722572917F] = true; // cSUSD
        curveSwap[0xC25a3A3b969415c80451098fa907EC722572917F] = 0xA5407eAE9Ba41422680e2e00537571bcC53efBfD;
        curve[0xD905e2eaeBe188fc92179b6350807D8bd91Db0D8] = true; // cPAX
        curveSwap[0xD905e2eaeBe188fc92179b6350807D8bd91Db0D8] = 0x06364f10B501e868329afBc005b3492902d6C763;

        compound[0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643] = true; // cDAI
        underlyingDecimals[0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643] = 1e18;
        compound[0x39AA39c021dfbaE8faC545936693aC917d5E7563] = true; // cUSDC
        underlyingDecimals[0x39AA39c021dfbaE8faC545936693aC917d5E7563] = 1e6;
        compound[0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9] = true; // cUSDT
        underlyingDecimals[0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9] = 1e6;

        cream[0x44fbeBd2F576670a6C33f6Fc0B00aA8c5753b322] = true; // crUSDC
        underlyingDecimals[0x44fbeBd2F576670a6C33f6Fc0B00aA8c5753b322] = 1e6;
        cream[0x797AAB1ce7c01eB727ab980762bA88e7133d2157] = true; // crUSDT
        underlyingDecimals[0x797AAB1ce7c01eB727ab980762bA88e7133d2157] = 1e6;
        cream[0x1FF8CDB51219a8838b52E9cAc09b71e591BC998e] = true; // crBUSD
        underlyingDecimals[0x1FF8CDB51219a8838b52E9cAc09b71e591BC998e] = 1e18;
        cream[0x4EE15f44c6F0d8d1136c83EfD2e8E4AC768954c6] = true; // crYUSD
        underlyingDecimals[0x4EE15f44c6F0d8d1136c83EfD2e8E4AC768954c6] = 1e18;
    }

    function getPrice(address token) public view returns (uint) {
        if (native[token]) {
            return 1e18;
        } else if (yearn[token]) {
            uint price = Yearn(token).getPricePerFullShare();
            // If it's yUSD or y3Crv, need to consider the price of underlying.
            if (token == 0x5dbcF33D8c2E976c6b560249878e6F1491Bca25c || token == 0x9cA85572E6A3EbF24dEDd195623F188735A5179f) {
                 address underlying = Yearn(token).token();
                 price = price.mul(getPrice(underlying)).div(1e18);
            }
            return price;
        } else if (curve[token]) {
            return Curve(curveSwap[token]).get_virtual_price();
        } else if (compound[token]) {
            return getCompoundPrice(token);
        } else if (cream[token]) {
            uint price = getCreamPrice(token);
            // If it's crYUSD, need to consider the price of underlying.
            if (token == 0x4EE15f44c6F0d8d1136c83EfD2e8E4AC768954c6) {
                address underlying = Cream(token).underlying();
                price = price.mul(getPrice(underlying)).div(1e18);
            }
            return price;
        } else {
            return uint(0);
        }
    }

    function getCompoundPrice(address token) public view returns (uint) {
        address underlying = Compound(token).underlying();
        uint8 decimals = UnderlyingToken(underlying).decimals();
        return Compound(token).exchangeRateStored().mul(1e8).div(uint(10) ** decimals);
    }

    function getCreamPrice(address token) public view returns (uint) {
        address underlying = Cream(token).underlying();
        uint8 decimals = UnderlyingToken(underlying).decimals();
        return Cream(token).exchangeRateStored().mul(1e8).div(uint(10) ** decimals);
    }
}

