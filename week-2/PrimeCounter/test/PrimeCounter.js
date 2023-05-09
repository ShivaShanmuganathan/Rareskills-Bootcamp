const {
  time,
  loadFixture
} = require('@nomicfoundation/hardhat-network-helpers')
const { anyValue } = require('@nomicfoundation/hardhat-chai-matchers/withArgs')
const { expect } = require('chai')
const { ethers } = require('hardhat')
const fc = require('fast-check')

const countPrimes = numbers => {
  let count = 0
  for (let i = 0; i < numbers.length; i++) {
    if (isPrime(numbers[i])) {
      count++
    }
  }
  return count
}

const isPrime = num => {
  if (num < 2) {
    return false
  }
  for (let i = 2; i <= Math.sqrt(num); i++) {
    if (num % i === 0) {
      return false
    }
  }
  return true
}

describe('PrimeCounter', function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  let supply

  async function deployNFTandPrime () {
    const nft_name = 'MyCollection'
    const nft_symbol = 'MyC'
    const maxSupply = supply

    const [
      owner,
      signer,
      user1,
      user2,
      user3,
      user4,
      user5
    ] = await ethers.getSigners()
    // Contracts are deployed using the first signer/account by default
    const NFTCollection = await ethers.getContractFactory('NFTCollection')
    const nft = await NFTCollection.deploy(nft_name, nft_symbol, maxSupply)

    const PrimeCounter = await ethers.getContractFactory('PrimeCounter')
    const prime_counter = await PrimeCounter.deploy(nft.address)

    return {
      nft,
      prime_counter,
      nft_name,
      nft_symbol,
      maxSupply,
      owner,
      signer,
      user1,
      user2,
      user3,
      user4,
      user5
    }
  }

  describe('Deployment', function () {
    it('Should set the right nft contract details', async function () {
      supply = 20
      const { nft, nft_name, nft_symbol, maxSupply } = await loadFixture(
        deployNFTandPrime
      )

      expect(await nft.name()).to.eq(nft_name)
      expect(await nft.symbol()).to.eq(nft_symbol)
      expect(await nft.symbol()).to.eq(nft_symbol)
      expect(await nft.maxSupply()).to.eq(maxSupply)
    })
    it('Should set the right nft contract details', async function () {
      supply = 20
      const { nft, prime_counter } = await loadFixture(deployNFTandPrime)

      expect(await prime_counter.nftCollection()).to.eq(nft.address)
    })

    it('Should set the nft right owner', async function () {
      supply = 20
      const { nft, owner } = await loadFixture(deployNFTandPrime)

      expect(await nft.owner()).to.equal(owner.address)
    })

    // it('Should set the prime counter right owner', async function () {
    //   supply = 20
    //   const { nft, owner, prime_counter } = await loadFixture(deployNFTandPrime)

    //   expect(await prime_counter.owner()).to.equal(owner.address)
    // })
  })

  describe('PrimeCounter', function () {
    describe('Validations', function () {
      it('Should revert with the right error if called from another account', async function () {
        supply = 20
        const { nft, user1 } = await loadFixture(deployNFTandPrime)

        await expect(nft.connect(user1).mint(user1.address)).to.be.revertedWith(
          'Ownable: caller is not the owner'
        )
      })
    })

    describe('Events', function () {
      it('Should emit an event on mient', async function () {
        supply = 20
        const { nft, user1, owner, TENTH_ETHER } = await loadFixture(
          deployNFTandPrime
        )
        const token_id = await nft.tokenId()
        await expect(nft.connect(owner).mint(user1.address))
          .to.emit(nft, 'Transfer')
          .withArgs(ethers.constants.AddressZero, user1.address, token_id)
      })
    })

    describe('Prime-Counter', function () {
      it('Should mint and check nft balance', async function () {
        supply = 20
        const { nft, user2, owner, prime_counter } = await loadFixture(
          deployNFTandPrime
        )

        for (let i = 1; i <= supply; i++) {
          let user_nft_balance_before = await nft.balanceOf(user2.address)
          // console.log('TokenID ' + i)
          await expect(nft.connect(owner).mint(user2.address))
            .to.emit(nft, 'Transfer')
            .withArgs(ethers.constants.AddressZero, user2.address, i)
          let user_nft_balance_after = await nft.balanceOf(user2.address)
          expect(user_nft_balance_after - user_nft_balance_before).to.eq(1)
        }
      })

      it('Should check prime numbers', async function () {
        data = [50, 250, 500, 1000]
        for (let j = 0; j < data.length; j++) {
          const nft_name = 'MyCollection'
          const nft_symbol = 'MyC'
          let maxSupply = data[j]

          const [owner, user2] = await ethers.getSigners()
          // Contracts are deployed using the first signer/account by default
          const NFTCollection = await ethers.getContractFactory('NFTCollection')
          let nft = await NFTCollection.deploy(nft_name, nft_symbol, maxSupply)

          const PrimeCounter = await ethers.getContractFactory('PrimeCounter')
          let prime_counter = await PrimeCounter.deploy(nft.address)

          for (let i = 1; i <= maxSupply; i++) {
            let user_nft_balance_before = await nft.balanceOf(user2.address)

            await expect(nft.connect(owner).mint(user2.address))
              .to.emit(nft, 'Transfer')
              .withArgs(ethers.constants.AddressZero, user2.address, i)
            let user_nft_balance_after = await nft.balanceOf(user2.address)
            expect(user_nft_balance_after - user_nft_balance_before).to.eq(1)
          }

          let user_nft_balance = await nft.balanceOf(user2.address)

          user_token_ids = []
          for (let k = 0; k < user_nft_balance; k++) {
            user_token_ids.push(await nft.tokenOfOwnerByIndex(user2.address, k))
          }

          prime_result_js = countPrimes(user_token_ids)
          prime_result_sol = await prime_counter.countPrimeNFTs(user2.address)

          expect(prime_result_js).to.be.eq(prime_result_sol)
        }
      })
    })
  })
})
