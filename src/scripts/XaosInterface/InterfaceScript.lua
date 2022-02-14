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
------------------------------------------------------------------------

--setup global table for msdp, the client will put things here automatically.
--keep in mind other packages will work with this table.
--table should always be created as seen below, so you don't overwrite.
msdp = msdp or {}

local profilePath = getMudletHomeDir() --setup profilePath so we can use in in functions below.
profilePath = profilePath:gsub("\\","/") --fix the path for windows folks

--Setup global table for XaosInterface.
xi = xi or {
    version = 0.2, --version we compare for updating
    downloading = false, --if we are downloading an update
    downloadPath = "https://raw.githubusercontent.com/nsweeting2/Xaos-UI/main/XaosInterface/", --path we download files from
    folder = "/xaosinterface",
    file = "XaosInterface.xml",
    updating = false, --if we are installing an update
    neededMSDP = { --all of the msdp variable we will be requesting from the server
        [[CHARACTER_NAME]], [[CHARACTER_ID]],
        [[HEALTH]], [[HEALTH_MAX]],
        [[MOVEMENT]], [[MOVEMENT_MAX]],
        [[MANA]], [[MANA_MAX]],
        [[EXPERIENCE]], [[EXPERIENCE_MAX]],
        [[HERO_EXP]], [[HERO_EXP_TNL]],
        [[ASCEND_EXP]], [[ASCEND_EXP_MAX]],
        [[SHIELD_UNIT]], [[PARTY_MEM]],
        [[IN_ROOM]],
        },
    stylesheet = { -- all of our stylesheets, I think we should consider loading these from a lua file... 
        [ [[shieldbar_front]] ] = [[
            background-color: rgba(155, 155, 155, 80%);
            border-width: 1px;
            border-color: black;
            border-style: solid;
            border-radius: 7;
            padding: 3px;
            ]],
        [ [[shieldbar_back]] ] = [[
            background-color: rgba(155, 155, 155, 50%);
            border-width: 1px;
            border-color: black;
            border-style: solid;
            border-radius: 7;
            padding: 3px;
            ]],
        [ [[hpbar_front]] ] = [[
            background-color: rgba(0, 255, 0,100%);
            border-width: 1px;
            border-color: black;
            border-style: solid;
            border-radius: 7;
            padding: 3px;
            ]],
        [ [[hpbar_back]] ] = [[
            background-color: rgba(0, 255, 0,50%);
            border-width: 1px;
            border-color: black;
            border-style: solid;
            border-radius: 7;
            padding: 3px;
            ]],
        [ [[manabar_front]] ] = [[
            background-color: rgba(0, 0, 255, 100%);
            border-width: 1px;
            border-color: black;
            border-style: solid;
            border-radius: 7;
            padding: 3px;
            ]],
        [ [[manabar_back]] ] = [[
            background-color: rgba(0, 0, 255, 50%);
            border-width: 1px;
            border-color: black;
            border-style: solid;
            border-radius: 7;
            padding: 3px;
            ]],
        [ [[movebar_front]] ] = [[
            background-color: rgba(198, 198, 0, 100%);
            border-width: 1px;
            border-color: black;
            border-style: solid;
            border-radius: 7;
            padding: 3px;
            ]],
        [ [[movebar_back]] ] = [[
            background-color: rgba(198, 198, 0, 50%);
            border-width: 1px;
            border-color: black;
            border-style: solid;
            border-radius: 7;
            padding: 3px;
            ]],
        [ [[expbar_front]] ] = [[
            background-color: rgba(155,0,225, 100%);
            border-width: 1px;
            border-color: black;
            border-style: solid;
            border-radius: 7;
            padding: 3px;
            ]],
        [ [[expbar_back]] ] = [[
            background-color: rgba(155,0,225, 75%);
            border-width: 1px;
            border-color: black;
            border-style: solid;
            border-radius: 7;
            padding: 3px;
            ]],
        [ [[herobar_front]] ] = [[
            background-color: rgba(155,0,225, 15%);
            border-width: 1px;
            border-color: black;
            border-style: solid;
            border-radius: 7;
            padding: 3px;
            ]],
        [ [[herobar_back]] ] = [[
            background-color: rgba(0,0,0, 0%);
            border-width: 1px;
            border-color: black;
            border-style: solid;
            border-radius: 7;
            padding: 3px;
            ]],
        },
    gaugeState = { false, false, false, false, false, false, }, -- table to hold the settings for the gauges display type
    }

