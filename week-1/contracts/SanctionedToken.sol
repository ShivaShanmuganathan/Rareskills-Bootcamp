// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC1363, ERC20} from "erc-payable-token/contracts/token/ERC1363/ERC1363.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @title SanctionedToken
 * @dev ERC20 token contract that allows blacklisting of specific addresses
 */
contract SanctionedToken is ERC1363, Ownable2Step {
    mapping(address => bool) public blacklist;
    address public immutable admin;

    event UserBlacklisted(address indexed user);
    event UserWhitelisted(address indexed user);

    /**
     * @dev Initializes the contract with a given name, symbol, and initial supply.
     * @param _name The name of the token.
     * @param _symbol The symbol of the token.
     * @param _initialSupply The initial supply of the token.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply
    ) ERC20(_name, _symbol) {
        // set initial supply, and admin
        _mint(msg.sender, _initialSupply);
        admin = msg.sender;
    }

    /**
     * @dev Modifier that only allows the admin to call a function.
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    /**
     * @notice Adds an address to the blacklist.
     * @dev Only accesssible by Admin
     * @param user The address to add to the blacklist.
     */
    function addToBlacklist(address user) external onlyAdmin {
        require(!blacklist[user], "User already blacklisted");
        blacklist[user] = true;
        emit UserBlacklisted(user);
    }

    /**
     * @notice Removes an address from the blacklist.
     * @dev Only accesssible by Admin
     * @param user The address to remove from the blacklist.
     */
    function removeFromBlacklist(address user) external onlyAdmin {
        require(blacklist[user], "User not blacklisted");
        blacklist[user] = false;
        emit UserWhitelisted(user);
    }

    /**
     * @dev Checks if either the sender or the recipient is blacklisted
     * @param from Address of the sender.
     * @param to Address of the recipient.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal view override {
        require(!blacklist[from] && !blacklist[to], "User is blacklisted");
    }

    /**
     * @notice Mints tokens and assigns them to the specified address.
     * @dev Only accesssible by Owner
     * @param to The address to assign the minted tokens to.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
