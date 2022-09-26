// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ETHStore {
uint256 public balance;
address public owner;

constructor() {
    owner = msg.sender;
}

//Adds to balance
receive() payable external {
    balance += msg.value;
}

//To code in a more clean way I am creating a modifier.
modifier onlyowner(){
    //Trying to keep error messages short to save gas.
    require(msg.sender==owner, "Unauthorized");
    _;
}

//Only owner can withdraw money so modified with onlyowner() modifier
function withdraw(uint amount, address payable destination) public onlyowner{
    require(amount <= balance, "Insufficient");
    //Placing this code before the second one in order to prevent hacking. 
    balance = balance - amount;
    destination.transfer(amount);
}
}
