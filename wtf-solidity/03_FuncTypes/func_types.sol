// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract FuncTypes {
    uint256 public number = 5;

    function add() external {
        number = number + 1;
    }

    // internal 内部函数合约外无法直接调用
    function minus() internal {
        number = number - 1;
    }

    // 需要一个 external 的函数来调用 internal 修饰的函数
    function minusCall() external {
        minus();
    }

    function minusPayable() external payable returns(uint256 balance) {
        minus();
        balance = address(this).balance;
    }
}