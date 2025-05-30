
;; sBTC-GaiaGuard
;; Conservation Smart Contract

;; Error Constants
(define-constant contract-administrator tx-sender)
(define-constant ERROR-UNAUTHORIZED-ADMINISTRATOR (err u100))
(define-constant ERROR-CONTRACT-ALREADY-INITIALIZED (err u101))
(define-constant ERROR-CONTRACT-NOT-INITIALIZED (err u102))
(define-constant ERROR-INVALID-AMOUNT-PROVIDED (err u103))
(define-constant ERROR-INSUFFICIENT-BALANCE (err u104))
(define-constant ERROR-PROJECT-ALREADY-EXISTS (err u105))
(define-constant ERROR-PROJECT-NOT-FOUND (err u106))
(define-constant ERROR-INSUFFICIENT-PERMISSIONS (err u107))
(define-constant ERROR-MILESTONE-ALREADY-APPROVED (err u108))
(define-constant ERROR-MILESTONE-NOT-FOUND (err u109))
(define-constant ERROR-INVALID-TIMESTAMP (err u110))
(define-constant ERROR-VOTING-PERIOD-ENDED (err u111))
(define-constant ERROR-USER-ALREADY-VOTED (err u112))
(define-constant ERROR-PROJECT-NO-LONGER-ACTIVE (err u113))
(define-constant ERROR-INVALID-INPUT (err u114))

;; Conservation Project Categories
(define-constant conservation-categories 
    (list 
        "wildlife"
        "forest"
        "marine"
        "climate"
        "biodiversity"
    )
)

;; Main Project Information Storage
(define-map ConservationProjectDetails
    { conservation-project-id: uint }
    {
        project-creator: principal,
        conservation-project-name: (string-ascii 50),
        conservation-project-description: (string-ascii 500),
        project-website-url: (string-ascii 100),
        conservation-category: (string-ascii 12),
        total-funding-target: uint,
        accumulated-funds: uint,
        project-current-status: (string-ascii 20),
        project-approval-status: bool,
        project-start-block-height: uint,
        project-end-block-height: uint,
        environmental-impact-score: uint,
        total-voter-participation: uint,
        completed-milestone-count: uint
    }
)

;; Donor Information Tracking
(define-map ConservationDonorRecord
    { conservation-project-id: uint, donor-wallet-address: principal }
    { 
        total-donation-amount: uint,
        most-recent-donation-date: uint,
        lifetime-donation-count: uint,
        conservation-rewards-claimed: bool
    }
)

;; Project Validator Registry
(define-map ConservationProjectValidators principal bool)

;; Project Milestone Tracking
(define-map ConservationMilestoneDetails
    { conservation-project-id: uint, milestone-sequence-id: uint }
    {
        milestone-description: (string-ascii 200),
        milestone-target-date: uint,
        milestone-completion-status: bool,
        milestone-verification-hash: (buff 32),
        milestone-validator: (optional principal)
    }
)

;; Voter Participation Records
(define-map ConservationVoteRegistry
    { conservation-project-id: uint, voter-wallet-address: principal }
    {
        staked-token-amount: uint,
        vote-submission-date: uint,
        voter-decision: (string-ascii 10)
    }
)

;; Environmental Impact Metrics
(define-map ConservationImpactMetrics
    { conservation-project-id: uint }
    {
        trees-planted-count: uint,
        conservation-area-square-meters: uint,
        carbon-offset-tons: uint,
        protected-species-count: uint,
        community-benefit-score: uint
    }
)

;; Contract State Management
(define-data-var conservation-project-counter uint u0)
(define-data-var total-active-projects uint u0)
(define-data-var contract-operational-status bool false)
(define-data-var minimum-stake-requirement uint u100)
(define-data-var voting-period-duration uint u1440) ;; 10 days in blocks

;; Helper Functions
(define-private (is-valid-string (input (string-ascii 500)))
    (and 
        (>= (len input) u1)
        (<= (len input) u500)
    )
)

