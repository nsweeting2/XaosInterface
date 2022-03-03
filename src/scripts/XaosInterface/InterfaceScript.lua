------------------------------------------------------------------------
--  Xaos Interface written by Quid and Noax.                          --
--  Created January 2022                                              --
--                                                                    --
--  Updater code based on Jor'Mox's Generic Map Script,               --
--  I opted to check for updates only when a character is             --
--  connected or reconnected to the server to save on complexity.     --
--  I do this by handling a IAC AYT signal with sysTelnetEvent.       --
--                                                                    --
--  Requires the msdp protocol.                                       --
--  Requires the MDK Mudlet Package by Demonnic                       --
------------------------------------------------------------------------

--setup global table for msdp, the client will put things here automatically.
--keep in mind other packages will work with this table.
--table should always be created as seen below, so you don't overwrite.
msdp = msdp or {}

--require SUG from MDK by Demonnic
local SUG = require("MDK.sug")

--Setup global table for XaosInterface.
xi = xi or {
    version = 0.2, --version we compare for updating
    downloading = false, --if we are downloading an update
    downloadPath = "https://raw.githubusercontent.com/nsweeting2/Xaos-UI/main/XaosInterface/", --path we download files from
    folder = "/xaosinterface",
    file = "XaosInterface.xml",
    updating = false, --if we are installing an update
    neededMSDP = { --all of the msdp variables we will be requesting from the server
        [[CHARACTER_NAME]], [[CHARACTER_ID]], [[HEALTH]], [[HEALTH_MAX]],
        [[MOVEMENT]], [[MOVEMENT_MAX]], [[MANA]], [[MANA_MAX]],
        [[EXPERIENCE]], [[EXPERIENCE_MAX]], [[HERO_EXP]], [[HERO_EXP_TNL]],
        [[SHIELDER]], [[SHIELDER_MAX]], [[PARTY_MEM]], [[IN_ROOM]],
        },
    stylesheet = { -- all of our stylesheets, I think we should consider loading these from a lua file... 
        shieldbar_front = [[
            background-color: rgba(155, 155, 155, 80%);
            border-width: 1px;
            border-color: black;
            border-style: solid;
            border-radius: 7;
            padding: 3px;
            ]],
        shieldbar_back = [[
            background-color: rgba(155, 155, 155, 50%);
            border-width: 1px;
            border-color: black;
            border-style: solid;
            border-radius: 7;
            padding: 3px;
            ]],
        hpbar_front = [[
            background-color: rgba(0, 255, 0,100%);
            border-width: 1px;
            border-color: black;
            border-style: solid;
            border-radius: 7;
            padding: 3px;
            ]],
        hpbar_back = [[
            background-color: rgba(0, 255, 0,50%);
            border-width: 1px;
            border-color: black;
            border-style: solid;
            border-radius: 7;
            padding: 3px;
            ]],
        manabar_front = [[
            background-color: rgba(0, 0, 255, 100%);
            border-width: 1px;
            border-color: black;
            border-style: solid;
            border-radius: 7;
            padding: 3px;
            ]],
        manabar_back = [[
            background-color: rgba(0, 0, 255, 50%);
            border-width: 1px;
            border-color: black;
            border-style: solid;
            border-radius: 7;
            padding: 3px;
            ]],
        movebar_front = [[
            background-color: rgba(198, 198, 0, 100%);
            border-width: 1px;
            border-color: black;
            border-style: solid;
            border-radius: 7;
            padding: 3px;
            ]],
        movebar_back = [[
            background-color: rgba(198, 198, 0, 50%);
            border-width: 1px;
            border-color: black;
            border-style: solid;
            border-radius: 7;
            padding: 3px;
            ]],
        expbar_front = [[
            background-color: rgba(155,0,225, 100%);
            border-width: 1px;
            border-color: black;
            border-style: solid;
            border-radius: 7;
            padding: 3px;
            ]],
        expbar_back = [[
            background-color: rgba(155,0,225, 75%);
            border-width: 1px;
            border-color: black;
            border-style: solid;
            border-radius: 7;
            padding: 3px;
            ]],
        herobar_front = [[
            background-color: rgba(155,0,225, 15%);
            border-width: 1px;
            border-color: black;
            border-style: solid;
            border-radius: 7;
            padding: 3px;
            ]],
        herobar_back = [[
            background-color: rgba(0,0,0, 0%);
            border-width: 1px;
            border-color: black;
            border-style: solid;
            border-radius: 7;
            padding: 3px;
            ]],
        targetbar_front = [[
            background-color: rgba(255,0,0, 0%);
            border-width: 1px;
            border-color: black;
            border-style: solid;
            border-radius: 7;
            padding: 3px;
            ]],
        targetbar_back = [[
            background-color: rgba(255,0,0, 50%);
            border-width: 1px;
            border-color: black;
            border-style: solid;
            border-radius: 7;
            padding: 3px;
            ]],
        neutralbar_front = [[
            background-color: rgba(204,204,0, 0%);
            border-width: 1px;
            border-color: black;
            border-style: solid;
            border-radius: 7;
            padding: 3px;
            ]],
        neutralbar_back = [[
            background-color: rgba(204,204,0, 50%);
            border-width: 1px;
            border-color: black;
            border-style: solid;
            border-radius: 7;
            padding: 3px;
            ]],
        allybar_front = [[
            background-color: rgba(0,255,0, 0%);
            border-width: 1px;
            border-color: black;
            border-style: solid;
            border-radius: 7;
            padding: 3px;
            ]],
        allybar_back = [[
            background-color: rgba(0,255,0, 50%);
            border-width: 1px;
            border-color: black;
            border-style: solid;
            border-radius: 7;
            padding: 3px;
            ]],
    },
}

