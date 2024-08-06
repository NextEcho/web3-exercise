package main

import (
	"crypto/ecdsa"
	"fmt"
	"log"

	"github.com/ethereum/go-ethereum/common/hexutil"
	"github.com/ethereum/go-ethereum/crypto"
)

func GenerateNewWallet() {

	privateKey, err := crypto.GenerateKey()
	if err != nil {
		log.Fatalf(err.Error())
		return
	}

	// convert into bytes
	pkBytes := crypto.FromECDSA(privateKey)
	fmt.Println("privateKey is", hexutil.Encode(pkBytes))

	// generate public key from privateKey
	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		log.Fatal("Cannot assert type: publicKey is not of type *ecdsa.PublicKey")
	}

	publicKeyBytes := crypto.FromECDSAPub(publicKeyECDSA)
	fmt.Println("publicKey is", hexutil.Encode(publicKeyBytes)[4:])

	address := crypto.PubkeyToAddress(*publicKeyECDSA).Hex()
	fmt.Println("address generated from publicKey is", address)
}
