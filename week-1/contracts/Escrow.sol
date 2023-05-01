// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract Escrow is Ownable2Step {
    using SafeERC20 for IERC20;

    struct Deposit {
        address buyer;
        address seller;
        address token;
        uint256 amount;
        uint256 releaseTime;
        bool withdrawn;
    }

    mapping(uint256 => Deposit) public deposits;
    uint256 public depositId;

    event DepositReceived(
        address indexed buyer,
        address indexed seller,
        address indexed token,
        uint256 amount,
        uint256 releaseTime
    );
    event Withdrawal(address seller, uint256 amount);

    function depositToken(
        address seller,
        address token,
        uint256 amount,
        uint256 releaseTime
    ) external returns (uint256) {
        // check input params
        isValidAddress(seller);
        isValidAddress(token);
        isValidValue(amount);
        isValidValue(releaseTime);
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        depositId += 1;
        deposits[depositId] = Deposit({
            buyer: msg.sender,
            seller: seller,
            token: token,
            amount: amount,
            releaseTime: block.timestamp + releaseTime,
            withdrawn: false
        });
        emit DepositReceived(
            msg.sender,
            seller,
            token,
            amount,
            block.timestamp + releaseTime
        );
        return depositId;
    }

    function withdrawToken(uint256 _depositId) external {
        Deposit storage deposit = deposits[_depositId];
        isValidAddress(deposit.buyer); // check valid _depositId by checking if buyer exists
        require(msg.sender == deposit.seller, "Only seller can withdraw");
        require(!deposit.withdrawn, "Deposit already withdrawn");
        require(
            block.timestamp >= deposit.releaseTime,
            "Release time not yet reached"
        );
        deposit.withdrawn = true;

        IERC20 token = IERC20(deposit.token);
        uint256 balance = token.balanceOf(address(this));
        uint256 amount = deposit.amount;
        require(balance >= amount, "Insufficient balance");
        token.safeTransfer(msg.sender, amount);
        emit Withdrawal(msg.sender, amount);
    }

    function getEscrowStatus(uint256 _depositId) external view returns (bool) {
        return deposits[_depositId].withdrawn;
    }

    function refund(uint256 _depositId) external returns (bool) {
        Deposit storage deposit = deposits[_depositId];
        isValidAddress(deposit.buyer); // check valid _depositId by checking if buyer exists
        require(msg.sender == deposit.buyer, "Only buyer can refund");
        require(!deposit.withdrawn, "Deposit already withdrawn");
        require(block.timestamp < deposit.releaseTime, "Release time reached");
        deposit.withdrawn = true;
        IERC20 token = IERC20(deposit.token);
        uint256 balance = token.balanceOf(address(this));
        uint256 amount = deposit.amount;
        require(balance >= amount, "Insufficient balance");
        token.safeTransfer(msg.sender, amount);
        emit Withdrawal(msg.sender, amount);
        return true;
    }

    function isValidAddress(address addr) internal pure {
        require(addr != address(0), "Not a valid address");
    }

    function isValidValue(uint256 value) internal pure {
        require(value > 0, "Value cannot be 0");
    }
}
