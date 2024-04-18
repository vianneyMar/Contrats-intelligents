'use client'
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useAccount } from 'wagmi';
import { useState, useEffect } from 'react';
import { readContract, prepareWriteContract, writeContract } from '@wagmi/core';
import { abi, contractAddress } from '@/constants';

export default function Home() {
  const { address, isConnected, connect, isDisconnected, disconnect } = useAccount();
  const [workflowStatus, setWorkflowStatus] = useState('');
  const [getProposal, setGetProposal] = useState();
  const [setProposal, setSetProposal] = useState();
  const [proposalId, setProposalId] = useState();
  const [voterAddress, setVoterAddress] = useState('');
  const [proposalDescription, setProposalDescription] = useState('');
  const [proposalComment, setProposalComment] = useState('');
  const [proposals, setProposals] = useState([]);
  const [selectedProposalId, setSelectedProposalId] = useState();

  useEffect(() => {
    if (isConnected) {
      fetchProposals();
    }
  }, [isConnected]);

  const fetchProposals = async () => {
    const data = await readContract({
      address: contractAddress,
      abi: abi,
      functionName: 'getAllProposals',
    });
    setProposals(data);
  };
  const getWorkflowStatus = async () => {
    try {
      const status = await readContract({
        address: contractAddress,
        abi: abi,
        functionName: 'getWorkflowStatus'
      });
      setWorkflowStatus(status);
    } catch (error) {
      console.error("Error getting workflow status:", error);
    }
  };

  const updateWorkflowStatus = async () => {
    try {
      const { request } = await prepareWriteContract({
        address: contractAddress,
        abi: abi,
        functionName: 'updateWorkflowStatus'
      });
      await writeContract(request);
      await getWorkflowStatus();
    } catch (error) {
      console.error("Error updating workflow status:", error);
    }
  };

  const getTheProposal = async() => {
    const data = await readContract({
      address: contractAddress,
      abi: abi,
      functionName: 'getWinningProposal',
    })
    setGetProposal(data)
  }

  const changeProposal = async() => {
    const { request } = await prepareWriteContract({
      address: contractAddress,
      abi: abi,
      functionName: 'registerProposal',
      args: [proposalDescription, proposalComment]
    })
    const { hash } = await writeContract(request)
    await getTheProposal()
    setSetProposal()
  }

  const voteForProposal = async() => {
    const { request } = await prepareWriteContract({
      address: contractAddress,
      abi: abi,
      functionName: 'vote',
      args: [selectedProposalId]
    })
    const { hash } = await writeContract(request)
  }

  const registerVoter = async () => {
    const { request } = await prepareWriteContract({
      address: contractAddress,
      abi: abi,
      functionName: 'addToWhitelist',
      args: [voterAddress],
      account: address
    });
    await writeContract(request);
  };
  const removeVoter = async () => {
    const { request } = await prepareWriteContract({
      address: contractAddress,
      abi: abi,
      functionName: 'removeFromWhitelist',
      args: [voterAddress]
    });
    await writeContract(request);
  };

  const isWhitelisted = async () => {
    const data = await readContract({
      address: contractAddress,
      abi: abi,
      functionName: 'isWhitelisted',
      args: [voterAddress]
    });
    return data;
  };
  const startProposalsRegistration = async () => {
    const { request } = await prepareWriteContract({
      address: contractAddress,
      abi: abi,
      functionName: 'startProposalsRegistration'
    });
    await writeContract(request);
  };

  const registerProposal = async () => {
    const { request } = await prepareWriteContract({
      address: contractAddress,
      abi: abi,
      functionName: 'registerProposal',
      args: [proposalDescription, proposalComment]
    });
    await writeContract(request);
  };

  const startVotingSession = async () => {
    const { request } = await prepareWriteContract({
      address: contractAddress,
      abi: abi,
      functionName: 'startVotingSession'
    });
    await writeContract(request);
  };



  return (
      <>
        <ConnectButton />
        {isConnected ? (
            <button onClick={disconnect}>Disconnect</button>
        ) : (
            <button onClick={connect}>Connect</button>
        )}
        {isConnected ? (
            <div>
              {proposals.map((proposal, index) => (
                  <div key={index}>
                    <p>{proposal.description}</p>
                    <button onClick={() => setSelectedProposalId(proposal.id)}>Vote for this proposal</button>
                  </div>
              ))}
              <button onClick={voteForProposal}>Submit vote</button>
              <p>Workflow Status: {workflowStatus}</p>
              <button onClick={getWorkflowStatus}>Get Workflow Status</button>
              <button onClick={updateWorkflowStatus}>Update Workflow Status</button>
              <p><button onClick={getTheProposal}>Get The Winning Proposal</button> : {getProposal}</p>
              <p><input type="text" onChange={(e) => setSetProposal(e.target.value)} /> <button onClick={changeProposal}>Submit a proposal</button></p>
              <p><input type="number" onChange={(e) => setProposalId(e.target.value)} /> <button onClick={() => voteForProposal(proposalId)}>Vote for a proposal</button></p>
              <input type="text" onChange={(e) => setVoterAddress(e.target.value)} placeholder="Voter Address" />
              <button onClick={registerVoter}>Register Voter</button>
              <button onClick={removeVoter}>Remove Voter</button>
              <button onClick={isWhitelisted}>Check if Voter is Whitelisted</button>
              <button onClick={startProposalsRegistration}>Start Proposals Registration</button>
              <input type="text" onChange={(e) => setProposalDescription(e.target.value)} placeholder="Proposal Description" />
              <input type="text" onChange={(e) => setProposalComment(e.target.value)} placeholder="Proposal Comment" />
              <button onClick={registerProposal}>Register Proposal</button>
              <button onClick={startVotingSession}>Start Voting Session</button>
            </div>
        ) : (
            <p>Please connect your Wallet to our DApp.</p>
        )}
      </>
  )
}