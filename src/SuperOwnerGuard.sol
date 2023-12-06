// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {GnosisSafe} from "@safe-contracts/GnosisSafe.sol";
import {Guard} from "@safe-contracts/base/GuardManager.sol";
import {Enum} from "@safe-contracts/common/Enum.sol";
import {console} from "forge-std/console.sol";

contract SuperOwnerGuard is Guard {
    /// Events
    event SetSuperOwner(address indexed owner, bool state);
    event SetSuperRestrictedSelector(bytes4 indexed selector, bool state);

    /// Custom errors
    error SuperOwnerGuard__checkZeroAddress_zeroAddress();
    error SuperOwnerGuard__setSuperRestrictedSelector_emptySelector();
    error SuperOwnerGuard__setSuperOwner_NotSafeOwner();
    error SuperOwnerGuard_checkTransaction_onlyexecutableBySuperOwner();
    error SuperOwnerGuard_onlySafe();

    bytes4 constant ZERO_SELECTOR = 0x000000;

    // From @safe-contracts/contracts/base/OwnerManager.sol
    // cast sig 'addOwnerWithThreshold(address,uint256)'
    bytes4 internal constant _addOwnerWithThreshold = 0x0d582f13;
    // cast sig 'removeOwner(address,address,uint256)'
    bytes4 internal constant _removeOwner = 0xf8dc5dd9;
    // cast sig 'swapOwner(address,address,address)'
    bytes4 internal constant _swapOwner = 0xe318b52b;
    // cast sig 'changeThreshold(uint256)'
    bytes4 internal constant _changeThreshold = 0x694e80c3;
    // cast sig 'setSuperOwner(address,bool)'

    // From src/contracts/SuperOwnerGuard.sol
    bytes4 internal constant __setSuperOwner = 0xf282e9ff;
    // cast sig 'setSuperRestrictedSelector(bytes4,bool)'
    bytes4 internal constant __setSuperRestrictedSelector = 0x2bcf063a;

    mapping(address => bool) public isSuperOwner;
    mapping(bytes4 => bool) public superRestrictedSelectors;

    GnosisSafe public immutable safe;

    modifier onlySafe() {
        if (msg.sender != address(safe)) {
            revert SuperOwnerGuard_onlySafe();
        }
        _;
    }

    constructor(address safe_, address[] memory superOwners) {
        _checkZeroAddress(safe_);
        safe = GnosisSafe(payable(safe_));
        uint256 len = superOwners.length;
        for (uint256 i = 0; i < len; i++) {
            _setSuperOwner(superOwners[i], true, GnosisSafe(payable(safe_)));
        }
        superRestrictedSelectors[_addOwnerWithThreshold] = true;
        superRestrictedSelectors[_removeOwner] = true;
        superRestrictedSelectors[_swapOwner] = true;
        superRestrictedSelectors[_changeThreshold] = true;
        superRestrictedSelectors[__setSuperOwner] = true;
        superRestrictedSelectors[__setSuperRestrictedSelector] = true;
    }

    function checkTransaction(
        address,
        uint256,
        bytes memory data,
        Enum.Operation,
        uint256,
        uint256,
        uint256,
        address,
        address payable,
        bytes memory,
        address msgSender
    ) public view override {
        bytes4 selector = _sliceFunctionSelector(data);
        if (selector != ZERO_SELECTOR && superRestrictedSelectors[selector] && !isSuperOwner[msgSender]) {
            revert SuperOwnerGuard_checkTransaction_onlyexecutableBySuperOwner();
        }
    }

    /**
     * @dev Unused method
     */
    function checkAfterExecution(bytes32, bool) external override {}

    function setSuperOwner(address owner, bool state) external onlySafe {
        _setSuperOwner(owner, state, safe);
    }

    function setSuperRestrictedSelector(bytes4 selector, bool state) external onlySafe {
        _setSuperRestrictedSelector(selector, state);
    }

    function _setSuperOwner(address owner, bool state, GnosisSafe safe_) internal {
        _checkZeroAddress(owner);
        if (!_checkIsOwnerInSafe(owner, safe_)) {
            revert SuperOwnerGuard__setSuperOwner_NotSafeOwner();
        }
        isSuperOwner[owner] = true;
        emit SetSuperOwner(owner, state);
    }

    function _setSuperRestrictedSelector(bytes4 selector, bool state) internal {
        if (selector == ZERO_SELECTOR) {
            revert SuperOwnerGuard__setSuperRestrictedSelector_emptySelector();
        }
        if (state) {
            superRestrictedSelectors[selector] = state;
        } else {
            delete superRestrictedSelectors[selector];
        }
        emit SetSuperRestrictedSelector(selector, state);
    }

    function _sliceFunctionSelector(bytes memory data) internal pure returns (bytes4 selector) {
        if (data.length < 4) {
            selector = ZERO_SELECTOR;
        } else {
            assembly {
                // Copy the first 4 bytes of 'data' into 'selector'
                // 'mload' loads a word (32 bytes) from the specified location
                selector := mload(add(data, 32))
            }
        }
    }

    function _checkIsOwnerInSafe(address addr, GnosisSafe safe_) internal view returns (bool) {
        return safe_.isOwner(addr);
    }

    function _checkZeroAddress(address addr) private pure {
        if (addr == address(0)) {
            revert SuperOwnerGuard__checkZeroAddress_zeroAddress();
        }
    }
}
