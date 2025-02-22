;; HopeChain: Decentralized Disaster Relief Protocol

;; Define NFT Trait
(define-trait nft-trait
    (
        (transfer (uint principal principal) (response bool uint))
        (get-owner (uint) (response principal uint))
        (get-last-token-id () (response uint uint))
        (get-token-uri (uint) (response (optional (string-ascii 256)) uint))
    )
)

;; Constants
(define-data-var contract-administrator principal tx-sender)
(define-data-var minimum-donation-amount uint u100000) ;; minimum donation in microSTX
(define-data-var proposal-approval-threshold uint u75) ;; 75% threshold for proposal approval
(define-constant nft-metadata-base-uri "ipfs://disaster-relief/metadata/")

;; Error Constants
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_DISASTER_NOT_ACTIVE (err u101))
(define-constant ERR_INSUFFICIENT_BALANCE (err u102))
(define-constant ERR_INVALID_DONATION_AMOUNT (err u103))
(define-constant ERR_PROPOSAL_ALREADY_EXECUTED (err u104))
(define-constant ERR_TOKEN_TRANSFER_FAILED (err u105))
(define-constant ERR_NOT_NFT_OWNER (err u106))
(define-constant ERR_NFT_NOT_FOUND (err u107))
(define-constant ERR_ALREADY_VOTED (err u108))
(define-constant ERR_DISASTER_NOT_FOUND (err u109))
(define-constant ERR_THRESHOLD_NOT_MET (err u110))
(define-constant ERR_INVALID_PARAMETER (err u111))

;; Data Variables
(define-data-var total-donated-funds uint u0)
(define-data-var current-disaster-id uint u0)
(define-data-var nft-token-counter uint u0)

;; Data Maps
(define-map donor-records 
    principal 
    {total-donation-amount: uint, 
     governance-power: uint, 
     owned-nft-count: uint})

(define-map disaster-registry 
    uint 
    {disaster-name: (string-ascii 64), 
     disaster-severity-level: uint, 
     funding-target: uint, 
     distributed-funds: uint, 
     is-active: bool})

(define-map relief-fund-proposals
    uint 
    {proposal-description: (string-ascii 256),
     requested-amount: uint,
     vote-count: uint,
     total-possible-votes: uint,
     is-executed: bool,
     beneficiary: principal})

(define-map nft-metadata-registry
    uint 
    (string-ascii 256))

(define-map nft-ownership-registry
    uint
    principal)

;; Track user votes
(define-map user-votes 
    {disaster-id: uint, voter: principal} 
    bool)

;; NFT Implementation
(define-non-fungible-token disaster-relief-token uint)

;; Events
(define-data-var last-event-id uint u0)

(define-map events
    uint
    {event-type: (string-ascii 32),
     data: (string-ascii 256)})

;; Event Helper Function
(define-private (emit-event (event-type (string-ascii 32)) (data (string-ascii 256)))
    (let ((event-id (+ (var-get last-event-id) u1)))
        (var-set last-event-id event-id)
        (map-set events event-id {event-type: event-type, data: data})
        (ok event-id)))

;; Administrative Functions
(define-public (update-administrator (new-admin principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-administrator)) ERR_UNAUTHORIZED)
        (asserts! (not (is-eq new-admin (var-get contract-administrator))) ERR_INVALID_PARAMETER)
        (ok (var-set contract-administrator new-admin))))

(define-public (update-minimum-donation (new-minimum uint))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-administrator)) ERR_UNAUTHORIZED)
        (asserts! (> new-minimum u0) ERR_INVALID_PARAMETER)
        (ok (var-set minimum-donation-amount new-minimum))))

(define-public (update-approval-threshold (new-threshold uint))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-administrator)) ERR_UNAUTHORIZED)
        (asserts! (and (>= new-threshold u1) (<= new-threshold u100)) ERR_INVALID_PARAMETER)
        (ok (var-set proposal-approval-threshold new-threshold))))

;; Read-Only Functions
(define-read-only (get-donor-details (donor-address principal))
    (default-to 
        {total-donation-amount: u0, governance-power: u0, owned-nft-count: u0}
        (map-get? donor-records donor-address)))

