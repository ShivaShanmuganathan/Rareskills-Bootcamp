Create a markdown file about what problems ERC777 and ERC1363 solves. 
Why was ERC1363 introduced, and what issues are there with ERC777?

### Key problems that ERC777 addresses:
- More efficient transfers: ERC777 tokens have "atomic" transfers that combine the token transfer and callback functions into a single transaction, making transfers more efficient and reducing gas costs.

- The tokensToSend and tokensReceived hooks offer a way for both contracts and regular addresses to have control over and reject the tokens they send or receive.


### Key problems that ERC1363 addresses:
- ERC1363 tokens are an extension of the ERC20 standard, providing additional functionality through the use of callback functions to notify the receiver contract of token transfers or approvals.


- The tokensToSend and tokensReceived hooks offer a way for both contracts and regular addresses to have control over and reject the tokens they send or receive.

### Issues with ERC777
- Complexity: ERC777 is a more complex token standard than ERC20, which could make it harder for developers to implement and for users to understand.