--formatting for stylized echos
local xiTag = "<DarkViolet>[-XAOS-<DarkViolet>]  - <reset>"

--echo function for style points
function xi.echo(text)

    cecho(xiTag .. text .. "\n")

end

--GEYSER WORK GOES HERE

local function buildGaugeArea()

    --setup adjustable container
    xi.gaugeAdjCon =  xi.gaugeAdjCon or Adjustable.Container:new({
        name = "gaugeAdjCon",
        adjLabelstyle = "background-color:rgba(220,220,220,100%); border: 5px groove grey;",
        buttonstyle = [[
            QLabel{ border-radius: 7px; background-color: rgba(140,140,140,100%);}
            QLabel::hover{ background-color: rgba(160,160,160,50%);}
            ]],
        buttonFontSize = 10,
        buttonsize = 20,
        titleText = "Gauge Area",
        titleTxtColor = "black",
        padding = 15,
        })

    --now we make a vbox with four hbox's in it
    xi.gaugeVCon = xi.gaugeVCon or Geyser.VBox:new({
        name = "gaugeVCon",
        x = 0, y = 0,
        width = "100%", height = "100%"
        },xi.gaugeAdjCon)

    xi.gaugeHCon1 = xi.gaugeHCon1 or Geyser.HBox:new({
        name = "gaugeHCon1",
        },xi.gaugeVCon)

    xi.gaugeHCon2 = xi.gaugeHCon2 or Geyser.HBox:new({
        name = "gaugeHCon2",
        },xi.gaugeVCon)

    xi.gaugeHCon3 = xi.gaugeHCon3 or Geyser.HBox:new({
        name = "gaugeHCon3",
        },xi.gaugeVCon)

    xi.gaugeHCon4 = xi.gaugeHCon4 or Geyser.HBox:new({
        name = "gaugeHCon4",
        },xi.gaugeVCon)

    --spawn three gauges in our third hbox, for shield, hp, and mana
    --Shielder Gauge
    xi.shieldbar = xi.shieldbar or Geyser.Gauge:new({
        name = "shieldbar",
        },xi.gaugeHCon3)

    xi.shieldbar.front:setStyleSheet(xi.stylesheet.shieldbar_front)
    xi.shieldbar.back:setStyleSheet(xi.stylesheet.shieldbar_back)
    xi.shieldbar.text:setToolTip("Shielding Unit", "10")
    --xi.shieldbar.text:setDoubleClickCallback("gaugeDisplayToggle",1)
    xi.shieldbar.text:setDoubleClickCallback(function() xi.gaugeDisplayToggle(1) end)
    xi.shieldbar:hide()

    --HP Gauge
    xi.hpbar = xi.hpbar or Geyser.Gauge:new({
        name = "hpbar",
        },xi.gaugeHCon3)

    xi.hpbar.front:setStyleSheet(xi.stylesheet.hpbar_front)
    xi.hpbar.back:setStyleSheet(xi.stylesheet.hpbar_back)
    xi.hpbar.text:setToolTip("Health", "10")
    --xi.hpbar.text:setDoubleClickCallback("gaugeDisplayToggle",2)
    xi.hpbar.text:setDoubleClickCallback(function() xi.gaugeDisplayToggle(2) end)
    xi.hpbar:hide()

    --Mana Gauge
    xi.manabar = xi.manabar or Geyser.Gauge:new({
        name = "manabar",
        },xi.gaugeHCon3)

    xi.manabar.front:setStyleSheet(xi.stylesheet.manabar_front)
    xi.manabar.back:setStyleSheet(xi.stylesheet.manabar_back)
    xi.manabar.text:setToolTip("Mana", "10")
    --xi.manabar.text:setDoubleClickCallback("xi.gauge_toggle",3)
    xi.manabar.text:setDoubleClickCallback(function() xi.gaugeDisplayToggle(3) end)
    xi.manabar:hide()

    --spawn three gauges in our fourth hbox, for movement, hero exp, and exp
    --Move Gauge
    xi.movebar = xi.movebar or Geyser.Gauge:new({
        name = "movebar",
        },xi.gaugeHCon4)

    xi.movebar.front:setStyleSheet(xi.stylesheet.movebar_front)
    xi.movebar.back:setStyleSheet(xi.stylesheet.movebar_back)
    xi.movebar.text:setToolTip("Movement", "10")
    --xi.movebar.text:setDoubleClickCallback("gaugeDisplayToggle",2)
    xi.movebar.text:setDoubleClickCallback(function() xi.gaugeDisplayToggle(4) end)
    xi.movebar:hide()

    --Exp Gauge
    xi.expbar = xi.expbar or Geyser.Gauge:new({
        name = "expbar",
        },xi.gaugeHCon4)

    xi.expbar.front:setStyleSheet(xi.stylesheet.expbar_front)
    xi.expbar.back:setStyleSheet(xi.stylesheet.expbar_back)
    xi.expbar.text:setToolTip("Experience", "10")
    --xi.expbar.text:setDoubleClickCallback("xi.gauge_toggle",3)
    xi.expbar.text:setDoubleClickCallback(function() xi.gaugeDisplayToggle(5) xi.gaugeDisplayToggle(6) end)
    xi.expbar:hide()

    --HeroExp Gauge
    xi.herobar = xi.herobar or Geyser.Gauge:new({
        name = "herobar",
        },xi.gaugeHCon4)

    xi.herobar.front:setStyleSheet(xi.stylesheet.herobar_front)
    xi.herobar.back:setStyleSheet(xi.stylesheet.herobar_back)
    --xi.herobar.text:setToolTip("Hero Experience", "10")
    --xi.herobar.text:setDoubleClickCallback("xi.gauge_toggle",3)
    xi.herobar.text:setDoubleClickCallback(function() xi.gaugeDisplayToggle(5) xi.gaugeDisplayToggle(6) end)
    xi.herobar:hide()

    --put everyone in their place
    xi.gaugePosAdjustment()

    --xi.gaugesAdjCon:hide()

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
    
    --setup our gauge area
    buildGaugeArea()

    --and we are done configuring QuestingWithNoax
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
        enableAlias("QuestingUpdate")
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

