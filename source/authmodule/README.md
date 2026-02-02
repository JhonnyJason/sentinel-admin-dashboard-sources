# Auth Module

Admin authentication for the Sentinel Admin Dashboard.

## Entry States

On application start, determine state based on URL and localStorage:

| Condition | Action |
|-----------|--------|
| URL has `otc=<32 hex chars>` | → Key Setup |
| No `otc`, locked key in localStorage | → Key Unlock |
| No `otc`, no locked key | → "Not Accessible" |

### 1. Key Setup
Triggered by one-time-code in URL: `?otc=e56eaabf124...`

**Flow:**
1. Ask user for associated PIN (4-digit)
2. Recover secret: `secret = sha256(otc + pin + pwdSalt)`
   - OTC = challenge, secret = response
   - pwdSalt: fixed constant from app config
3. Generate random privateKey (curve25519)
4. POST `/registerAdmin` with payload:
   ```
   { publicKey, otc, secret, timestamp, signature }
   ```
   - Signature: sign full payload with `signature=""` using privateKey
   - On failure → fall back to "Not Accessible"
   - On success → continue
5. Key-split: scan QR code (camera) with retry logic
   - Generate random `salt` (48 bytes via createSymKey)
   - `keyFragment = sha256(qrContent + salt)`
6. Lock and store:
   - `lockedKey = privateKey XOR keyFragment`
   - `targetHash = sha256(publicKey + salt)`
   - Store in localStorage `"key-info"`:
     ```
     { lockedKey, targetHash, salt, lockType: "qr" }
     ```
7. Complete:
   - Unlocked key available in memory (ThingyCryptoNode)
   - Locked key persisted in localStorage
   - Clear OTC from memory
   - → Navigate to home

### 2. Key Unlock
Triggered when locked key exists in localStorage.

**Flow:**
1. Read `key-info` from localStorage (done at initialize)
2. Request QR code via camera with retry logic
   - Up to 10 scan retries per validation attempt
   - Up to 3 validation attempts (wrong QR code)
3. Unlock:
   - `keyFragment = sha256(qrContent + salt)`
   - `privateKey = lockedKey XOR keyFragment`
4. Validate key:
   - Derive publicKey from privateKey
   - Compare `sha256(publicKey + salt)` against stored targetHash
   - If mismatch → retry with new QR scan
5. Complete:
   - Unlocked key in memory (ThingyCryptoNode)
   - → Navigate to home

### 3. Not Accessible
Dead end state. No way to proceed without:
- A valid OTC link, or
- A previously set up key

## localStorage

Key: `"key-info"`
```
{
  lockedKey: <hex string 64>,
  targetHash: <hex string 64>,
  salt: <non-empty string>,
  lockType: "qr"
}
```

## Implementation Notes

- `readWithRetries(maxAttempts)` - Shared helper for QR scan retry logic
- Server call in `registerAdmin` is stubbed (commented out) pending backend
- PIN validation: 4 digits required (handled in authframemodule)
