// SPDX-License-Indetifier: MIT
pragma solidity ^0.8.18;

// Solidity 中的引用类型包含
// 1. 数组(array)
// 2. 结构体(struct)
// 3. 映射(mapping)
// 由于这一类的数据类型占用空间大，在声明这些类型的变量时需要指定数据存储的未知

// data location contains Three types:
// 1. storage: stroaged on blockchain.
// 2. memory: storaged in memory.
// 3. calldata: stroaged in memory. but compared to memory, it's read-only


/////////////////////////////////
/////////////////////////////////
contract DataStroage {

    uint[] x = [1,2,3];

    function fCallData(uint[] calldata _x)   public pure returns(uint[] calldata) {
        return (_x);
    }

    function fStorage() public {
        uint[] storage xStorage = x;
        xStorage[1] = 200;
    }
}