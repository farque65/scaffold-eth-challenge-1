//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol"; //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract Staker {
  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  mapping (address => uint256) public balances;
  uint256 public threshold = 1 ether;
  uint256 public deadline = block.timestamp + 24 hours;

  event Withdraw(address indexed withdrawer, uint256 amount);
  event Stake(address indexed staker, uint256 balance);
  bool public openForWithdraw = false;

  modifier deadlineReached(bool beforeDeadline) {
    if(beforeDeadline) {
      require(block.timestamp < deadline, "Deadline is already reached");
    } else {
      require(block.timestamp >= deadline, "Deadline not yet reached");
    }
    _;
  }

  modifier notCompleted() {
    require(
        exampleExternalContract.completed() == false,
        "ExampleExternalContract is not complete"
    );
    _;
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable deadlineReached(true) notCompleted  {
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() public payable deadlineReached(false) notCompleted {
    uint256 contractBalance = address(this).balance;

    // check the contract has enough ETH to reach the treshold
    require(contractBalance >= threshold, "Threshold not reached");

    // Execute the external contract, transfer all the balance to the contract
    // (bool sent, bytes memory data) = exampleExternalContract.complete{value: contractBalance}();
    (bool sent,) = address(exampleExternalContract).call{value: contractBalance}(abi.encodeWithSignature("complete()"));
    require(sent, "exampleExternalContract.complete failed");
  }

  // if the `threshold` was not met, allow everyone to call a `withdraw()` function
  function withdraw() public payable notCompleted {
    uint256 contractBalance = address(this).balance;
    if (block.timestamp >= deadline && contractBalance > threshold) {
      revert("Threshold met deadline and stake amount cannot be withdrawn.");
    }
    uint256 userBalance = balances[msg.sender];
    require(userBalance > 0, "Empty Balance");
    balances[msg.sender] = 0;
    // Transfer balance back to the user
    (bool sent,) = msg.sender.call{value: userBalance}("");
    require(sent, "Failed to send user balance back to the user");
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
    if( block.timestamp >= deadline ) {
      return 0;
    }
    return deadline - block.timestamp;
  }
}
