// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @title Escrow
 * @dev A smart contract for escrowing ERC20 tokens between a buyer and seller.
 */
contract Escrow is Ownable2Step {
    using SafeERC20 for IERC20;
    // add whitelist for ERC20 Tokens by owner
    mapping(address => bool) public whitelist;
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
        uint256 depositId,
        address indexed buyer,
        address indexed seller,
        address indexed token,
        uint256 amount,
        uint256 releaseTime
    );
    event Withdrawal(uint256 depositId, address indexed seller, uint256 amount);
    event TokenWhitelisted(address indexed token);
    event TokenBlacklisted(address indexed token);

    /**
     * @dev Allows a buyer to deposit tokens into the escrow contract for a specific seller.
     * @param seller The address of the seller receiving the deposit.
     * @param token The address of the token being deposited.
     * @param amount The amount of tokens being deposited.
     * @param releaseTime The time after which the tokens can be withdrawn by the seller.
     * Requirements:
     * - `seller` and `token` addresses must be valid.
     * - `amount` and `releaseTime` must be greater than 0.
     * - `token` must be whitelisted.
     * Effects:
     * - The tokens are transferred from the buyer to the escrow contract.
     * - A new deposit is created and stored in the `deposits` mapping.
     * Emits:
     * - `DepositReceived` event indicating the deposit details, including the release time.
     * Returns:
     * - The ID of the new deposit.
     */
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
        require(whitelist[token], "Token is not whitelisted");
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
            depositId,
            msg.sender,
            seller,
            token,
            amount,
            block.timestamp + releaseTime
        );
        return depositId;
    }

    /**
     * @dev Allows the seller to withdraw the deposited tokens once the release time has passed.
     * @param _depositId The ID of the deposit to be withdrawn.
     * Requirements:
     * - `_depositId` must correspond to an existing deposit.
     * - Only the seller can withdraw the deposited tokens.
     * - The deposit must not have been already withdrawn.
     * - The release time must have passed.
     * - The contract must have sufficient balance of the deposited token.
     * Effects:
     * - The deposited tokens are transferred to the seller.
     * - The deposit status is updated to withdrawn.
     * Emits:
     * - `Withdrawal` event indicating the amount of tokens withdrawn by the seller.
     */
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
        emit Withdrawal(_depositId, msg.sender, amount);
    }

    /**
     * @dev Allows the buyer to request a refund of their deposit if the release time has not yet been reached.
     * @param _depositId The ID of the deposit to be refunded.
     * @return A boolean indicating whether the refund was successful or not.
     * Emits a {Withdrawal} event indicating the amount refunded to the buyer's address.
     * Requirements:
     * - `_depositId` must correspond to an existing deposit.
     * - Only the buyer who made the deposit can request a refund.
     * - The deposit must not have already been withdrawn.
     * - The current time must be before the release time.
     * - The contract must have sufficient balance of the deposited token to refund the buyer.
     */
    function refundToken(uint256 _depositId) external returns (bool) {
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
        emit Withdrawal(_depositId, msg.sender, amount);
        return true;
    }

    /**
     * @dev Adds a token to the whitelist.
     * @param token The address of the token to be added.
     * Requirements:
     * - The `token` address must be a valid Ethereum address.
     * - The `token` must not already be whitelisted.
     */
    function addTokenToWhitelist(address token) external onlyOwner {
        isValidAddress(token);
        require(!whitelist[token], "Token is already whitelisted");
        whitelist[token] = true;
        emit TokenWhitelisted(token);
    }

    /**
     * @dev Removes a token from the whitelist.
     * @param token The address of the token to be removed.
     * Requirements:
     * - The `token` address must be a valid Ethereum address.
     * - The `token` must be currently whitelisted.
     */
    function removeTokenFromWhitelist(address token) external onlyOwner {
        isValidAddress(token);
        require(whitelist[token], "Token is not whitelisted");
        whitelist[token] = false;
        emit TokenBlacklisted(token);
    }

    /**
     * @dev Returns the withdrawal status of a deposit.
     * @param _depositId The ID of the deposit to be checked.
     * @return A boolean indicating whether the deposit has been withdrawn or not.
     * Requirements:
     * - `_depositId` must correspond to an existing deposit.
     */
    function getEscrowStatus(uint256 _depositId) external view returns (bool) {
        return deposits[_depositId].withdrawn;
    }

    /**
     * @dev Validates that the given address is not the zero address.
     * @param addr The address to be validated.
     * Requirements:
     * - The address must not be the zero address.
     */
    function isValidAddress(address addr) internal pure {
        require(addr != address(0), "Not a valid address");
    }

    /**
     * @dev Validates that the given value is greater than zero.
     * @param value The value to be validated.
     * Requirements:
     * - The value must be greater than zero.
     */
    function isValidValue(uint256 value) internal pure {
        require(value > 0, "Value cannot be 0");
    }
}
