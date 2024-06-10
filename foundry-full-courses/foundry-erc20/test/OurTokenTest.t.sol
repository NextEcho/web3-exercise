// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {OurToken} from "../src/OurToken.sol";
import {DeployOurToken} from "../script/DeployOurToken.s.sol";

contract OurTokenTest is Test {
    OurToken public ourToken;
    DeployOurToken public deployOurToken;

    address bob = makeAddr("Bob");
    address alice = makeAddr("Alice");

    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() public {
        deployOurToken = new DeployOurToken();
        ourToken = deployOurToken.run();

        vm.prank(msg.sender);
        ourToken.transfer(bob, STARTING_BALANCE);
    }

    function testBobBalance() public view {
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE);
    }

    function testAllowanceTransfer() public {
        uint256 initialAllowance = 1000;

        // bob approve alice to spend tokens on his behalf
        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);

        uint256 transferAmount = 500;

        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);

        assertEq(ourToken.balanceOf(alice), transferAmount);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
    }

    function testTransfer() public {
        uint256 amount = 100;
        address receiver = address(0x1);

        vm.prank(msg.sender);
        ourToken.transfer(receiver, amount);
        assertEq(ourToken.balanceOf(receiver), amount);
    }
}
