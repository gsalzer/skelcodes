pragma solidity 0.6.1;

interface IERC20 {
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function decimals() external view returns (uint256 digits);

    function totalSupply() external view returns (uint256 supply);
}

contract Wrapper {

    IERC20 internal constant ETH_TOKEN_ADDRESS = IERC20(
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
    );
    
    function getBalances(address reserve, IERC20[] calldata tokens) external view returns(uint[] memory) {
        uint[] memory result = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            uint balance = 0;
            if (tokens[i] == ETH_TOKEN_ADDRESS) {
                balance = reserve.balance;
            } else {
                (bool success, bytes memory data) = address(tokens[i]).staticcall(
                    abi.encode(
                        "balanceOf(address)",
                        reserve
                    )
                );
                if (success) {
                    balance = toUint256(data, 0);
                }
            }

            result[i] = balance;
        }
        return result;
    }

    function toUint256(bytes memory _bytes, uint _start) internal pure returns(uint) {
        require(_bytes.length >= (_start + 32), "Read out of bounds");
        uint tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }
}
