// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "woke/console.sol";

interface Pair {
    function swapExactIn(
        address tokenIn,
        uint256 amountIn,
        address tokenOut
    ) external returns (uint256);

    function swapExactOut(
        address tokenIn,
        address tokenOut,
        uint256 amountOut
    ) external returns (uint256);

    function _getOutputAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) external pure returns (uint256);

    function _getInputAmount(
        uint256 outputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) external pure returns (uint256);

    function getReserveInAndOut(
        address tokenIn,
        address tokenOut
    )
        external
        view
        returns (
            uint256 reserveIn,
            uint256 reserveOut,
            address poolIn,
            address poolOut
        );
}

contract AMM is Ownable {
    address[] public pairs;
    mapping(address => address) public tokenToPool;

    bool private isSwapping;

    modifier nonReentrant() {
        require(!isSwapping, "Reentrant call");
        isSwapping = true;
        _;
        isSwapping = false;
    }

    function setTokenToPool(address token, address pool) external onlyOwner {
        tokenToPool[token] = pool;
    }

    function swapExactIn(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 pairIdx
    ) external nonReentrant {
        require(
            IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn),
            "Token transfer failed"
        );
        Pair pair = Pair(pairs[pairIdx]);

        uint256 amountOut = pair.swapExactIn(tokenIn, amountIn, tokenOut);
        require(
            IERC20(tokenOut).transfer(msg.sender, amountOut),
            "Token transfer failed"
        );
    }

    function swapExactOut(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 pairIdx
    ) external nonReentrant {
        Pair pair = Pair(pairs[pairIdx]);

        (uint256 reserveIn, uint256 reserveOut, , ) = pair.getReserveInAndOut(
            tokenIn,
            tokenOut
        );

        uint256 amountIn = pair._getInputAmount(
            amountOut,
            reserveIn,
            reserveOut
        );

        require(
            IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn),
            "Token transfer failed"
        );

        uint256 amountOutMin = pair.swapExactOut(tokenIn, tokenOut, amountOut);
        require(
            IERC20(tokenOut).transfer(msg.sender, amountOutMin),
            "Token transfer failed"
        );
    }

    function addPair(address pairAddress) external onlyOwner {
        pairs.push(pairAddress);
    }

    function setMaxApproval(
        address receiver,
        address token
    ) external onlyOwner {
        IERC20(token).approve(receiver, type(uint256).max);
    }
}
