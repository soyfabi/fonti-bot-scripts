-- Rune: UE - Editor -- 
-- Rune
-- Players in Screen
-- Monsters Count for Spells UE

-- Storage
-- It will be saved in the Storage folder and choose your profile_1.json.
local panelStorage = "Rune: UE - Editor"
storage[panelStorage] = storage[panelStorage] or
{
	enabled = false,
	runeItem = 3155,
	ueSpells = "exevo gran mas frigo",
	mpPercent = 25,
	playersInScreen = false,
	monstersCount = 3,
}

macro(100, function()
	local target = g_game.getAttackingCreature()
	if not target then return end

	if not storage[panelStorage].enabled then
		return
	end

	local playerPosition = g_game.getLocalPlayer():getPosition()
	local monstersScreen = g_map.getSpectators(playerPosition, false)

	local function playerinScreen()
		for _, spec in ipairs(getSpectators()) do
			if spec ~= g_game.getLocalPlayer() and spec:isPlayer() then
				return true
			end
		end
		return false
	end

	local monsterCount = 0
	for _, creature in ipairs(monstersScreen) do
		if creature:isMonster() then
			local creaturePosition = creature:getPosition()
			local distance = math.sqrt((creaturePosition.x - playerPosition.x) ^ 2 +
				(creaturePosition.y - playerPosition.y) ^ 2)
			if distance <= 7 then
				monsterCount = monsterCount + 1
			end
		end
	end

	if storage[panelStorage].playersInScreen then
		if monsterCount >= storage[panelStorage].monstersCount then
			if manapercent() >= storage[panelStorage].mpPercent then
				say(storage[panelStorage].ueSpells)
			else
				if findItem(storage[panelStorage].runeItem) then
					useWith(storage[panelStorage].runeItem, target)
				end
			end
		else
			if findItem(storage[panelStorage].runeItem) then
				useWith(storage[panelStorage].runeItem, target)
			end
		end
	else
		if playerinScreen() then
			if findItem(storage[panelStorage].runeItem) then
				useWith(storage[panelStorage].runeItem, target)
			end
		else
			if monsterCount >= storage[panelStorage].monstersCount then
				if manapercent() >= storage[panelStorage].mpPercent then
					say(storage[panelStorage].ueSpells)
				else
					if findItem(storage[panelStorage].runeItem) then
						useWith(storage[panelStorage].runeItem, target)
					end
				end
			else
				if findItem(storage[panelStorage].runeItem) then
					useWith(storage[panelStorage].runeItem, target)
				end
			end
		end
	end
end)

local ui = setupUI([[
Panel
  height: 19

  BotSwitch
    id: title
    anchors.top: parent.top
    anchors.left: parent.left
    text-align: center
    width: 130
    font: verdana-11px-rounded
    !text: tr("Rune: UE - Editor")

  Button
    id: edit
    anchors.top: prev.top
    anchors.left: prev.right
    anchors.right: parent.right
    margin-left: 3
    height: 17
    text: "Config"
    font: verdana-9px-italic
]])

local config = setupUI([[
Panel
  height: 185

  Label
    id: runeBox
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    margin-top: 5
    text-align: center
    text: "Rune"
    font: verdana-11px-rounded

  BotItem
    id: runeItem
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: runeBox.bottom
    margin-top: 5

  Label
    id: ueBox
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: prev.bottom
    margin-top: 7
    margin-left: 45
    text-align: left
    text: "Spell UE"
    font: verdana-11px-rounded

  BotTextEdit
    id: ueSpells
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: prev.bottom
    margin-top: 0
    margin-left: -15
    width: 140

  Label
    id: mpLabel
    anchors.right: parent.right
    anchors.top: ueBox.top
    text-align: right
    text: "MP%"
    font: verdana-11px-rounded

  BotTextEdit
    id: mpText
    anchors.right: parent.right
    anchors.top: ueSpells.top
    width: 30

  CheckBox
    id: boxPlayers
    anchors.left: parent.left
    anchors.top: mpText.bottom
    margin-top: 10
    margin-left: 18

  Label
    id: playersInScreen
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: boxPlayers.top
    text-align: center
    text: "Players In Screen"
    font: verdana-11px-rounded
    color: #fe4400

  Label
    id: scrollCount
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: playersInScreen.bottom
    margin-top: 10
    text-align: center
    text: "Monsters Count"
    font: verdana-11px-rounded

  HorizontalScrollBar
    id: scrollBarCount
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: scrollCount.bottom
    margin-left: 5
    margin-right: 5
    margin-top: 2
    minimum: 1
    maximum: 10
    step: 1

  Label
    id: labelOwner
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: scrollBarCount.bottom
    margin-top: 10
    text-align: center
    font: verdana-11px-rounded
]])
config:hide()

