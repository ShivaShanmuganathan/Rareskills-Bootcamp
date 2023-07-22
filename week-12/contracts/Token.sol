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
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        bool status = super.transferFrom(sender, recipient, amount);

        bytes memory b = abi.encodeCall(
            IReceiver.onTokenTransfer,
            (recipient, amount)
        );
        (bool success, ) = sender.call(b);
        emit Log("Token Transfer", success);
        return status;
    }

    // function mint
}
