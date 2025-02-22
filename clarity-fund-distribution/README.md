# HopeChain: Decentralized Disaster Relief Protocol

HopeChain is a transparent and fair disaster relief fund management system implemented as a smart contract on the Stacks blockchain. The protocol enables efficient disaster relief fundraising, fund distribution, and governance through a decentralized approach.

## Features

### Core Functionality
- Transparent donation management
- NFT-based governance system
- Decentralized proposal submission and voting
- Automated fund distribution
- Dynamic disaster severity tracking

### Key Components
1. **Donation System**
   - Minimum donation threshold
   - Automatic NFT minting for donors
   - Transparent fund tracking

2. **Governance**
   - NFT-based voting power
   - Proportional governance rights
   - Transferable NFTs with governance power
   
3. **Disaster Management**
   - Active disaster registration
   - Severity level tracking
   - Funding target management
   
4. **Proposal System**
   - Community-driven fund allocation
   - Threshold-based approval system
   - Automated execution

## Smart Contract Functions

### Administrative Functions
- `update-administrator`: Update contract administrator
- `update-minimum-donation`: Modify minimum donation amount
- `update-approval-threshold`: Adjust proposal approval threshold
- `register-new-disaster`: Register new disaster events
- `update-disaster-severity-level`: Update disaster severity

### Public Functions
- `make-donation`: Make a donation and receive governance NFT
- `submit-relief-proposal`: Submit fund distribution proposal
- `cast-proposal-vote`: Vote on active proposals
- `execute-proposal`: Execute approved proposals
- `transfer-nft`: Transfer governance NFTs between users

### Read-Only Functions
- `get-donor-details`: View donor information
- `get-disaster-details`: View disaster information
- `get-total-donations`: Check total donated funds
- `get-nft-owner`: Check NFT ownership
- `get-nft-metadata-uri`: Get NFT metadata
- `has-voted`: Check if user has voted on proposal

## Error Codes

- `ERR_UNAUTHORIZED` (u100): Unauthorized access
- `ERR_DISASTER_NOT_ACTIVE` (u101): Disaster not active
- `ERR_INSUFFICIENT_BALANCE` (u102): Insufficient funds
- `ERR_INVALID_DONATION_AMOUNT` (u103): Invalid donation amount
- `ERR_PROPOSAL_ALREADY_EXECUTED` (u104): Proposal already executed
- `ERR_TOKEN_TRANSFER_FAILED` (u105): NFT transfer failed
- `ERR_NOT_NFT_OWNER` (u106): Not NFT owner
- `ERR_NFT_NOT_FOUND` (u107): NFT not found
- `ERR_ALREADY_VOTED` (u108): Already voted
- `ERR_DISASTER_NOT_FOUND` (u109): Disaster not found
- `ERR_THRESHOLD_NOT_MET` (u110): Approval threshold not met
- `ERR_INVALID_PARAMETER` (u111): Invalid parameter

## Events

The contract emits the following events for tracking and transparency:
- `ADMIN_UPDATED`: Administrator change
- `MIN_DONATION_UPDATED`: Minimum donation update
- `THRESHOLD_UPDATED`: Approval threshold change
- `DONATION_RECEIVED`: New donation
- `DISASTER_REGISTERED`: New disaster registration
- `PROPOSAL_SUBMITTED`: New proposal submission
- `VOTE_CAST`: Vote recording
- `PROPOSAL_EXECUTED`: Proposal execution
- `NFT_TRANSFERRED`: NFT transfer
- `SEVERITY_UPDATED`: Disaster severity update

## Security Features

1. **Reentrancy Protection**
   - State updates before transfers
   - Strict access controls
   
2. **Parameter Validation**
   - Amount validation
   - Threshold checks
   - Ownership verification

3. **Access Control**
   - Administrator-only functions
   - NFT-based governance
   - Vote duplicate prevention

## Usage Example

1. Administrator registers a new disaster:
```clarity
(contract-call? .hopechain register-new-disaster "Hurricane Relief" u5 u1000000000)
```

2. User makes a donation:
```clarity
(contract-call? .hopechain make-donation u1000000)
```

3. Submit relief proposal:
```clarity
(contract-call? .hopechain submit-relief-proposal u1 "Emergency Supplies Distribution" u500000 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

4. Vote on proposal:
```clarity
(contract-call? .hopechain cast-proposal-vote u1)
```

## Notes

- All amounts are in microSTX (1 STX = 1,000,000 microSTX)
- NFT metadata is stored using IPFS
- Governance power is proportional to donation amount
- Proposals require 75% approval by default