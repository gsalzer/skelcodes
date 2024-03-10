// https://github.com/gnosis/contract-proxy-kit/blob/master/contracts/CPKFactory.sol
// Adjusted to fix bug: https://github.com/gnosis/contract-proxy-kit/issues/90
// Adjusted to have payable modifier
pragma solidity 0.5.12;

import {Enum} from "./Enum.sol";
import {GnosisSafeProxy} from "./GnosisSafeProxy.sol";
import {GnosisSafe} from "./GnosisSafe.sol";

contract CPKFactoryCustom {
    event ProxyCreation(GnosisSafeProxy proxy);

    function proxyCreationCode() external pure returns (bytes memory) {
        return type(GnosisSafeProxy).creationCode;
    }

    function createProxyAndExecTransaction(
        address masterCopy,
        uint256 saltNonce,
        address fallbackHandler,
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    )
        external
        payable
        returns (bool execTransactionSuccess)
    {
        GnosisSafe proxy;
        bytes memory deploymentData = abi.encodePacked(
            type(GnosisSafeProxy).creationCode,
            abi.encode(masterCopy)
        );
        bytes32 salt = keccak256(abi.encode(msg.sender, saltNonce));
        // solium-disable-next-line security/no-inline-assembly

        // Deploy Proxy with create2
        assembly {
            proxy := create2(0x0, add(0x20, deploymentData), mload(deploymentData), salt)
        }
        require(address(proxy) != address(0), "create2 call failed");

        {
            address[] memory tmp = new address[](1);
            tmp[0] = address(this);

            // Setup Proxy with CPKFactory as owner
            proxy.setup(
                tmp,  // [CPKFactory]
                1,
                address(0),
                "",
                fallbackHandler,
                address(0),
                0,
                address(0)
            );
        }

        // Exec arbitrary Logic (could use multisend)
        execTransactionSuccess = proxy.execTransaction.value(msg.value)(
            to,
            value,
            data,
            operation,
            0,
            0,
            0,
            address(0),
            address(0),
            abi.encodePacked(uint(address(this)), uint(0), uint8(1))
        );
        require(execTransactionSuccess, "CPKFactoryCustom.create.execTransaction: failed");

        // SwapOwner from CPKFactory to msg.sender
        execTransactionSuccess = proxy.execTransaction(
            address(proxy), 0,
            abi.encodeWithSignature(
                "swapOwner(address,address,address)",
                address(1),  // prevOwner in linked list (SENTINEL)
                address(this),  // oldOwner (CPKFactory)
                msg.sender  // newOwner (User/msg.sender)
            ),
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            address(0),
            abi.encodePacked(uint(address(this)), uint(0), uint8(1))
        );
        require(execTransactionSuccess, "CPKFactoryCustom.create.swapOwner: failed");

        emit ProxyCreation(GnosisSafeProxy(address(proxy)));
   }
}
