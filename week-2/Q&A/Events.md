# Events 

## How can OpenSea quickly determine which NFTs an address owns if most NFTs don’t use ERC721 enumerable? 
I think OpenSea determines which NFTs an address owns by subscribing to events emitted by the ERC721 contracts whenever an NFT is transferred.

## Explain how you would accomplish this if you were creating an NFT marketplace.
If I were creating an NFT marketplace, I would subscribe to the "Transfer" and "Approval" events. By indexing and querying these events, we would be able to determine the owner of an NFT without relying on the ERC721Enumerable interface. I would also consider using other methods, such as off-chain indexing and caching, to reduce the amount of on-chain queries necessary for determining NFT ownership.





