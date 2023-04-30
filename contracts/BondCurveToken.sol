// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC1363} from "erc-payable-token/contracts/token/ERC1363/ERC1363.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title BondCurveToken
/// @author Shiva
/// @notice This contract implements linear bonding curve
/// @dev Refrain from 
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
    /// @param amount uinst256 Amount of token to buy
    function buy(uint256 amount) external payable {
        require(
            msg.value == getBuyPrice(amount),
            "msg.value is not equal to price"
        );
        require(depositTime[msg.sender] == 0, "User already has a deposit");
        depositTime[msg.sender] = block.timestamp;
        _mint(msg.sender, amount);
    }

    /**
     * @notice automatic sell when tranfering to contract
     * @param operator address The address which called `transferAndCall` or `transferFromAndCall` function
     * @param from address The address which are token transferred from
     * @param value uint256 The amount of tokens transferred
     * @param data bytes Additional data with no specified format
     */
    function onTransferReceived(
        address operator,
        address from,
        uint256 value,
        bytes memory data
    ) external returns (bytes4) {
        require(depositTime[msg.sender] > 0, "User does not have a deposit");
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
     * @notice Calculation of ether price for amount
     * @param amount uint256 The amount of tokens to calculate price for
     * @return Price to pay for the given amount
     */
    function getBuyPrice(uint256 amount) public view returns (uint256) {
        uint256 currentPrice = basePrice +
            (priceSlope * totalSupply()) /
            10 ** decimals();
        uint256 buyPrice = ((amount * currentPrice)) / 10 ** decimals();
        return (buyPrice);
    }

    function getSellPrice(uint256 amount) public view returns (uint256) {
        uint256 currentPrice = basePrice +
            (priceSlope * (totalSupply() - amount)) /
            10 ** decimals();
        uint256 sellPrice = ((amount * currentPrice)) / 10 ** decimals();
        return (sellPrice);
    }

    function _mint(address account, uint256 amount) internal virtual override {
        require(
            ERC20.totalSupply() + amount <= maxSupply,
            "ERC20Capped: cap exceeded"
        );
        super._mint(account, amount);
    }

    function burn(address to, uint256 amount) public onlyOwner {
        _burn(to, amount);
    }

    /// @dev See {ERC20-_mint}
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
