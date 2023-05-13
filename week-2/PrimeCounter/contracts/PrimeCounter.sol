// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title PrimeCounter
 * @author Shiva
 * @dev A contract to count the number of prime NFTs owned by an address
 */
contract PrimeCounter {
    ERC721Enumerable public nftCollection;

    /**
     * @dev Initializes the contract with the address of the NFT collection
     * @param _nftCollection The address of the NFT collection contract
     */
    constructor(address _nftCollection) {
        nftCollection = ERC721Enumerable(_nftCollection);
    }

    /**
     * @dev Counts the number of prime NFTs owned by the specified address
     * @param user The address for which to count the prime NFTs
     * @return The number of prime NFTs owned by the address
     */
    function countPrimeNFTs(address user) public view returns (uint256) {
        uint256 balance = nftCollection.balanceOf(user);
        uint256 count = 0;
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = nftCollection.tokenOfOwnerByIndex(user, i);
            if (isPrime(tokenId)) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Determines whether the specified number is prime
     * @param n The number to check
     * @return True if the number is prime, false otherwise
     */
    function isPrime(uint n) internal pure returns (bool) {
        if (n < 4) {
            return n > 1;
        }
        if (n % 2 == 0 || n % 3 == 0) {
            return false;
        }
        uint i = 5;
        uint sqrtN = uint(Math.sqrt(n));
        while (i < sqrtN + 1) {
            if (n % i == 0 || n % (i + 2) == 0) {
                return false;
            }
            i += 6;
        }
        return true;
    }
}
