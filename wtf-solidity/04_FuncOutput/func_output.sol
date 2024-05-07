// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract FuncOutput {

    // 返回多种变量
    function returnMultiple() public pure returns(uint256, bool, uint256[3] memory) {
        return (1, true, [uint256(2), 5, 10]);
    }

    // 命名式返回
    function returnNamed() public pure returns(uint256 _number, bool _bool, uint256[3] memory _arr) {
        _number = 2;
        _bool = true;
        _arr = [uint256(2), 5, 10];

        // 这里不需要加 return
    }
}