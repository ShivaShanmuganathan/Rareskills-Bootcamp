// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Pool is Ownable {
    IERC20 public token;
    uint256 private reserve;

    address public pairContract;
    uint256 public constant maxApprovalAmount = type(uint256).max;

    event Deposit(address indexed depositor, uint256 amount);
    event Withdraw(address indexed withdrawer, uint256 amount);

    constructor(address _token) {
        token = IERC20(_token);
    }

    function approvePairContract(address _pairContract) external onlyOwner {
        require(_pairContract != address(0), "Pair contract address not set");

        require(
            token.approve(pairContract, maxApprovalAmount),
            "Approval failed"
        );
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");

        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Token transfer failed"
        );

        reserve += amount;

        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(reserve >= amount, "Insufficient reserves");

        require(token.transfer(msg.sender, amount), "Token transfer failed");

        reserve -= amount;

        emit Withdraw(msg.sender, amount);
    }

    function getReserve() external view returns (uint256) {
        return reserve;
    }
}
