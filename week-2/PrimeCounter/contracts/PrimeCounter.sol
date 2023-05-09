// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract PrimeCounter {
    ERC721Enumerable public nftCollection;

    constructor(address _nftCollection) {
        nftCollection = ERC721Enumerable(_nftCollection);
    }

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