(define-read-only (get-disaster-details (disaster-id uint))
    (map-get? disaster-registry disaster-id))

(define-read-only (get-total-donations)
    (var-get total-donated-funds))

(define-read-only (get-nft-owner (token-id uint))
    (ok (map-get? nft-ownership-registry token-id)))

(define-read-only (get-nft-metadata-uri (token-id uint))
    (ok (map-get? nft-metadata-registry token-id)))

(define-read-only (get-current-token-count)
    (ok (var-get nft-token-counter)))

(define-read-only (has-voted (disaster-id uint) (voter principal))
    (default-to false (map-get? user-votes {disaster-id: disaster-id, voter: voter})))

;; Public Functions
(define-public (make-donation (donation-amount uint))
    (let ((donor-data (get-donor-details tx-sender)))
        (asserts! (>= donation-amount (var-get minimum-donation-amount)) ERR_INVALID_DONATION_AMOUNT)
        (asserts! (<= donation-amount (stx-get-balance tx-sender)) ERR_INSUFFICIENT_BALANCE)
        
        ;; Update state first to prevent reentrancy
        (map-set donor-records tx-sender
            {total-donation-amount: (+ (get total-donation-amount donor-data) donation-amount),
             governance-power: (+ (get governance-power donor-data) donation-amount),
             owned-nft-count: (+ (get owned-nft-count donor-data) u1)})
        (var-set total-donated-funds (+ (var-get total-donated-funds) donation-amount))
        
        ;; Perform transfer after state updates
        (try! (stx-transfer? donation-amount tx-sender (as-contract tx-sender)))
        
        ;; Mint NFT
        (let ((new-nft-id (+ (var-get nft-token-counter) u1)))
            (var-set nft-token-counter new-nft-id)
            (try! (nft-mint? disaster-relief-token new-nft-id tx-sender))
            (map-set nft-ownership-registry new-nft-id tx-sender)
            (map-set nft-metadata-registry new-nft-id nft-metadata-base-uri)
            (print "DONATION_RECEIVED")
            (ok true))))

(define-public (register-new-disaster (disaster-name (string-ascii 64)) (severity-level uint) (funding-target uint))
    (let ((new-disaster-id (+ (var-get current-disaster-id) u1)))
        (asserts! (is-eq tx-sender (var-get contract-administrator)) ERR_UNAUTHORIZED)
        (asserts! (> funding-target u0) ERR_INVALID_PARAMETER)
        (asserts! (and (>= severity-level u1) (<= severity-level u5)) ERR_INVALID_PARAMETER)
        (asserts! (not (is-eq disaster-name "")) ERR_INVALID_PARAMETER)
        (begin
            (map-set disaster-registry new-disaster-id
                {disaster-name: disaster-name,
                 disaster-severity-level: severity-level,
                 funding-target: funding-target,
                 distributed-funds: u0,
                 is-active: true})
            (var-set current-disaster-id new-disaster-id)
            (print "DISASTER_REGISTERED")
            (ok new-disaster-id))))

(define-public (submit-relief-proposal 
    (disaster-id uint) 
    (proposal-description (string-ascii 256)) 
    (requested-amount uint)
    (beneficiary principal))
    (let ((disaster-info (unwrap! (get-disaster-details disaster-id) ERR_DISASTER_NOT_FOUND)))
        (asserts! (get is-active disaster-info) ERR_DISASTER_NOT_ACTIVE)
        (asserts! (<= requested-amount (var-get total-donated-funds)) ERR_INSUFFICIENT_BALANCE)
        (asserts! (not (is-eq proposal-description "")) ERR_INVALID_PARAMETER)
        (asserts! (not (is-eq beneficiary tx-sender)) ERR_INVALID_PARAMETER)
        (begin
            (map-set relief-fund-proposals disaster-id
                {proposal-description: proposal-description,
                 requested-amount: requested-amount,
                 vote-count: u0,
                 total-possible-votes: (var-get total-donated-funds),
                 is-executed: false,
                 beneficiary: beneficiary})
            (print "PROPOSAL_SUBMITTED")
            (ok true))))

