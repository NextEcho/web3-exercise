package main

import (
	"context"
	"fmt"
	"log"
	"math"
	"math/big"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
)

const Account_0 = "0xF6b9f85e01228B56ca43A039DBE15AF867c6b2C0"

func QueryBalanceOfAccount() {

	client, err := ethclient.Dial("http://127.0.0.1:8545")
	if err != nil {
		log.Fatal(err)
	}

	account := common.HexToAddress(Account_0)
	balance, err := client.BalanceAt(context.Background(), account, nil)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("balance is %v wei\n", balance)

	// if need to block_number, type must be `*big.Int`
	blockNumber := big.NewInt(0)
	balance, err = client.BalanceAt(context.Background(), account, blockNumber)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("balance is %v wei\n", balance)

	// Convert into ETH
	fBalance := new(big.Float)
	fBalance.SetString(balance.String())
	ethValue := new(big.Float).Quo(fBalance, big.NewFloat(math.Pow10(18)))
	fmt.Printf("ETH of balance is %v eth\n", ethValue)

	// PendingBalanceAt function
	pendingBalance, err := client.PendingBalanceAt(context.Background(), account)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("PendingBalance is %v wei\n", pendingBalance)
}
