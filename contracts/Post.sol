//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./PostFactory.sol";

// Author: @boostaid
contract Post {
    address public owner;
    address public parent;
    address payable public questioner;
    address payable public company;
    address[] public answerers;
    uint public questionerBounty; // TODO: figure out if we can use chainlink to force a minimum amount of for the bounty such as $25c or $1
    uint public companyBounty; // TODO: figure out if we can use chainlink to force a minimum amount of for the bounty such as $25c or $1
    bool locked = false;
    address winner;

    // TODO: Do we want to add an expiration date imo out of scope???
    // uint public expirationDate = block.timestamp;

    // TODO: Check if modifiers can be refactored in some way
    modifier onlyQuestioner() {
        require(
            msg.sender == questioner,
            "Only the questioner can call this function"
        );
        _;
    }

    modifier noWinnerSelected() {
        require(winner == address(0), "A winner has already been selected");
        _;
    }

    modifier payableCannotBeZero() {
        require(msg.value > 0, "The amount must be greater than 0");
        _;
    }

    modifier payableMustMatchAmount(uint amount) {
        require(msg.value == amount, "Ether sent must match amount specified");
        _;
    }

    modifier nonReentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }

    modifier noAnswers() {
        require(
            answerers.length == 0,
            "Can only be called when there are no answers"
        );
        _;
    }

    modifier onlyCompany() {
        require(
            msg.sender == company,
            "Only the company can call this function"
        );
        _;
    }

    modifier isAnswerer(address answerer) {
        bool isAnswerer = false;
        for (uint i = 0; i < answerers.length; i++) {
            if (answerers[i] == answerer) {
                isAnswerer = true;
                break;
            }
        }

        require(isAnswerer, "Address is not an answerer");
        _;
    }

    // we deploy the contract because we gather funds from company contract and the user
    constructor(
        address _owner,
        address _parent,
        address _questioner,
        address _company,
        uint _questionerBounty,
        uint _companyBounty
    ) payable {
        require(
            _owner != address(0),
            "Owner address cannot be the zero address"
        );
        require(
            _parent != address(0),
            "Parent address cannot be the zero address"
        );
        require(
            _questioner != address(0),
            "Questioner address cannot be the zero address"
        );
        require(
            _company != address(0),
            "Company address cannot be the zero address"
        );
        require(msg.value >= 0, "Bounty must be greater than 0");
        require(
            msg.value == _questionerBounty + _companyBounty,
            "The amount sent must be equal to the sum of the bounties"
        );
        owner = _owner;
        parent = _parent;
        questioner = _questioner;
        company = _company;
        questionerBounty = _questionerBounty;
        companyBounty = _companyBounty;

        PostFactory(parent).notifyNewQuestionPosted(
            address(this),
            questioner,
            company,
            questionerBounty,
            companyBounty
        );
    }

    // TODO: Add a minimum amount they can increase the bounty by using oracle
    function increaseQuestionerBounty(
        uint amount
    )
        public
        payable
        onlyQuestioner
        noWinnerSelected
        payableCannotBeZero
        payableMustMatchAmount(amount)
    {
        questionerBounty += amount;
        PostFactory(parent).notifyQuestionerBountyIncreased(
            address(this),
            questioner,
            amount
        );
    }

    // TODO: since the contract is paying out we need to ensure gas is also added, maybe oracle helps with this too
    function decreaseQuestionerBounty(
        uint amount
    ) public onlyQuestioner noWinnerSelected noAnswers nonReentrant {
        require(
            questionerBounty >= amount,
            "Amount to be decreased by cannot be greater than the bounty"
        );
        questionerBounty -= amount;
        bool success = questioner.send(amount);
        require(success, "Failed to send ether.");
        PostFactory(parent).notifyQuestionerBountyDecreased(
            address(this),
            questioner,
            amount
        );
    }

    // TODO: Add a minimum amount they can increase the bounty by using oracle
    function increaseCompanyBounty(
        uint amount
    )
        public
        payable
        onlyCompany
        noWinnerSelected
        payableCannotBeZero
        payableMustMatchAmount(amount)
    {
        companyBounty += amount;
        PostFactory(parent).notifyCompanyBountyIncreased(
            address(this),
            company,
            amount
        );
    }

    // TODO: since the contract is paying out we need to ensure gas is also added, maybe oracle helps with this too
    function decreaseCompanyBounty(
        uint amount
    ) public onlyCompany noWinnerSelected noAnswers nonReentrant {
        require(
            companyBounty >= amount,
            "Amount to be decreased by cannot be greater than the bounty"
        );
        companyBounty -= amount;
        bool success = company.send(amount);
        require(success, "Failed to send ether.");
        PostFactory(parent).notifyCompanyBountyDecreased(
            address(this),
            company,
            amount
        );
    }

    function addAnswer() public noWinnerSelected {
        require(
            msg.sender != questioner || msg.sender != company,
            "Only addresses that are not the questioner or company can call this function"
        );

        answerers.push(msg.sender);
        PostFactory(parent).notifyAnswerAdded(address(this), msg.sender);
    }

    function removeAnswer() public noWinnerSelected isAnswerer(msg.sender) {
        for (uint i = 0; i < answerers.length; i++) {
            if (answerers[i] == msg.sender) {
                answerers[i] = answerers[answerers.length - 1];
                answerers.pop();
                break;
            }
        }

        PostFactory(parent).notifyAnswerRemoved(address(this), msg.sender);
    }

    // TODO: since the contract is paying out we need to ensure gas is also added, maybe oracle helps with this too
    function removeQuestion() public noWinnerSelected nonReentrant {
        require(msg.sender == owner, "Only the owner can call this function");

        bool success = company.send(companyBounty);
        require(success, "Failed to send ether back to company.");
        companyBounty = 0;

        bool success = questioner.send(questionerBounty);
        require(success, "Failed to send ether back to questioner.");
        questionerBounty = 0;

        PostFactory(parent).notifyQuestionRemoved(address(this));
    }

    // TODO: since the contract is paying out we need to ensure gas is also added, maybe oracle helps with this too
    function chooseWinner(
        address winner
    ) public onlyQuestioner noWinnerSelected isAnswerer(winner) nonReentrant {
        winner = winner;

        uint memory questionerBountyReward = questionerBounty;
        uint memory companyBountyReward = companyBountyReward;

        bool success = winner.send(questionerBounty + companyBountyReward);
        require(success, "Failed to send ether to winner.");
        questionerBounty = 0;
        companyBountyReward = 0;

        PostFactory(parent).notifyWinnerSelected(
            address(this),
            winner,
            questionerBountyReward,
            companyBountyReward
        );
    }
}
