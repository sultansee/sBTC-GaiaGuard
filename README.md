

#  sBTC-GaiaGuard

A smart contract for managing, funding, and tracking environmental conservation projects on the blockchain. It empowers project creators, donors, validators, and voters to collaborate transparently to support conservation efforts across diverse categories like wildlife, marine, forest, climate, and biodiversity.

---

## 🚀 Features

* **Project Lifecycle Management**: Initialize, fund, and manage conservation projects with defined goals and durations.
* **Milestone Tracking**: Define and complete milestones, validated through hash-based verification.
* **Voting System**: Stake tokens to vote on projects, encouraging community involvement.
* **Impact Recording**: Quantify and update project impact via environmental metrics.
* **Donor and Validator Registry**: Keep track of contributors and validators.
* **Transparency & Governance**: Permission checks and auditability built-in via immutable maps.

---

## 🧱 Smart Contract Structure

### 🔐 Constants & Errors

Defined constant values for error handling and validation, improving code readability and maintainability.

### 📂 Core Data Maps

* `ConservationProjectDetails`: Stores metadata and state for each conservation project.
* `ConservationDonorRecord`: Tracks donations per user per project.
* `ConservationProjectValidators`: Registry of project validators.
* `ConservationMilestoneDetails`: Contains data for individual project milestones.
* `ConservationVoteRegistry`: Records votes with token stakes and decisions.
* `ConservationImpactMetrics`: Tracks quantifiable environmental impact stats.

### 🔧 Contract State Variables

* `conservation-project-counter`: Tracks the total number of projects created.
* `total-active-projects`: Number of projects currently active.
* `contract-operational-status`: Indicates if the contract has been initialized.
* `minimum-stake-requirement`: Minimum token stake required for voting/project creation.
* `voting-period-duration`: Set to 10 days in blocks (default: 1440).

---

## ✅ Function Overview

### 🔓 Public Functions

#### Initialization & Admin

* `initialize-conservation-contract`: Activates the contract (only callable once by admin).
* `update-minimum-stake-requirement`: Adjusts minimum token stake (admin only).

#### Project Management

* `initiate-conservation-project`: Launch a new project with funding goals and timeline.
* `create-conservation-milestone`: Adds a milestone to an active project.
* `complete-conservation-milestone`: Marks a milestone as complete with proof.

#### Participation

* `submit-conservation-vote`: Stake tokens and vote on project progression.
* `update-environmental-impact`: Submit impact metrics for the project.

### 📖 Read-only Functions

* `get-conservation-impact-metrics`: Fetch environmental data.
* `get-conservation-milestone-info`: Retrieve specific milestone data.
* `get-conservation-vote-info`: Check individual voter participation.
* `get-conservation-project-metrics`: Overview of project performance (funding, impact, milestones).
* `get-conservation-project-timeline`: View time and participation statistics.

---

## 🛡️ Validation & Safety

* **Role Checks**: Only project creators or admins can modify certain states.
* **Duplicate Protection**: Prevents duplicate votes and milestones.
* **Token Transfers**: Uses `stx-transfer?` for financial operations with error handling.
* **Strict Input Validation**: Ensures strings and categories are valid using helper functions.

---

## 📊 Environmental Impact Metrics Tracked

* Trees planted
* Conservation area (square meters)
* Carbon offset (tons)
* Protected species count
* Community benefit score

These contribute to an aggregate `environmental-impact-score`.

---

## 📎 Deployment Notes

* **Admin** is the deploying address (`tx-sender` on contract initialization).
* **Contract must be initialized** via `initialize-conservation-contract` before usage.
* **Projects require staking** the minimum defined token amount to prevent spam.

---

## 💡 Suggested Improvements

* Add support for NFT-based donor badges.
* Implement withdrawal mechanisms post-project success.
* Introduce governance-based validator nomination.
