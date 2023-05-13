const {
  time,
  loadFixture
} = require('@nomicfoundation/hardhat-network-helpers')
const { anyValue } = require('@nomicfoundation/hardhat-chai-matchers/withArgs')
const { expect } = require('chai')

describe('Overmint1', function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployOvermint1 () {
    // Contracts are deployed using the first signer/account by default
    const [owner, user1, user2] = await ethers.getSigners()

    const Overmint1 = await ethers.getContractFactory('Overmint1')
    const overmint1 = await Overmint1.deploy()

    return { overmint1, owner, user1, user2 }
  }

  describe('Deployment', function () {
    it('Should deployer AttackOvermint1 and mint 5 NFTs', async function () {
      // We don't use the fixture here because we want a different deployment
      const { overmint1, owner, user1 } = await loadFixture(deployOvermint1)
      const AttackOvermint1 = await ethers.getContractFactory('AttackOvermint1')
      const attacker = await AttackOvermint1.deploy(overmint1.address)

      await attacker.attack()
      for (let i = 1; i <= 5; i++) {
        await attacker.transferNFTs(i)
      }

      expect(await overmint1.balanceOf(owner.address)).to.be.eq(5)

      expect(await overmint1.success(owner.address)).to.be.true
    })
  })
})
