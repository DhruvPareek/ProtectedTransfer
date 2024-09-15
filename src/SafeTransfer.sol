// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// ░██████╗░█████╗░███████╗███████╗████████╗██████╗░░█████╗░███╗░░██╗░██████╗███████╗███████╗██████╗░
// ██╔════╝██╔══██╗██╔════╝██╔════╝╚══██╔══╝██╔══██╗██╔══██╗████╗░██║██╔════╝██╔════╝██╔════╝██╔══██╗
// ╚█████╗░███████║█████╗░░█████╗░░░░░██║░░░██████╔╝███████║██╔██╗██║╚█████╗░█████╗░░█████╗░░██████╔╝
// ░╚═══██╗██╔══██║██╔══╝░░██╔══╝░░░░░██║░░░██╔══██╗██╔══██║██║╚████║░╚═══██╗██╔══╝░░██╔══╝░░██╔══██╗
// ██████╔╝██║░░██║██║░░░░░███████╗░░░██║░░░██║░░██║██║░░██║██║░╚███║██████╔╝██║░░░░░███████╗██║░░██║
// ╚═════╝░╚═╝░░╚═╝╚═╝░░░░░╚══════╝░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░╚═╝░░░░░╚══════╝╚═╝░░╚═╝

//Can add asserts to say balance of this order is 0 or you cannot claim this order or you cannot cancel this order

contract SafeTransfer {
    mapping(bytes32 => uint256) public balances;

    function send(address _to, string calldata _secret) public payable {
        balances[keccak256(abi.encodePacked(msg.sender, _to, _secret))] += msg.value;
    }

    function cancelSend(address _to, string calldata _secret) public {
        balances[keccak256(abi.encodePacked(msg.sender, _to, _secret))] = 0;
    }

    function claim(address _from, string calldata _secret) public {
        payable(msg.sender).transfer(balances[keccak256(abi.encodePacked(_from, msg.sender, _secret))]);
        balances[keccak256(abi.encodePacked(_from, msg.sender, _secret))] = 0;
    }
}
