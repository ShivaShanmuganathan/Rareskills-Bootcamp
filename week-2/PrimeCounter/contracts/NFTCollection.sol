// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @title NFTCollection
 * @author Shiva
 * @dev This contract is an ERC721 token with the added functionality of being able to enumerate its tokens.
 */
contract NFTCollection is ERC721Enumerable, Ownable2Step {
    uint256 public immutable maxSupply;
    uint256 public tokenId = 1;

    /**
     * @dev Constructor for the NFTCollection contract.
     * @param _name string Name of the token.
     * @param _symbol string Symbol of the token.
     * @param _maxSupply Maximum number of tokens that can be minted.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply
    ) ERC721(_name, _symbol) {
        maxSupply = _maxSupply;
    }

    /**
     * @dev Mint a new token to the given address.
     * @param _to address Address to which the new token will be minted.
     * @return uint256 The ID of the newly minted token.
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

    /**
     * @dev See {ERC721Enumerable-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
