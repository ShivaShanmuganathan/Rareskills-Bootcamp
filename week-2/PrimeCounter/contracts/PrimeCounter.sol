// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

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
    
    function isPrime(uint256 n) internal pure returns (bool) {
        if (n <= 1) {
            return false;
        }
        for (uint256 i = 2; i <= n / 2; i++) {
            if (n % i == 0) {
                return false;
            }
        }
        return true;
    }
}
