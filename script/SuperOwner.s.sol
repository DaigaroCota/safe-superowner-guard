// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

contract SuperOwnerScript is Script {
    bytes4[] public selectors;

    function setUp() public {
        // From @safe-contracts/contracts/base/OwnerManager.sol
        selectors.push(0x0d582f13); // cast sig 'addOwnerWithThreshold(address,uint256)'
        selectors.push(0xf8dc5dd9); // cast sig 'removeOwner(address,address,uint256)'
        selectors.push(0xe318b52b); // cast sig 'swapOwner(address,address,address)'
        selectors.push(0x694e80c3); // cast sig 'changeThreshold(uint256)'
    }

    function run() public {
        vm.broadcast();
    }
}
