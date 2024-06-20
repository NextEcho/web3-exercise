package main

import (
	"context"
	"fmt"
	"log"
	"math/big"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
)

func main() {
	// 链接本地区块链网络
	client, err := ethclient.Dial("http://localhost:8545")
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Connection!")
	_ = client

	// 地址转换
	address := common.HexToAddress("0x71c7656ec7ab88b098defb751b7401b5f6d8976f")
	fmt.Println(address.Hex())

	// 账户余额操作
	blockNumber := big.NewInt(0) // 可以指定传递区块号, 传递 nil 则表示账户下最新的区块
	balance, err := client.BalanceAt(context.Background(), address, blockNumber)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("账户余额: ", balance)

	// 生成新钱包
	// privateKey, err := crypto.GenerateKey()
	// if err != nil {
	// 	log.Fatal(err)
	// }

	// privateKeyBytes := crypto.FromECDSA(privateKey)

}
