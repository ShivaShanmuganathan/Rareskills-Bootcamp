const {
  time,
  loadFixture
} = require('@nomicfoundation/hardhat-network-helpers')
const { anyValue } = require('@nomicfoundation/hardhat-chai-matchers/withArgs')
const { expect } = require('chai')

describe('Overmint2', function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployOvermint1 () {
    // Contracts are deployed using the first signer/account by default
    const [owner, user1, user2] = await ethers.getSigners()

    const Overmint2 = await ethers.getContractFactory('Overmint2')
    const overmint2 = await Overmint2.deploy()

    return { overmint2, owner, user1, user2 }
  }

  describe('Deployment', function () {
    it('Should deployer AttackOvermint2 and mint 5 NFTs', async function () {
      // We don't use the fixture here because we want a different deployment
      const { overmint2, owner, user1 } = await loadFixture(deployOvermint1)
      const AttackOvermint2 = await ethers.getContractFactory('AttackOvermint2')
      const attacker = await AttackOvermint2.deploy(
        overmint2.address,
        user1.address
      )

      for (let i = 1; i <= 5; i++) {
        await attacker.attack()
        await attacker.transferNFTs(i)
      }

      expect(await overmint2.balanceOf(owner.address)).to.be.eq(5)

      expect(await overmint2.success()).to.be.true
    })
  })
})