(define-private (is-valid-category (category (string-ascii 12)))
    (is-some (index-of conservation-categories category))
)

(define-private (is-valid-project-id (project-id uint))
    (<= project-id (var-get conservation-project-counter))
)

(define-private (is-valid-milestone-id (project-id uint) (milestone-id uint))
    (match (map-get? ConservationProjectDetails { conservation-project-id: project-id })
        project-data (<= milestone-id (get completed-milestone-count project-data))
        false
    )
)

;; Contract Initialization
(define-public (initialize-conservation-contract)
    (begin
        (asserts! (is-eq tx-sender contract-administrator) ERROR-UNAUTHORIZED-ADMINISTRATOR)
        (asserts! (not (var-get contract-operational-status)) ERROR-CONTRACT-ALREADY-INITIALIZED)
        (var-set contract-operational-status true)
        (ok true)
    )
)

;; Update Stake Requirements
(define-public (update-minimum-stake-requirement (new-stake-amount uint))
    (begin
        (asserts! (is-eq tx-sender contract-administrator) ERROR-UNAUTHORIZED-ADMINISTRATOR)
        (asserts! (> new-stake-amount u0) ERROR-INVALID-AMOUNT-PROVIDED)
        (var-set minimum-stake-requirement new-stake-amount)
        (ok true)
    )
)

;; Initialize New Conservation Project
(define-public (initiate-conservation-project 
    (project-name (string-ascii 50))
    (project-description (string-ascii 500))
    (project-website (string-ascii 100))
    (conservation-type (string-ascii 12))
    (funding-target-amount uint)
    (project-duration uint))
    (let
        (
            (new-project-id (+ (var-get conservation-project-counter) u1))
            (project-completion-height (+ block-height project-duration))
        )
        (asserts! (is-valid-string project-name) ERROR-INVALID-INPUT)
        (asserts! (is-valid-string project-description) ERROR-INVALID-INPUT)
        (asserts! (is-valid-string project-website) ERROR-INVALID-INPUT)
        (asserts! (is-valid-category conservation-type) ERROR-INVALID-INPUT)
        (asserts! (> funding-target-amount u0) ERROR-INVALID-AMOUNT-PROVIDED)
        (asserts! (> project-duration u0) ERROR-INVALID-TIMESTAMP)

        ;; Process stake requirement
        (try! (stx-transfer? (var-get minimum-stake-requirement) tx-sender (as-contract tx-sender)))

        (map-set ConservationProjectDetails
            { conservation-project-id: new-project-id }
            {
                project-creator: tx-sender,
                conservation-project-name: project-name,
                conservation-project-description: project-description,
                project-website-url: project-website,
                conservation-category: conservation-type,
                total-funding-target: funding-target-amount,
                accumulated-funds: u0,
                project-current-status: "active",
                project-approval-status: false,
                project-start-block-height: block-height,
                project-end-block-height: project-completion-height,
                environmental-impact-score: u0,
                total-voter-participation: u0,
                completed-milestone-count: u0
            }
        )
        (var-set conservation-project-counter new-project-id)
        (var-set total-active-projects (+ (var-get total-active-projects) u1))
        (ok new-project-id)
    )
)

;; Create Project Milestone
(define-public (create-conservation-milestone 
    (conservation-project-id uint)
    (milestone-description (string-ascii 200))
    (milestone-deadline uint))
    (let
        (
            (project-data (unwrap! (map-get? ConservationProjectDetails { conservation-project-id: conservation-project-id }) ERROR-PROJECT-NOT-FOUND))
            (current-milestone-number (get completed-milestone-count project-data))
        )
        (asserts! (is-valid-project-id conservation-project-id) ERROR-PROJECT-NOT-FOUND)
        (asserts! (is-eq (get project-creator project-data) tx-sender) ERROR-INSUFFICIENT-PERMISSIONS)
        (asserts! (> milestone-deadline block-height) ERROR-INVALID-TIMESTAMP)
        (asserts! (is-valid-string milestone-description) ERROR-INVALID-INPUT)

        (map-set ConservationMilestoneDetails
            { conservation-project-id: conservation-project-id, milestone-sequence-id: current-milestone-number }
            {
                milestone-description: milestone-description,
                milestone-target-date: milestone-deadline,
                milestone-completion-status: false,
                milestone-verification-hash: 0x,
                milestone-validator: none
            }
        )
        (ok true)
    )
)

