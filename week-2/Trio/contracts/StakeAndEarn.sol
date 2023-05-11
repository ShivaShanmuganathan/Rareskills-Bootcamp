// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IRewardToken, RewardToken} from "./RewardToken.sol";

/**
 * @title StakeAndEarn
 * @author Shiva
 * @notice Contract that allows users to stake their ERC721 tokens and earn rewards in a separate ERC20 token
 * @dev This contract uses the OpenZeppelin library for ERC721 and Ownable contracts
 */
contract StakeAndEarn is Ownable2Step, IERC721Receiver {
    /**
     * @dev Struct to store the deposit details of each ERC721 token
     * @param originalOwner Address of the original owner who deposited the token
     * @param depositTime Timestamp when the token was deposited
     */
    struct DepositStruct {
        address originalOwner;
        uint256 depositTime;
    }

    /**
     * @dev Address of the ERC20 token used for rewards
     */
    IRewardToken public RewardToken;

    /**
     * @dev Address of the ERC721 token collection that can be deposited for staking
     */
    IERC721 public immutable NFTCollection;

    /**
     * @dev Mapping to store the deposit details of each ERC721 token
     */
    mapping(uint256 => DepositStruct) deposits;

    /**
     * @dev Event emitted when rewards are claimed by a user
     * @param claimer Address of the user who claimed the rewards
     * @param tokenId ID of the ERC721 token for which the rewards were claimed
     * @param rewards Amount of rewards claimed by the user
     */
    event RewardsClaimed(
        address indexed claimer,
        uint256 tokenId,
        uint256 rewards
    );

    /**
     * @dev Event emitted when an ERC721 token is withdrawn from the contract
     * @param to Address of the user who received the withdrawn ERC721 token
     * @param tokenId ID of the withdrawn ERC721 token
     * @param rewardAmount Amount of rewards earned by the user for staking the withdrawn ERC721 token
     */
    event NFTWithdrawn(
        address indexed to,
        uint256 tokenId,
        uint256 rewardAmount
    );

    /**
     * @dev Event emitted when an ERC721 token is deposited for staking
     * @param operator Address of the user who deposited the ERC721 token
     * @param from Address of the user who owned the deposited ERC721 token
     * @param tokenId ID of the deposited ERC721 token
     * @param depositTime Timestamp when the token was deposited
     */
    event NFTDeposited(
        address indexed operator,
        address indexed from,
        uint256 tokenId,
        uint256 depositTime
    );

    /**
     * @dev Event emitted when the ERC20 reward token address is updated
     * @param oldRewardToken Address of the old ERC20 reward token contract
     * @param newRewardToken Address of the new ERC20 reward token contract
     */
    event RewardTokenUpdated(
        address indexed oldRewardToken,
        address indexed newRewardToken
    );

    /**
     * @dev Constructor function to set the ERC721 token collection address
     * @param _NFTCollection Address of the ERC721 token collection that can be deposited for staking
     */
    constructor(address _NFTCollection) {
        NFTCollection = IERC721(_NFTCollection);
    }

    /**
     * @dev Calculates the amount of staking rewards earned for a specific NFT token.
     * @param tokenId uint256 ID of the NFT token.
     * @return earnedRewards uint256 amount of staking rewards earned for the specified NFT token.
     */
    function calculateStakingRewards(
        uint256 tokenId
    ) public view returns (uint256) {
        uint256 claimTime = deposits[tokenId].depositTime;
        uint256 elapsedTime = block.timestamp - claimTime;
        uint256 earnedRewards = (elapsedTime * 10 ether) / 1 days;
        return earnedRewards;
    }

    /**
     * @notice Allows the original owner of an NFT that has been deposited into the contract to claim their staking rewards without withdrawing their NFT.
     * @param tokenId The ID of the NFT that the caller wishes to claim rewards for.
     * @return A boolean indicating whether the function was successful.
     */
    function claimRewards(uint256 tokenId) external returns (bool) {
        DepositStruct memory _deposit = deposits[tokenId];
        require(
            _deposit.originalOwner == _msgSender(),
            "_msgSender() not original owner!"
        );
        uint256 calculatedRewards = calculateStakingRewards(tokenId);
        _deposit.depositTime = block.timestamp;
        deposits[tokenId] = _deposit;
        RewardToken.mint(_msgSender(), calculatedRewards);
        emit RewardsClaimed(_msgSender(), tokenId, calculatedRewards);
        return true;
    }

    /**
     * @dev Withdraws an NFT and any earned rewards from the staking contract.
     * @param tokenId The ID of the NFT to withdraw.
     * Emits an {NFTWithdrawn} event with the address of the withdrawer, the token ID,
     * and the amount of rewards earned.
     * Requirements:
     * - The sender must be the original owner of the deposited NFT.
     */
    function withdrawNFT(uint256 tokenId) external {
        DepositStruct memory _deposit = deposits[tokenId];
        require(
            _deposit.originalOwner == _msgSender(),
            "_msgSender() not original owner!"
        );
        uint256 calculatedRewards = calculateStakingRewards(tokenId);
        NFTCollection.safeTransferFrom(address(this), _msgSender(), tokenId);
        RewardToken.mint(_msgSender(), calculatedRewards);
        emit NFTWithdrawn(_msgSender(), tokenId, calculatedRewards);
    }

    /**
     * @dev Receives an ERC721 token deposit from the NFT collection contract.
     * @param operator The address that transferred the token.
     * @param from The address that previously owned the token.
     * @param tokenId The ID of the token being deposited.
     * @param data Additional data with no specified format.
     * @return bytes4 The ERC721 receiver return value.
     * Emits a {NFTDeposited} event.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        require(_msgSender() == address(NFTCollection), "Not the NFT contract");
        deposits[tokenId] = DepositStruct(operator, block.timestamp);
        emit NFTDeposited(operator, from, tokenId, block.timestamp);
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @dev Allows the owner of the contract to update the RewardToken address to a new address.
     * Emits a RewardTokenUpdated event with the old and new RewardToken addresses.
     * Requirements:
     * - Only the owner of the contract can call this function.
     * @param newRewardToken The address of the new RewardToken contract.
     */
    function setRewardToken(address newRewardToken) external onlyOwner {
        address oldRewardToken = address(RewardToken);
        RewardToken = IRewardToken(newRewardToken);
        emit RewardTokenUpdated(oldRewardToken, newRewardToken);
    }
}
