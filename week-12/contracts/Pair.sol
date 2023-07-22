// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "woke/console.sol";

interface Pool {
    function getReserve() external view returns (uint256);

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;
}

contract Pair is Ownable {
    address public poolA;
    address public poolB;
    address public ammContract; // The address of the AMM contract
    mapping(address => address) public tokenToPool;

    modifier isAMM() {
        require(
            msg.sender == ammContract,
            "Not authorized. Only AMM contract can call this function."
        );
        _;
    }

    constructor(address _poolA, address _poolB, address _ammContract) {
        poolA = _poolA;
        poolB = _poolB;
        ammContract = _ammContract;
    }

    function setTokenToPool(address token, address pool) external onlyOwner {
        tokenToPool[token] = pool;
    }

    function _getOutputAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        require(inputAmount > 0, "Input amount must be greater than 0");
        require(inputReserve > 0 && outputReserve > 0, "Invalid reserves");

        // The constant product formula: inputReserve * outputReserve = (inputReserve - x) * (outputReserve + y)
        // x = inputReserve - (inputReserve * outputReserve) / (outputReserve + y)

        // Rearranging the formula to solve for 'y'
        uint256 outputAmount = inputReserve -
            (inputReserve * outputReserve) /
            (outputReserve + inputAmount);

        require(outputAmount > 0, "Invalid output amount");

        return outputAmount;
    }

    function _getInputAmount(
        uint256 outputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        require(outputAmount > 0, "Output amount must be greater than 0");
        require(inputReserve > 0 && outputReserve > 0, "Invalid reserves");
        // inputReserve * outputReserve = (inputReserve - x) * (outputReserve + y)
        // y = (inputReserve * outputReserve) / (inputReserve - x) - outputReserve

        // Rearranging the formula to solve for 'x'
        uint256 inputAmount = ((inputReserve * outputReserve) /
            (inputReserve - outputAmount)) - outputReserve;

        require(inputAmount > 0, "Invalid input amount");

        return inputAmount;
    }

    function swapExactIn(
        address tokenIn,
        uint256 amountIn,
        address tokenOut
    ) external isAMM returns (uint256) {
        require(
            tokenToPool[tokenIn] == poolA || tokenToPool[tokenIn] == poolB,
            "Invalid tokenIn"
        );
        require(
            tokenToPool[tokenOut] == poolA || tokenToPool[tokenOut] == poolB,
            "Invalid tokenOut"
        );
        require(amountIn > 0, "Amount must be greater than 0");

        (
            uint256 reserveIn,
            uint256 reserveOut,
            address poolIn,
            address poolOut
        ) = getReserveInAndOut(tokenIn, tokenOut);

        uint256 amountOut = _getOutputAmount(amountIn, reserveIn, reserveOut);

        require(
            IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn),
            "Token transfer failed"
        );
        Pool(poolIn).deposit(amountIn);

        Pool(poolOut).withdraw(amountOut);
        require(
            IERC20(tokenOut).transfer(msg.sender, amountOut),
            "Token transfer failed"
        );
        return amountOut;
    }

    function swapExactOut(
        address tokenIn,
        address tokenOut,
        uint256 amountOutMin
    ) external isAMM returns (uint256) {
        require(
            tokenToPool[tokenIn] == poolA || tokenToPool[tokenIn] == poolB,
            "Invalid tokenIn"
        );
        require(
            tokenToPool[tokenOut] == poolA || tokenToPool[tokenOut] == poolB,
            "Invalid tokenOut"
        );
        require(amountOutMin > 0, "Amount must be greater than 0");

        (
            uint256 reserveIn,
            uint256 reserveOut,
            address poolIn,
            address poolOut
        ) = getReserveInAndOut(tokenIn, tokenOut);

        uint256 amountIn = _getInputAmount(amountOutMin, reserveIn, reserveOut);

        require(
            IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn),
            "Token transfer failed"
        );

        Pool(poolIn).deposit(amountIn);
        Pool(poolOut).withdraw(amountOutMin);
        require(
            IERC20(tokenOut).transfer(msg.sender, amountOutMin),
            "Token transfer failed"
        );

        return amountOutMin;
    }

    function setMaxApproval(
        address receiver,
        address token
    ) external onlyOwner {
        IERC20(token).approve(receiver, type(uint256).max);
    }

    function getReserveInAndOut(
        address tokenIn,
        address tokenOut
    )
        public
        view
        returns (
            uint256 reserveIn,
            uint256 reserveOut,
            address poolIn,
            address poolOut
        )
    {
        if (tokenToPool[tokenIn] == poolA && tokenToPool[tokenOut] == poolB) {
            reserveIn = Pool(poolA).getReserve();
            reserveOut = Pool(poolB).getReserve();
            poolIn = poolA;
            poolOut = poolB;
        } else if (
            tokenToPool[tokenIn] == poolB && tokenToPool[tokenOut] == poolA
        ) {
            reserveIn = Pool(poolB).getReserve();
            reserveOut = Pool(poolA).getReserve();
            poolIn = poolB;
            poolOut = poolA;
        } else {
            return (0, 0, address(0), address(0));
            // revert("Invalid tokenIn/tokenOut pair");
        }
    }
}
