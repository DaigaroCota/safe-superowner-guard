// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {GnosisSafe} from "@safe-contracts/GnosisSafe.sol";

contract MockGnosisSafe is GnosisSafe {
    constructor() {
        threshold = 0;
    }

    function getGuardPublic() public view returns (address) {
        return getGuard();
    }
}
