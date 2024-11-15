import { ethers } from 'ethers';
import { randomBytes } from 'crypto';

const LOTTERY_ABI = [
  "function inResolution() view returns (bool)",
  "function lotteryId() view returns (uint32)",
  "function startTimes(uint32) view returns (uint256)",
  "function DURATION() view returns (uint256)",
  "function commitValueAndStartResolution(uint256) payable",
  "function revealValueAndResolveLottery(uint256)",
  "function COMMITTER_STAKE() view returns (uint256)"
];

const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY!, provider);
const lotteryContract = new ethers.Contract(process.env.LOTTERY_ADDRESS!, LOTTERY_ABI, wallet);

async function monitorLottery() {
  console.log('Starting lottery monitor...');

  let storedPreimage: bigint | null = null;
  let commitBlock: number | null = null;

  provider.on('block', async (blockNumber) => {
    try {
      const inResolution = await lotteryContract.inResolution();
      if (inResolution) {
        // We're already in resolution phase
        if (storedPreimage && commitBlock && blockNumber > commitBlock) {
          // Time to reveal our preimage
          console.log('Revealing preimage...');
          const tx = await lotteryContract.revealValueAndResolveLottery(storedPreimage);
          await tx.wait();
          console.log('Successfully revealed and resolved lottery!');
          storedPreimage = null;
          commitBlock = null;
        }
        return;
      }

      // Check if lottery is ready for resolution
      const lotteryId = await lotteryContract.lotteryId();
      const startTime = await lotteryContract.startTimes(lotteryId);
      const duration = await lotteryContract.DURATION();
      const currentTime = Math.floor(Date.now() / 1000);

      if (currentTime < startTime + duration) {
        return; // Not ready yet
      }

      // Time to commit our value
      console.log('Starting resolution...');
      
      // Generate random preimage
      const preimageBytes = randomBytes(32);
      const preimage = BigInt('0x' + preimageBytes.toString('hex'));
      const commitHash = ethers.keccak256(ethers.toBeArray(preimage));
      
      // Get stake amount
      const stake = await lotteryContract.COMMITTER_STAKE();
      
      // Commit our value
      const tx = await lotteryContract.commitValueAndStartResolution(commitHash, {
        value: stake
      });
      await tx.wait();
      
      // Store preimage for reveal
      storedPreimage = preimage;
      commitBlock = blockNumber;
      
      console.log('Successfully committed value');

    } catch (error) {
      console.error('Error in lottery monitor:', error);
    }
  });
}

// Handle cleanup
process.on('SIGINT', () => {
  provider.removeAllListeners();
  process.exit();
});

monitorLottery().catch(console.error);