// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Voting.sol";

contract TestVoting {
    Voting voting = Voting(DeployedAddresses.Voting());

    // Test de l'enregistrement des propositions
    function testProposalRegistration() public {
        voting.addToWhitelist(address(this));
        voting.startProposalsRegistration();
        voting.registerProposal("Proposition 1", "Commentaire 1");
        voting.registerProposal("Proposition 2", "Commentaire 2");

        Assert.equal(voting.proposals.length, 2, "Le nombre de propositions enregistrées devrait être 2");
    }

    // Test du processus de vote
    function testVote() public {
        voting.startVotingSession();
        voting.vote(0);

        Assert.equal(voting.proposals[0].voteCount, 1, "Le nombre de votes pour la proposition 1 devrait être 1");
    }

    // Test du calcul du podium
    function testGeneratePodium() public {
        uint[3] memory podium = voting.generatePodium();

        Assert.equal(podium[0], 0, "Le premier élément du podium devrait être la proposition 1");
    }

    // Test du vote avec paiement
    function testVoteWithPayment() public payable {
        uint initialVoteCount = voting.proposals[0].voteCount;
        voting.voteWithPayment{value: 1 ether}(0);

        Assert.equal(voting.proposals[0].voteCount, initialVoteCount + 6600000000000000, "Le nombre de votes pour la proposition 1 devrait être augmenté en fonction du paiement");
    }
}
