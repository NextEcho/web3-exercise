package main

import (
	"fmt"
	"log"

	"github.com/ethereum/go-ethereum/ethclient"
)

// 1. Connect ethereum client with go
func ConnectEthClient() {

	client, err := ethclient.Dial("http://127.0.0.1:8545")
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Connection!!!")
	_ = client
}
