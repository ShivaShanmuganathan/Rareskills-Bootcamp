// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IRewardToken, RewardToken} from "./RewardToken.sol";
import {NFTCollection} from "./NFTCollection.sol";

contract StakeAndEarn is Ownable2Step, IERC721Receiver {
    struct DepositStruct {
        address originalOwner;
        uint256 depositTime;
    }

    IRewardToken public RewardToken;
    IERC721 public immutable NFTCollection;

    mapping(uint256 => DepositStruct) deposits;

    event RewardsClaimed(
        address indexed claimer,
        uint256 tokenId,
        uint256 rewards
    );

    event NFTWithdrawn(
        address indexed to,
        uint256 tokenId,
        uint256 rewardAmount
    );

    event NFTDeposited(
        address indexed operator,
        address indexed from,
        uint256 tokenId,
        uint256 depositTime
    );

    event RewardTokenUpdated(
        address indexed oldRewardToken,
        address indexed newRewardToken
    );

    constructor(address _NFTCollection) {
        NFTCollection = IERC721(_NFTCollection);
    }

    function calculateStakingRewards(
        uint256 tokenId
    ) public view returns (uint256) {
        uint256 claimTime = deposits[tokenId].depositTime;
        uint256 elapsedTime = block.timestamp - claimTime;
        uint256 earnedRewards = (elapsedTime * 10 ether) / 1 days;
        return earnedRewards;
    }

    /**
     * @notice Claim your rewards without withdrawing your NFT
     * @param tokenId uint256 ID of the token to withdraw
     */
    function claimRewards(uint256 tokenId) external returns(bool){
        DepositStruct memory _deposit = deposits[tokenId];
        require(
            _deposit.originalOwner == _msgSender(),
            "_msgSender() not original owner!"
        );
        uint256 calculatedRewards = calculateStakingRewards(
            tokenId
        );
        _deposit.depositTime = block.timestamp;
        deposits[tokenId] = _deposit;
        RewardToken.mint(_msgSender(), calculatedRewards);
        emit RewardsClaimed(_msgSender(), tokenId, calculatedRewards);
        return true;
    }

    function withdrawNFT(uint256 tokenId) external {
        DepositStruct memory _deposit = deposits[tokenId];
        require(
            _deposit.originalOwner == _msgSender(),
            "_msgSender() not original owner!"
        );
        uint256 calculatedRewards = calculateStakingRewards(
            _deposit.depositTime
        );
        NFTCollection.safeTransferFrom(address(this), _msgSender(), tokenId);
        RewardToken.mint(_msgSender(), calculatedRewards);
        emit NFTWithdrawn(_msgSender(), tokenId, calculatedRewards);
    }

    /**
     * @notice Transfering your NFT to this contract do the same as depositNFT
     * @param operator address Token transfered by this address
     * @param from address Token transfered from this address
     * @param tokenId uint256 ID of the token to deposit
     * @param data Additionnal data
     * @return IERC721Receiver.onERC721Received.selector
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

    function setRewardToken(address newRewardToken) external onlyOwner {
        address oldRewardToken = address(RewardToken);
        RewardToken = IRewardToken(newRewardToken);
        emit RewardTokenUpdated(oldRewardToken, newRewardToken);
    }
}
