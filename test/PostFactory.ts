import hre from 'hardhat';
import { expect } from 'chai';
import { loadFixture } from '@nomicfoundation/hardhat-toolbox/network-helpers';

describe('PostFactory', () => {
  const deployPostFactory = async () => {
    const [owner, questioner, company] = await hre.ethers.getSigners();

    // contract is deployed using first signer by default
    const PostFactory = await hre.ethers.getContractFactory('PostFactory');

    const postFactory = await PostFactory.deploy();

    return { postFactory, owner, questioner, company };
  };

  describe('Deployment', () => {
    it('Sets the correct address as the owner', async () => {
      const { postFactory, owner } = await loadFixture(deployPostFactory);

      expect(await postFactory.owner()).to.equal(owner.address);
    });

    it('Contract is payable, can receive money', async () => {
      const { postFactory, company } = await loadFixture(
        deployPostFactory
      );

      const oneEther = hre.ethers.parseEther('1');

      expect(await postFactory.getBalance()).to.equal(0);
      const tx = await company.sendTransaction({
        to: await postFactory.getAddress(),
        value: oneEther,
      });

      await tx.wait();

      expect(await postFactory.getBalance()).to.equal(oneEther);
    });
  });
});
