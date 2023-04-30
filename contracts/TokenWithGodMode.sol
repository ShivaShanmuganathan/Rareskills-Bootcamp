// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC1363, ERC20} from "erc-payable-token/contracts/token/ERC1363/ERC1363.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TokenWithGodMode
 * @dev A token contract where the god address has unrestricted access to transfer tokens.
 */
contract TokenWithGodMode is ERC1363, Ownable {
    address public godAddress;
    event SetNewGod(address indexed godAddress);

    /**
     * @dev Initializes the contract with an initial supply of tokens and sets the god address.
     * @param _name Name of the token.
     * @param _symbol Symbol of the token.
     * @param _initialSupply Initial supply of tokens.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, _initialSupply);
        godAddress = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the god address.
     */
    modifier onlyGod() {
        require(msg.sender == godAddress, "Only god can call this function");
        _;
    }

    /**
     * @dev Transfer tokens from one address to another using the god address.
     * @param from The address to transfer tokens from.
     * @param to The address to transfer tokens to.
     * @param amount The amount of tokens to transfer.
     */
    function godTransfer(
        address from,
        address to,
        uint256 amount
    ) external onlyGod {
        _transfer(from, to, amount);
    }

    /**
     * @dev Sets a new god address.
     * @param newGodAddress The address to set as the new god address.
     */
    function setGod(address newGodAddress) external onlyGod {
        godAddress = newGodAddress;
        emit SetNewGod(newGodAddress);
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     * @param to Address to mint tokens to.
     * @param amount Number of tokens to mint.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