;; Complete Project Milestone
(define-public (complete-conservation-milestone 
    (conservation-project-id uint)
    (milestone-sequence-id uint)
    (verification-proof (buff 32)))
    (let
        (
            (project-data (unwrap! (map-get? ConservationProjectDetails { conservation-project-id: conservation-project-id }) ERROR-PROJECT-NOT-FOUND))
            (milestone-data (unwrap! (map-get? ConservationMilestoneDetails { conservation-project-id: conservation-project-id, milestone-sequence-id: milestone-sequence-id }) ERROR-MILESTONE-NOT-FOUND))
        )
        (asserts! (is-valid-project-id conservation-project-id) ERROR-PROJECT-NOT-FOUND)
        (asserts! (is-valid-milestone-id conservation-project-id milestone-sequence-id) ERROR-MILESTONE-NOT-FOUND)
        (asserts! (is-eq (get project-creator project-data) tx-sender) ERROR-INSUFFICIENT-PERMISSIONS)
        (asserts! (not (get milestone-completion-status milestone-data)) ERROR-MILESTONE-ALREADY-APPROVED)

        (map-set ConservationMilestoneDetails
            { conservation-project-id: conservation-project-id, milestone-sequence-id: milestone-sequence-id }
            (merge milestone-data {
                milestone-completion-status: true,
                milestone-verification-hash: verification-proof
            })
        )

        (map-set ConservationProjectDetails
            { conservation-project-id: conservation-project-id }
            (merge project-data {
                completed-milestone-count: (+ (get completed-milestone-count project-data) u1)
            })
        )
        (ok true)
    )
)

;; Register Project Vote
(define-public (submit-conservation-vote 
    (conservation-project-id uint)
    (token-stake-amount uint)
    (vote-selection (string-ascii 10)))
    (let
        (
            (project-data (unwrap! (map-get? ConservationProjectDetails { conservation-project-id: conservation-project-id }) ERROR-PROJECT-NOT-FOUND))
            (existing-vote-record (map-get? ConservationVoteRegistry { conservation-project-id: conservation-project-id, voter-wallet-address: tx-sender }))
        )
        (asserts! (is-valid-project-id conservation-project-id) ERROR-PROJECT-NOT-FOUND)
        (asserts! (is-eq (get project-current-status project-data) "active") ERROR-PROJECT-NO-LONGER-ACTIVE)
        (asserts! (is-none existing-vote-record) ERROR-USER-ALREADY-VOTED)
        (asserts! (>= (- (get project-end-block-height project-data) block-height) (var-get voting-period-duration)) ERROR-VOTING-PERIOD-ENDED)
        (asserts! (> token-stake-amount u0) ERROR-INVALID-AMOUNT-PROVIDED)
        (asserts! (is-valid-string vote-selection) ERROR-INVALID-INPUT)

        (try! (stx-transfer? token-stake-amount tx-sender (as-contract tx-sender)))

        (map-set ConservationVoteRegistry
            { conservation-project-id: conservation-project-id, voter-wallet-address: tx-sender }
            {
                staked-token-amount: token-stake-amount,
                vote-submission-date: block-height,
                voter-decision: vote-selection
            }
        )

        (map-set ConservationProjectDetails
            { conservation-project-id: conservation-project-id }
            (merge project-data {
                total-voter-participation: (+ (get total-voter-participation project-data) u1)
            })
        )
        (ok true)
    )
)

