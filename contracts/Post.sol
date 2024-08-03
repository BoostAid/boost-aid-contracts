//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Author: @boostaid
contract Post {
    address public owner;
    address payable public questioner;
    address payable public company;
    address[] public answerers;
    uint public bountyInEther; // TODO: figure out if we can use chainlink to force a minimum amount of for the bounty such as $25c or $1
    uint public companyBountyInEther; // TODO: figure out if we can use chainlink to force a minimum amount of for the bounty such as $25c or $1
    bool locked = false;
    address winner;

    // TODO: Do we want to add an expiration date imo out of scope???
    // uint public expirationDate = block.timestamp;

    // TODO: Move events into their own file
    event NewQuestionPosted(
        address indexed _questioner,
        address indexed _company,
        uint _questionerBountyInEther,
        uint _companyBountyInEther
    );
    event QuestionerBountyIncreased(
        address indexed _question,
        address indexed _questioner,
        uint _amount
    );
    event QuestionerBountyDecreased(
        address indexed _question,
        address indexed _questioner,
        uint _amount
    );
    event CompanyBountyIncreased(
        address indexed _question,
        address indexed _company,
        uint _amount
    );
    event CompanyBountyDecreased(
        address indexed _question,
        address indexed _company,
        uint _amount
    );
    event NewAnswerAdded(address indexed _question, address indexed _answerer);
    event AnswerRemoved(address indexed _question, address indexed _answerer);
    event QuestionRemovedByAdmin(address indexed _question);
    event WinnerSelected(
        address indexed _question,
        address indexed _winner,
        uint _questionerBountyInEther,
        uint _companyBountyInEther
    );

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
        require(
            getEtherValue(msg.value) > 0 ether,
            "The amount must be greater than 0"
        );
        _;
    }

    modifier payableMustMatchAmount(uint amountInEther) {
        require(
            getEtherValue(msg.value) == amountInEther,
            "Ether sent must match amount specified"
        );
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
        address _questioner,
        address _company,
        uint _bountyInEther,
        uint _companyBountyInEther
    ) payable {
        require(
            getEtherValue(msg.value) >= 0 ether,
            "Bounty must be greater than 0"
        );
        require(
            getEtherValue(msg.value) == _bountyInEther + _companyBountyInEther,
            "The amount sent must be equal to the sum of the bounties"
        );
        questioner = _questioner;
        company = _company;
        bountyInEther = _bountyInEther;
        companyBountyInEther = _companyBountyInEther;
        owner = msg.sender;

        emit NewQuestionPosted(
            _questioner,
            _company,
            _bountyInEther,
            _companyBountyInEther
        );
    }

    // TODO: Add a minimum amount they can increase the bounty by using oracle
    function increaseQuestionerBounty(
        uint amountInEther
    )
        public
        payable
        onlyQuestioner
        noWinnerSelected
        payableCannotBeZero
        payableMustMatchAmount(amountInEther)
    {
        bountyInEther += amountInEther;
        emit QuestionerBountyIncreased(
            address(this),
            msg.sender,
            amountInEther
        );
    }

    // TODO: since the contract is paying out we need to ensure gas is also added, maybe oracle helps with this too
    function decreaseQuestionerBounty(
        uint amountInEther
    ) public onlyQuestioner noWinnerSelected noAnswers nonReentrant {
        require(bountyInEther >= amountInEther, "Bounty cannot be less than 0");
        require(
            getEtherValue(address(this).balance) >= amountInEther,
            "Contract balance cannot be less than 0"
        );
        bountyInEther -= amountInEther;
        bool success = questioner.send(convertToWei(amountInEther));
        require(success, "Failed to send ether.");
        emit QuestionerBountyDecreased(address(this), questioner, amount);
    }

    // TODO: Add a minimum amount they can increase the bounty by using oracle
    function increaseCompanyBounty(
        uint amountInEther
    )
        public
        payable
        onlyCompany
        noWinnerSelected
        payableCannotBeZero
        payableMustMatchAmount(amountInEther)
    {
        companyBountyInEther += amountInEther;
        emit CompanyBountyIncreased(address(this), msg.sender, amountInEther);
    }

    // TODO: since the contract is paying out we need to ensure gas is also added, maybe oracle helps with this too
    function decreaseCompanyBounty(
        uint amountInEther
    ) public onlyCompany noWinnerSelected noAnswers nonReentrant {
        require(
            companyBountyInEther >= amountInEther,
            "Bounty cannot be less than 0"
        );
        require(
            getEtherValue(address(this).balance) >= amountInEther,
            "Contract balance cannot be less than 0"
        );
        companyBountyInEther -= amountInEther;
        bool success = company.send(convertToWei(amountInEther));
        require(success, "Failed to send ether.");
        emit CompanyBountyDecreased(address(this), company, amountInEther);
    }

    function addAnswer() public noWinnerSelected {
        require(
            msg.sender != questioner || msg.sender != company,
            "Only addresses that are not the questioner or company can call this function"
        );

        answerers.push(msg.sender);
        emit NewAnswerAdded(address(this), msg.sender);
    }

    function removeAnswer() public noWinnerSelected isAnswerer(msg.sender) {
        for (uint i = 0; i < answerers.length; i++) {
            if (answerers[i] == msg.sender) {
                answerers[i] = answerers[answerers.length - 1];
                answerers.pop();
                break;
            }
        }

        emit AnswerRemoved(address(this), answerer);
    }

    // TODO: since the contract is paying out we need to ensure gas is also added, maybe oracle helps with this too
    function removeQuestion() public noWinnerSelected nonReentrant {
        require(msg.sender == owner, "Only the owner can call this function");

        bool success = company.send(convertToWei(companyBountyInEther));
        require(success, "Failed to send ether back to company.");
        companyBountyInEther = 0;

        bool success = questioner.send(convertToWei(bountyInEther));
        require(success, "Failed to send ether back to questioner.");
        bountyInEther = 0;

        emit QuestionRemovedByAdmin(address(this));
    }

    // TODO: since the contract is paying out we need to ensure gas is also added, maybe oracle helps with this too
    function chooseWinner(
        address winner
    ) public onlyQuestioner noWinnerSelected isAnswerer(winner) nonReentrant {
        winner = winner;

        uint memory questionerBountyInEther = bountyInEther;
        uint memory companyBountyInEther = companyBountyInEther;

        bool success = winner.send(
            convertToWei(bountyInEther + companyBountyInEther)
        );
        require(success, "Failed to send ether to winner.");
        bountyInEther = 0;
        companyBountyInEther = 0;

        emit WinnerSelected(
            address(this),
            winner,
            questionerBountyInEther,
            companyBountyInEther
        );
    }

    // TODO: move the unit conversion methods somewhere else
    function getEtherValue(uint256 weiAmount) public pure returns (uint256) {
        return weiAmount / 1 ether; // 1 ether is equal to 10^18 wei
    }

    function convertToWei(uint256 etherAmount) public pure returns (uint256) {
        return etherAmount * 1 ether; // 1 ether is equal to 10^18 wei
    }
}