local profilePath = getMudletHomeDir() --setup profilePath so we can use in in functions below.
profilePath = profilePath:gsub("\\","/") --fix the path for windows folks

--formatting for stylized echos
local xiTag = "<DarkViolet>[-XAOS-<DarkViolet>]  - <reset>"

--echo function for style points
function xi.echo(text)

    cecho(xiTag .. text .. "\n")

end

local function on_IN_ROOM()

    display(msdp.IN_ROOM)

end

local function playerGaugesAdjustment()

    if tonumber(msdp.SHIELDER_MAX) == 0 then
        xi.shieldbar:hide()
        xi.shieldbar:stop()
        xi.hpbar:move(0,0)
        xi.manabar:move("50%",0)
        xi.hpbar:resize("50%","100%")
        xi.manabar:resize("50%","100%")
    else
        xi.shieldbar:show()
        xi.shieldbar:start()
        xi.shieldbar:move(0,0)
        xi.hpbar:move("5%",0)
        xi.manabar:move("50%",0)
        xi.shieldbar:resize("5%","100%")
        xi.hpbar:resize("45%","100%")
        xi.manabar:resize("50%","100%")
    end
    xi.movebar:move("50%",0)
    xi.expbar:move(0,0)
    xi.herobar:move(0,0)
    xi.movebar:resize("50%", "100%")
    xi.expbar:resize("50%", "100%")
    xi.herobar:resize("50%", "100%")

end

local function roomGaugesAdjustment()

end

local function partyGaugesAdjustment()

end

