// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC1363} from "erc-payable-token/contracts/token/ERC1363/ERC1363.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title BondCurveToken
/// @author Shiva
/// @notice This contract implements a linear bonding curve
/// @dev Please refrain from using this contract on mainnet without proper testing and auditing
contract BondCurveToken is ERC1363, Ownable {
    uint256 public constant priceSlope = 0.1 gwei;
    uint256 public constant basePrice = 0.01 ether;
    uint public maxSupply;
    mapping(address => uint) public depositTime;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply
    ) ERC20(_name, _symbol) {
        maxSupply = _maxSupply;
    }

    /// @notice Buy tokens with ether
    /// @param amount uint256 Amount of token to buy
    function buy(uint256 amount) external payable {
        /// @dev Require the amount of ether sent to be equal to the price of the tokens
        require(
            msg.value == getBuyPrice(amount),
            "msg.value is not equal to price"
        );
        /// @dev Require the user to not have an existing deposit
        require(depositTime[msg.sender] == 0, "User already has a deposit");
        depositTime[msg.sender] = block.timestamp;
        _mint(msg.sender, amount);
    }

    /**
     * @notice Automatically sell tokens when transferring to the contract
     * @param operator address The address which called `transferAndCall` or `transferFromAndCall` function
     * @param from address The address which are token transferred from
     * @param value uint256 The amount of tokens transferred
     * @param data bytes Additional data with no specified format
     * @return bytes4 A bytes4 value indicating success or failure
     */
    function onTransferReceived(
        address operator,
        address from,
        uint256 value,
        bytes memory data
    ) external returns (bytes4) {
        /// @dev Require the user to have an existing deposit
        require(depositTime[msg.sender] > 0, "User does not have a deposit");
        /// @dev Require the user to have waited for at least 10 minutes since their deposit time
        require(
            (depositTime[msg.sender] + 10 minutes) < block.timestamp,
            "Please wait for 10 minutes since your deposit time."
        );
        depositTime[msg.sender] = 0;
        uint256 sellPrice = getSellPrice(value);
        _burn(address(this), value);
        payable(from).transfer(sellPrice);
        return
            bytes4(
                keccak256("onTransferReceived(address,address,uint256,bytes)")
            );
    }

    /**
     * @notice Calculate the ether price for a given amount of tokens
     * @param amount uint256 The amount of tokens to calculate the price for
     * @return uint256 The price in ether to pay for the given amount of tokens
     */
    function getBuyPrice(uint256 amount) public view returns (uint256) {
        uint256 currentPrice = basePrice +
            (priceSlope * totalSupply()) /
            10 ** decimals();
        uint256 buyPrice = ((amount * currentPrice)) / 10 ** decimals();
        return buyPrice;
    }

    /**
     * @notice Calculation of ether price for selling amount of tokens
     * @param amount uint256 The amount of tokens to calculate the sell price for
     * @return uint256 Price to receive for selling the given amount
     */
    function getSellPrice(uint256 amount) public view returns (uint256) {
        uint256 currentPrice = basePrice +
            (priceSlope * (totalSupply() - amount)) /
            10 ** decimals();
        uint256 sellPrice = ((amount * currentPrice)) / 10 ** decimals();
        return sellPrice;
    }

    /**
     * @dev Overrides the {_mint} function of the ERC20 contract to add a check for the maximum supply limit.
     * @param account The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(
            ERC20.totalSupply() + amount <= maxSupply,
            "ERC20Capped: cap exceeded"
        );
        super._mint(account, amount);
    }

    /**
     * @notice Burns a specific amount of tokens from the target address.
     * @dev The caller must be the owner of the contract.
     * @param to The address from which to burn the tokens.
     * @param amount The amount of tokens to burn.
     */
    function burn(address to, uint256 amount) public onlyOwner {
        _burn(to, amount);
    }

    /**
     * @notice Mints a specific amount of tokens to the target address.
     * @dev The caller must be the owner of the contract.
     * @param to The address to which to mint the tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