(define-public (cast-proposal-vote (disaster-id uint))
    (let ((proposal-data (unwrap! (map-get? relief-fund-proposals disaster-id) ERR_DISASTER_NOT_ACTIVE))
          (donor-data (get-donor-details tx-sender))
          (has-voted-already (has-voted disaster-id tx-sender)))
        
        (asserts! (not has-voted-already) ERR_ALREADY_VOTED)
        (asserts! (not (get is-executed proposal-data)) ERR_PROPOSAL_ALREADY_EXECUTED)
        
        (map-set user-votes {disaster-id: disaster-id, voter: tx-sender} true)
        (map-set relief-fund-proposals disaster-id
            (merge proposal-data 
                {vote-count: (+ (get vote-count proposal-data) (get governance-power donor-data))}))
        
        (print "VOTE_CAST")
        (ok true)))

(define-public (execute-proposal (disaster-id uint))
    (let ((proposal-data (unwrap! (map-get? relief-fund-proposals disaster-id) ERR_DISASTER_NOT_ACTIVE))
          (vote-percentage (/ (* (get vote-count proposal-data) u100) 
                            (get total-possible-votes proposal-data))))
        
        (asserts! (not (get is-executed proposal-data)) ERR_PROPOSAL_ALREADY_EXECUTED)
        (asserts! (>= vote-percentage (var-get proposal-approval-threshold)) ERR_THRESHOLD_NOT_MET)
        
        ;; Update state first
        (map-set relief-fund-proposals disaster-id
            (merge proposal-data {is-executed: true}))
        
        ;; Transfer funds
        (try! (as-contract 
            (stx-transfer? 
                (get requested-amount proposal-data)
                tx-sender
                (get beneficiary proposal-data))))
        
        (print "PROPOSAL_EXECUTED")
        (ok true)))

(define-public (transfer-nft (token-id uint) (recipient principal))
    (let ((token-owner (unwrap! (map-get? nft-ownership-registry token-id) ERR_NFT_NOT_FOUND))
          (current-owner-data (get-donor-details tx-sender))
          (recipient-data (get-donor-details recipient)))
        
        (asserts! (is-eq tx-sender token-owner) ERR_NOT_NFT_OWNER)
        (asserts! (not (is-eq tx-sender recipient)) ERR_INVALID_PARAMETER)
        
        ;; Update governance power
        (let ((governance-power-per-nft (/ (get total-donation-amount current-owner-data) 
                                           (get owned-nft-count current-owner-data))))
            (map-set donor-records tx-sender
                (merge current-owner-data 
                    {governance-power: (- (get governance-power current-owner-data) governance-power-per-nft),
                     owned-nft-count: (- (get owned-nft-count current-owner-data) u1)}))
            
            (map-set donor-records recipient
                (merge recipient-data
                    {owned-nft-count: (+ (get owned-nft-count recipient-data) u1),
                     governance-power: (+ (get governance-power recipient-data) governance-power-per-nft)}))
            
            ;; Transfer NFT ownership
            (try! (nft-transfer? disaster-relief-token token-id tx-sender recipient))
            (map-set nft-ownership-registry token-id recipient)
            (print "NFT_TRANSFERRED")
            (ok true))))

;; Impact Oracle Integration
(define-public (update-disaster-severity-level (disaster-id uint) (updated-severity uint))
    (let ((disaster-info (unwrap! (get-disaster-details disaster-id) ERR_DISASTER_NOT_FOUND)))
        (asserts! (is-eq tx-sender (var-get contract-administrator)) ERR_UNAUTHORIZED)
        (asserts! (and (>= updated-severity u1) (<= updated-severity u5)) ERR_INVALID_PARAMETER)
        (asserts! (< disaster-id (+ (var-get current-disaster-id) u1)) ERR_INVALID_PARAMETER)
        (asserts! (not (is-eq updated-severity (get disaster-severity-level disaster-info))) ERR_INVALID_PARAMETER)
        (begin
            (map-set disaster-registry disaster-id
                (merge disaster-info {disaster-severity-level: updated-severity}))
            (print "SEVERITY_UPDATED")
            (ok true))))