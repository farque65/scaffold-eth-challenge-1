//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ExampleExternalContract.sol"; //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract Staker {
  ExampleExternalContract public exampleExternalContract;

  mapping (address => uint256) public balances;
  uint256 public threshold = 1 ether;
  uint256 public deadline = block.timestamp + 30 seconds;

  event Stake(address indexed staker, uint256 balance);
  bool public openForWithdraw;

  modifier deadlineReached(bool requireReached) {
    uint256 remainingTime = timeLeft();
    if(requireReached) {
      require(remainingTime == 0, "Deadline is not reached yet");
    }
    require(block.timestamp >= deadline, "Deadline is already reached");
    _;
  }

  modifier notCompleted() {
    require(
        exampleExternalContract.completed() == false,
        "ExampleExternalContract is not complete"
    );
    _;
  }

  constructor(address exampleExternalContractAddress) public {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable notCompleted deadlineReached(false) {
    balances[msg.sender] = balances[msg.sender] + msg.value;
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
  function withdraw() public payable notCompleted deadlineReached(true) {
    require(block.timestamp > deadline, "deadline hasn't passed yet");
    require(balances[msg.sender] > 0, "Stake amount is empty");
    address payable to = payable(msg.sender);
    to.transfer(balances[msg.sender]);
    emit Stake(msg.sender, balances[msg.sender]);
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256 timeleft) {
    if( block.timestamp >= deadline ) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
  }
}
