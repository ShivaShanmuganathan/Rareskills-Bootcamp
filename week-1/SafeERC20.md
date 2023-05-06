# SafeERC20
### Why does the SafeERC20 program exist and when should it be used?

- Return Value Handling: SafeERC20 library ensures proper return value handling of ERC20 token functions, preventing token loss and unexpected contract behavior.

- Reentrancy Protection: SafeERC20 library protects against reentrancy attacks by using mutex locks, ensuring token transfers are completed before external calls are made.