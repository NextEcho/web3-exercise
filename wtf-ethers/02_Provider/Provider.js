import { ethers } from "ethers";

const ALCHEMY_SEPOLIA_URL = "https://eth-sepolia.g.alchemy.com/v2/demo";
const providerSepolia = new ethers.JsonRpcProvider(ALCHEMY_SEPOLIA_URL);

// 1. 查询 Sepolia 测试网上某地址的 ETH 余额
console.log("1. query ETH balance of sepolia test network.\n");
const balance = await providerSepolia.getBalance("0xd8dA6BF26964aF9D7eEd9e03E534969A7a456C24");
console.log(`ETH balance of sepolia test network: ${ethers.formatEther(balance)} ETH.`);

// 2. 查询哪个链正在被连接
console.log("\n2. query which blockchain is connected.\n");
const network = await providerSepolia.getNetwork();
console.log(network.toJSON());

// 3. 查询区块链高度
console.log("\n3. query the hight of blockchain.\n");
const blockNumber = await providerSepolia.getBlockNumber();
console.log(blockNumber);

// 4. 查询该地址历史的交易次数
console.log("\n4. query the historical transaction count of an address.\n");
const transactionCount = await providerSepolia.getTransactionCount("0xd8dA6BF26964aF9D7eEd9e03E534969A7a456C24");
console.log(transactionCount);

// 5. 查询当前推荐的 gas 费用
console.log("\n5. query the currently suggested gas price.\n");
const gasPrice = await providerSepolia.getFeeData();
console.log(gasPrice);

// 6. 查询区块的信息
console.log("\n6. query the information of block.\n");
const block = await providerSepolia.getBlock(0);
console.log(block);

// 7. 查询某个合约地址的字节码
console.log("\n7. query contract bytecode of an address.\n");
const bytecode = await providerSepolia.getCode("0xd8dA6BF26964aF9D7eEd9e03E534969A7a456C24");
console.log(bytecode);
