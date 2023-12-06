// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {SuperOwnerGuard} from "./SuperOwnerGuard.sol";

contract SuperOwnerGuardFactory {
    /// Events
    event CreatedSuperOwnerGuard(address indexed newGuard, address msgSender);

    function createGuard(address safe_, address[] memory superOwners) public returns (address) {
        SuperOwnerGuard guard = new SuperOwnerGuard(safe_, superOwners);
        emit CreatedSuperOwnerGuard(address(guard), msg.sender);
        return address(guard);
    }
}
