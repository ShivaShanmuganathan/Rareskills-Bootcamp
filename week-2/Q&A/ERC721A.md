# ERC721A
## How does ERC721A save gas?

- ERC721A uses a single storage slot to represent multiple NFTs, which reduces the storage requirements for NFT contracts and saves gas.
- ERC721A also introduces batch minting and batch transfers, allowing multiple NFTs to be minted or transferred in a single transaction.
- In addition to batch minting and batch transfers, ERC721A also introduces other gas-saving features such as batch burning and batch approvals.

## Where does it add cost?
- The tradeoff of the ERC721A contract design is that transferFrom and safeTransferFrom transactions cost more gas, which means it may cost more to gift or sell an ERC721A NFT after minting.

## Why shouldn’t ERC721Enumerable’s implementation be used on-chain?
- One of the primary disadvantages of using ERC721Enumerable is that it adds an additional storage cost. 
- ERC721Enumerable uses redundant storage, which drives up the costs of not only minting tokens but also transferring them.
- ERC721Enumerable optimizes read functions to the detriment of write functions.