--will uninstall QuestingWithNoax and reinstall QuestingWithNoax
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

--will download the CombatTracker.xml file from the web
function xi.downloadPackage()

    if xi.downloadPath ~= "" then
        local path, file = profilePath .. xi.folder, xi.file
        xi.downloading = true
        downloadFile(path .. file, xi.downloadPath .. file)
    end

end

--MSDP WORK GOES HERE
local function on_HEALTH()

    xi.hpbar:show()
    xi.gaugePosAdjustment()

    if msdp.HEALTH == nil or msdp.HEALTH_MAX == nil then
        return
    end

    if xi.gaugeState[2] == true then
        local percent = math.floor((tonumber(msdp.HEALTH)/ tonumber(msdp.HEALTH_MAX)) * 100)
        xi.hpbar:setText("<center>&#x2665;<strong> " .. tostring(percent) .. "%")
    else
        xi.hpbar:setText("<center>&#x2665;<strong> " .. tostring(msdp.HEALTH) .. "/" .. tostring(msdp.HEALTH_MAX))
    end

    xi.hpbar:setValue(tonumber(msdp.HEALTH), tonumber(msdp.HEALTH_MAX))

end

local function on_MOVEMENT()

    xi.movebar:show()
    xi.gaugePosAdjustment()

    if msdp.MOVEMENT == nil or msdp.MOVEMENT_MAX == nil then
        return
    end

    if xi.gaugeState[4] == true then
        local percent = math.floor((tonumber(msdp.MOVEMENT)/ tonumber(msdp.MOVEMENT_MAX)) * 100)
        xi.movebar:setText("<center>&#x1F9B6;<strong> " .. tostring(percent) .. "%")
    else
        xi.movebar:setText("<center>&#x1F9B6;<strong> " .. tostring(msdp.MOVEMENT) .. "/" .. tostring(msdp.MOVEMENT_MAX))
    end
    xi.movebar:setValue(tonumber(msdp.MOVEMENT), tonumber(msdp.MOVEMENT_MAX))

end

local function on_MANA()

    xi.manabar:show()
    xi.gaugePosAdjustment()

    if msdp.MANA == nil or msdp.MANA_MAX == nil then
        return
    end

    if xi.gaugeState[3] == true then
        local percent = math.floor((tonumber(msdp.MANA)/ tonumber(msdp.MANA_MAX)) * 100)
        xi.manabar:setText("<center>&#x1F9B6;<strong> " .. tostring(percent) .. "%")
    else
        xi.manabar:setText("<center>&#x1F9B6;<strong> " .. tostring(msdp.MANA) .. "/" .. tostring(msdp.MANA_MAX))
    end

    xi.manabar:setValue(tonumber(msdp.MANA), tonumber(msdp.MANA_MAX))

