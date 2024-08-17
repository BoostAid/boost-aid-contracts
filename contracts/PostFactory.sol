// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Post.sol";
import "./IPostFactory.sol";

// Author: @boostaid
contract PostFactory is IPostFactory {
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
    event QuestionerBountyIncreased(
        address indexed post,
        address indexed questioner,
        uint amount
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier isPostEvoking() {
        bool foundPostEvoking = false;
        for (uint i = 0; i < posts.length; i++) {
            if (msg.sender == address(posts[i])) {
                foundPostEvoking = true;
                break;
            }
        }

        require(foundPostEvoking, "Only a child post can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    fallback() external payable {}

    receive() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    // amounts come from escrow wallet
    function createPost(
        address payable questioner,
        address payable company,
        uint questionerBounty,
        uint companyBounty
    ) public payable {
        require(msg.value > 0, "You must send some ether");
        require(
            msg.value >= questionerBounty + companyBounty,
            "The bounties must add up to the amount sent"
        );
        Post newPost = (new Post){value: msg.value}(
            msg.sender,
            payable(address(this)),
            questioner,
            company,
            questionerBounty,
            companyBounty
        );

        posts.push(newPost);
    }

    function notifyNewQuestionPosted(
        address parent,
        address post,
        address questioner,
        address company,
        uint questionerBounty,
        uint companyBounty
    ) external {
        require(
            parent == address(this),
            "Only a child post can call this function"
        );

        emit NewQuestionPosted(
            post,
            questioner,
            company,
            questionerBounty,
            companyBounty
        );
    }

    function notifyQuestionRemoved(address post) external isPostEvoking {
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
    ) external isPostEvoking {
        emit WinnerSelected(post, winner, questionerBounty, companyBounty);
    }

    function notifyAnswerRemoved(
        address post,
        address answerer
    ) external isPostEvoking {
        emit AnswerRemoved(post, answerer);
    }

    function notifyAnswerAdded(
        address post,
        address answerer
    ) external isPostEvoking {
        emit AnswerAdded(post, answerer);
    }

    function notifyCompanyBountyDecreased(
        address post,
        address company,
        uint amount
    ) external isPostEvoking {
        emit CompanyBountyDecreased(post, company, amount);
    }

    function notifyCompanyBountyIncreased(
        address post,
        address company,
        uint amount
    ) external isPostEvoking {
        emit CompanyBountyIncreased(post, company, amount);
    }

    function notifyQuestionerBountyDecreased(
        address post,
        address questioner,
        uint amount
    ) external isPostEvoking {
        emit QuestionerBountyDecreased(post, questioner, amount);
    }

    function notifyQuestionerBountyIncreased(
        address post,
        address questioner,
        uint amount
    ) external isPostEvoking {
        emit QuestionerBountyIncreased(post, questioner, amount);
    }

    function getPostsLength() external view returns (uint) {
        return posts.length;
    }
}
