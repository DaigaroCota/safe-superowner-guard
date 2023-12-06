// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/StdUtils.sol";
import {SuperOwnerGuard} from "../src/SuperOwnerGuard.sol";
import {MockGnosisSafe, GnosisSafe} from "./mocks/MockGnosisSafe.sol";
import {Enum} from "@safe-contracts/common/Enum.sol";
import {FallbackManager} from "@safe-contracts/base/FallbackManager.sol";
import {GuardManager} from "@safe-contracts/base/GuardManager.sol";
import {OwnerManager} from "@safe-contracts/base/OwnerManager.sol";

contract SuperOwnerGuardTest is Test {
    VmSafe.Wallet public Alice;
    VmSafe.Wallet public Bob;
    VmSafe.Wallet public Charlie;
    address[] private _safeOwners;

    GnosisSafe public safe;
    address public fallbackManager;

    SuperOwnerGuard public guard;
    bytes4[] public selectors;
    // From @safe-contracts/contracts/base/OwnerManager.sol
    // cast sig 'addOwnerWithThreshold(address,uint256)'
    bytes4 internal constant addOwnerWithThreshold = 0x0d582f13;
    // cast sig 'removeOwner(address,address,uint256)'
    bytes4 internal constant removeOwner = 0xf8dc5dd9;
    // cast sig 'swapOwner(address,address,address)'
    bytes4 internal constant swapOwner = 0xe318b52b;
    // cast sig 'changeThreshold(uint256)'
    bytes4 internal constant changeThreshold = 0x694e80c3;
    // cast sig 'setSuperOwner(address,bool)'

    // From src/contracts/SuperOwnerGuard.sol
    bytes4 internal constant setSuperOwner = 0xf282e9ff;
    // cast sig 'setSuperRestrictedSelector(bytes4,bool)'
    bytes4 internal constant setSuperRestrictedSelector = 0x2bcf063a;

    function setUp() public {
        Alice = vm.createWallet("Alice");
        Bob = vm.createWallet("Bob");
        Charlie = vm.createWallet("Charlie");

        _safeOwners.push(Alice.addr);
        _safeOwners.push(Bob.addr);

        fallbackManager = address(new FallbackManager());
        safe = new MockGnosisSafe();

        safe.setup(
            _safeOwners,
            2,
            0x0000000000000000000000000000000000000000,
            "",
            fallbackManager,
            0x0000000000000000000000000000000000000000,
            0,
            payable(0x0000000000000000000000000000000000000000)
        );

        address[] memory superOwners = new address[](1);
        superOwners[0] = Alice.addr;
        selectors.push(addOwnerWithThreshold);
        selectors.push(removeOwner);
        selectors.push(swapOwner);
        selectors.push(changeThreshold);
        selectors.push(setSuperOwner);
        selectors.push(setSuperRestrictedSelector);

        guard = new SuperOwnerGuard(address(safe), superOwners);

        bytes memory data = abi.encodeWithSelector(GuardManager.setGuard.selector, address(guard));

        bytes32 safeTxHash = safe.getTransactionHash(
            address(safe), // to
            0, // value
            data, // data
            Enum.Operation.Call, // operation
            0, // safeTxGas
            0, // baseGase
            0, // gasPrice
            address(0), // gasToken
            address(0), // refundReceiver
            safe.nonce() // nonce
        );

        bytes memory aliceSignature = generate_signature(safeTxHash, Alice.privateKey);
        bytes memory bobSignature = generate_signature(safeTxHash, Bob.privateKey);
        // Signatures must be added in reverse order as signers were added during setup.
        bytes memory signatures = abi.encodePacked(bobSignature, aliceSignature);

        safe.execTransaction(
            address(safe), // to
            0, // value
            data, // data
            Enum.Operation.Call, // operation
            0, // safeTxGas
            0, // baseGase
            0, // gasPrice
            address(0), // gasToken
            payable(address(0)), // refundReceiver
            signatures // nonce
        );
    }

    function test_safeOwners() public {
        assertEq(safe.isOwner(Alice.addr), true);
        assertEq(safe.isOwner(Bob.addr), true);
        assertEq(safe.isOwner(Charlie.addr), false);
    }

    function test_safeHasGuard() public {
        address checkGuard = MockGnosisSafe(payable(address(safe))).getGuardPublic();
        assertEq(checkGuard, address(guard));
    }

    function test_safeWithdraw() public {
        uint256 amount = 10 ether;
        deal(address(safe), amount);

        bytes memory data = "";

        bytes32 safeTxHash = safe.getTransactionHash(
            Charlie.addr, // to
            amount, // value
            data, // data
            Enum.Operation.Call, // operation
            0, // safeTxGas
            0, // baseGase
            0, // gasPrice
            address(0), // gasToken
            address(0), // refundReceiver
            safe.nonce() // nonce
        );

        bytes memory aliceSignature = generate_signature(safeTxHash, Alice.privateKey);
        bytes memory bobSignature = generate_signature(safeTxHash, Bob.privateKey);
        // Signatures must be added in reverse order as signers were added during setup.
        bytes memory signatures = abi.encodePacked(bobSignature, aliceSignature);

        safe.execTransaction(
            Charlie.addr, // to
            amount, // value
            data, // data
            Enum.Operation.Call, // operation
            0, // safeTxGas
            0, // baseGase
            0, // gasPrice
            address(0), // gasToken
            payable(address(0)), // refundReceiver
            signatures // nonce
        );

        assertEq(Charlie.addr.balance, amount);
    }

    function test_guardSuperUser() public {
        assertEq(guard.isSuperOwner(Alice.addr), true);
    }

    function test_superRestrictedSelectors() public {
        assertEq(guard.superRestrictedSelectors(addOwnerWithThreshold), true);
        assertEq(guard.superRestrictedSelectors(removeOwner), true);
        assertEq(guard.superRestrictedSelectors(swapOwner), true);
        assertEq(guard.superRestrictedSelectors(changeThreshold), true);
    }

    function test_notSuperUserCallsSelector() public {
        bytes memory data = abi.encodeWithSelector(OwnerManager.addOwnerWithThreshold.selector, Charlie.addr, 2);

        bytes32 safeTxHash = safe.getTransactionHash(
            address(safe), // to
            0, // value
            data, // data
            Enum.Operation.Call, // operation
            0, // safeTxGas
            0, // baseGase
            0, // gasPrice
            address(0), // gasToken
            address(0), // refundReceiver
            safe.nonce() // nonce
        );

        bytes memory aliceSignature = generate_signature(safeTxHash, Alice.privateKey);
        bytes memory bobSignature = generate_signature(safeTxHash, Bob.privateKey);
        // Signatures must be added in reverse order as signers were added during setup.
        bytes memory signatures = abi.encodePacked(bobSignature, aliceSignature);

        vm.expectRevert(SuperOwnerGuard.SuperOwnerGuard_checkTransaction_onlyexecutableBySuperOwner.selector);
        vm.prank(Bob.addr);
        safe.execTransaction(
            address(safe), // to
            0, // value
            data, // data
            Enum.Operation.Call, // operation
            0, // safeTxGas
            0, // baseGase
            0, // gasPrice
            address(0), // gasToken
            payable(address(0)), // refundReceiver
            signatures // nonce
        );

        vm.expectRevert(SuperOwnerGuard.SuperOwnerGuard_checkTransaction_onlyexecutableBySuperOwner.selector);
        safe.execTransaction(
            address(safe), // to
            0, // value
            data, // data
            Enum.Operation.Call, // operation
            0, // safeTxGas
            0, // baseGase
            0, // gasPrice
            address(0), // gasToken
            payable(address(0)), // refundReceiver
            signatures // nonce
        );
    }

    function test_superUserCallsSelector() public {
        bytes memory data = abi.encodeWithSelector(OwnerManager.addOwnerWithThreshold.selector, Charlie.addr, 2);

        bytes32 safeTxHash = safe.getTransactionHash(
            address(safe), // to
            0, // value
            data, // data
            Enum.Operation.Call, // operation
            0, // safeTxGas
            0, // baseGase
            0, // gasPrice
            address(0), // gasToken
            address(0), // refundReceiver
            safe.nonce() // nonce
        );

        bytes memory aliceSignature = generate_signature(safeTxHash, Alice.privateKey);
        bytes memory bobSignature = generate_signature(safeTxHash, Bob.privateKey);
        // Signatures must be added in reverse order as signers were added during setup.
        bytes memory signatures = abi.encodePacked(bobSignature, aliceSignature);

        vm.prank(Alice.addr);
        safe.execTransaction(
            address(safe), // to
            0, // value
            data, // data
            Enum.Operation.Call, // operation
            0, // safeTxGas
            0, // baseGase
            0, // gasPrice
            address(0), // gasToken
            payable(address(0)), // refundReceiver
            signatures // nonce
        );

        address[] memory theOwners = safe.getOwners();

        assertEq(theOwners.length, 3);
    }

    function generate_signature(bytes32 digest, uint256 signerPrivKey) private pure returns (bytes memory signature) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivKey, digest);
        return abi.encodePacked(r, s, v);
    }
}
