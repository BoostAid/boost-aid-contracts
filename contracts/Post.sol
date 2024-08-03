//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Author: @boostaid
contract Post {
    address public owner;
    address public questioner;
    uint public bounty;
    address[] public answerers;

    event BountyIncreased(address indexed _by, uint _amount);
    event BountyDecreased(address indexed _by, uint _amount);
    event NewQuestioner(address indexed _previousQuestioner, address indexed _questioner);
    event WinnerChosen(address indexed _questioner, address indexed _winner);

    constructor() {
        owner = msg.sender;
    }

    function increaseBounty(uint amount) public {
        bounty += amount;
        emit BountyIncreased(msg.sender, amount);
    }

    function decreaseBounty(uint amount) public {
        require(bounty > 0, "Bounty cannot be decrease below 0");
        bounty -= amount;
        emit BountyDecreased(msg.sender, amount);
    }

    // temporary method set just for testing
    function setNewQuestioner(address newQuestioner) public {
        questioner = newQuestioner;
        emit NewQuestioner(msg.sender, newQuestioner);
    }

    function chooseWinner(address winner) public {
        emit WinnerChosen(questioner, winner);
    }
}