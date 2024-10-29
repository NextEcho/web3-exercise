import { ethers, Mnemonic } from "ethers";

// generate from prvateKey
const privateKey = "";
const wallet2 = new ethers.Wallet(privateKey, priovider);

// generate from Phrase
const wallet3 = ethers.Wallet.fromPhrase(Mnemonic.phrase)

const tx = {
	to: address,
	value: ethers.parseEther("0.001"),
}

const txRes = await wallet3.sendTransaction(tx);
const receipt = await txRes.wait(); // 等待链上确认
console.log(receipt);

const ALCHEMY_SEPOLIA_URL = "";
const provider = new ethers.JsonRpcProvider(ALCHEMY_SEPOLIA_URL);


