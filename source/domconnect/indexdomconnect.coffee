indexdomconnect = {name: "indexdomconnect"}

############################################################
indexdomconnect.initialize = () ->
    global.content = document.getElementById("content")
    global.pairInput = document.getElementById("pair-input")
    global.pairDropdown = document.getElementById("pair-dropdown")
    global.selectedPair = document.getElementById("selected-pair")
    global.baseArea = document.getElementById("base-area")
    global.quoteArea = document.getElementById("quote-area")
    global.sidenav = document.getElementById("sidenav")
    global.usermanagementBtn = document.getElementById("usermanagement-btn")
    global.forexscoreBtn = document.getElementById("forexscore-btn")
    global.authframe = document.getElementById("authframe")
    global.pinInput = document.getElementById("pin-input")
    global.acceptPinButton = document.getElementById("accept-pin-button")
    global.header = document.getElementById("header")
    global.logoutButton = document.getElementById("logout-button")
    global.qrreaderBackground = document.getElementById("qrreader-background")
    global.qrreaderVideoElement = document.getElementById("qrreader-video-element")
    global.messagebox = document.getElementById("messagebox")
    global.s = document.getElementById("s")
    global.l = document.getElementById("l")
    return
    
module.exports = indexdomconnect