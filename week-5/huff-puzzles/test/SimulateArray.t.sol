// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {HuffConfig} from "foundry-huff/HuffConfig.sol";
import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";
import {NonMatchingSelectorHelper} from "./test-utils/NonMatchingSelectorHelper.sol";

interface SimulateArray {
    function pushh(uint256 num) external;

    function popp() external;

    function read(uint256 index) external view returns (uint256);

    function length() external view returns (uint256);

    function write(uint256 index, uint256 num) external;
}

contract SimulateArrayTest is Test, NonMatchingSelectorHelper {
    SimulateArray public simulateArray;

    function setUp() public {
        simulateArray = SimulateArray(
            HuffDeployer.config().deploy("SimulateArray")
        );
    }

    function testSimulateArrayReverts() external {
        assertEq(
            simulateArray.length(),
            0,
            "length is initially meant to be 0"
        );

        vm.expectRevert(bytes4(keccak256("ZeroArray()")));
        simulateArray.popp();

        vm.expectRevert(bytes4(keccak256("OutOfBounds()")));
        simulateArray.read(0);

        vm.expectRevert(bytes4(keccak256("OutOfBounds()")));
        simulateArray.write(0, 1);
    }

    function testSimulateArray() external {
        assertEq(
            simulateArray.length(),
            0,
            "length is initially meant to be 0"
        );

        simulateArray.pushh(42);
        assertEq(simulateArray.length(), 1, "expected length to be 1");
        assertEq(simulateArray.read(0), 42, "expected arr[0] to be 42");

        simulateArray.pushh(24);
        assertEq(simulateArray.length(), 2, "expected length to be 2");
        assertEq(simulateArray.read(0), 42, "expected arr[0] to be 42");
        assertEq(simulateArray.read(1), 24, "expected arr[1] to be 24");

        simulateArray.write(0, 122);
        assertEq(simulateArray.length(), 2, "expected length to be 2");
        assertEq(simulateArray.read(0), 122, "expected arr[0] to be 122");
        assertEq(simulateArray.read(1), 24, "expected arr[1] to be 24");

        simulateArray.write(1, 346);
        assertEq(simulateArray.length(), 2, "expected length to be 2");
        assertEq(simulateArray.read(0), 122, "expected arr[0] to be 122");
        assertEq(simulateArray.read(1), 346, "expected arr[1] to be 346");

        simulateArray.popp();
        assertEq(simulateArray.length(), 1, "expected length to be 1");
        assertEq(simulateArray.read(0), 122, "expected arr[0] to be 122");
        vm.expectRevert(bytes4(keccak256("OutOfBounds()")));
        simulateArray.read(1);
    }

    /// @notice Test that a non-matching selector reverts
    function testNonMatchingSelector(bytes32 callData) public {
        bytes4[] memory func_selectors = new bytes4[](5);
        func_selectors[0] = SimulateArray.pushh.selector;
        func_selectors[1] = SimulateArray.popp.selector;
        func_selectors[2] = SimulateArray.read.selector;
        func_selectors[3] = SimulateArray.length.selector;
        func_selectors[4] = SimulateArray.write.selector;

        bool success = nonMatchingSelectorHelper(
            func_selectors,
            callData,
            address(simulateArray)
        );
        assert(!success);
    }
}


// Runtime bytecode
// 60003560e01c80635edfe85d1461004d5780636a57dbc71461005c578063ed2e5a971461005d5780631f7b6d321461005e57639c0e3f7a1461005f575b60006000fd5b600160005260206000f35b60043560005460010180600055555b5b5b5b

// Input calldata for pushh
// calldata: 0x5edfe85d000000000000000000000000000000000000000000000000000000000000002a
// calldata: 0x5edfe85d0000000000000000000000000000000000000000000000000000000000000018
// pushh: 0x5edfe85d
// 4: 0000000000000000000000000000000000000000000000000000000000000004
// 42: 000000000000000000000000000000000000000000000000000000000000002a
// 24: 0000000000000000000000000000000000000000000000000000000000000018
// 122: 000000000000000000000000000000000000000000000000000000000000007a
// 346: 000000000000000000000000000000000000000000000000000000000000015a
// 534


// Runtime bytcode 2
// 60003560e01c80635edfe85d1461004d5780636a57dbc714610066578063ed2e5a97146100755780631f7b6d321461007657639c0e3f7a14610077575b60006000fd5b600160005260206000f35b6004356000546001018060005555600060005260006000f35b60005460008155600190036000555b5b5b

// Input calldata for popp
// calldata: 0x6a57dbc7
// popp: 0x6a57dbc7


// Runtime bytecode 3
// 60003560e01c80635edfe85d1461004d5780636a57dbc71461005d578063ed2e5a971461006d5780631f7b6d321461007d57639c0e3f7a1461007e575b60006000fd5b600160005260206000f35b6004356000546001018060005555005b6000546000815560019003600055005b6004356001015460005260206000f35b5b

// Input calldata for read
// calldata: 0xed2e5a970000000000000000000000000000000000000000000000000000000000000000
// calldata2: 0xed2e5a970000000000000000000000000000000000000000000000000000000000000001
// read: 0xed2e5a97


// Runtime Bytecode 3
// 60003560e01c80635edfe85d1461004d5780636a57dbc71461005d578063ed2e5a971461009d5780631f7b6d32146100e157639c0e3f7a146100ed575b60006000fd5b600160005260206000f35b6004356000546001018060005555005b6000548015610073576000815560019003600055005b7ff0ef74700000000000000000000000000000000000000000000000000000000060005260046000fd5b6000546004358091116100d4577fb4120f140000000000000000000000000000000000000000000000000000000060005260046000525b6001015460005260206000f35b60005460005260206000f35b600054600435809111610124577fb4120f140000000000000000000000000000000000000000000000000000000060005260046000525b6001016024359055
// Calldata
// length calldata: 0x1f7b6d32
// popp calldata: 0x6a57dbc7    [Error] revert
// read calldata: 0xed2e5a970000000000000000000000000000000000000000000000000000000000000000




// OG bytecode
// 60003560e01c80635edfe85d1461004d5780636a57dbc714610061578063ed2e5a97146100a55780631f7b6d32146100e957639c0e3f7a146100f5575b60006000fd5b600160005260206000f35b600435600054600101806000555560006000f35b600054801561007b57600081556001900360005560006000f35b7ff0ef74700000000000000000000000000000000000000000000000000000000060005260046000fd5b6000546004358091116100dc577fb4120f140000000000000000000000000000000000000000000000000000000060005260046000fd5b6001015460005260206000f35b60005460005260206000f35b60005460043580911161012c577fb4120f140000000000000000000000000000000000000000000000000000000060005260046000525b6001016024359055