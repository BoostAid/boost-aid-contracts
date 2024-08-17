import { ethers } from 'hardhat';
import 'dotenv/config';

async function main() {
  const contractAddress = '0x19dccc733761953d47E9529fc1B2f0c8E53b48B1';
  const wallet = new ethers.Wallet(
    process.env.ARB_WALLET_QUESTIONER_PRIVATE_KEY!
  );

  // arbitrum sepolia connection
  const provider = new ethers.AlchemyProvider(
    'arbitrum-sepolia',
    process.env.ACLHEMY_ARB_API_KEY!
  );

  const signer = wallet.connect(provider);

  const postContract = await ethers.getContractAt(
    'Post',
    contractAddress,
    signer
  );
  const tx = await postContract.increaseQuestionerBounty(
    ethers.parseEther('0.0000278'),
    {
      value: ethers.parseEther('0.0000278'),
    }
  );
  console.log(`Transaction hash: ${tx.hash}`);

  await tx.wait();
  console.log('Transaction confirmed');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
