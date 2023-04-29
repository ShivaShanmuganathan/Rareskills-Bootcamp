// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC1363, ERC20} from "erc-payable-token/contracts/token/ERC1363/ERC1363.sol";

contract TokenWithGodMode is ERC1363 {
    address public godAddress;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply
    ) ERC20(_name, _symbol) {
        // set initial supply, and admin
        _mint(msg.sender, _initialSupply);
        godAddress = msg.sender;
    }

    modifier onlyGod() {
        require(msg.sender == godAddress, "Only god can call this function");
        _;
    }

    function godTransfer(
        address from,
        address to,
        uint256 amount
    ) external onlyGod {
        _transfer(from, to, amount);
    }

    function setGod(address newGodAddress) external onlyGod {
        godAddress = newGodAddress;
    }
}
