// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract SuperOwnerGuard {
    uint256 public number;

    function checkTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures
    ) public {
        number = newNumber;
    }
}
