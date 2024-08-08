package main

import (
	"log"

	"github.com/ethereum/go-ethereum/ethclient"
)

const Addr = "http://127.0.0.1:8545"

func ConnectEthClient() *ethclient.Client {

	client, err := ethclient.Dial(Addr)
	if err != nil {
		log.Fatal(err)
		panic(err)
	}

	return client
}