end

local function on_EXPERIENCE()

    xi.expbar:show()
    xi.herobar:show()
    xi.gaugePosAdjustment()

    if msdp.EXPERIENCE == nil or msdp.EXPERIENCE_MAX == nil then
        return
    end

    if msdp.HERO_EXP == nil or msdp.HERO_EXP_TNL == nil then
        return
    end

    if xi.gaugeState[5] == true then
        local percent1 = math.floor((tonumber(msdp.EXPERIENCE)/ tonumber(msdp.EXPERIENCE_MAX)) * 100)
        --xi.expbar:setText("<center>&#x1F310;<strong> " .. tostring(percent) .. "%")
        local percent2 = math.floor((tonumber(msdp.HERO_EXP)/ tonumber(msdp.HERO_EXP_TNL)) * 100)
        xi.herobar:setText("<center><strong>" .. tostring(percent1) .. "%  &#x1F310; | " .. tostring(percent2) .. "%  &#x1F310;")
    else
        --xi.expbar:setText("<center>&#x1F310;<strong> " .. tostring(msdp.EXPERIENCE) .. "/" .. tostring(msdp.EXPERIENCE_MAX))
        xi.herobar:setText("<center><strong>" .. tostring(msdp.HERO_EXP) .. "/" .. tostring(msdp.HERO_EXP_TNL) .. " &#x1F310; | " .. tostring(msdp.HERO_EXP) .. "/" .. tostring(msdp.HERO_EXP_TNL)  .. "&#x1F310;")
    end

    local current = msdp.EXPERIENCE
    local max = msdp.EXPERIENCE_MAX

    --them over experienced fools
    if current < max then
        current = max
    end

    xi.expbar:setValue(tonumber(current), tonumber(max))
    xi.herobar:setValue(tonumber(msdp.HERO_EXP), tonumber(msdp.HERO_EXP_TNL))

end

local function on_SHIELD_UNIT()

    if msdp.SHIELD_UNIT == "None" or msdp.SHIELD_UNIT == nil then
        xi.shieldbar:hide()
        xi.gaugePosAdjustment()
        return
    end

    local curr = 0
    local max = 0

    --idk why i did that, i should make it just a simple string in the server code
    --SHIELD_UNIT data comes in as a table so we need to iterate the table
    for k,v in pairs(msdp.SHIELD_UNIT) do
        curr, max = rex.match(v,[[^(\d+)\:(\d+)\:\d+\:\d+$]])
        --cecho("<yellow>[ DEBUG ] - <grey>SHIELD_UNIT updated to:"..tostring(v).."\n")
    end

    xi.shieldbar:show()
    xi.gaugePosAdjustment()

    if xi.gaugeState[1] == true then
        local percent = math.floor((tonumber(curr)/ tonumber(max)) * 100)
        xi.shieldbar:setText("<center>&#x1F6E1;<strong> " .. tostring(percent) .. "%")
    else
        xi.shieldbar:setText("<center>&#x1F6E1;<strong> " .. tostring(curr) .. "/" .. tostring(max))
    end

    xi.shieldbar:setValue(tonumber(curr), tonumber(max))

end

local function on_PARTY_MEM()

