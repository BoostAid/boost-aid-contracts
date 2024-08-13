// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Post.sol";

// Author: @boostaid
contract PostFactory {
    // TODO: maybe store the index in the post for faster lookups
    Post[] public posts;
    address public owner;

    event NewQuestionPosted(
        address indexed post,
        address indexed questioner,
        address indexed company,
        uint questionerBounty,
        uint companyBounty
    );
    event QuestionRemovedByAdmin(address indexed post);
    event WinnerSelected(
        address indexed post,
        address indexed winner,
        uint questionerBounty,
        uint companyBounty
    );
    event AnswerRemoved(address indexed post, address indexed answerer);
    event AnswerAdded(address indexed post, address indexed answerer);
    event CompanyBountyDecreased(
        address indexed post,
        address indexed company,
        uint amount
    );
    event CompanyBountyIncreased(
        address indexed post,
        address indexed company,
        uint amount
    );
    event QuestionerBountyDecreased(
        address indexed post,
        address indexed questioner,
        uint amount
    );
    event QuestionBountyIncreased(
        address indexed post,
        address indexed questioner,
        uint amount
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier isPostEvoking() {
        bool isPostEvoking = false;
        for (uint i = 0; i < posts.length; i++) {
            if (msg.sender == address(posts[i])) {
                isPostEvoking = true;
                break;
            }
        }

        require(isPostEvoking, "Only a child post can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // amounts come from escrow wallet
    function createPost(
        address questioner,
        address company,
        uint questionerBounty,
        uint companyBounty
    ) public payable {
        require(msg.value > 0, "You must send some ether");
        require(
            questionerBounty + companyBounty == msg.value,
            "The bounties must add up to the amount sent"
        );
        Post newPost = (new Post){value: msg.value}(
            msg.sender,
            address(this),
            questioner,
            company,
            questionerBounty,
            companyBounty
        );

        posts.push(newPost);
    }

    function notifyNewQuestionPosted(
        address post,
        address questioner,
        address company,
        uint questionerBounty,
        uint companyBounty
    ) public isPostEvoking {
        emit NewQuestionPosted(
            post,
            questioner,
            company,
            questionerBounty,
            companyBounty
        );
    }

    function notifyQuestionRemoved(address post) public isPostEvoking {
        for (uint i = 0; i < posts.length; i++) {
            if (address(posts[i]) == post) {
                posts[i] = posts[posts.length - 1];
                posts.pop();
                break;
            }
        }

        emit QuestionRemovedByAdmin(post);
    }

    function notifyWinnerSelected(
        address post,
        address winner,
        uint questionerBounty,
        uint companyBounty
    ) public isPostEvoking {
        emit WinnerSelected(post, winner, questionerBounty, companyBounty);
    }

    function notifyAnswerRemoved(
        address post,
        address answerer
    ) public isPostEvoking {
        emit AnswerRemoved(post, answerer);
    }

    function notifyAnswerAdded(
        address post,
        address answerer
    ) public isPostEvoking {
        emit AnswerAdded(post, answerer);
    }

    function notifyCompanyBountyDecreased(
        address post,
        address company,
        uint amount
    ) public isPostEvoking {
        emit CompanyBountyDecreased(post, company, amount);
    }

    function notifyCompanyBountyIncreased(
        address post,
        address company,
        uint amount
    ) public isPostEvoking {
        emit CompanyBountyIncreased(post, company, amount);
    }

    function notifyQuestionerBountyDecreased(
        address post,
        address questioner,
        uint amount
    ) public isPostEvoking {
        emit QuestionerBountyDecreased(post, questioner, amount);
    }

    function notifyQuestionBountyIncreased(
        address post,
        address questioner,
        uint amount
    ) public isPostEvoking {
        emit QuestionBountyIncreased(post, questioner, amount);
    }
}