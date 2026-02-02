indexdomconnect = {name: "indexdomconnect"}

############################################################
indexdomconnect.initialize = () ->
    global.content = document.getElementById("content")
    global.sidenav = document.getElementById("sidenav")
    global.usermanagementBtn = document.getElementById("usermanagement-btn")
    global.forexscoreBtn = document.getElementById("forexscore-btn")
    global.authframe = document.getElementById("authframe")
    global.header = document.getElementById("header")
    global.s = document.getElementById("s")
    global.l = document.getElementById("l")
    return
    
module.exports = indexdomconnect