local function buildPlayerGaugeArea()

    --setup adjustable container
    xi.playerGaugeAdjCon =  xi.playerGaugeAdjCon or Adjustable.Container:new({
        name = "playerGaugeAdjCon",
        x = "0%", y = "90%",
        width = "100%", height = "10%",
        adjLabelstyle = [[
            background-color:rgba(0,0,0,100%);
            border: 5px groove grey;
            ]],
        buttonstyle = [[
            QLabel{
                border-radius: 7px;
                background-color: rgba(140,140,140,100%);
                }
            QLabel::hover{
                background-color: rgba(160,160,160,50%);
                }
            ]],
        buttonFontSize = 4,
        buttonsize = 8,
        titleText = "",
        titleTxtColor = "black",
        padding = 8,
        })

    xi.playerGaugeAdjCon:attachToBorder("bottom")
    xi.playerGaugeAdjCon:lockContainer("light")

    --now we make a vbox with two hbox's in it
    xi.playerGaugeVCon = xi.playerGaugeVCon or Geyser.VBox:new({
        name = "playerGaugeVCon",
        x = 0, y = 0,
        width = "100%", height = "100%"
        },xi.playerGaugeAdjCon)

    xi.playerGaugeHCon1 = xi.playerGaugeHCon1 or Geyser.HBox:new({
        name = "playerGaugeHCon1",
        },xi.playerGaugeVCon)

    xi.playerGaugeHCon2 = xi.playerGaugeHCon2 or Geyser.HBox:new({
        name = "playerGaugeHCon2",
        },xi.playerGaugeVCon)

    --I used doubleclick calls when we used default gauges,
    --SUG made it not needed, but i left the code incase.

    --spawn three gauges in our first hbox, for shield, hp, and mana
    --Shielder Gauge
    xi.shieldbar = xi.shieldbar or SUG:new({
        name = "shieldbar",
        updateTime = 250,
        textTemplate = "<center><strong>&#x1F6E1;</strong></center>",
        currentVariable = "msdp.SHIELDER",
        maxVariable = "msdp.SHIELDER_MAX",
        },xi.playerGaugeHCon1)

    xi.shieldbar.front:setStyleSheet(xi.stylesheet.shieldbar_front)
    xi.shieldbar.back:setStyleSheet(xi.stylesheet.shieldbar_back)
    --xi.shieldbar.text:setDoubleClickCallback("gaugeDisplayToggle",1)
    --xi.shieldbar.text:setDoubleClickCallback(function() xi.gaugeDisplayToggle(1) end)
    xi.shieldbar:stop() --we don't always want this updating
    xi.shieldbar:hide() --we don't always show this bar

    --HP Gauge
    xi.hpbar = xi.hpbar or SUG:new({
        name = "hpbar",
        updateTime = 250,
        textTemplate = "<center><strong>&#x2764;: |c/|m (|p%)</strong></center>",
        currentVariable = "msdp.HEALTH",
        maxVariable = "msdp.HEALTH_MAX",
        },xi.playerGaugeHCon1)

    xi.hpbar.front:setStyleSheet(xi.stylesheet.hpbar_front)
    xi.hpbar.back:setStyleSheet(xi.stylesheet.hpbar_back)
    --xi.hpbar.text:setDoubleClickCallback("gaugeDisplayToggle",2)
    --xi.hpbar.text:setDoubleClickCallback(function() xi.gaugeDisplayToggle(2) end)

    --Mana Gauge
    xi.manabar = xi.manabar or SUG:new({
        name = "manabar",
        updateTime = 250,
        textTemplate = "<strong><center>&#9964;: |c/|m (|p%)</strong></center>",
        currentVariable = "msdp.MANA",
        maxVariable = "msdp.MANA_MAX",
        },xi.playerGaugeHCon1)

    xi.manabar.front:setStyleSheet(xi.stylesheet.manabar_front)
    xi.manabar.back:setStyleSheet(xi.stylesheet.manabar_back)
    --xi.manabar.text:setDoubleClickCallback("xi.gauge_toggle",3)
    --xi.manabar.text:setDoubleClickCallback(function() xi.gaugeDisplayToggle(3) end)

    --spawn three gauges in our fourth hbox, for movement, hero exp, and exp
    --Move Gauge
    xi.movebar = xi.movebar or SUG:new({
        name = "movebar",
        updateTime = 250,
        textTemplate = "<center><strong>&#129462;: |c/|m (|p%)</strong></center>",
        currentVariable = "msdp.MOVEMENT",
        maxVariable = "msdp.MOVEMENT_MAX",
        },xi.playerGaugeHCon2)

    xi.movebar.front:setStyleSheet(xi.stylesheet.movebar_front)
    xi.movebar.back:setStyleSheet(xi.stylesheet.movebar_back)
    --xi.movebar.text:setDoubleClickCallback("gaugeDisplayToggle",2)
    --xi.movebar.text:setDoubleClickCallback(function() xi.gaugeDisplayToggle(4) end)

    --Exp Gauge
    xi.expbar = xi.expbar or SUG:new({
        name = "expbar",
        updateTime = 250,
        textTemplate = " ",
        currentVariable = "msdp.EXPERIENCE",
        maxVariable = "msdp.EXPERIENCE_MAX",
        },xi.playerGaugeHCon2)

    xi.expbar.front:setStyleSheet(xi.stylesheet.expbar_front)
    xi.expbar.back:setStyleSheet(xi.stylesheet.expbar_back)
    --xi.expbar.text:setDoubleClickCallback("xi.gauge_toggle",3)
    --xi.expbar.text:setDoubleClickCallback(function() xi.gaugeDisplayToggle(5) xi.gaugeDisplayToggle(6) end)

    --HeroExp Gauge
    xi.herobar = xi.herobar or SUG:new({
        name = "herobar",
        updateTime = 250,
        textTemplate = "<center><strong>EXP: |c/|m (|p%)</center></strong>",
        currentVariable = "msdp.HERO_EXP",
        maxVariable = "msdp.HERO_EXP_TNL",
        },xi.playerGaugeHCon2)

    xi.herobar.front:setStyleSheet(xi.stylesheet.herobar_front)
    xi.herobar.back:setStyleSheet(xi.stylesheet.herobar_back)
    --xi.herobar.text:setDoubleClickCallback("xi.gauge_toggle",3)
    --xi.herobar.text:setDoubleClickCallback(function() xi.gaugeDisplayToggle(5) xi.gaugeDisplayToggle(6) end)

    --put everyone in their place
    playerGaugesAdjustment()

