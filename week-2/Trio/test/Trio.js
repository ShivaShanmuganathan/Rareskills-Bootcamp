const {
  time,
  loadFixture
} = require('@nomicfoundation/hardhat-network-helpers')
const { anyValue } = require('@nomicfoundation/hardhat-chai-matchers/withArgs')
const { expect } = require('chai')
const { StandardMerkleTree } = require('@openzeppelin/merkle-tree')

const getProofsAndTickets = (merkle_tree, user) => {
  var merkle_proofs = []
  var merkle_tickets = []
  for (const [i, v] of merkle_tree.entries()) {
    if (v[1] === user) {
      const proof = merkle_tree.getProof(i)
      merkle_tickets.push(v[0])
      merkle_proofs.push(proof)
    }
  }
  return {
    tickets: merkle_tickets,
    proofs: merkle_proofs
  }
}

describe('Trio', function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployTrio () {
    const ONE_DAY_IN_SECS = 24 * 60 * 60
    const TENTH_ETHER = ethers.utils.parseEther('0.1')

    const nft_name = 'MyCollection'
    const nft_symbol = 'MyC'
    const maxSupply = 20
    const royaltyFee = 250
    const feeDenominator = 10000

    const [
      owner,
      signer,
      user1,
      user2,
      user3,
      user4,
      user5
    ] = await ethers.getSigners()
    const whitelist_arr = []
    const whitelist_json = {
      1: owner.address,
      2: signer.address,
      3: user2.address,
      4: user1.address,
      5: signer.address,
      6: user3.address,
      7: user4.address,
      8: user3.address,
      9: user4.address,
      10: user2.address
    }

    for (var id in whitelist_json) {
      whitelist_arr.push([id, whitelist_json[id]])
    }
    const merkle_tree = StandardMerkleTree.of(whitelist_arr, [
      'uint256',
      'address'
    ])

    const merkle_root = merkle_tree.root
    // Contracts are deployed using the first signer/account by default
    const NFTCollection = await ethers.getContractFactory('NFTCollection')
    const nft = await NFTCollection.deploy(
      nft_name,
      nft_symbol,
      merkle_root,
      royaltyFee
    )

    const erc20_name = 'RewardToken'
    const erc20_symbol = 'RT'

    const StakeAndEarn = await ethers.getContractFactory('StakeAndEarn')
    const stakeAndEarn = await StakeAndEarn.connect(owner).deploy(nft.address)

    const RewardToken = await ethers.getContractFactory('RewardToken')
    const rewardToken = await RewardToken.connect(owner).deploy(
      erc20_name,
      erc20_symbol,
      stakeAndEarn.address
    )

    await stakeAndEarn.connect(owner).setRewardToken(rewardToken.address)

    return {
      nft,
      nft_name,
      nft_symbol,
      maxSupply,
      royaltyFee,
      feeDenominator,
      rewardToken,
      erc20_name,
      erc20_symbol,
      stakeAndEarn,
      owner,
      signer,
      user1,
      user2,
      user3,
      user4,
      user5,
      merkle_tree,
      merkle_root,
      TENTH_ETHER,
      ONE_DAY_IN_SECS
    }
  }

  describe('Deployment', function () {
    it('Should set the right nft contract details', async function () {
      const { nft, nft_name, nft_symbol, maxSupply } = await loadFixture(
        deployTrio
      )

      expect(await nft.name()).to.eq(nft_name)
      expect(await nft.symbol()).to.eq(nft_symbol)
      expect(await nft.symbol()).to.eq(nft_symbol)
      expect(await nft.maxSupply()).to.eq(maxSupply)
    })

    it('Should set the right nft owner', async function () {
      const { nft, owner } = await loadFixture(deployTrio)

      expect(await nft.owner()).to.equal(owner.address)
    })

    it('Should set the right nft royalty info', async function () {
      const {
        nft,
        signer,
        user1,
        royaltyFee,
        signer_proof,
        feeDenominator,
        TENTH_ETHER
      } = await loadFixture(deployTrio)
      expect(await nft.mint(user1.address, { value: TENTH_ETHER }))
      const token_id = (await nft.tokenId()) - 1
      const tokenPrice = await nft.tokenPrice()
      const discountedTokenPrice = await nft.discountedTokenPrice()

      expect((await nft.royaltyInfo(10, tokenPrice))[1]).to.eq(
        (tokenPrice * royaltyFee) / feeDenominator
      )
      expect((await nft.royaltyInfo(token_id, discountedTokenPrice))[1]).to.eq(
        (discountedTokenPrice * royaltyFee) / feeDenominator
      )
    })

    it('Should set the right nft claim info', async function () {
      const {
        nft,
        signer,
        user1,
        user2,
        user5,
        merkle_tree,
        TENTH_ETHER
      } = await loadFixture(deployTrio)
      expect(await nft.mint(user1.address, { value: TENTH_ETHER }))
      const signer_params = getProofsAndTickets(merkle_tree, signer.address)

      expect(
        await nft.canClaim(
          signer_params.tickets[0],
          signer.address,
          signer_params.proofs[0]
        )
      ).to.eq(true)
    })

    it('Should set the reward token details', async function () {
      const { rewardToken } = await loadFixture(deployTrio)

      expect(await rewardToken.name()).to.equal('RewardToken')
      expect(await rewardToken.symbol()).to.equal('RT')
    })

    it('Should set the right address in reward token', async function () {
      const { rewardToken, stakeAndEarn } = await loadFixture(deployTrio)
      expect(await rewardToken.stakeAndEarn()).to.equal(stakeAndEarn.address)
    })

    it('Should set the right owner, reward token and nft address in stake contract', async function () {
      const { rewardToken, nft, stakeAndEarn, owner } = await loadFixture(
        deployTrio
      )
      expect(await stakeAndEarn.owner()).to.equal(owner.address)
      expect(await stakeAndEarn.RewardToken()).to.equal(rewardToken.address)
      expect(await stakeAndEarn.NFTCollection()).to.equal(nft.address)
    })
  })

  describe('Trio Testing', function () {
    describe('Validations', function () {
      it('Should revert with the right error when using new nft to deposit', async function () {
        const {
          rewardToken,
          nft,
          stakeAndEarn,
          user1,
          TENTH_ETHER,
          nft_name,
          nft_symbol,
          merkle_root,
          royaltyFee
        } = await loadFixture(deployTrio)

        const NFTCollection2 = await ethers.getContractFactory('NFTCollection')
        const nft2 = await NFTCollection2.deploy(
          nft_name,
          nft_symbol,
          merkle_root,
          royaltyFee
        )

        await nft2.connect(user1).mint(user1.address, { value: TENTH_ETHER })
        const token_id = (await nft2.tokenId()) - 1

        await expect(
          nft2
            .connect(user1)
            ['safeTransferFrom(address,address,uint256)'](
              user1.address,
              stakeAndEarn.address,
              token_id
            )
        ).to.be.revertedWith('Not the NFT contract')
      })

      it('Should revert with the right error for nft double deposit', async function () {
        const {
          rewardToken,
          nft,
          stakeAndEarn,
          user1,
          TENTH_ETHER
        } = await loadFixture(deployTrio)

        await nft.connect(user1).mint(user1.address, { value: TENTH_ETHER })
        const token_id = (await nft.tokenId()) - 1

        await expect(
          nft
            .connect(user1)
            ['safeTransferFrom(address,address,uint256)'](
              user1.address,
              stakeAndEarn.address,
              token_id
            )
        )
          .to.emit(stakeAndEarn, 'NFTDeposited')
          .withArgs(user1.address, user1.address, token_id, anyValue)

        await expect(
          nft
            .connect(user1)
            ['safeTransferFrom(address,address,uint256)'](
              user1.address,
              stakeAndEarn.address,
              token_id
            )
        ).to.be.revertedWith('ERC721: caller is not token owner or approved')
      })

      it('Should revert with the right error during withdraw', async function () {
        const {
          rewardToken,
          nft,
          stakeAndEarn,
          user1,
          TENTH_ETHER
        } = await loadFixture(deployTrio)

        await nft.connect(user1).mint(user1.address, { value: TENTH_ETHER })
        const token_id = (await nft.tokenId()) - 1
        await expect(
          stakeAndEarn.connect(user1).withdrawNFT(token_id)
        ).to.be.revertedWith('_msgSender() not original owner!')
      })
    })

    describe('Events', function () {
      it('Should emit NFTDeposited event on depositing NFT', async function () {
        const {
          rewardToken,
          nft,
          stakeAndEarn,
          user1,
          TENTH_ETHER
        } = await loadFixture(deployTrio)

        await nft.connect(user1).mint(user1.address, { value: TENTH_ETHER })
        const token_id = (await nft.tokenId()) - 1

        await expect(
          nft
            .connect(user1)
            ['safeTransferFrom(address,address,uint256)'](
              user1.address,
              stakeAndEarn.address,
              token_id
            )
        )
          .to.emit(stakeAndEarn, 'NFTDeposited')
          .withArgs(user1.address, user1.address, token_id, anyValue)
      })

      it('Should emit NFTWithdrawn event on withdrawing NFT', async function () {
        const {
          rewardToken,
          nft,
          stakeAndEarn,
          user1,
          TENTH_ETHER
        } = await loadFixture(deployTrio)

        await nft.connect(user1).mint(user1.address, { value: TENTH_ETHER })
        const token_id = (await nft.tokenId()) - 1

        await expect(
          nft
            .connect(user1)
            ['safeTransferFrom(address,address,uint256)'](
              user1.address,
              stakeAndEarn.address,
              token_id
            )
        )
          .to.emit(stakeAndEarn, 'NFTDeposited')
          .withArgs(user1.address, user1.address, token_id, anyValue)

        await expect(stakeAndEarn.connect(user1).withdrawNFT(token_id))
          .to.emit(stakeAndEarn, 'NFTWithdrawn')
          .withArgs(user1.address, token_id, anyValue)
      })

      it('Should emit RewardTokenUpdated event on updating reward token', async function () {
        const {
          rewardToken,
          nft,
          stakeAndEarn,
          user1,
          TENTH_ETHER,
          erc20_name,
          erc20_symbol,
          owner
        } = await loadFixture(deployTrio)
        const RewardToken = await ethers.getContractFactory('RewardToken')
        const newRewardToken = await RewardToken.connect(owner).deploy(
          erc20_name,
          erc20_symbol,
          stakeAndEarn.address
        )

        await expect(
          stakeAndEarn.connect(owner).setRewardToken(newRewardToken.address)
        )
          .to.emit(stakeAndEarn, 'RewardTokenUpdated')
          .withArgs(rewardToken.address, newRewardToken.address)
      })
    })

    describe('Stake Rewards', function () {
      it('Should mint nft, stake it, wait for some time, claim rewards', async function () {
        const {
          rewardToken,
          nft,
          stakeAndEarn,
          user1,
          TENTH_ETHER,
          ONE_DAY_IN_SECS
        } = await loadFixture(deployTrio)

        await nft.connect(user1).mint(user1.address, { value: TENTH_ETHER })
        const token_id = (await nft.tokenId()) - 1

        await expect(
          nft
            .connect(user1)
            ['safeTransferFrom(address,address,uint256)'](
              user1.address,
              stakeAndEarn.address,
              token_id
            )
        )
          .to.emit(stakeAndEarn, 'NFTDeposited')
          .withArgs(user1.address, user1.address, token_id, anyValue)

        const oneDayLater = (await time.latest()) + ONE_DAY_IN_SECS
        // We can increase the time in Hardhat Network
        await time.increaseTo(oneDayLater)

        const stakingRewards = await stakeAndEarn.calculateStakingRewards(
          token_id
        )

        await expect(stakeAndEarn.connect(user1).claimRewards(token_id))
          .to.emit(stakeAndEarn, 'RewardsClaimed')
          .withArgs(user1.address, token_id, anyValue)
        const user_balance_after = await rewardToken.balanceOf(user1.address)
        expect(user_balance_after).to.be.greaterThanOrEqual(stakingRewards)

        const twoDaysLater =
          (await time.latest()) + ONE_DAY_IN_SECS + ONE_DAY_IN_SECS
        await time.increaseTo(twoDaysLater)

        const stakingRewards2 = await stakeAndEarn.calculateStakingRewards(
          token_id
        )

        await expect(stakeAndEarn.connect(user1).claimRewards(token_id))
          .to.emit(stakeAndEarn, 'RewardsClaimed')
          .withArgs(user1.address, token_id, anyValue)
        const user_balance_after_2 = await rewardToken.balanceOf(user1.address)
        expect(user_balance_after_2).to.be.greaterThanOrEqual(stakingRewards2)
      })

      it('Should mint nft using merkle proof, stake it, wait for some time, claim rewards', async function () {
        const {
          rewardToken,
          nft,
          stakeAndEarn,
          user1,
          merkle_tree,
          TENTH_ETHER,
          ONE_DAY_IN_SECS
        } = await loadFixture(deployTrio)

        const user1_params = getProofsAndTickets(merkle_tree, user1.address)
        const token_id = await nft.tokenId()
        await expect(
          nft
            .connect(user1)
            .verifyAndMint(user1_params.tickets[0], user1_params.proofs[0], {
              value: TENTH_ETHER
            })
        )
          .to.emit(nft, 'Transfer')
          .withArgs(ethers.constants.AddressZero, user1.address, token_id)

        await expect(
          nft
            .connect(user1)
            ['safeTransferFrom(address,address,uint256)'](
              user1.address,
              stakeAndEarn.address,
              token_id
            )
        )
          .to.emit(stakeAndEarn, 'NFTDeposited')
          .withArgs(user1.address, user1.address, token_id, anyValue)

        const oneDayLater = (await time.latest()) + ONE_DAY_IN_SECS
        // We can increase the time in Hardhat Network
        await time.increaseTo(oneDayLater)

        const stakingRewards = await stakeAndEarn.calculateStakingRewards(
          token_id
        )

        await expect(stakeAndEarn.connect(user1).claimRewards(token_id))
          .to.emit(stakeAndEarn, 'RewardsClaimed')
          .withArgs(user1.address, token_id, anyValue)
        const user_balance_after = await rewardToken.balanceOf(user1.address)
        expect(user_balance_after).to.be.greaterThanOrEqual(stakingRewards)

        const twoDaysLater =
          (await time.latest()) + ONE_DAY_IN_SECS + ONE_DAY_IN_SECS
        await time.increaseTo(twoDaysLater)

        const stakingRewards2 = await stakeAndEarn.calculateStakingRewards(
          token_id
        )

        await expect(stakeAndEarn.connect(user1).claimRewards(token_id))
          .to.emit(stakeAndEarn, 'RewardsClaimed')
          .withArgs(user1.address, token_id, anyValue)
        const user_balance_after_2 = await rewardToken.balanceOf(user1.address)
        expect(user_balance_after_2).to.be.greaterThanOrEqual(stakingRewards2)
      })

      it('Should mint nft using merkle proof, stake it, wait for some time, withdraw with rewards', async function () {
        const {
          rewardToken,
          nft,
          stakeAndEarn,
          user1,
          merkle_tree,
          TENTH_ETHER,
          ONE_DAY_IN_SECS
        } = await loadFixture(deployTrio)

        const user1_params = getProofsAndTickets(merkle_tree, user1.address)
        const token_id = await nft.tokenId()
        await expect(
          nft
            .connect(user1)
            .verifyAndMint(user1_params.tickets[0], user1_params.proofs[0], {
              value: TENTH_ETHER
            })
        )
          .to.emit(nft, 'Transfer')
          .withArgs(ethers.constants.AddressZero, user1.address, token_id)

        await expect(
          nft
            .connect(user1)
            ['safeTransferFrom(address,address,uint256)'](
              user1.address,
              stakeAndEarn.address,
              token_id
            )
        )
          .to.emit(stakeAndEarn, 'NFTDeposited')
          .withArgs(user1.address, user1.address, token_id, anyValue)

        const fiveDaysLater =
          (await time.latest()) +
          ONE_DAY_IN_SECS +
          ONE_DAY_IN_SECS +
          ONE_DAY_IN_SECS +
          ONE_DAY_IN_SECS +
          ONE_DAY_IN_SECS
        await time.increaseTo(fiveDaysLater)

        const stakingRewards3 = await stakeAndEarn.calculateStakingRewards(
          token_id
        )

        expect(await nft.ownerOf(token_id)).to.be.eq(stakeAndEarn.address)
        await expect(stakeAndEarn.connect(user1).withdrawNFT(token_id))
          .to.emit(stakeAndEarn, 'NFTWithdrawn')
          .withArgs(user1.address, token_id, anyValue)
        const user_balance_after_3 = await rewardToken.balanceOf(user1.address)
        expect(user_balance_after_3).to.be.greaterThanOrEqual(stakingRewards3)
        expect(await nft.ownerOf(token_id)).to.be.eq(user1.address)
      })
    })
  })
})
