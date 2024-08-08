package main

import (
	"context"
	"fmt"
	"log"

	"github.com/ethereum/go-ethereum/common"
)

func QueryTransactions() {

	client := ConnectEthClient()

	block, err := client.BlockByNumber(context.Background(), nil)
	if err != nil {
		panic(err)
	}

	fmt.Println("Count of block's tx is", len(block.Transactions()))
	for _, tx := range block.Transactions() {
		fmt.Println(tx.Hash().Hex())

		// There is a receipt for each transaction, that contains result of the transaction
		receipt, err := client.TransactionReceipt(context.Background(), tx.Hash())
		if err != nil {
			log.Fatal(err)
		}

		fmt.Println(receipt.Status)
		fmt.Println(receipt.Logs)
	}

	// query transaction by hash
	txHash := common.HexToHash("0x5d49fcaa394c97ec8a9c3e7bd9e8388d420fb050a52083ca52ff24b3b65bc9c2")
	tx, isPending, err := client.TransactionByHash(context.Background(), txHash)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println(tx.Hash().Hex())
	fmt.Println(isPending)
}
