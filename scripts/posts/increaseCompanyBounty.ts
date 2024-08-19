import { ethers } from 'hardhat';
import 'dotenv/config';

async function main() {
  const contractAddress = process.env.ARB_SEPOLIA_POST_CONTRACT_ADDRESS!;
  const wallet = new ethers.Wallet(process.env.ARB_WALLET_COMPANY_PRIVATE_KEY!);

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
  const tx = await postContract.increaseCompanyBounty(
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
