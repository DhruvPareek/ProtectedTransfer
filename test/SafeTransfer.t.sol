// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SafeTransfer} from "../src/SafeTransfer.sol";

contract TestSafeTransfer is Test {
    SafeTransfer public safeTransfer = new SafeTransfer();
    address public jaxon = address(0x1);
    address public lockett = address(0x2);
    address public dk = address(0x3);

    function setUp() public {
        safeTransfer = new SafeTransfer();
        vm.deal(jaxon, 1 ether);
        vm.deal(lockett, 1 ether);
    }

    function testSend() public {
        vm.startPrank(jaxon);

        safeTransfer.send{value: 100 wei}(lockett, "secret");
        assertEq(safeTransfer.balances(keccak256(abi.encodePacked(jaxon, lockett, "secret"))), 100);

        vm.stopPrank();
    }

    function testCancelSend() public {
        vm.prank(jaxon);
        safeTransfer.send{value: 100 wei}(lockett, "secret");

        //non tx creator can't cancel someone else's tx
        vm.startPrank(lockett);
        safeTransfer.cancelSend(lockett, "secret");
        assertEq(safeTransfer.balances(keccak256(abi.encodePacked(jaxon, lockett, "secret"))), 100);
        vm.stopPrank();

        vm.startPrank(jaxon);

        //cancel tx with different secret shouldn't affect original tx
        safeTransfer.cancelSend(lockett, "secret1");
        assertEq(safeTransfer.balances(keccak256(abi.encodePacked(jaxon, lockett, "secret"))), 100);

        //correct cancel tx should work
        safeTransfer.cancelSend(lockett, "secret");
        assertEq(safeTransfer.balances(keccak256(abi.encodePacked(jaxon, lockett, "secret"))), 0);

        //cancel tx twice shouldn't do anything
        safeTransfer.cancelSend(lockett, "secret");
        assertEq(safeTransfer.balances(keccak256(abi.encodePacked(jaxon, lockett, "secret"))), 0);

        vm.stopPrank();

        vm.startPrank(lockett);

        //claiming tx after cancel should not work
        uint256 balance = address(jaxon).balance;
        safeTransfer.claim(jaxon, "secret");
        uint256 balance2 = address(jaxon).balance;
        assertEq(balance, balance2);

        vm.stopPrank();
    }

    function testClaim() public {
        vm.prank(jaxon);
        safeTransfer.send{value: 100 wei}(lockett, "tokeen");

        vm.startPrank(dk);

        //wrong receiver shohuld not be able to claim tx
        uint256 balance = address(dk).balance;
        safeTransfer.claim(dk, "tokeenn");
        uint256 balance2 = address(dk).balance;
        assertEq(balance, balance2);

        vm.startPrank(lockett);

        //wrong secret should not be able to claim tx
        balance = address(jaxon).balance;
        safeTransfer.claim(jaxon, "tokern");
        balance2 = address(jaxon).balance;
        assertEq(balance, balance2);

        //correct claim should work
        balance = address(lockett).balance;
        safeTransfer.claim(jaxon, "tokeen");
        balance2 = address(lockett).balance;
        assertEq(balance, balance2 - 100 wei);

        vm.stopPrank();
    }
    //srite test for wrong secret should fail
}
