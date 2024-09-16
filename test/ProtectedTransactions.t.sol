// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ProtectedTransactions} from "../src/ProtectedTransactions.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";

contract TestProtectedTransactions is Test {
    ProtectedTransactions public protectedTransactions = new ProtectedTransactions();

    address public jaxon = address(0x1);
    address public lockett = address(0x2);
    address public dk = address(0x3);

   MockERC20 public baseToken;
   MockERC20 public baseTokeern;

    function setUp() public {
        protectedTransactions = new ProtectedTransactions();
        baseToken = new MockERC20("Juan", "JUAN");
        baseTokeern = new MockERC20("Carlos", "CARLOS");

        vm.deal(jaxon, 1 ether);
        vm.deal(lockett, 1 ether);

        baseToken.mint(jaxon, 1000);
        baseToken.mint(lockett, 1000);
    }

    function testSendEth() public {
        vm.startPrank(jaxon);

        protectedTransactions.sendEth{value: 100 wei}(lockett, "secret");
        assertEq(protectedTransactions.transactions(keccak256(abi.encodePacked(jaxon, lockett, "secret"))), 100);

        vm.stopPrank();
    }

    function testCancelSendEth() public {
        vm.prank(jaxon);
        protectedTransactions.sendEth{value: 100 wei}(lockett, "secret");

        //non tx creator can't cancel someone else's tx
        vm.startPrank(lockett);
        protectedTransactions.cancelSendEth(lockett, "secret");
        assertEq(protectedTransactions.transactions(keccak256(abi.encodePacked(jaxon, lockett, "secret"))), 100);
        vm.stopPrank();

        vm.startPrank(jaxon);

        //cancel tx with different secret shouldn't affect original tx
        protectedTransactions.cancelSendEth(lockett, "secret1");
        assertEq(protectedTransactions.transactions(keccak256(abi.encodePacked(jaxon, lockett, "secret"))), 100);

        //correct cancel tx should work
        protectedTransactions.cancelSendEth(lockett, "secret");
        assertEq(protectedTransactions.transactions(keccak256(abi.encodePacked(jaxon, lockett, "secret"))), 0);

        //cancel tx twice shouldn't do anything
        protectedTransactions.cancelSendEth(lockett, "secret");
        assertEq(protectedTransactions.transactions(keccak256(abi.encodePacked(jaxon, lockett, "secret"))), 0);

        vm.stopPrank();

        vm.startPrank(lockett);

        //claiming tx after cancel should not work
        uint256 balance = address(jaxon).balance;
        protectedTransactions.claimEth(jaxon, "secret");
        uint256 balance2 = address(jaxon).balance;
        assertEq(balance, balance2);

        vm.stopPrank();
    }

    function testClaimEth() public {
        vm.prank(jaxon);
        protectedTransactions.sendEth{value: 100 wei}(lockett, "tokeen");

        vm.startPrank(dk);

        //wrong receiver shohuld not be able to claim tx
        uint256 balance = address(dk).balance;
        protectedTransactions.claimEth(jaxon, "tokeenn");
        uint256 balance2 = address(dk).balance;
        assertEq(balance, balance2);

        vm.stopPrank();

        vm.startPrank(lockett);

        //wrong secret should not be able to claim tx
        balance = address(lockett).balance;
        protectedTransactions.claimEth(jaxon, "tokern");
        balance2 = address(lockett).balance;
        assertEq(balance, balance2);

        //correct claim should work
        balance = address(lockett).balance;
        protectedTransactions.claimEth(jaxon, "tokeen");
        balance2 = address(lockett).balance;
        assertEq(balance, balance2 - 100 wei);

        vm.stopPrank();
    }

    function testSendToken() public {
        vm.startPrank(jaxon);

        baseToken.approve(address(protectedTransactions), 200);
        protectedTransactions.sendToken(lockett, 100 wei, "secret", address(baseToken));
        assertEq(protectedTransactions.transactions(keccak256(abi.encodePacked(jaxon, lockett, "secret", address(baseToken)))), 100);

        protectedTransactions.sendToken(lockett, 100 wei, "secret", address(baseToken));
        assertEq(protectedTransactions.transactions(keccak256(abi.encodePacked(jaxon, lockett, "secret", address(baseToken)))), 200);

        vm.stopPrank();
    }

    //should test that correct token address must be used or else tx not canced
    function testCancelSendToken() public {
        vm.startPrank(jaxon);
        baseToken.approve(address(protectedTransactions), 100 wei);
        protectedTransactions.sendToken(lockett, 100 wei, "secret", address(baseToken));
        vm.stopPrank();

        //non tx creator can't cancel someone else's tx
        vm.prank(lockett);
        protectedTransactions.cancelSendToken(lockett, "secret", address(baseToken));
        assertEq(protectedTransactions.transactions(keccak256(abi.encodePacked(jaxon, lockett, "secret", address(baseToken)))), 100);

        vm.startPrank(jaxon);

        //cancel tx with wrong tokena address shouldn't affect original tx
        protectedTransactions.cancelSendToken(lockett, "secret", address(baseTokeern));
        assertEq(protectedTransactions.transactions(keccak256(abi.encodePacked(jaxon, lockett, "secret", address(baseToken)))), 100);

        //cancel tx with different secret shouldn't affect original tx
        protectedTransactions.cancelSendToken(lockett, "secret1", address(baseToken));
        assertEq(protectedTransactions.transactions(keccak256(abi.encodePacked(jaxon, lockett, "secret", address(baseToken)))), 100);

        //correct cancel tx should work
        protectedTransactions.cancelSendToken(lockett, "secret", address(baseToken));
        assertEq(protectedTransactions.transactions(keccak256(abi.encodePacked(jaxon, lockett, "secret", address(baseToken)))), 0);

        //cancel tx twice shouldn't do anything
        protectedTransactions.cancelSendToken(lockett, "secret", address(baseToken));
        assertEq(protectedTransactions.transactions(keccak256(abi.encodePacked(jaxon, lockett, "secret", address(baseToken)))), 0);

        vm.stopPrank();

        vm.startPrank(lockett);

        //claiming tx after cancel should not work
        uint256 balance = baseToken.balanceOf(jaxon);
        protectedTransactions.claimToken(jaxon, "secret", address(baseToken));
        uint256 balance2 = baseToken.balanceOf(jaxon);
        assertEq(balance, balance2);

        vm.stopPrank();
    }

    function testClaimToken() public {
        vm.startPrank(jaxon);
        baseToken.approve(address(protectedTransactions), 100 wei);
        protectedTransactions.sendToken(lockett, 100 wei, "secret", address(baseToken));
        vm.stopPrank();

        vm.startPrank(dk);

        //wrong receiver shohuld not be able to claim tx
        uint256 balance = baseToken.balanceOf(dk);
        protectedTransactions.claimToken(jaxon, "secret", address(baseToken));
        uint256 balance2 = baseToken.balanceOf(dk);
        assertEq(balance, balance2);
        vm.stopPrank();

        vm.startPrank(lockett);

        //wrong secret should not be able to claim tx
        balance = baseToken.balanceOf(lockett);
        protectedTransactions.claimToken(jaxon, "tokern", address(baseToken));
        balance2 = baseToken.balanceOf(lockett);
        assertEq(balance, balance2);

        //wrong token address should not be able to claim tx
        balance = baseToken.balanceOf(lockett);
        protectedTransactions.claimToken(jaxon, "secret", address(baseTokeern));
        balance2 = baseToken.balanceOf(lockett);
        assertEq(balance, balance2);

        //correct claim should work
        balance = baseToken.balanceOf(lockett);
        protectedTransactions.claimToken(jaxon, "secret", address(baseToken));
        balance2 = baseToken.balanceOf(lockett);
        assertEq(balance + 100 wei, balance2);

        vm.stopPrank();
    }
}
