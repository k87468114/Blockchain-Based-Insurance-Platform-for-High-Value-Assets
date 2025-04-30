;; Policy Management Contract
;; Records coverage terms and conditions

(define-data-var admin principal tx-sender)
(define-data-var policy-counter uint u0)

;; Policy data structure
(define-map policies
  { policy-id: uint }
  {
    asset-id: uint,
    owner: principal,
    premium-paid: uint,
    coverage-amount: uint,
    start-block: uint,
    end-block: uint,
    active: bool
  }
)

;; Asset to policy mapping
(define-map asset-policies
  { asset-id: uint }
  { policy-id: uint }
)

;; Create a new policy
(define-public (create-policy
                (asset-id uint)
                (premium uint)
                (coverage-amount uint)
                (duration uint))
  (let (
    (policy-id (+ (var-get policy-counter) u1))
    (current-block block-height)
  )
    (begin
      (asserts! (> premium u0) (err u300))
      (asserts! (> coverage-amount u0) (err u301))
      (asserts! (> duration u0) (err u302))

      ;; Update policy counter
      (var-set policy-counter policy-id)

      ;; Create policy record
      (map-set policies
        { policy-id: policy-id }
        {
          asset-id: asset-id,
          owner: tx-sender,
          premium-paid: premium,
          coverage-amount: coverage-amount,
          start-block: current-block,
          end-block: (+ current-block duration),
          active: true
        }
      )

      ;; Map asset to policy
      (map-set asset-policies
        { asset-id: asset-id }
        { policy-id: policy-id }
      )

      (ok policy-id)
    )
  )
)

;; Cancel a policy
(define-public (cancel-policy (policy-id uint))
  (let ((policy (unwrap! (map-get? policies { policy-id: policy-id }) (err u303))))
    (begin
      (asserts! (is-eq tx-sender (get owner policy)) (err u304))
      (asserts! (get active policy) (err u305))

      (ok (map-set policies
        { policy-id: policy-id }
        (merge policy { active: false })
      ))
    )
  )
)

;; Check if policy is active
(define-read-only (is-policy-active (policy-id uint))
  (let ((policy (default-to
                  { active: false, end-block: u0 }
                  (map-get? policies { policy-id: policy-id }))))
    (and
      (get active policy)
      (<= block-height (get end-block policy))
    )
  )
)

;; Get policy details
(define-read-only (get-policy (policy-id uint))
  (map-get? policies { policy-id: policy-id })
)

;; Get policy for an asset
(define-read-only (get-policy-for-asset (asset-id uint))
  (let ((policy-map (map-get? asset-policies { asset-id: asset-id })))
    (match policy-map
      policy-data (get-policy (get policy-id policy-data))
      none
    )
  )
)