end

local function buildInRoomGaugeArea()

    --setup adjustable container
    xi.inRoomGaugeAdjCon =  xi.gaugeAinRoomGaugeAdjCondjCon or Adjustable.Container:new({
        name = "inRoomGaugeAdjCon",
        x = "0%", y = "0%",
        width = "100%", height = "6%",
        adjLabelstyle = [[
            background-color:rgba(0,0,0,100%);
            border: 5px groove grey;
            ]],
        buttonstyle = [[
            QLabel{
                border-radius: 7px;
                background-color: rgba(140,140,140,100%);
                }
            QLabel::hover{
                background-color: rgba(160,160,160,50%);
                }
            ]],
        buttonFontSize = 4,
        buttonsize = 8,
        titleText = "",
        titleTxtColor = "black",
        padding = 8,
        })

    xi.inRoomGaugeAdjCon:attachToBorder("top")
    xi.inRoomGaugeAdjCon:lockContainer("light")

    --now we make a hbox
    xi.inRoomGaugeHCon = xi.inRoomGaugeHCon or Geyser.HBox:new({
        name = "inRoomGaugeHCon",
        x = 0, y = 0,
        width = "100%", height = "100%"
        },xi.inRoomGaugeAdjCon)

    --spawn up nine gauges and one label in our hbox, for in room hp bars
    --In Room Gauges

    --Target Gauge
    xi.targetbar = xi.targetbar or SUG:new({
        name = "targetbar",
        updateTime = 250,
        textTemplate = "<center><strong>&#x2764;:|p%</center></strong>",
        --currentVariable = "",
        --maxVariable = "",
        },xi.inRoomGaugeHCon)

    xi.targetbar.front:setStyleSheet(xi.stylesheet.targetbar_front)
    xi.targetbar.back:setStyleSheet(xi.stylesheet.targetbar_back)

    xi.targetbar:stop()
    --xi.targetbar:hide()

    xi.irbar = xi.irbar or {}

    for i = 1,8 do
        xi.irbar[i] = xi.irbar[i] or SUG:new({
            name = "irbar"..i,
            updateTime = 500,
            textTemplate = "<center><strong>&#x2764;:|p%</center></strong>",
            --currentVariable = "",
            --maxVariable = "",
            },xi.inRoomGaugeHCon)

        xi.irbar[i].front:setStyleSheet(xi.stylesheet.neutralbar_front)
        xi.irbar[i].back:setStyleSheet(xi.stylesheet.neutralbar_back)

        xi.irbar[i]:stop()
        --xi.irbar[i]:hide()

    end

    --overflow label for when we have over 8 people in room
    --In Room Overflow Label
    xi.iroverflow = xi.iroverflow or Geyser.Label:new({
        name = "iroverflow",
        },xi.inRoomGaugeHCon)

    --xi.iroverflow:echo("<left><strong>...", "18")
    --xi.iroverflow:hide()

    --put everything in its place
    roomGaugesAdjustment()

