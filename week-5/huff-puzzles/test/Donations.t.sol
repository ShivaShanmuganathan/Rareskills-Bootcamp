// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {HuffConfig} from "foundry-huff/HuffConfig.sol";
import {HuffDeployer} from "foundry-huff/HuffDeployer.sol";

import {console} from "forge-std/console.sol";

interface Donations {
    function donated(address user) external view returns (uint256);
}

contract DonationsTest is Test {
    Donations public donations;

    function setUp() public {
        donations = Donations(HuffDeployer.config().deploy("Donations"));
    }

    function testDonations() public {
        // first party
        vm.deal(address(this), 1 ether);
        (bool success, bytes memory data) = address(donations).call{value: 0.5 ether}("");
        require(success, "call failed");
        assertEq(
            donations.donated(address(this)),
            0.5 ether,
            "expected donated balance of address(this) to be 0.5 ether"
        );
        (success, ) = address(donations).call{value: 0.2 ether}("");
        require(success, "call failed");
        assertEq(
            donations.donated(address(this)),
            0.7 ether,
            "expected donated balance of address(this) to be 0.7 ether"
        );

        // second party
        startHoax(address(0xCAFE), 1 ether);
        (success, ) = address(donations).call{value: 0.5 ether}("");
        require(success, "call failed");
        assertEq(
            donations.donated(address(0xCAFE)),
            0.5 ether,
            "expected donated balance of address(0xCAFE) to be 0.5 ether"
        );
        (success, ) = address(donations).call{value: 0.3 ether}("");
        require(success, "call failed");
        assertEq(
            donations.donated(address(0xCAFE)),
            0.8 ether,
            "expected donated balance of address(0xCAFE) to be 0.8 ether"
        );

        // try send 0
        (success, ) = address(donations).call{value: 0 ether}("");
        require(success, "call failed");
        assertEq(
            donations.donated(address(0xCAFE)),
            0.8 ether,
            "expected donated balance of address(0xCAFE) to be 0.8 ether"
        );
    }
}

// runtime bytecode
// 60003560e01c63fb690dcc1461002e5734151961001d575b60006000fd5b336000526020600020805434019055005b60043560005260206000205460005260206000f3

// caller
// 0xbe862ad9abfe6f22bcb087716c7d89a26051f74c

// input calldata
// 0xfb690dcc000000000000000000000000be862ad9abfe6f22bcb087716c7d89a26051f74c
// 000000000000000000000000be862ad9abfe6f22bcb087716c7d89a26051f74c
// be862ad9abfe6f22bcb087716c7d89a26051f74c
// be862ad9abfe6f22bcb087716c7d89a26051f74c