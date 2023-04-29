// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC1363, ERC20} from "erc-payable-token/contracts/token/ERC1363/ERC1363.sol";

contract SanctionedToken is ERC1363 {
    mapping(address => bool) public blacklist;
    address public immutable admin;

    event UserBlacklisted(address indexed user);
    event UserWhitelisted(address indexed wallet);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply
    ) ERC20(_name, _symbol) {
        // set initial supply, and admin
        _mint(msg.sender, _initialSupply);
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    /**
     * Add address to blacklist
     *
     */
    function addToBlacklist(address user) public onlyAdmin {
        require(!blacklist[user], "User already blacklisted");
        blacklist[user] = true;
        emit UserBlacklisted(user);
    }

    /**
     * Remove address from blacklist.
     */
    function removeFromBlacklist(address user) public onlyAdmin {
        require(blacklist[user], "User not blacklisted");
        blacklist[user] = false;
        emit UserWhitelisted(user);
    }

    /**
     * Checks the sanctioned status of any to/from address before any transfer.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal view override {
        require(!blacklist[from] && !blacklist[to], "User is blacklisted");
    }
}
