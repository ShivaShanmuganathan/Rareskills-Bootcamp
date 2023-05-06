Create a markdown file about what problems ERC777 and ERC1363 solves. 
Why was ERC1363 introduced, and what issues are there with ERC777?

### Key problems that ERC777 addresses:
- More efficient transfers: ERC777 tokens have "atomic" transfers that combine the token transfer and callback functions into a single transaction, making transfers more efficient and reducing gas costs.

- The tokensToSend and tokensReceived hooks offer a way for both contracts and regular addresses to have control over and reject the tokens they send or receive.

### Issues with ERC777
- Complexity: ERC777 is a more complex token standard than ERC20, which could make it harder for developers to implement and for users to understand.

- Token Security: ERC777 introduces the concept of operators, allowing designated addresses to perform token operations on behalf of holders. While useful, this introduces security risks if operators are not managed properly or have unauthorized access.

### Key problems that ERC1363 addresses:
- ERC1363 tokens are an extension of the ERC20 standard, providing additional functionality through the use of callback functions to notify the receiver contract of token transfers or approvals.

- ERC1363 simplifies token interactions by enabling users to directly transfer tokens to contracts, reducing complexity and steps for a better user experience.

- ERC1363 tokens are backward compatible with ERC20, ensuring easy integration into existing Ethereum wallets, exchanges, and applications.