--this is getting recoded on the server level to be more helpful

    --cecho("<yellow>[ DEBUG ] - <grey>PARTY_MEM:\n")
    --display(msdp.PARTY_MEM)
    --local id = 0
    --local name = ""
    --local hp = 0
    --local mana = 0
    --local move = 0
    --local guarding = ""
    --local guarded = ""
    --local c = 0
    --local dump_watched = true
    --UI.lockedallybar:hide()
    --for i = 10, 18 do
      --UI.irbar[i]:hide()
    --end
    --UI.iroverflow2:hide()
    --if tonumber(UI.watched_ally) == 0 then
      --cecho("<yellow>[ DEBUG ] - <grey>PARTY_MEM: We need to adjust the bars to the left\n")
      --UI.irbars_adjust2(true)
    --else
      --cecho("<yellow>[ DEBUG ] - <grey>PARTY_MEM: We do need to adjust the bars to the right\n")
      --UI.irbars_adjust2(false)
    --end
    --for k,v in pairs(msdp.PARTY_MEM) do
      --c = c + 1
      --id, name, hp, mana, move, guarding, guarded = rex.match(v,[[^(\d+)\:(.*)\:(\d+)\:(\d+)\:(\d+)\:(\w+)\:(\w+)$]])
      --cecho("<yellow>[ DEBUG ] - <grey>PARTY_MEM: Rex gave "..tostring(id).. " for id\n")
      --cecho("<yellow>[ DEBUG ] - <grey>PARTY_MEM: Rex gave "..tostring(name).. " for name\n")
      --cecho("<yellow>[ DEBUG ] - <grey>PARTY_MEM: Rex gave "..tostring(hp).. " for hp\n")
      --cecho("<yellow>[ DEBUG ] - <grey>PARTY_MEM: Rex gave "..tostring(mana).. " for mana\n")
      --cecho("<yellow>[ DEBUG ] - <grey>PARTY_MEM: Rex gave "..tostring(move).. " for move\n")
      --cecho("<yellow>[ DEBUG ] - <grey>PARTY_MEM: Rex gave "..tostring(guarding).. " for guarding\n")
      --cecho("<yellow>[ DEBUG ] - <grey>PARTY_MEM: Rex gave "..tostring(guarded).. " for guarded\n")
      --if tonumber(id) == 0 then
        --cecho("<yellow>[ DEBUG ] - <grey>PARTY_MEM: Empty party\n")
        --return;
      --end
      --if tonumber(id) == tonumber(UI.watched_ally) then
        --UI.lockedallybar.text:setDoubleClickCallback("UI.set_watched_ally", 0)
        --UI.lockedallybar:setText("<center>&#x1F571;<strong> "..tostring(name).." ".. tostring(hp) .. "%")
        --UI.lockedallybar:setValue(tonumber(hp), 100)
        --UI.lockedallybar:show()
        --c = c - 1
        --dump_watched = false
      --else
        --if tonumber(c) > 9 then
          --cecho("<yellow>[ DEBUG ] - <grey>PARTY_MEM: More in room then ir bars available\n")
          --cecho("<yellow>[ DEBUG ] - <grey>PARTY_MEM: Show the overflow label\n")
          --UI.iroverflow2:show()
          --return;
        --end
        --UI.irbar[c + 9].text:setDoubleClickCallback("UI.set_watched_ally", id)
        --UI.irbar[c + 9]:setText("<center>&#x1F571;<strong> "..tostring(name).." ".. tostring(hp) .. "%")
        --UI.irbar[c + 9]:setValue(tonumber(hp), 100)
        --UI.irbar[c + 9]:show()
      --end
    --end
    --if dump_watched then
      --UI.set_watched_ally(0)
    --end

end

local function on_IN_ROOM()

    --cecho("<yellow>[ DEBUG ] - <grey>IN_ROOM:\n")
    --display(msdp.IN_ROOM)
    local id = 0
    local name = ""
    local hp = 0
    local move = 0
    local targetid = 0
    local targetname = ""
    local enemy = ""
    local c = 0
    for i = 1, 9 do
      UI.irbar[i]:hide()
    end
    UI.irbars_adjust1(true)
    UI.iroverflow1:hide()
    for k,v in pairs(msdp.IN_ROOM) do
      c = c + 1
      --cecho("<yellow>[ DEBUG ] - <grey>IN_ROOM: v contains  "..tostring(v).. " for rex\n")
      name, hp, move, targetid, targetname = rex.match(v,[[^(.*)\:(\d+)\:(\d+)\:(\d+)\:(.*)$]])
      --cecho("<yellow>[ DEBUG ] - <grey>IN_ROOM: Rex gave "..tostring(name).. " for name\n")
      --cecho("<yellow>[ DEBUG ] - <grey>IN_ROOM: Rex gave "..tostring(hp).. " for hp\n")
      --cecho("<yellow>[ DEBUG ] - <grey>IN_ROOM: Rex gave "..tostring(move).. " for move\n")
      --cecho("<yellow>[ DEBUG ] - <grey>IN_ROOM: Rex gave "..tostring(targetid).. " for target id\n")
      --cecho("<yellow>[ DEBUG ] - <grey>IN_ROOM: Rex gave "..tostring(targetname).. " for target name\n")
      if tostring(name) == "None" then
        --cecho("<yellow>[ DEBUG ] - <grey>IN_ROOM: Rex gave "..tostring(name).. " for target name\n")
        return
      end
      if tostring(targetname) == tostring(msdp.CHARACTER_NAME) then
        UI.irbar[c].front:setStyleSheet(UI.oppobarfrontStyleSheet)
        UI.irbar[c].back:setStyleSheet(UI.oppobarbackStyleSheet)
        UI.irbar[c]:setText("<center>&#x1F571;<strong> "..tostring(name).." ".. tostring(hp) .. "%")
        UI.irbar[c]:setValue(tonumber(hp), 100)
      else
        UI.irbar[c].front:setStyleSheet(UI.irbarfrontStyleSheet)
        UI.irbar[c].back:setStyleSheet(UI.irbarbackStyleSheet)
        UI.irbar[c]:setText("<center>&#x1F571;<strong> "..tostring(name).." ".. tostring(hp) .. "%")
        UI.irbar[c]:setValue(tonumber(hp), 100)
      end
      UI.irbar[c]:show()
    end

