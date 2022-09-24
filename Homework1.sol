// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ETHStore {
uint256 public balance;
address public owner;

constructor() {
    owner = msg.sender;
}

receive() payable external {
    balance += msg.value;
}

modifier onlyowner(){
    //Trying to keep error messages short to save gas.
    require(msg.sender==owner, "Unauthorized");
    _;
}

function withdraw(uint amount, address payable destination) public onlyowner{
    require(amount <= balance, "Insufficient");
    balance = balance - amount;
    destination.transfer(amount);
}
}