end

local function buildPartyGaugeArea()

    --this is not complete and needs to be fully reviewed

      --spawn up nine gauges and one label in our second hbox, for ally hp bars
    --ally Gauges

    --Target Gauge
    xi.partnerbar = xi.partnerbar or SUG:new({
        name = "partnerbar",
        updateTime = 250,
        textTemplate = "<center><strong>&#x2764;:|p%</center></strong>",
        --currentVariable = "",
        --maxVariable = "",
        },xi.gaugeHCon2)

    xi.partnerbar.front:setStyleSheet(xi.stylesheet.allybar_front)
    xi.partnerbar.back:setStyleSheet(xi.stylesheet.allybar_back)

    xi.partnerbar:stop()
    --xi.partnerbar:hide()

    xi.allybar = xi.allybar or {}

    for i = 1,8 do
        xi.allybar[i] = xi.allybar[i] or SUG:new({
            name = "allybar"..i,
            updateTime = 500,
            textTemplate = "<center><strong>&#x2764;:|p%</center></strong>",
            --currentVariable = "",
            --maxVariable = "",
            },xi.gaugeHCon2)

        xi.allybar[i].front:setStyleSheet(xi.stylesheet.allybar_front)
        xi.allybar[i].back:setStyleSheet(xi.stylesheet.allybar_back)

        xi.allybar[i]:stop()
        --xi.allybar[i]:hide()

    end

    --overflow label for when we have over 8 people in party
    --Ally Overflow Label
    xi.allyoverflow = xi.allyoverflow or Geyser.Label:new({
        name = "allyoverflow",
        },xi.gaugeHCon2)

    --xi.allyoverflow:echo("<left><strong>...", "18")
    --xi.allyoverflow:hide()

    --put everything in its place
    partyGaugesAdjustment()

end

--will save needed values into config.lua
function xi.saveConfigs()

    local configs = {}
    local path = profilePath .. xi.folder

    --this is where we would save stuff
    table.save(path.."/configs.lua",configs)
    xi.saveTimer = tempTimer(60, [[xi.saveConfigs()]])

end

--will load needed values from config.lua
--will setup MSDP and check it
local function config()

    local configs = {}
    local path = profilePath .. xi.folder

    --if our subdir doesn't exist make it
    if not io.exists(path) then
        lfs.mkdir(path)
    end

    --load stored configs from file if it exists
    if io.exists(path.."/configs.lua") then
        table.load(path.."/configs.lua",configs)
        --this is where we would load stuff
    end

    --configure the msdp we need for questing
    for k, v in pairs (xi.neededMSDP) do
        sendMSDP("REPORT",tostring(v))
    end

    --setup our gauge areas
    buildPlayerGaugeArea()

    buildInRoomGaugeArea()

    --buildPartyGaugeArea()

    --and we are done configuring XaosInterface
    xi.echo("The -=XAOS=- Interface has been configured.")

end

