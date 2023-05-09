// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @title NFTCollection
 * @author Shiva
 */

contract NFTCollection is ERC721Enumerable, Ownable2Step {
    uint256 public immutable maxSupply;
    uint256 public tokenId = 1;

    constructor(
        string memory _name,
        string memory _symbol,
        uint96 _maxSupply
    ) ERC721(_name, _symbol) {
        maxSupply = _maxSupply;
    }

    /**
     * @notice Mint NFT with price = tokenPrice
     * @param _to address Address to which NFT will be minted
     * @return tokenId to let user know
     */
    function mint(address _to) public onlyOwner returns (uint256) {
        uint256 _tokenId = tokenId;
        require(_tokenId <= maxSupply, "Maximum token supply has been reached");
        unchecked {
            tokenId = _tokenId + 1;
        }
        _mint(_to, _tokenId);
        return _tokenId;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
