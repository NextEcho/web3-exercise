// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BasicNft is ERC721 {
    // NFT 代币是代币ID和地址的组合
    uint256 private s_tokenCounter;

    constructor() ERC721("Dogie", "DOG") {
        s_tokenCounter = 0;
    }

    // EIP721 中最重要的函数之一: tokenURI
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return "saldkjsakld";
    }
}
