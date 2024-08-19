// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IPostFactory {
    function notifyNewQuestionPosted(
        address parent,
        address post,
        address questioner,
        address company,
        uint questionerBounty,
        uint companyBounty
    ) external;

    function notifyQuestionRemoved(address post) external;

    function notifyWinnerSelected(
        address post,
        address winner,
        uint questionerBounty,
        uint companyBounty
    ) external;

    function notifyAnswerRemoved(address post, address answerer) external;

    function notifyAnswerAdded(address post, address answerer) external;

    function notifyCompanyBountyDecreased(
        address post,
        address company,
        uint amount
    ) external;

    function notifyCompanyBountyIncreased(
        address post,
        address company,
        uint amount
    ) external;

    function notifyQuestionerBountyDecreased(
        address post,
        address questioner,
        uint amount
    ) external;

    function notifyQuestionerBountyIncreased(
        address post,
        address questioner,
        uint amount
    ) external;

    function getPostsLength() external view returns (uint);
}