end

local function on_rewrap_window()

    mWidth, mHeight = getMainWindowSize()
    fWidth, fHeight = calcFontSize("main")
    lBorder = getBorderLeft()
    rBorder = getBorderRight()
    nSize = mWidth - lBorder - rBorder
    wrap = (nSize / fWidth - 1)
    setWindowWrap("main",wrap)
    setWindowWrap("middle",wrap)
    GUI.bottom:connectToBorder("left")
    GUI.bottom:connectToBorder("right")
    GUI.middle:attachToBorder("right")
    GUI.middle:attachToBorder("left")
    GUI.middle:attachToBorder("bottom")
    GUI.middle:attachToBorder("top")
    GUI.middle:connectToBorder("right")
    GUI.middle:connectToBorder("left")
    GUI.middle:connectToBorder("top")
    GUI.middle:connectToBorder("bottom")
    echo("fwidth " ..fWidth.."fheight " ..fHeight.. " lBorder " ..lBorder.. " rBorder " ..rBorder.. " nSize " ..nSize.. " wrap " ..wrap)

end

function xi.gaugePosAdjustment()

    if tostring(msdp.SHIELD_UNIT) == "None"
        or tostring(msdp.SHIELD_UNIT) == ""
        or  msdp.SHIELD_UNIT == nil then
        xi.hpbar:move(0,0)
        xi.manabar:move("50%",0)
        xi.hpbar:resize("50%","100%")
        xi.manabar:resize("25%","100%")
    else
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

function xi.gaugeDisplayToggle(index)

    --check we got a good index
    if tonumber(index) > #xi.gaugeState then
        return
    end

    --flip the bool
    if xi.gaugeState[index] == nil or xi.gaugeState[index] == false then
        xi.gaugeState[index] = true
    else
        xi.gaugeState[index] = false
    end

    --force an update of the relevant gauge
    if tonumber(index) == 1 then
        on_SHIELD_UNIT()
    elseif tonumber(index) == 2 then
        on_HEALTH()
    elseif tonumber(index) == 3 then
        on_MANA()
    elseif tonumber(index) == 4 then
        on_MOVEMENT()
    elseif tonumber(index) == 5 then
        on_EXPERIENCE()
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
    registerNamedEventHandler("noax","handle_HEALTH","msdp.HEALTH",on_HEALTH),
    registerNamedEventHandler("noax","handle_HEALTH_MAX","msdp.HEALTH_MAX",on_HEALTH),
    registerNamedEventHandler("noax","handle_MOVEMENT","msdp.MOVEMENT",on_MOVEMENT),
    registerNamedEventHandler("noax","handle_MOVEMENT_MAX","msdp.MOVEMENT_MAX",on_MOVEMENT),
    registerNamedEventHandler("noax","handle_MANA","msdp.MANA",on_MANA),
    registerNamedEventHandler("noax","handle_MANA_MAX","msdp.MANA_MAX",on_MANA),
    registerNamedEventHandler("noax","handle_EXPERIENCE","msdp.EXPERIENCE",on_EXPERIENCE),
    registerNamedEventHandler("noax","handle_EXPERIENCE_MAX","msdp.EXPERIENCE_MAX",on_EXPERIENCE),
    registerNamedEventHandler("noax","handle_HERO_EXP","msdp.HERO_EXP",on_EXPERIENCE),
    registerNamedEventHandler("noax","handle_HERO_EXP_TNL","msdp.HERO_EXP_TNL",on_EXPERIENCE),
    registerNamedEventHandler("noax","handle_SHIELD_UNIT","msdp.SHIELD_UNIT",on_SHIELD_UNIT),
    registerNamedEventHandler("noax","handle_PARTY_MEM","msdp.PARTY_MEM",on_PARTY_MEM),
    registerNamedEventHandler("noax","handle_IN_ROOM","msdp.IN_ROOM",on_IN_ROOM),
    }