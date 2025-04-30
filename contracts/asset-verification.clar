;; Asset Verification Contract
;; Validates legitimate high-value items

(define-data-var admin principal tx-sender)

;; Asset data structure
(define-map assets
  { asset-id: uint }
  {
    owner: principal,
    value: uint,
    description: (string-utf8 256),
    verified: bool
  }
)

;; Asset verification status
(define-map verifiers principal bool)

;; Add a verifier
(define-public (add-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100))
    (ok (map-set verifiers verifier true))
  )
)

;; Register a new asset
(define-public (register-asset (asset-id uint) (value uint) (description (string-utf8 256)))
  (begin
    (asserts! (is-none (map-get? assets { asset-id: asset-id })) (err u101))
    (ok (map-set assets
      { asset-id: asset-id }
      {
        owner: tx-sender,
        value: value,
        description: description,
        verified: false
      }
    ))
  )
)

;; Verify an asset
(define-public (verify-asset (asset-id uint))
  (let ((asset-data (unwrap! (map-get? assets { asset-id: asset-id }) (err u102))))
    (begin
      (asserts! (default-to false (map-get? verifiers tx-sender)) (err u103))
      (ok (map-set assets
        { asset-id: asset-id }
        (merge asset-data { verified: true })
      ))
    )
  )
)

;; Get asset details
(define-read-only (get-asset (asset-id uint))
  (map-get? assets { asset-id: asset-id })
)

;; Check if asset is verified
(define-read-only (is-asset-verified (asset-id uint))
  (default-to false (get verified (map-get? assets { asset-id: asset-id })))
)
