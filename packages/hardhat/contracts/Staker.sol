pragma solidity ^0.8.0;

import "./ExampleExternalContract.sol"; //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract Staker {
  // External contract that will old stacked funds
  ExampleExternalContract public exampleExternalContract;

  // Balances of the user's stacked funds
  mapping(address => uint256) public balances;

  // Staking threshold
  uint public constant threshold = 1 ether;

  // Contract's Events
  event Stake(address indexed sender, uint256 amount);

  constructor(address exampleExternalContractAddress) public {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  function stake() public payable {
    // update the user's balance
    balances[msg.sender] += msg.value;

    //emit the event to notify the blockchain that we have correctly Staked some fund for the user
    emit Stake(msg.sender, msg.value);
  }
}
