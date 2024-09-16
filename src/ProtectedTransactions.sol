// ██████╗░██████╗░░█████╗░████████╗███████╗░█████╗░████████╗███████╗██████╗░
// ██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██╔══██╗╚══██╔══╝██╔════╝██╔══██╗
// ██████╔╝██████╔╝██║░░██║░░░██║░░░█████╗░░██║░░╚═╝░░░██║░░░█████╗░░██║░░██║
// ██╔═══╝░██╔══██╗██║░░██║░░░██║░░░██╔══╝░░██║░░██╗░░░██║░░░██╔══╝░░██║░░██║
// ██║░░░░░██║░░██║╚█████╔╝░░░██║░░░███████╗╚█████╔╝░░░██║░░░███████╗██████╔╝
// ╚═╝░░░░░╚═╝░░╚═╝░╚════╝░░░░╚═╝░░░╚══════╝░╚════╝░░░░╚═╝░░░╚══════╝╚═════╝░

// ████████╗██████╗░░█████╗░███╗░░██╗░██████╗░█████╗░░█████╗░████████╗██╗░█████╗░███╗░░██╗░██████╗
// ╚══██╔══╝██╔══██╗██╔══██╗████╗░██║██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║██╔════╝
// ░░░██║░░░██████╔╝███████║██╔██╗██║╚█████╗░███████║██║░░╚═╝░░░██║░░░██║██║░░██║██╔██╗██║╚█████╗░
// ░░░██║░░░██╔══██╗██╔══██║██║╚████║░╚═══██╗██╔══██║██║░░██╗░░░██║░░░██║██║░░██║██║╚████║░╚═══██╗
// ░░░██║░░░██║░░██║██║░░██║██║░╚███║██████╔╝██║░░██║╚█████╔╝░░░██║░░░██║╚█████╔╝██║░╚███║██████╔╝
// ░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░╚═╝░░╚═╝░╚════╝░░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝╚═════╝░

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";


contract ProtectedTransactions {
    using SafeTransferLib for ERC20;
    mapping(bytes32 => uint256) public transactions;

    event TokenTxCreated(address _from, address _to, bytes32 _secret, address _tokenAddress);
    event EthTxCreated(address _from, address _to, bytes32 _secret);

    function sendEth(address _to, string calldata _secret) public payable {
        transactions[keccak256(abi.encodePacked(msg.sender, _to, _secret))] += msg.value;
        emit EthTxCreated(msg.sender, _to, keccak256(abi.encodePacked(_secret)));
    }

    function cancelSendEth(address _to, string calldata _secret) public {
        transactions[keccak256(abi.encodePacked(msg.sender, _to, _secret))] = 0;
    }

    function claimEth(address _from, string calldata _secret) public {
        payable(msg.sender).transfer(transactions[keccak256(abi.encodePacked(_from, msg.sender, _secret))]);
        transactions[keccak256(abi.encodePacked(_from, msg.sender, _secret))] = 0;
    }
    

    function sendToken(address _to, uint256 _amount, string calldata _secret, address _tokenAddress) public 
    {
        // Transfer tokens from the sender to this contract
        require(
            ERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount),
            "Token transfer failed"
        );

        //update transactions
        transactions[keccak256(abi.encodePacked(msg.sender, _to, _secret, _tokenAddress))] += _amount;
        emit TokenTxCreated(msg.sender, _to, keccak256(abi.encodePacked(_secret)), _tokenAddress);
    }

    function cancelSendToken(address _to, string calldata _secret, address _tokenAddress) public {
        //transfer tokens back to the sender
        ERC20(_tokenAddress).safeTransfer(msg.sender, transactions[keccak256(abi.encodePacked(msg.sender, _to, _secret, _tokenAddress))]);
        //update transactions
        transactions[keccak256(abi.encodePacked(msg.sender, _to, _secret, _tokenAddress))] = 0;
    }

    function claimToken(address _from, string calldata _secret, address _tokenAddress) public {
        ERC20(_tokenAddress).safeTransfer(msg.sender, transactions[keccak256(abi.encodePacked(_from, msg.sender, _secret, _tokenAddress))]);
        transactions[keccak256(abi.encodePacked(_from, msg.sender, _secret, _tokenAddress))] = 0;
    }
}