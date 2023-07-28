// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IReceiver {
    function onTokenTransfer(address _to, uint256 _amount) external;
}

contract Token is ERC20, Ownable {
    event Log(string message, bool success);

    constructor() ERC20("Token", "TK") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override returns (bool) {
        super.transferFrom(from, to, value);
        transferAndCall(from, to, value);
        return true;
    }

    function transfer(
        address to,
        uint256 value
    ) public override returns (bool) {
        super.transfer(to, value);
        address from = msg.sender;
        transferAndCall(from, to, value);
        return true;
    }

    function transferAndCall(address from, address to, uint256 value) internal {
        // Encode the function selector and arguments
        bytes memory payload = abi.encodeWithSignature(
            "onTokenTransfer(address,uint256)",
            to,
            value
        );

        // Make the low-level call to the target contract
        (bool success, bytes memory result) = from.call(payload);
        emit Log("Token Transfer", success);
    }
}
