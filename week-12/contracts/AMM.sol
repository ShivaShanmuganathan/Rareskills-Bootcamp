// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface Pair {
    function swapExactIn(
        address tokenIn,
        uint256 amountIn,
        address tokenOut
    ) external;

    function swapExactOut(
        address tokenIn,
        address tokenOut,
        uint256 amountOut
    ) external;
}

contract AMM is Ownable {
    address[] public pairs;

    bool private isSwapping;

    modifier nonReentrant() {
        require(!isSwapping, "Reentrant call");
        isSwapping = true;
        _;
        isSwapping = false;
    }

    // constructor(address _tokenA, address _tokenB, to) {}

    function swapExactIn(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 pairIdx
    ) external nonReentrant {
        Pair pair = Pair(pairs[pairIdx]);
        pair.swapExactIn(tokenIn, amountIn, tokenOut);
    }

    function swapExactOut(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 pairIdx
    ) external nonReentrant {
        Pair pair = Pair(pairs[pairIdx]);
        pair.swapExactOut(tokenIn, tokenOut, amountOut);
    }

    function addPair(address pairAddress) external onlyOwner {
        pairs.push(pairAddress);
    }
}
