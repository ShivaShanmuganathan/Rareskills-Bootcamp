const {
  time,
  loadFixture
} = require('@nomicfoundation/hardhat-network-helpers')
const { anyValue } = require('@nomicfoundation/hardhat-chai-matchers/withArgs')
const { expect } = require('chai')
const { ethers } = require('hardhat')
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

describe('NFTCollection', function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployNFTCollection () {
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

    return {
      nft,
      nft_name,
      nft_symbol,
      maxSupply,
      royaltyFee,
      feeDenominator,
      owner,
      signer,
      user1,
      user2,
      user3,
      user4,
      user5,
      merkle_tree,
      merkle_root,
      TENTH_ETHER
    }
  }

  describe('Deployment', function () {
    it('Should set the right contract details', async function () {
      const { nft, nft_name, nft_symbol, maxSupply } = await loadFixture(
        deployNFTCollection
      )

      expect(await nft.name()).to.eq(nft_name)
      expect(await nft.symbol()).to.eq(nft_symbol)
      expect(await nft.symbol()).to.eq(nft_symbol)
      expect(await nft.maxSupply()).to.eq(maxSupply)
    })

    it('Should set the right owner', async function () {
      const { nft, owner } = await loadFixture(deployNFTCollection)

      expect(await nft.owner()).to.equal(owner.address)
    })

    it('Should set the right royalty info', async function () {
      const {
        nft,
        signer,
        user1,
        royaltyFee,
        signer_proof,
        feeDenominator,
        TENTH_ETHER
      } = await loadFixture(deployNFTCollection)
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

    it('Should set the right claim info', async function () {
      const {
        nft,
        signer,
        user1,
        user2,
        user5,
        merkle_tree,
        TENTH_ETHER
      } = await loadFixture(deployNFTCollection)
      expect(await nft.mint(user1.address, { value: TENTH_ETHER }))
      const token_id = (await nft.tokenId()) - 1
      const signer_params = getProofsAndTickets(merkle_tree, signer.address)
      const user1_params = getProofsAndTickets(merkle_tree, user1.address)
      const user5_params = getProofsAndTickets(merkle_tree, user5.address)

      expect(
        await nft.canClaim(
          signer_params.tickets[0],
          signer.address,
          signer_params.proofs[0]
        )
      ).to.eq(true)

      expect(
        await nft.canClaim(
          user1_params.tickets[0],
          user1.address,
          user1_params.proofs[0]
        )
      ).to.eq(true)

      expect(
        await nft.canClaim(
          user1_params.tickets[0],
          user2.address,
          user1_params.proofs[0]
        )
      ).to.eq(false)

      expect(
        await nft.canClaim(10, user5.address, user1_params.proofs[0])
      ).to.eq(false)
    })
  })

  describe('NFTCollection', function () {
    describe('Validations', function () {
      it('Should revert with the right error if called from another account', async function () {
        const { nft, user1 } = await loadFixture(deployNFTCollection)

        await expect(nft.connect(user1).withdrawEther()).to.be.revertedWith(
          'Ownable: caller is not the owner'
        )
      })
    })

    describe('Events', function () {
      it('Should emit an event on withdrawals', async function () {
        const {
          nft,
          owner,
          signer,
          user1,
          user2,
          merkle_tree,
          TENTH_ETHER
        } = await loadFixture(deployNFTCollection)
        expect(
          await nft.connect(user1).mint(user1.address, { value: TENTH_ETHER })
        )

        await expect(nft.connect(owner).withdrawEther())
          .to.emit(nft, 'EtherWithdrawn')
          .withArgs(owner.address, TENTH_ETHER)
      })

      it('Should emit an event on mint', async function () {
        const { nft, user1, TENTH_ETHER } = await loadFixture(
          deployNFTCollection
        )
        const token_id = await nft.tokenId()
        await expect(
          nft.connect(user1).mint(user1.address, { value: TENTH_ETHER })
        )
          .to.emit(nft, 'Transfer')
          .withArgs(ethers.constants.AddressZero, user1.address, token_id)
      })

      it('Should emit an event on verifyAndMint', async function () {
        const { nft, signer, merkle_tree, TENTH_ETHER } = await loadFixture(
          deployNFTCollection
        )
        const token_id = await nft.tokenId()
        const signer_params = getProofsAndTickets(merkle_tree, signer.address)

        await expect(
          nft
            .connect(signer)
            .verifyAndMint(signer_params.tickets[0], signer_params.proofs[0], {
              value: TENTH_ETHER
            })
        )
          .to.emit(nft, 'Transfer')
          .withArgs(ethers.constants.AddressZero, signer.address, token_id)
      })
    })

    describe('VerifyAndMint', function () {
      it('Should verify the user using merkle proofs and mint', async function () {
        const { nft, user2, merkle_tree, TENTH_ETHER } = await loadFixture(
          deployNFTCollection
        )
        const token_id = await nft.tokenId()
        const user2_params = getProofsAndTickets(merkle_tree, user2.address)
        const user_nft_balance_before = await nft.balanceOf(user2.address)

        await expect(
          nft
            .connect(user2)
            .verifyAndMint(user2_params.tickets[0], user2_params.proofs[0], {
              value: TENTH_ETHER
            })
        )
          .to.emit(nft, 'Transfer')
          .withArgs(ethers.constants.AddressZero, user2.address, token_id)
          .to.changeEtherBalances([nft], [TENTH_ETHER])

        const user_nft_balance_after = await nft.balanceOf(user2.address)
        expect(user_nft_balance_after - user_nft_balance_before).to.eq(1)
      })

      it('Should revert when attempting to double mint using same ticket id', async function () {
        const { nft, user2, merkle_tree, TENTH_ETHER } = await loadFixture(
          deployNFTCollection
        )
        const token_id = await nft.tokenId()
        const user2_params = getProofsAndTickets(merkle_tree, user2.address)
        const user_nft_balance_before = await nft.balanceOf(user2.address)

        await expect(
          nft
            .connect(user2)
            .verifyAndMint(user2_params.tickets[0], user2_params.proofs[0], {
              value: TENTH_ETHER
            })
        )
          .to.emit(nft, 'Transfer')
          .withArgs(ethers.constants.AddressZero, user2.address, token_id)
          .to.changeEtherBalances([nft], [TENTH_ETHER])

        const user_nft_balance_after = await nft.balanceOf(user2.address)
        expect(user_nft_balance_after - user_nft_balance_before).to.eq(1)

        await expect(
          nft
            .connect(user2)
            .verifyAndMint(user2_params.tickets[0], user2_params.proofs[0], {
              value: TENTH_ETHER
            })
        ).to.be.revertedWith('ticketNumber has already been used')
      })

      it('Should revert when attempting to double mint using same proof', async function () {
        const { nft, user2, merkle_tree, TENTH_ETHER } = await loadFixture(
          deployNFTCollection
        )
        const token_id = await nft.tokenId()
        const user2_params = getProofsAndTickets(merkle_tree, user2.address)
        const user_nft_balance_before = await nft.balanceOf(user2.address)

        await expect(
          nft
            .connect(user2)
            .verifyAndMint(user2_params.tickets[0], user2_params.proofs[0], {
              value: TENTH_ETHER
            })
        )
          .to.emit(nft, 'Transfer')
          .withArgs(ethers.constants.AddressZero, user2.address, token_id)
          .to.changeEtherBalances([nft], [TENTH_ETHER])

        const user_nft_balance_after = await nft.balanceOf(user2.address)
        expect(user_nft_balance_after - user_nft_balance_before).to.eq(1)

        await expect(
          nft
            .connect(user2)
            .verifyAndMint(user2_params.tickets[1], user2_params.proofs[0], {
              value: TENTH_ETHER
            })
        ).to.be.revertedWith('Invalid merkle proof')
      })

      it('Should verify the user again for 2nd ticket and proof', async function () {
        const { nft, user2, merkle_tree, TENTH_ETHER } = await loadFixture(
          deployNFTCollection
        )
        const token_id = await nft.tokenId()
        const user2_params = getProofsAndTickets(merkle_tree, user2.address)
        const user_nft_balance_before = await nft.balanceOf(user2.address)

        await expect(
          nft
            .connect(user2)
            .verifyAndMint(user2_params.tickets[0], user2_params.proofs[0], {
              value: TENTH_ETHER
            })
        )
          .to.emit(nft, 'Transfer')
          .withArgs(ethers.constants.AddressZero, user2.address, token_id)
          .to.changeEtherBalances([nft], [TENTH_ETHER])

        const user_nft_balance_after = await nft.balanceOf(user2.address)
        expect(user_nft_balance_after - user_nft_balance_before).to.eq(1)

        await expect(
          nft
            .connect(user2)
            .verifyAndMint(user2_params.tickets[1], user2_params.proofs[1], {
              value: TENTH_ETHER
            })
        )
          .to.emit(nft, 'Transfer')
          .withArgs(ethers.constants.AddressZero, user2.address, token_id)
          .to.changeEtherBalances([nft], [TENTH_ETHER])
          expect(await nft.balanceOf(user2.address) - user_nft_balance_after).to.eq(1)
      })
    })
  })
})
