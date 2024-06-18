// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {BasicNft} from "../src/BasicNft.sol";
import {MoodNft} from "../src/MoodNft.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "forge-std/StdJson.sol";

contract MintBasicNft is Script {
    string public constant PUG =
        "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";

    function run() external {
        // address mostRecentlyDeployContract = DevOpsTools
        //     .get_most_recent_deployment("BasicNft", block.chainid);

        address mostRecentlyDeployContract = getDeployedContractAddress();

        mintNftOnContract(mostRecentlyDeployContract);
    }

    function mintNftOnContract(address contractAddress) public {
        vm.startBroadcast();
        BasicNft(contractAddress).mintNft(PUG);
        vm.stopBroadcast();
    }

    // Tool Function
    function getDeployedContractAddress() private view returns (address) {
        string memory path = string.concat(
            vm.projectRoot(),
            "/broadcast/DeployBasicNft.s.sol/",
            Strings.toString(block.chainid),
            "/run-latest.json"
        );
        string memory json = vm.readFile(path);
        bytes memory contractAddress = stdJson.parseRaw(
            json,
            ".transactions[0].contractAddress"
        );
        return (bytesToAddress(contractAddress));
    }

    function bytesToAddress(
        bytes memory bys
    ) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 32))
        }
    }
}

contract MintMoodNft is Script {
    function run() external {
        address mostRecentlyDeployContract = getDeployedContractAddress();

        mintMoodNftOnContract(mostRecentlyDeployContract);
    }

    function mintMoodNftOnContract(address contractAddress) public {
        vm.startBroadcast();
        MoodNft(contractAddress).mintNft();
        vm.stopBroadcast();
    }

    // Tool Function
    function getDeployedContractAddress() private view returns (address) {
        string memory path = string.concat(
            vm.projectRoot(),
            "/broadcast/DeployMoodNft.s.sol/",
            Strings.toString(block.chainid),
            "/run-latest.json"
        );
        string memory json = vm.readFile(path);
        bytes memory contractAddress = stdJson.parseRaw(
            json,
            ".transactions[0].contractAddress"
        );
        return (bytesToAddress(contractAddress));
    }

    function bytesToAddress(
        bytes memory bys
    ) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 32))
        }
    }
}

contract FlipMoodNft is Script {
    function run() external {
        address mostRecentlyDeployContract = getDeployedContractAddress();

        flipMoodNftOnContract(mostRecentlyDeployContract);
    }

    function flipMoodNftOnContract(address contractAddress) public {
        vm.startBroadcast();
        MoodNft(contractAddress).flipMood(0);
        vm.stopBroadcast();
    }

    // Tool Function
    function getDeployedContractAddress() private view returns (address) {
        string memory path = string.concat(
            vm.projectRoot(),
            "/broadcast/DeployMoodNft.s.sol/",
            Strings.toString(block.chainid),
            "/run-latest.json"
        );
        string memory json = vm.readFile(path);
        bytes memory contractAddress = stdJson.parseRaw(
            json,
            ".transactions[0].contractAddress"
        );
        return (bytesToAddress(contractAddress));
    }

    function bytesToAddress(
        bytes memory bys
    ) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 32))
        }
    }
}