;; Record Project Environmental Impact
(define-public (update-environmental-impact
    (conservation-project-id uint)
    (trees-planted uint)
    (protected-area uint)
    (carbon-reduction uint)
    (protected-species uint)
    (social-impact uint))
    (let
        (
            (project-data (unwrap! (map-get? ConservationProjectDetails { conservation-project-id: conservation-project-id }) ERROR-PROJECT-NOT-FOUND))
        )
        (asserts! (is-valid-project-id conservation-project-id) ERROR-PROJECT-NOT-FOUND)
        (asserts! (is-eq (get project-creator project-data) tx-sender) ERROR-INSUFFICIENT-PERMISSIONS)
        (asserts! (>= trees-planted u0) ERROR-INVALID-AMOUNT-PROVIDED)
        (asserts! (>= protected-area u0) ERROR-INVALID-AMOUNT-PROVIDED)
        (asserts! (>= carbon-reduction u0) ERROR-INVALID-AMOUNT-PROVIDED)
        (asserts! (>= protected-species u0) ERROR-INVALID-AMOUNT-PROVIDED)
        (asserts! (>= social-impact u0) ERROR-INVALID-AMOUNT-PROVIDED)

        (map-set ConservationImpactMetrics
            { conservation-project-id: conservation-project-id }
            {
                trees-planted-count: trees-planted,
                conservation-area-square-meters: protected-area,
                carbon-offset-tons: carbon-reduction,
                protected-species-count: protected-species,
                community-benefit-score: social-impact
            }
        )

        (map-set ConservationProjectDetails
            { conservation-project-id: conservation-project-id }
            (merge project-data {
                environmental-impact-score: (+ trees-planted protected-area carbon-reduction protected-species social-impact)
            })
        )
        (ok true)
    )
)

;; Read-only Functions

;; Retrieve Project Impact Metrics
(define-read-only (get-conservation-impact-metrics (conservation-project-id uint))
    (map-get? ConservationImpactMetrics { conservation-project-id: conservation-project-id })
)

;; Retrieve Milestone Information
(define-read-only (get-conservation-milestone-info (conservation-project-id uint) (milestone-sequence-id uint))
    (map-get? ConservationMilestoneDetails { conservation-project-id: conservation-project-id, milestone-sequence-id: milestone-sequence-id })
)

;; Retrieve Voting Information
(define-read-only (get-conservation-vote-info (conservation-project-id uint) (voter-wallet-address principal))
    (map-get? ConservationVoteRegistry { conservation-project-id: conservation-project-id, voter-wallet-address: voter-wallet-address })
)

;; Retrieve Project Performance Metrics
(define-read-only (get-conservation-project-metrics (conservation-project-id uint))
    (match (map-get? ConservationProjectDetails { conservation-project-id: conservation-project-id })
        project-data (ok {
            funding-progress-percentage: (/ (* (get accumulated-funds project-data) u100) (get total-funding-target project-data)),
            milestone-completion-percentage: (/ (* (get completed-milestone-count project-data) u100) u5),
            environmental-impact-rating: (get environmental-impact-score project-data),
            total-participant-count: (get total-voter-participation project-data)
        })
        ERROR-PROJECT-NOT-FOUND
    )
)

;; Retrieve Project Timeline Statistics
(define-read-only (get-conservation-project-timeline (conservation-project-id uint))
    (match (map-get? ConservationProjectDetails { conservation-project-id: conservation-project-id })
        project-data (ok {
            days-until-completion: (/ (- (get project-end-block-height project-data) block-height) u144),
            total-donor-count: (get total-voter-participation project-data),
            current-impact-rating: (get environmental-impact-score project-data),
            total-milestones-completed: (get completed-milestone-count project-data)
        })
        ERROR-PROJECT-NOT-FOUND
    )
)