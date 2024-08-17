import hre from 'hardhat';
import { expect } from 'chai';
import { loadFixture } from '@nomicfoundation/hardhat-toolbox/network-helpers';

describe('PostFactory', () => {
  const deployPostFactory = async () => {
    const [owner, questioner, company, answerer] =
      await hre.ethers.getSigners();

    // contract is deployed using first signer by default
    const PostFactory = await hre.ethers.getContractFactory('PostFactory');

    const postFactory = await PostFactory.deploy();

    return { postFactory, owner, questioner, company, answerer };
  };

  describe('Deployment', () => {
    it('Sets the correct address as the owner', async () => {
      const { postFactory, owner } = await loadFixture(deployPostFactory);

      expect(await postFactory.owner()).to.equal(owner.address);
    });

    it('Contract is payable, can receive money', async () => {
      const { postFactory, company } = await loadFixture(deployPostFactory);

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

  describe('Functionality', () => {
    it('Can create a new post', async () => {
      const { postFactory, owner, questioner, company } = await loadFixture(
        deployPostFactory
      );

      // call transaction with eth
      const bountyAmount = hre.ethers.parseEther('0.0005');
      const tx = await postFactory.createPost(
        questioner,
        company,
        bountyAmount,
        bountyAmount,
        { value: hre.ethers.parseEther('0.001') }
      );

      // check that post was created
      const post = await postFactory.posts(0);
      const postContract = await hre.ethers.getContractAt('Post', post, owner);
      expect(await postContract.questioner()).to.equal(questioner.address);
      expect(await postContract.company()).to.equal(company.address);
      expect(await postContract.companyBounty()).to.equal(bountyAmount);
      expect(await postContract.questionerBounty()).to.equal(bountyAmount);
      expect(await postContract.owner()).to.equal(owner.address);
      expect(await postContract.parent()).to.equal(
        await postFactory.getAddress()
      );
      expect(
        await hre.ethers.provider.getBalance(await postContract.getAddress())
      ).to.equal(hre.ethers.parseEther('0.001'));

      await expect(tx)
        .to.emit(postFactory, 'NewQuestionPosted')
        .withArgs(
          await postContract.getAddress(),
          questioner.address,
          company.address,
          bountyAmount,
          bountyAmount
        );
    });

    it('Bounty can be increased by questioner', async () => {
      const { postFactory, questioner, company } = await loadFixture(
        deployPostFactory
      );

      // create post
      const bountyAmount = hre.ethers.parseEther('0.0005');
      await postFactory.createPost(
        questioner,
        company,
        bountyAmount,
        bountyAmount,
        { value: hre.ethers.parseEther('0.001') }
      );

      // increase bounty
      const post = await postFactory.posts(0);
      const postContract = await hre.ethers.getContractAt(
        'Post',
        post,
        questioner // IMPORTANT: questioner should be signer as we are interacting with the contract as questioner
      );
      const increaseAmount = hre.ethers.parseEther('0.0001');
      const tx = await postContract.increaseQuestionerBounty(increaseAmount, {
        value: increaseAmount,
      });

      expect(await postContract.companyBounty()).to.equal(bountyAmount);
      expect(await postContract.questionerBounty()).to.equal(
        bountyAmount + increaseAmount
      );

      await expect(tx)
        .to.emit(postFactory, 'QuestionerBountyIncreased')
        .withArgs(
          await postContract.getAddress(),
          questioner.address,
          increaseAmount
        );
    });

    it('Bounty can be decreased by questioner', async () => {
      const { postFactory, questioner, company } = await loadFixture(
        deployPostFactory
      );

      // create post
      const bountyAmount = hre.ethers.parseEther('0.0005');
      await postFactory.createPost(
        questioner,
        company,
        bountyAmount,
        bountyAmount,
        { value: hre.ethers.parseEther('0.001') }
      );

      // decrease bounty
      const post = await postFactory.posts(0);
      const postContract = await hre.ethers.getContractAt(
        'Post',
        post,
        questioner // IMPORTANT: questioner should be signer as we are interacting with the contract as questioner
      );
      const decreaseAmount = hre.ethers.parseEther('0.0001');
      const tx = await postContract.decreaseQuestionerBounty(decreaseAmount);

      expect(await postContract.companyBounty()).to.equal(bountyAmount);
      expect(await postContract.questionerBounty()).to.equal(
        bountyAmount - decreaseAmount
      );

      await expect(tx)
        .to.emit(postFactory, 'QuestionerBountyDecreased')
        .withArgs(
          await postContract.getAddress(),
          questioner.address,
          decreaseAmount
        );
    });

    it('Bounty can be increased by company', async () => {
      const { postFactory, questioner, company } = await loadFixture(
        deployPostFactory
      );

      // create post
      const bountyAmount = hre.ethers.parseEther('0.0005');
      await postFactory.createPost(
        questioner,
        company,
        bountyAmount,
        bountyAmount,
        { value: hre.ethers.parseEther('0.001') }
      );

      // increase bounty
      const post = await postFactory.posts(0);
      const postContract = await hre.ethers.getContractAt(
        'Post',
        post,
        company // IMPORTANT: company should be signer as we are interacting with the contract as company
      );
      const increaseAmount = hre.ethers.parseEther('0.0001');
      const tx = await postContract.increaseCompanyBounty(increaseAmount, {
        value: increaseAmount,
      });

      expect(await postContract.companyBounty()).to.equal(
        bountyAmount + increaseAmount
      );
      expect(await postContract.questionerBounty()).to.equal(bountyAmount);

      await expect(tx)
        .to.emit(postFactory, 'CompanyBountyIncreased')
        .withArgs(
          await postContract.getAddress(),
          company.address,
          increaseAmount
        );
    });

    it('Bounty can be decreased by company', async () => {
      const { postFactory, questioner, company } = await loadFixture(
        deployPostFactory
      );

      // create post
      const bountyAmount = hre.ethers.parseEther('0.0005');
      await postFactory.createPost(
        questioner,
        company,
        bountyAmount,
        bountyAmount,
        { value: hre.ethers.parseEther('0.001') }
      );

      // decrease bounty
      const post = await postFactory.posts(0);
      const postContract = await hre.ethers.getContractAt(
        'Post',
        post,
        company // IMPORTANT: company should be signer as we are interacting with the contract as company
      );
      const decreaseAmount = hre.ethers.parseEther('0.0001');
      const tx = await postContract.decreaseCompanyBounty(decreaseAmount);

      expect(await postContract.companyBounty()).to.equal(
        bountyAmount - decreaseAmount
      );
      expect(await postContract.questionerBounty()).to.equal(bountyAmount);

      await expect(tx)
        .to.emit(postFactory, 'CompanyBountyDecreased')
        .withArgs(
          await postContract.getAddress(),
          company.address,
          decreaseAmount
        );
    });

    it('Answerer can add an answer', async () => {
      const { postFactory, questioner, company, answerer } = await loadFixture(
        deployPostFactory
      );

      // create post
      const bountyAmount = hre.ethers.parseEther('0.0005');
      await postFactory.createPost(
        questioner,
        company,
        bountyAmount,
        bountyAmount,
        { value: hre.ethers.parseEther('0.001') }
      );

      // add answer
      const post = await postFactory.posts(0);
      const postContract = await hre.ethers.getContractAt(
        'Post',
        post,
        answerer // IMPORTANT: answerer should be signer as we are interacting with the contract as answerer
      );
      const tx = await postContract.addAnswer();

      expect(await postContract.answerers(0)).to.equal(answerer.address);

      await expect(tx)
        .to.emit(postFactory, 'AnswerAdded')
        .withArgs(await postContract.getAddress(), answerer.address);
    });

    it('Answerer can remove an answer', async () => {
      const { postFactory, questioner, company, answerer } = await loadFixture(
        deployPostFactory
      );

      // create post
      const bountyAmount = hre.ethers.parseEther('0.0005');
      await postFactory.createPost(
        questioner,
        company,
        bountyAmount,
        bountyAmount,
        { value: hre.ethers.parseEther('0.001') }
      );

      // add answer
      const post = await postFactory.posts(0);
      const postContract = await hre.ethers.getContractAt(
        'Post',
        post,
        answerer // IMPORTANT: answerer should be signer as we are interacting with the contract as answerer
      );
      await postContract.addAnswer();

      // remove answer
      const tx = await postContract.removeAnswer();

      expect(await postContract.getAnswerersLength()).to.equal(0);

      await expect(tx)
        .to.emit(postFactory, 'AnswerRemoved')
        .withArgs(await postContract.getAddress(), answerer.address);
    });

    it('Question can be removed by owner', async () => {
      const { postFactory, questioner, company, owner } = await loadFixture(
        deployPostFactory
      );

      const questionerBalance = await hre.ethers.provider.getBalance(
        questioner.address
      );
      const companyBalance = await hre.ethers.provider.getBalance(
        company.address
      );

      // create post
      const bountyAmount = hre.ethers.parseEther('0.0005');
      await postFactory.createPost(
        questioner,
        company,
        bountyAmount,
        bountyAmount,
        { value: hre.ethers.parseEther('0.001') }
      );

      // remove question
      const post = await postFactory.posts(0);
      const postContract = await hre.ethers.getContractAt(
        'Post',
        post,
        owner // IMPORTANT: owner should be signer as we are interacting with the contract as owner
      );
      const tx = await postContract.removeQuestion();

      expect(await postFactory.getPostsLength()).to.equal(0);

      await expect(tx)
        .to.emit(postFactory, 'QuestionRemovedByAdmin')
        .withArgs(await postContract.getAddress());

      // check that funds are returned to questioner and company
      expect(await hre.ethers.provider.getBalance(questioner.address)).to.equal(
        questionerBalance + bountyAmount
      );
      expect(await hre.ethers.provider.getBalance(company.address)).to.equal(
        companyBalance + bountyAmount
      );
    });

    it('Winner can be chosen by  questioner', async () => {
      const { postFactory, questioner, company, answerer } = await loadFixture(
        deployPostFactory
      );

      // create post
      const bountyAmount = hre.ethers.parseEther('0.0005');
      await postFactory.createPost(
        questioner,
        company,
        bountyAmount,
        bountyAmount,
        { value: hre.ethers.parseEther('0.001') }
      );

      // choose winner
      const post = await postFactory.posts(0);
      const postContractAsAnswerer = await hre.ethers.getContractAt(
        'Post',
        post,
        answerer // IMPORTANT: answerer should be signer as we are interacting with the contract as answerer
      );
      await postContractAsAnswerer.addAnswer();
      expect(await postContractAsAnswerer.getAnswerersLength()).to.equal(1);

      const postContractAsQuestioner = await hre.ethers.getContractAt(
        'Post',
        post,
        questioner // IMPORTANT: questioner should be signer as we are interacting with the contract as questioner
      );

      expect(await postContractAsQuestioner.getAnswerersLength()).to.equal(1);
      const startingAnswererBalance = await hre.ethers.provider.getBalance(
        answerer.address
      );
      const tx = await postContractAsQuestioner.chooseWinner(answerer.address);
      expect(await postContractAsQuestioner.winner()).to.equal(
        answerer.address
      );

      await expect(tx)
        .to.emit(postFactory, 'WinnerSelected')
        .withArgs(
          await postContractAsAnswerer.getAddress(),
          answerer.address,
          bountyAmount,
          bountyAmount
        );

      // check that funds are transferred to winner
      expect(await hre.ethers.provider.getBalance(answerer.address)).to.equal(
        startingAnswererBalance + bountyAmount + bountyAmount
      );
    });
  });
});
