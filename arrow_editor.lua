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
    !text: tr('Arrows - Editor')

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
  height: 260

  Label
    id: singleLabel
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    margin-left: 0
    margin-right: 83
    margin-top: 5
    text-align: center
    text: "Single"
    font: verdana-11px-rounded

  BotItem
    id: defaultLeftItem
    anchors.left: parent.left
    anchors.top: singleLabel.bottom
    margin-left: 30
    margin-top: 2

  Label
    id: AOELabel
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    margin-left: 80
    margin-top: 5
    text-align: center
    text: "AOE"
    font: verdana-11px-rounded

  BotItem
    id: defaultRightItem
    anchors.right: parent.right
    anchors.top: AOELabel.bottom
    margin-right: 30
    margin-top: 2

  Label
    id: quiverLabel
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: prev.bottom
    margin-top: 10
    text: "Backpack or Quiver"
    font: verdana-11px-rounded

  BotItem
    id: defaultCenterItem
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: prev.bottom
    margin-top: 2

  Label
    id: monstersCountLabel
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.right: parent.right
    anchors.top: prev.bottom
    margin-top: 10
    text-align: center
    font: verdana-11px-rounded

  HorizontalScrollBar
    id: scrollOne
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: prev.bottom
    margin-top: 5
    minimum: 2
    maximum: 10
    step: 1

  CheckBox
    id: playerScreen
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: prev.bottom
    margin-left: 40
    margin-top: 12
    text: "Players in Screen"
    color: #fe4400
    font: verdana-11px-rounded

  Label
    id: ignorePlayersLabel
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: prev.bottom
    margin-top: 15
    text-align: center
    text: "Ignore Players:"
    font: verdana-11px-rounded

  BotTextEdit
    id: ignorePlayersText
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: prev.bottom
    margin-top: 5
    width: 140

  Label
    id: labelOwner
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: prev.bottom
    margin-top: 15
    text-align: center
    font: verdana-11px-rounded
]])
config:hide()

local panelStorage = "Arrows - Editor"

local slot = SlotRight -- Inside the Quiver is SlotRight or SlotLeft, if outside then SlotAmmo.
macro(100, function()
  if not storage[panelStorage].enabled then
    return
	end

  local function playerinScreen()
		for _, spec in ipairs(getSpectators()) do
			if spec ~= g_game.getLocalPlayer() and spec:isPlayer() then
				return true
			end
		end
		return false
	end

  if storage[panelStorage].playerScreen then
    if getMonsters(7) >= storage[panelStorage].monstersCount then
      moveToSlot(storage[panelStorage].defaultRightItem, slot)
    else
      moveToSlot(storage[panelStorage].defaultLeftItem, slot)
    end
  else
    if getPlayers(7 , false) > 0 then
      moveToSlot(storage[panelStorage].defaultLeftItem, slot)
    else
      if getMonsters(7) >= storage[panelStorage].monstersCount then
        moveToSlot(storage[panelStorage].defaultRightItem, slot)
      else
        moveToSlot(storage[panelStorage].defaultLeftItem, slot)
      end
    end
  end
end)

-- Storage
-- It will be saved in the Storage folder and choose your profile_1.json.
storage[panelStorage] = storage[panelStorage] or
{
	enabled = false,
	defaultLeftItem = 3447,
  defaultRightItem = 3449,
  defaultCenterItem = 35562,
	playerScreen = true,
	monstersCount = 2,
  ignorePlayers = "Monaco, Pusher"
}

do
  config.defaultLeftItem:setItemId(storage[panelStorage].defaultLeftItem)
  config.defaultLeftItem.onItemChange = function(self) storage[panelStorage].defaultLeftItem = self:getItemId() end
  config.defaultRightItem:setItemId(storage[panelStorage].defaultRightItem)
  config.defaultRightItem.onItemChange = function(self) storage[panelStorage].defaultRightItem = self:getItemId() end
  config.defaultCenterItem:setItemId(storage[panelStorage].defaultCenterItem)
  config.defaultCenterItem.onItemChange = function(self) storage[panelStorage].defaultCenterItem = self:getItemId() end
  config.scrollOne.onValueChange = function(scroll, value) monstersCount = value storage[panelStorage].monstersCount = monstersCount config.monstersCountLabel:setText("Monsters Count >= " .. monstersCount) end
  config.scrollOne:setValue(storage[panelStorage].monstersCount)
  config.monstersCountLabel:setText("Monsters Count >= " .. storage[panelStorage].monstersCount)
  config.playerScreen:setChecked(storage[panelStorage].playerScreen or false)
  config.playerScreen.onClick = function(widget) local currentCheckedState = widget:isChecked() storage[panelStorage].playerScreen = not currentCheckedState widget:setChecked(not currentCheckedState) end
  config.ignorePlayersText:setText(storage[panelStorage].ignorePlayers or storage[panelStorage].ignorePlayers)
  config.ignorePlayersText.onTextChange = function(widget, text) storage[panelStorage].ignorePlayers = text end
end

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

-- Main Window UI
ui.title:setOn(storage[panelStorage].enabled)
ui.title.onClick = function(widget)
    storage[panelStorage].enabled = not storage[panelStorage].enabled
    widget:setOn(storage[panelStorage].enabled)
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
  local text = "<> Kazadoru <>"
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