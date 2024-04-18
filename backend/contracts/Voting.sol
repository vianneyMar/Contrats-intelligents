// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Voting is Ownable{
    // Permet au déployeur de posséder le contrat
    constructor() Ownable(msg.sender) {
        workflowStatus = WorkflowStatus.RegisteringVoters;
    }

    string winnerProposal = "";

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        uint id;
        string description;
        string comment; // Les électeurs peuvent ajouter des justifications de leur vote
        uint voteCount;
    }

    mapping(address => Voter) public voters;
    Proposal[] public proposals;

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    WorkflowStatus public workflowStatus;

    // Ajout d'un utilisateur à la whitelist
    function addToWhitelist(address _user) public onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, "Users can only be added to the whitelist before proposals registration has started.");
        require(!voters[_user].isRegistered, "The user is already registered.");

        voters[_user].isRegistered = true;
    }

    // Suppression d'un utilisateur de la whitelist
    function removeFromWhitelist(address _user) public onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, "Users can only be removed from the whitelist before proposals registration has started.");
        require(voters[_user].isRegistered, "The user is not registered.");

        voters[_user].isRegistered = false;
    }

    // Vérification si un utilisateur est dans la whitelist
    function isWhitelisted(address _user) public view returns (bool) {
        return voters[_user].isRegistered;
    }

    function startProposalsRegistration() public onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, "Proposals registration can only be started after voters registration.");

        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
    }

    function registerProposal(string memory _proposalDescription, string memory _comment) public {
        require(voters[msg.sender].isRegistered, "Only registered voters can register proposals.");
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, "Proposals can only be registered during proposals registration.");

        proposals.push(Proposal(proposals.length, _proposalDescription, _comment, 0));
    }

    function endProposalsRegistration() public onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, "Proposals registration can only be ended after it has started.");

        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
    }

    function startVotingSession() public onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, "Voting session can only be started after proposals registration has ended.");

        workflowStatus = WorkflowStatus.VotingSessionStarted;
    }

    function vote(uint _proposalId) public {
        require(voters[msg.sender].isRegistered, "Only registered voters can vote.");
        require(!voters[msg.sender].hasVoted, "The voter has already voted.");
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, "Votes can only be cast during the voting session.");
        require(_proposalId < proposals.length, "Invalid proposal id.");

        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalId;

        proposals[_proposalId].voteCount += 1;
    }

    function endVotingSession() public onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, "Voting session can only be ended after it has started.");

        workflowStatus = WorkflowStatus.VotingSessionEnded;
    }

    function tallyVotes() public onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionEnded, "Votes can only be tallied after voting session has ended.");

        workflowStatus = WorkflowStatus.VotesTallied;
    }

    function getWinningProposal() public view returns (string memory _winningProposalDescription, string memory _winningProposalComment) {
        require(workflowStatus == WorkflowStatus.VotesTallied, "The winning proposal can only be determined after votes have been tallied.");

        uint winningVoteCount = 0;
        uint winningProposalId = 0;

        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposalId = i;
            }
        }

        _winningProposalDescription = proposals[winningProposalId].description;
        _winningProposalComment = proposals[winningProposalId].comment;
    }

    function getAllProposals() public view returns (Proposal[] memory) {
        return proposals;
    }
}
