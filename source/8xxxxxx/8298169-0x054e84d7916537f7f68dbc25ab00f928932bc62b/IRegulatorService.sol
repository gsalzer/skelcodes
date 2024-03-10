pragma solidity 0.5.8;

interface IRegulatorService {
    function canMint(address to, string calldata iso, uint256 value) external view returns(bool);

    function canTransfer(address from, string calldata isoFrom, address to, string calldata isoTo, uint256 value) external view returns(bool);

    function canAddToWhitelist(address account, string calldata iso) external view returns(bool);

    function canRemoveFromWhitelist(address account, string calldata iso) external view returns(bool);

    function canRecoveryTokens(address from, address to) external view returns(bool);
}

