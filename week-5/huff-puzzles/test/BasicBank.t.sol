// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {HuffConfig} from "foundry-huff/HuffConfig.sol";
import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";
import "forge-std/console.sol";

interface BasicBank {
    function balanceOf(address user) external view returns (uint256);

    function withdraw(uint256 amount) external;
}

contract BasicBankTest is Test {
    BasicBank public basicBank;

    function setUp() public {
        basicBank = BasicBank(HuffDeployer.config().deploy("BasicBank"));
    }

    function testDeposit() external {
        vm.deal(address(this), 1 ether);
        (bool success, ) = address(basicBank).call{value: 1 ether}("");
        require(success, "deposit failed");
        assertEq(
            address(basicBank).balance,
            1 ether,
            "expected balance of basic bank contract to be 1 ether"
        );
        assertEq(
            basicBank.balanceOf(address(this)),
            1 ether,
            "expected balance of basic bank contract to be 1 ether"
        );
    }

    function testRemoveEther() external {
        vm.deal(address(this), 1 ether);
        vm.expectRevert();
        basicBank.withdraw(1);
        (bool success, ) = address(basicBank).call{value: 1 ether}("");
        require(success, "deposit failed");
        console.log("Reached Here");
        basicBank.withdraw(1 ether);
        assertEq(
            address(this).balance,
            1 ether,
            "expected balance of address(this) to be 1 ether"
        );
        console.log("Reached Here2");
        console.log("Bank Balance", basicBank.balanceOf(address(this)));
        console.log("Real Bank Balance", address(basicBank).balance);
        assertEq(
            basicBank.balanceOf(address(this)),
            0 ether,
            "expected balance of basic bank contract to be 1 ether"
        );
    }

    receive() external payable {}
}

// runtime bytecode
// 60003560e01c806370a082311461008a57632e1a7d4d1461004257341519610028575b60006000fd5b336000526020600020805434019055600160005260206000f35b3360005260206000208054801561002257600435908181146100675781811115610022575b600060006000600060043533600435f11561002257039055600160005260206000f35b60043560005260206000205460005260206000f3

// deposit 1 FINNEY into contract msg.value: 1000000000000000 COMPLETED
// call withdraw function 0x2e1a7d4d
    // calldata: 0x2e1a7d4d00000000000000000000000000000000000000000000000000038d7ea4c68000
// call balanceOf function 70a08231
    // calldata: 0x70a08231000000000000000000000000be862ad9abfe6f22bcb087716c7d89a26051f74c

// 000000000000000000000000be862ad9abfe6f22bcb087716c7d89a26051f74c