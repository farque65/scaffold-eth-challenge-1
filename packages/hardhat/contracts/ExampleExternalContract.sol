pragma solidity ^0.8.4;

contract ExampleExternalContract {

  bool public completed;
  mapping (address => uint256) public balances;

  function complete() public payable {
    completed = true;
  }

  function ExampleExternalContractStake(uint256 amount) public payable {
    balances[msg.sender] += amount;
  }

}
