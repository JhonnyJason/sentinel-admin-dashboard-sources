############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("authmodule")
#endregion

############################################################
import {
  STRINGHEX64, NONEMPTYSTRING, createValidator
} from 'thingy-schema-validate';

############################################################
import { sha256, createKeyPair, createPublicKey, createSignature, createSymKey } from "secret-manager-crypto-utils"
import { hexToBytes, bytesToHex } from "thingy-byte-utils"
import { ThingyCryptoNode } from "thingy-crypto-node"
import * as validStamp from "validatabletimestamp"

############################################################
import { pwdSalt } from "./configmodule.js"
import * as qrReader from "./qrreadermodule.js"
import * as sci from "./scimodule.js"
import * as triggers from "./navtriggers.js"
import * as msgBox from "./messageboxmodule.js"

############################################################
KEY_INFO_KEY = "key-info"

############################################################
keyInfoSchema = {
    lockedKey: STRINGHEX64,
    targetHash: STRINGHEX64,
    salt: NONEMPTYSTRING,
    lockType: "qr" # only type QR for now :-)
}

############################################################
otcValue = null
keyInfo = null

############################################################
cryptoNode = null  # In-memory only, never persisted
setReady = null
isReady = new Promise(((rslv) -> setReady = rslv ))

############################################################
export initialize = ->
    log "initialize"
    logoutButton.addEventListener("click", logoutClicked)
    keyInfo = JSON.parse(localStorage.getItem(KEY_INFO_KEY))
    err = validateKeyInfoObj(keyInfo)
    if err then keyInfo = null
    else log "we got a valid key-info!"
    return


############################################################
validateKeyInfoObj = createValidator(keyInfoSchema, true)

############################################################
logoutClicked = ->
    log "logoutClicked"
    cryptoNode = null
    triggers.toHome()
    return

############################################################
# Called by appcore on startup with OTC from URL (if present)
export setOTC = (otc) ->
    log "setOTC"
    otcValue = otc
    return

############################################################
# Returns: "keySetup" | "keyLocked" | "keyUnlocked" | "inaccessible"
export getAuthenticationState = ->
    if otcValue then return "keySetup"
    if cryptoNode then return "keyUnlocked"
    if keyInfo then return "keyLocked"
    return "inaccessible"

export getAuthorizationMessage = ->
    log "getAuthorizationPayload"
    await isReady
    payload = {}
    payload.randomHex = createSymKey()
    payload.timestamp = validStamp.create()
    payload.publicKey = cryptoNode.publicKeyHex
    payload.signature = ""
    payloadString = JSON.stringify(payload)
    sig = await cryptoNode.sign(payloadString)
    payloadString.replace("signature:\"\"", "signature:\"#{sig}\"")
    return payloadString

############################################################
# Called by authframemodule when user confirms PIN during key setup
export createNewCredentials = (pin) ->
    log "createNewCredentials"
    try
        # Step 1: Recover secret from OTC + PIN + salt
        secret = await sha256(otcValue + pin + pwdSalt)
        log "secret recovered"

        # Step 2: Generate new key pair
        { secretKeyHex, publicKeyHex } = await createKeyPair()
        log "key pair generated"

        # Step 3: Register with server
        timestamp = Date.now().toString()
        payload = { publicKey: publicKeyHex, otc: otcValue, secret, timestamp, signature: "" }
        payloadStr = JSON.stringify(payload)
        signature = await createSignature(payloadStr, secretKeyHex)
        payload.signature = signature
        await sci.registerAdmin(payload)
        log "registered with server"

        # Step 4: Scan QR code for key fragment
        salt = createSymKey() # is 48bytes random values
        qrContent = await readWithRetries(100)
        if !qrContent then throw new Error("QR scan cancelled")
        keyFragment = await sha256(qrContent + salt)
        log "key fragment from QR"

        # Step 5: Lock the key (XOR with fragment)
        lockedKey = xorHex(secretKeyHex, keyFragment)
        log "key locked"

        # Step 6: Create targetHash for unlock validation
        targetHash = await sha256(publicKeyHex + salt)

        # Step 7: Store key-info
        keyInfo = { lockedKey, targetHash, salt, lockType: "qr" }
        localStorage.setItem(KEY_INFO_KEY, JSON.stringify(keyInfo))
        log "key-info stored"

        # Step 8: Keep unlocked key in memory
        cryptoNode = new ThingyCryptoNode({secretKeyHex, publicKeyHex})
        otcValue = null  # Clear OTC after successful setup
        log "credentials created successfully"
        setReady()
        
        triggers.toHome()
    catch err
        msgBox.error("createNewCredentials failed: #{err.message}")
        throw new Error("createNewCredentials failed")
    return

export unlockKey = ->
    log "unlockKey"
    try
        validationAttempts = 3

        while validationAttempts > 0 and !cryptoNode?
            # Read QR with retries for scan failures
            qrContent = await readWithRetries(10)
            continue unless qrContent

            # Attempt to unlock and validate
            keyFragment = await sha256(qrContent + keyInfo.salt)
            log "key fragment from QR"

            secretKeyHex = xorHex(keyInfo.lockedKey, keyFragment)
            log "attempting unlock"

            publicKeyHex = await createPublicKey(secretKeyHex)
            testHash = await sha256(publicKeyHex + keyInfo.salt)

            if testHash == keyInfo.targetHash
                cryptoNode = new ThingyCryptoNode({secretKeyHex, publicKeyHex})
                log "key validated successfully"
                setReady()
            else
                validationAttempts--
                msgBox.error("Wrong QR code - #{validationAttempts} attempts left")

        throw new Error("Key unlock failed") unless cryptoNode?
        
        
        log "key unlocked successfully"
        triggers.toHome()
    catch err
        log "unlockKey failed: #{err.message}"
        msgBox.error("unlockKey failed: #{err.message}")
        throw new Error("unlockKey failed")
    return

############################################################
# Retry QR reading until successful or max attempts exhausted
readWithRetries = (maxAttempts = 10) ->
    attempts = maxAttempts
    while attempts > 0
        result = await qrReader.read()
        return result if result
        log "QR read failed, #{attempts - 1} attempts left"
        attempts--
    return null

############################################################
# XOR two hex strings of equal length
xorHex = (hexA, hexB) ->
    bytesA = hexToBytes(hexA)
    bytesB = hexToBytes(hexB)
    result = new Uint8Array(bytesA.length)
    for i in [0...bytesA.length]
        result[i] = bytesA[i] ^ bytesB[i]
    return bytesToHex(result)