-- Main Window UI
ui.title:setOn(storage[panelStorage].enabled)
ui.title.onClick = function(widget)
    storage[panelStorage].enabled = not storage[panelStorage].enabled
    widget:setOn(storage[panelStorage].enabled)
end

do
    config.runeItem:setItemId(storage[panelStorage].runeItem)
    config.runeItem.onItemChange = function(self)
        storage[panelStorage].runeItem = self:getItemId()
    end
end

config.ueSpells:setText(storage[panelStorage].ueSpells or storage[panelStorage].ueSpells)
config.mpText:setText(storage[panelStorage].mpPercent)

config.ueSpells.onTextChange = function(widget, text)
    storage[panelStorage].ueSpells = text
end

config.mpText.onTextChange = function(widget, text)
    storage[panelStorage].mpPercent = tonumber(text)
end

config.boxPlayers:setChecked(storage[panelStorage].playersInScreen or false)
config.boxPlayers.onClick = function(widget)
    local currentCheckedState = widget:isChecked()
    storage[panelStorage].playersInScreen = not currentCheckedState
    widget:setChecked(not currentCheckedState)
end

config.scrollBarCount.onValueChange = function(scroll, value)
    monstersCount = value
    storage[panelStorage].monstersCount = monstersCount
    config.scrollCount:setText("Monsters Count: " .. monstersCount)
end

config.scrollBarCount:setValue(storage[panelStorage].monstersCount)
config.scrollCount:setText("Monsters Count: " .. storage[panelStorage].monstersCount)

-- Show or Hide Edit
local showEdit = false
ui.edit.onClick = function(widget)
    showEdit = not showEdit
    if showEdit then
        config:show()
    else
        config:hide()
    end
end

-- Trade Mark --// FUNCTION
function setRainbowColor(time)
    local r = math.floor(127 * math.sin(time) + 128)
    local g = math.floor(127 * math.sin(time + 2 * math.pi / 3) + 128)
    local b = math.floor(127 * math.sin(time + 4 * math.pi / 3) + 128)
    return string.format("#%02X%02X%02X", r, g, b)
end

function setBrightWhiteGlowColor()
    return "#dfbae9"
end

local glowPosition = 1
local glowDirection = 1

macro(5, function()
    local text = "<@!--^ FbnScripts v--!@>"
    local coloredText = {}

    local numChars = #text
    local glowRange = math.max(1, math.floor(numChars / 20))
    local time = os.clock() * 4

    for i = 1, numChars do
        local char = text:sub(i, i)
        local color = setRainbowColor(time + (i / 2))
        if math.abs(i - glowPosition) <= glowRange then
            color = setBrightWhiteGlowColor()
        end
        table.insert(coloredText, char)
        table.insert(coloredText, color)
    end

    glowPosition = glowPosition + glowDirection
    if glowPosition > numChars then
        glowPosition = numChars - 1
        glowDirection = -1
    elseif glowPosition < 1 then
        glowPosition = 2
        glowDirection = 1
    end

    if config.labelOwner and config.labelOwner.setColoredText then
        config.labelOwner:setColoredText(coloredText)
    end
end)
-- End Trade Mark

UI.Separator()
