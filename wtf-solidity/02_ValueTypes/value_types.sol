// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18

contract TypesValue {

    // bool 运算
    bool public _bool = false;
    bool public _bool1 = !_bool;
    bool public _bool2 = _bool && _bool1;
    bool public _bool2 = _bool || _bool1;
    bool public _bool3 = _bool == _bool1;
    bool public _bool4 = _bool != _bool1;

    // 数值运算
    int public _int = -100;
    uint public _uint = 20;
    uint256 public _number = 20220330;

    uint256 public _number1 = _number + 1;
    uint256 public _number2 = 2 **2  ; // 指数运算
    uint256 public _number3 = 7 % 2; // 取余数
    bool public _numberBool = _number2 > _number3;

    // 地址类型
    address public _address = 0x7A58c0Be72BE218B41C608b7Fe7C5bB630736C71;
    address payable public _address1 = payable(_address); // payable 表示该地址可转账和查余额
    uint public _balance = _address1.balance; // 该地址所持有的余额

    // 定长字节数组
    bytes32 public _byte32 = "MiniSolidity";
    bytes1 public _byte = _byte32[0];

    // 枚举，几乎没人用
    enum ActionSet {
        Buy,
        Hold,
        Sell
    }

    ActionSet action = ActionSet.Buy;
    function enumToUint() external view returns(uint) {
        return uint(action);
    }
}