--will compare xi.version to highest version is version.lua
--versions.lua must be downloaded by xi.downloadVersions first
local function compareVersion()

    local path = profilePath .. xi.folder .. "/versions.lua"
    local versions = {}

    --load versions.lua into versions table
    table.load(path, versions)

    --set pos to the index of value of ct.version
    local pos = table.index_of(versions, xi.version) or 0

    --if pos isn't the top side of versions then we are out of date by the difference
    --enable the update alias and echo that we are out of date
    if pos ~= #versions then
        enableAlias("InterfaceUpdate")
        xi.echo(string.format("XaosInterface is currently %d versions behind.",#versions - pos))
        xi.echo("To update now, please type: interface update")
    end

end

--will download the versions.lua file from the web
function xi.downloadVersions()

    if xi.downloadPath ~= "" then
        local path, file = profilePath .. xi.folder, "/versions.lua"
        xi.downloading = true
        downloadFile(path .. file, xi.downloadPath .. file)
    end

end

--will uninstall XaosInterface and reinstall XaosInterface
local function updatePackage()

    local path = profilePath .. xi.folder .. xi.file

    disableAlias("InterfaceUpdate")
    xi.updating = true
    uninstallPackage("XaosInterface")
    installPackage(path)
    xi.updating = nil
    xi.echo("XaosInterface updated successfully!")
    config()

end

--will download the XaosInterface.xml file from the web
function xi.downloadPackage()

    if xi.downloadPath ~= "" then
        local path, file = profilePath .. xi.folder, xi.file
        xi.downloading = true
        downloadFile(path .. file, xi.downloadPath .. file)
    end

end

--handles our annonymus events
function xi.eventHandler(event, ...)

    --download done, if this package was downloading, check the file name and launch a function
    if event == "sysDownloadDone" and xi.downloading then
        local file = arg[1]
        if string.ends(file,"/versions.lua") then
            xi.downloading = false
            compareVersion()
        elseif string.ends(file,xi.file) then
            xi.downloading = false
            updatePackage()
        end
    --download error, if this package was downloading, toss a error to screen
    elseif event == "sysDownloadError" and xi.downloading then
        local file = arg[1]
        if string.ends(file,"/versions.lua") then
            xi.echo("xi failed to download file versions.lua")
        elseif string.ends(file,xi.file) then
            xi.echo("xi failed to download file XaosInterface.xml")
        end
    --package is being uninstalled, unregister our events
    elseif event == "sysUninstallPackage" and not xi.updating and arg[1] == "XaosInterface" then
        for _,id in ipairs(xi.registeredEvents) do
            killAnonymousEventHandler(id)
        end
    --the server has been coded to send IAC AYT on connect and reconnect, use this to kick into config()
    elseif event == "sysTelnetEvent" then
        if tonumber(arg[1]) == 246 then --246 is AYT
            xi.downloading = false
            config()
            xi.downloadVersions()
        end
    elseif event == "sysWindowResizeEvent" then
        --testing
    end

end

xi.annonEvents = { --all of the events we will need to trigger on
    registerAnonymousEventHandler("sysDownloadDone", "xi.eventHandler"),
    registerAnonymousEventHandler("sysDownloadError", "xi.eventHandler"),
    registerAnonymousEventHandler("sysUninstallPackage", "xi.eventHandler"),
    registerAnonymousEventHandler("sysTelnetEvent", "xi.eventHandler"),
    registerAnonymousEventHandler("sysWindowResizeEvent","xi.eventHandler")
    }

xi.namedEvents = { --all of the events we will need to trigger on
    registerNamedEventHandler("noax","handle_SHIELDER","msdp.SHIELDER_MAX",playerGaugesAdjustment),
    --registerNamedEventHandler("noax","handle_PARTY_MEM","msdp.PARTY_MEM",on_PARTY_MEM),
    registerNamedEventHandler("noax","handle_IN_ROOM","msdp.IN_ROOM",on_IN_ROOM),
    }