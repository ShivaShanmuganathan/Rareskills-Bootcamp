// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC1363} from "erc-payable-token/contracts/token/ERC1363/ERC1363.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract BondCurveToken is ERC1363, Ownable{
    address public godAddress;
    uint begin_price = 1000 wei;
    uint end_price = 100 ether;
    uint maxSupply;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply
    ) ERC20(_name, _symbol) {
        maxSupply = _maxSupply;
    }

        /// @dev See {ERC20-_mint}
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function cap() public view returns(uint) {
        return maxSupply;
    }

    function getTokenPrice() public view returns(uint256) {
        //Beginning is in wei
        uint256 beginning = begin_price;
        //End is in wei
        uint256 end = end_price;
        //GrowthRate is in wei due to end and beginning being in wei
        uint256 growthRate = (end - beginning) / cap();
        //Returned value is in wei
        return begin_price + (growthRate * totalSupply());
    }

    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }
}
