import { ethers } from 'hardhat';
import 'dotenv/config';

async function main() {
  const contractAddress = process.env.ARB_SEPOLIA_POST_CONTRACT_ADDRESS!;
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
  const tx = await postContract.chooseWinner(
    '0x43Db655aeFFbFAf8575A58BE19abaad401f8c4B2'
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