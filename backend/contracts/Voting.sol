// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title Contrat de Vote
contract Voting is Ownable {
    using Strings for uint;

    string public winnerProposal = "";

    struct Voter {
        bool isRegistered; // Indique si l'électeur est enregistré
        bool hasVoted; // Indique si l'électeur a déjà voté
        uint votedProposalId; // ID de la proposition pour laquelle l'électeur a voté
    }

    struct Proposal {
        uint id; // ID de la proposition
        string description; // Description de la proposition
        string comment; // Commentaire associé à la proposition
        uint voteCount; // Nombre de votes reçus par la proposition
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

    constructor() Ownable(msg.sender) {
        // Le déploiement du contrat est effectué par le propriétaire
        // et le statut du workflow est initialisé à l'étape d'enregistrement des électeurs
        workflowStatus = WorkflowStatus.RegisteringVoters;
    }

    /// @dev Ajoute un utilisateur à la liste blanche des électeurs
    /// @param _user Adresse de l'utilisateur à ajouter
    function addToWhitelist(address _user) public onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, "Les utilisateurs ne peuvent etre ajoutes a la liste blanche qu'avant le debut de l'enregistrement des propositions");
        require(!voters[_user].isRegistered, "L'utilisateur est deje enregistre.");

        voters[_user].isRegistered = true;
    }

    /// @dev Supprime un utilisateur de la liste blanche des électeurs
    /// @param _user Adresse de l'utilisateur à supprimer
    function removeFromWhitelist(address _user) public onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, "Les utilisateurs ne peuvent etre supprimes de la liste blanche qu'avant le debut de l'enregistrement des propositions");
        require(voters[_user].isRegistered, "L'utilisateur n'est pas enregistre.");

        voters[_user].isRegistered = false;
    }

    /// @dev Vérifie si un utilisateur est enregistré comme électeur
    /// @param _user Adresse de l'utilisateur à vérifier
    /// @return bool True si l'utilisateur est enregistré, sinon False
    function isWhitelisted(address _user) public view returns (bool) {
        return voters[_user].isRegistered;
    }

    /// @dev Démarre la période d'enregistrement des propositions
    function startProposalsRegistration() public onlyOwner {
        require(workflowStatus == WorkflowStatus.RegisteringVoters, "L'enregistrement des voteurs n'est pas termine");

        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
    }

    /// @dev Enregistre une nouvelle proposition
    /// @param _proposalDescription Description de la proposition
    /// @param _comment Commentaire associé à la proposition
    function registerProposal(string memory _proposalDescription, string memory _comment) public {
        require(voters[msg.sender].isRegistered, "Vous n'etes pas sur la Whitelist");
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, "L'enregistrement des propositions n'a pas commence");

        proposals.push(Proposal(proposals.length, _proposalDescription, _comment, 0));
    }

    /// @dev Termine la période d'enregistrement des propositions
    function endProposalsRegistration() public onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationStarted, "L'enregistrement des propositions n'a pas commencee");

        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
    }

    /// @dev Démarre la session de vote
    function startVotingSession() public onlyOwner {
        require(workflowStatus == WorkflowStatus.ProposalsRegistrationEnded, "La session de vote ne peut etre demarree qu'apres la fin de l'enregistrement des propositions.");

        workflowStatus = WorkflowStatus.VotingSessionStarted;
    }

    /// @dev Permet à un électeur de voter pour une proposition
    /// @param _proposalId ID de la proposal pour laquelle l'électeur vote
    function vote(uint _proposalId) public {
        require(voters[msg.sender].isRegistered, "Seuls les lecteurs enregistres peuvent voter");
        require(!voters[msg.sender].hasVoted, "Vous avez deja soummis votre vote ");
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, "La session de vote n'a pas commencee");
        require(_proposalId < proposals.length, "ID de proposition invalide");

        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalId;

        proposals[_proposalId].voteCount += 1;
    }

    /// @dev Permet a l'utilisateur de voir les propositions
    /// @return Proposal renvoie les propositions
    function getAllProposals() public view returns (Proposal[] memory) {
        return proposals;
    }

    /// DWYW

    /// @dev Permet à un électeur de payer et de voter pour une proposition (#Capitalisme ahah)
    /// @param _proposalId ID de la proposal pour laquelle l'électeur vote
    function voteWithPayment(uint _proposalId) public payable {
        vote(_proposalId);

        // Calcul du nombre de votes en fonction de la valeur en ETH envoyée
        // Ici, nous supposons que 1 ETH équivaut à 3000 euros (vous pouvez ajuster ce ratio selon vos besoins)
        // 1 euro ≈ 0.00033 ETH, donc 1 euro ≈ 330000000000000 wei (0.00033 * 10^18)
        uint votes = msg.value * 330000000000000 / 1 ether; // Convertir les wei en ETH

        // Ajouter le nombre de votes calculé
        proposals[_proposalId].voteCount += votes * 2; // Le double de la valeur du vote
    }

    /// @dev Termine la session de vote
    function endVotingSession() public onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionStarted, "La session de vote n'a pas commencee");

        workflowStatus = WorkflowStatus.VotingSessionEnded;
    }

    /// @dev Détermine la proposition gagnante
    function tallyVotes() public onlyOwner {
        require(workflowStatus == WorkflowStatus.VotingSessionEnded, "Les votes ne peuvent etre depouilles qu'apres la fin de la session de vote");

        workflowStatus = WorkflowStatus.VotesTallied;
    }

    /// @dev Renvoie la proposal qui a gagné
    /// @return _winningProposalDescription Description de la proposal gagnante
    /// @return _winningProposalComment Commentaire associé à la proposal gagnante
    function getWinningProposal() public view returns (string memory _winningProposalDescription, string memory _winningProposalComment) {
        require(workflowStatus == WorkflowStatus.VotesTallied, "Meric d'attendre la fin des comptes");

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

    /// @dev Génère le podium des trois meilleures propositions
    /// @return _podium Array contenant les IDs des trois meilleures propositions
    function generatePodium() public view returns (uint[3] memory _podium) {
        require(workflowStatus == WorkflowStatus.VotesTallied, "Meric d'attendre la fin des comptes");

        uint[3] memory highestVotes;
        uint[3] memory highestIds;

        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > highestVotes[0]) {
                highestVotes[2] = highestVotes[1];
                highestVotes[1] = highestVotes[0];
                highestVotes[0] = proposals[i].voteCount;

                highestIds[2] = highestIds[1];
                highestIds[1] = highestIds[0];
                highestIds[0] = i;
            } else if (proposals[i].voteCount > highestVotes[1]) {
                highestVotes[2] = highestVotes[1];
                highestVotes[1] = proposals[i].voteCount;

                highestIds[2] = highestIds[1];
                highestIds[1] = i;
            } else if (proposals[i].voteCount > highestVotes[2]) {
                highestVotes[2] = proposals[i].voteCount;
                highestIds[2] = i;
            }
        }

        return highestIds;
    }
}
