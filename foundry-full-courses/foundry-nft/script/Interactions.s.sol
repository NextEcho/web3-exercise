// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {BasicNft} from "../src/BasicNft.sol";
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
